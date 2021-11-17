`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/08 14:48:17
// Design Name: 
// Module Name: Pooling
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   The module for neural network's average pooling layer.
// Dependencies: 
// 
// Revision:
// Revision 0.04 - TODO: Fix acc_enable, acc_clear and acc_load logic
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PoolingAvg
  #(
    parameter INWIDTH = 16, // Input data width
              IN_FRAC = 12, // Width of fractional part of input (and output) data
              ACC_WIDTH = 28 // Accumulation width
  )
  (
    input       CLK   , 
    input       RESET ,
    input       EN    ,
    input [1:0] PLTY  , // Type of pooling (2'b00->nop, 2'b01->avg TYPE1_LEN, 2'b10->avg TYPE2_LEN, 2'b11->sum)
    input       START , // Start pooling process (feed data, do the calculation and output)
    input  signed [INWIDTH-1:0] DIN       ,
    input                       DIN_VLD   , // Valid flag of DIN
    output                      DIN_RDY   , // Ready flag of DIN
    output signed [INWIDTH-1:0] DOUT      ,
    output                      DOUT_VLD  ,
    input                       DOUT_RDY  ,
    output                      DOUT_OVFL // Overflow flag of DOUT
  );

  function integer width_for(input integer dat); // The minimum bits to store dat
    begin
      width_for = $clog2(dat + 1);
    end
  endfunction

  function integer max(input integer a, input integer b);
    begin
      max = (a > b) ? a : b;
    end
  endfunction

  localparam  TYPE1_H = 25, // TYPE1 pooling input feature map height
              TYPE1_W = 13, // TYPE1 pooling ifm width
              TYPE1_K = 25, // TYPE1 pooling kernel height
              TYPE1_L = 13, // TYPE1 pooling kernel width

              TYPE2_H = 100, // TYPE2 pooling input feature map height
              TYPE2_W = 40,  // TYPE2 pooling ifm width
              TYPE2_K = 4,   // TYPE2 pooling kernel height
              TYPE2_L = 3;   // TYPE2 pooling kernel width
  localparam TYPE1_LEN = TYPE1_H * TYPE1_W, // The ifm length of TYPE1 pooling 
             TYPE2_LEN = TYPE2_H * TYPE2_W; // The ifm length of TYPE2 pooling
  localparam ADDR_WIDTH = width_for(max(TYPE1_LEN, TYPE2_LEN));
  localparam [2:0] IDLE = 3'b000, // Initial state
                   DECD = 3'b001, // Decode PLTY
                   INPT = 3'b011, // Receive data input
                   AVRG = 3'b010, // Do the accumulation and division (arithmetic right shift)
                   OUTP = 3'b110; // Output result
  localparam ADGEN_HEIGHT_WIDTH = width_for(max(max(TYPE1_H ,TYPE2_H), max(TYPE1_W , TYPE2_W)));
  localparam ADGEN_KERSIZE_WIDTH = width_for(max(max(TYPE1_K ,TYPE2_K), max(TYPE1_L , TYPE2_L)));

  reg [ADDR_WIDTH-1:0] icounter; // Counter for counting input transfers
  reg [1:0] plty_cache; // Cache PLTY input when Sreg is IDLE and START=1
  reg [2:0] Sreg, Snext; // State register and next state logic
  
  reg  pooling_type; // 0 is TYPE1, 1 is TYPE2
  reg  icounter_wrap; // If icounter reaches (TYPEx_LEN - 1) 
  reg  icwrap_reg;
  reg  inready;
  wire average_done;
  wire input_transfer = (DIN_VLD & DIN_RDY);
  wire output_success = (DOUT_RDY & DOUT_VLD);

  reg  signed [INWIDTH-1:0] din_buffer;

  reg      [ADDR_WIDTH-1:0] ram_addr;
  reg                       ram_we;
  wire        [INWIDTH-1:0] ram_dout_raw;
  wire signed [INWIDTH-1:0] ram_dout = $signed(ram_dout_raw);
  
  reg  acc_enable, acc_load;
  // wire acc_enable = adgen_addr_vld_d[3]; // 1 tick for addr buffer, 2 ticks for RAM
  // wire acc_load = adgen_addr_pack_d[4] & adgen_addr_vld_d[4]; // in which 2 ticks are for RAM
  wire acc_clear = adgen_addr_last_d[5]; // No need to &adgen_addr_vld_d[5] since LAST will only be valid when VLD is valid
  wire signed [ACC_WIDTH-1:0] acc_sum;
  wire signed [INWIDTH-1:0] acc_din = ram_dout;

  reg  adgen_start;
  wire adgen_addr_last, adgen_addr_vld, adgen_addr_pack;
  reg  [8:1] adgen_addr_vld_d, adgen_addr_pack_d, adgen_addr_last_d; // About the 8 here:
  reg  [ADGEN_HEIGHT_WIDTH-1:0]  adgen_h, adgen_w;
  reg  [ADGEN_KERSIZE_WIDTH-1:0] adgen_l, adgen_k;
  wire [ADDR_WIDTH-1:0]          adgen_addr;

  reg  signed [ACC_WIDTH-5:0] out_data;
  wire signed [INWIDTH-1:0] round_dout;
  wire                      round_ovfl;

  wire [INWIDTH:0]  ofifo_dout;
  wire              ofifo_full, ofifo_empty;
  wire              ofifo_write;

  always @(posedge CLK) begin : state_transition
    if (RESET) Sreg <= IDLE;
    else if (EN) Sreg <= Snext;
  end

  always @(*) begin : next_state_logic
    case (Sreg)
      IDLE: if (START == 1) Snext = DECD; 
            else Snext = IDLE;
      DECD: if ((plty_cache == 2'b01) || (plty_cache == 2'b10))
              Snext = INPT;
            else
              Snext = IDLE;
      INPT: if (icounter_wrap && input_transfer)
              Snext = AVRG;
            else
              Snext = INPT;
      AVRG: if (average_done)
              Snext = OUTP;
            else
              Snext = AVRG;
      OUTP: if (ofifo_empty)
              Snext = IDLE;
            else
              Snext = OUTP;
      default: Snext = IDLE;
    endcase
  end

  always @(posedge CLK) begin : buffer_DIN
    if (RESET) begin
      din_buffer <= 0;
    end
    else if (EN) begin
      if (input_transfer) begin
        din_buffer <= DIN;
      end
      else begin
        din_buffer <= din_buffer;
      end
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      icwrap_reg <= 0;
    end
    else if (EN) begin
      icwrap_reg <= icounter_wrap;
    end
  end

  always @(posedge CLK) begin : ram_i_signals
    if (RESET) begin
      ram_addr <= 0;
      ram_we <= 0;
    end
    else if (EN) begin
      if (input_transfer) begin
        ram_addr <= icounter;
        ram_we <= 1;
      end
      else begin
        ram_we <= icwrap_reg;
        if (adgen_addr_vld) begin
          ram_addr <= adgen_addr;
        end
      end
    end
  end

  always @(posedge CLK) begin : cache_PLTY
    if (RESET) begin
      plty_cache <= 2'b0;
    end
    else if (EN && (START == 1) && (Sreg == IDLE)) begin
      plty_cache <= PLTY;
    end
  end

  always @(posedge CLK) begin : decode_PLTY
    if (RESET) begin
      pooling_type <= 0;
    end 
    else if (EN && (Sreg == DECD)) begin
      case (plty_cache)
        2'b01: pooling_type <= 0;
        2'b10: pooling_type <= 1;
        default: pooling_type <= 0; // Invalid PLTYs
      endcase
    end
  end

  always @(posedge CLK) begin
    if (RESET)
      inready <= 0;
    else if (EN)
      inready <= !icounter_wrap && (Sreg == INPT);
  end

  always @(posedge CLK) begin : start_addr_gen
    if (RESET) begin
      adgen_start <= 0;
    end
    else if (EN) begin
      if ((Sreg == INPT) && (Snext == AVRG)) // State transition is about to happen
        adgen_start <= 1;
      else
        adgen_start <= 0;
    end
  end

  always @(posedge CLK) begin : prepare_adgen_inputs
    if (RESET) begin
      adgen_h <= 0;
      adgen_w <= 0;
      adgen_k <= 0;
      adgen_l <= 0;
    end 
    else if (EN) begin
      if (pooling_type == 1'b0) begin
        adgen_h <= TYPE1_H;
        adgen_w <= TYPE1_W;
        adgen_k <= TYPE1_K;
        adgen_l <= TYPE1_L;
      end
      else begin // (pooling_type == 1'b1)
        adgen_h <= TYPE2_H;
        adgen_w <= TYPE2_W;
        adgen_k <= TYPE2_K;
        adgen_l <= TYPE2_L;
      end
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      adgen_addr_vld_d <= 0;
      adgen_addr_last_d <= 0;
      adgen_addr_pack_d <= 0;
    end 
    else if (EN) begin
      adgen_addr_vld_d <= {adgen_addr_vld_d[7:1], adgen_addr_vld};
      adgen_addr_last_d <= {adgen_addr_last_d[7:1], adgen_addr_last};
      adgen_addr_pack_d <= {adgen_addr_pack_d[7:1], adgen_addr_pack};
    end
  end

  always @(posedge CLK) begin : update_icounter
    if (RESET) begin
      icounter <= 0;
    end
    else if (EN) begin
      if (Sreg == INPT) begin
        if (input_transfer) begin
          if (icounter_wrap)
            icounter <= 0;
          else 
            icounter <= icounter + 1;
        end
        else begin // (~input_transfer)
          icounter <= icounter;
        end
      end
      else begin // (Sreg != INPT)
        icounter <= 0;
      end
    end
  end

  always @(*) begin
    if (Sreg == INPT) begin
      if (pooling_type == 0) 
        icounter_wrap = (icounter == (TYPE1_LEN-1));
      else // pooling_type == 1
        icounter_wrap = (icounter == (TYPE2_LEN-1));
    end
    else begin
      icounter_wrap = 0;
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      acc_enable <= 0;
      acc_load <= 0;
    end
    else if (EN) begin
      acc_enable <= adgen_addr_vld_d[2] | (|adgen_addr_last_d[4:2]);
      acc_load <= adgen_addr_pack_d[3] & adgen_addr_vld_d[3];
    end
  end
  
  always @(posedge CLK) begin
    if (RESET) begin
      out_data <= 0;
    end
    else if (EN) begin
      if (pooling_type == 0) // The 25x13 pooling
        out_data <= (acc_sum >>> 8); // divide by 256
      else // The 4x3 pooling
        out_data <= (acc_sum >>> 4); // divide by 16
    end
  end

  assign ofifo_write = adgen_addr_pack_d[8] & adgen_addr_vld_d[8];
  assign average_done = adgen_addr_last_d[8];

  assign DIN_RDY = inready;
  assign DOUT = $signed(ofifo_dout[INWIDTH-1:0]);
  assign DOUT_VLD = !ofifo_empty;
  assign DOUT_OVFL = ofifo_dout[INWIDTH];

  RAM1P #( .DATA_WIDTH(INWIDTH), .ADDR_WIDTH(ADDR_WIDTH) ) U_ram (
    .CLK(CLK), .EN(EN), .RESET(RESET), 
    .WE(ram_we), .ADDR(ram_addr),
    .DIN(din_buffer), .DOUT(ram_dout_raw)
  );

  AddrGenPool #( 
    .ADDR_WIDTH(ADDR_WIDTH), 
    .HEIGHT_WIDTH(ADGEN_HEIGHT_WIDTH),
    .KERSIZE_WIDTH(ADGEN_KERSIZE_WIDTH)
  ) U_adgen (
    .CLK(CLK), .RESET(RESET), .EN(EN), 
    .H(adgen_h),
    .W(adgen_w),
    .K(adgen_k),
    .L(adgen_l),
    .START(adgen_start),
    .BIAS(adgen_addr),
    .BIAS_VALID(adgen_addr_vld),
    .BIAS_PACK(adgen_addr_pack),
    .BIAS_LAST(adgen_addr_last)
  );

  Acc #(.INWIDTH(INWIDTH), .ACC_WIDTH(ACC_WIDTH)) U_acc (
    .CLK(CLK), .RESET(RESET),
    .EN(acc_enable),
    .CLEAR(acc_clear),
    .LOAD(acc_load),
    .DIN(acc_din),
    .ACC(acc_sum)
  );

  FRound #(
    .INWIDTH(ACC_WIDTH-4+1), // To comply with out_data, and an extra fraction bit at the end
    .IN_FRAC(IN_FRAC+1), // FRound requires IN_FRAC > OUT_FRAC, so append a 0 at the end
    .OUTWIDTH(INWIDTH),
    .OUT_FRAC(IN_FRAC)
  ) U_round (
    .CLK(CLK), .RESET(RESET), .EN(EN),
    .DIN($signed({out_data, 1'b0})), // append 1'b0 at the LSB
    .DOUT(round_dout),
    .SATUR(round_ovfl),
    .OVFL(), .UDFL()
  );

  FIFOsync_ram #(
    .INWIDTH(INWIDTH+1), 
    .DEPTH(500) // > 325 and not too much greater
  ) U_ofifo ( 
    .CLK(CLK), .RESET(RESET), .EN(EN), 
    .DI({round_ovfl, round_dout}),
    .WRITE(ofifo_write),
    .DO(ofifo_dout),
    .READ(DOUT_RDY),
    .FULL(ofifo_full),
    .EMPTY(ofifo_empty)
  );
endmodule
