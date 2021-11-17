`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/13 09:46:53
// Design Name: 
// Module Name: AddLayer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AddLayer
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 12,
              HEIGHT_WIDTH = 5  // Enough for 25
  )
  (
    input                         CLK       ,
    input                         RESET     ,
    input                         EN        ,
    input   [HEIGHT_WIDTH-1:0]    H         , // Height of input feature map
    input   [HEIGHT_WIDTH-1:0]    W         , // Width of input feature map
    input                         START     ,
    input   signed  [INWIDTH-1:0] DIN       ,
    output                        DIN_RDY   ,
    input                         DIN_VLD   ,
    output  signed  [INWIDTH-1:0] DOUT      ,
    input                         DOUT_RDY  ,
    output                        DOUT_VLD  ,
    output                        DOUT_OVFL  
  );
  localparam ADDR_WIDTH = HEIGHT_WIDTH * 2 + 1; // Enough to hold two 25x13 input feature maps
  localparam [2:0] IDLE = 3'd0, // Initial state
                   DECD = 3'd1, // Decode PLTY
                   INPT = 3'd2, // Receive data input
                   ADDE = 3'd3, // Element-wise add
                   OUTP = 3'd4; // Output result
  
  reg   [ADDR_WIDTH-1:0]      icounter; // Counter for counting input transfers
  reg   [ADDR_WIDTH-1:0]      wrap_value; // Maximum value allowed for icounter (and ram_addr_ro)
  reg   [HEIGHT_WIDTH-1:0]    ifm_height, ifm_width;
  reg   [HEIGHT_WIDTH*2-1:0]  ifm_size, max_ifm_index;

  reg   [2:0] Sreg, Snext; // State register and next state
  
  reg   decd_done;

  reg   signed  [INWIDTH-1:0] din_buffer;
  reg   input_ready;
  wire  input_transfer;
  wire  icounter_wrap;

  reg   [ADDR_WIDTH-1:0]  ram_addr_wf, ram_addr_ro;
  reg                     ram_we;
  wire  [INWIDTH-1:0]     ram_dout1_raw, ram_dout2_raw;
  wire                    ram_addr_ro_wrap;
  reg                     ram_addr_wrap_reg;
  reg  [2:1]              ram_addr_wrap_d;
  reg                     ram_addr_valid, inpt_to_adde;
  reg  [5:1]              ram_addr_valid_d;

  wire  signed  [INWIDTH:0] add_result_wire;
  reg   signed  [INWIDTH:0] add_result;
  wire                      add_done, round_ovfl;

  wire  signed  [INWIDTH-1:0] round_dout;
  
  wire  [INWIDTH:0] ofifo_dout;
  wire              output_done;
  wire              ofifo_write, ofifo_full, ofifo_empty;

  always @(posedge CLK) begin
    if (RESET) begin
      Sreg <= IDLE;
    end
    else if (EN) begin
      Sreg <= Snext;
    end
  end

  always @* begin
    case (Sreg)
      IDLE: if (START == 1'b1)  Snext = DECD;
            else                Snext = IDLE;
      DECD: if (1'b1 == decd_done)  
              if (ifm_size != 0) 
                Snext = INPT;
              else
                Snext = IDLE;
            else
              Snext = DECD;
      INPT: if (icounter_wrap && input_transfer) 
              Snext = ADDE;
            else 
              Snext = INPT;
      ADDE: if (add_done) Snext = OUTP;
            else          Snext = ADDE;
      OUTP: if (output_done) Snext = IDLE;
            else             Snext = OUTP;
      default: Snext = IDLE;
    endcase
  end

  always @(posedge CLK) begin : cache_H_W
    if (RESET == 1'b1) begin
      ifm_height <= 0;
      ifm_width <= 0;
    end
    else if (EN) begin
      if ((Sreg == IDLE) && (START == 1'b1)) begin
        ifm_height <= H;
        ifm_width <= W;
      end
    end
  end

  always @(posedge CLK) begin : DECD_done
    if (RESET == 1'b1) begin
      decd_done <= 0;
    end
    else if (EN) begin
      decd_done <= (Sreg == DECD);
    end
  end

  always @(posedge CLK) begin : decode
    if (RESET == 1'b1) begin
      ifm_size <= 0;
      wrap_value <= 0;
      max_ifm_index <= 0;
    end
    else if (EN && (Sreg == DECD)) begin      
      ifm_size <= ifm_height * ifm_width;
      wrap_value <= ifm_height * ifm_width * 2 - 1;
      max_ifm_index <= (ifm_height * ifm_width) - 1;
    end
  end

  assign input_transfer = (DIN_RDY && DIN_VLD);
  assign icounter_wrap = (icounter == wrap_value);

  always @(posedge CLK) begin : input_ready_logic
    if (RESET == 1'b1) begin
      input_ready <= 0;      
    end
    else if (EN) begin
      if (Sreg == INPT)
        if (icounter_wrap && input_transfer)
          input_ready <= 0;
        else
          input_ready <= 1;
      else
        input_ready <= 0;
    end
  end

  always @(posedge CLK) begin : update_icounter
    if (RESET == 1'b1) begin
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
        else begin // No input transfer
          icounter <= icounter;
        end
      end
      else begin // Sreg != INPT
        icounter <= 0;
      end
    end
  end

  always @(posedge CLK) begin : buffer_DIN_and_enable_iRAM
    if (RESET == 1'b1) begin
      din_buffer <= 0;
      ram_we <= 0;
    end
    else if (EN) begin
      if (input_transfer) begin
        din_buffer <= DIN;
        ram_we <= 1;
      end
      else begin
        din_buffer <= din_buffer;
        ram_we <= 0;
      end
    end
  end

  always @(posedge CLK) begin : iRAM_address_wf
    if (RESET == 1'b1) begin
      ram_addr_wf <= 0;      
    end
    else if (EN) begin
      if (input_transfer)
        ram_addr_wf <= icounter;
      else if (Sreg == ADDE) // in addr gen process
        if (ram_addr_wf < max_ifm_index)
          ram_addr_wf <= ram_addr_wf + 1;
        else
          ram_addr_wf <= 0;
    end
  end

  assign ram_addr_ro_wrap = (ram_addr_ro == wrap_value);

  always @(posedge CLK) begin : iRAM_address_ro
    if (RESET == 1'b1) begin
      ram_addr_ro <= 0;
    end
    else if (EN) begin
      if (Sreg == ADDE) begin
        if (inpt_to_adde)
          ram_addr_ro <= ifm_size;
        else if (ram_addr_ro_wrap)
          ram_addr_ro <= 0;
        else
          ram_addr_ro <= ram_addr_ro + 1;
      end
    end
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      ram_addr_wrap_reg <= 0;
      ram_addr_wrap_d <= 0;
    end
    else if (EN) begin
      ram_addr_wrap_reg <= ram_addr_ro_wrap;
      ram_addr_wrap_d <= {ram_addr_wrap_d[(2-1):1], ram_addr_wrap_reg};
    end
  end

  assign add_done = ram_addr_wrap_d[2];
  assign add_result_wire = $signed(ram_dout1_raw) + $signed(ram_dout2_raw);

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      inpt_to_adde <= 0;      
    end
    else if (EN) begin
      inpt_to_adde <= (Sreg == INPT) && (icounter_wrap && input_transfer);
    end
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      ram_addr_valid <= 0;
    end
    else if (EN) begin
      if (inpt_to_adde)
        ram_addr_valid <= 1;
      else if (ram_addr_ro_wrap)
        ram_addr_valid <= 0;
      else
        ram_addr_valid <= ram_addr_valid;
    end
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      ram_addr_valid_d <= 0;      
    end
    else if (EN) begin
      ram_addr_valid_d <= {ram_addr_valid_d[(5-1):1], ram_addr_valid};
    end
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      add_result <= 0;      
    end
    else if (EN && (Sreg == ADDE)) begin
      add_result <= add_result_wire;
    end
  end

  assign ofifo_write = ram_addr_valid_d[4];
  assign output_done = ofifo_empty;

  assign DIN_RDY = input_ready;
  assign DOUT = $signed(ofifo_dout[INWIDTH-1:0]);
  assign DOUT_OVFL = $signed(ofifo_dout[INWIDTH]);
  assign DOUT_VLD = !ofifo_empty;

  RAM2P_WF_RO #(.DATA_WIDTH(INWIDTH), .ADDR_WIDTH(ADDR_WIDTH)) U_iRAM (
    .CLK(CLK), .RESET(RESET), .EN(EN),
    .WE(ram_we), .ADDR1(ram_addr_wf), 
    .ADDR2(ram_addr_ro),
    .DI(din_buffer),
    .DO1(ram_dout1_raw),
    .DO2(ram_dout2_raw)
  );

  FRound #(
    .INWIDTH(INWIDTH+1+1),
    .IN_FRAC(IN_FRAC+1),
    .OUTWIDTH(INWIDTH),
    .OUT_FRAC(IN_FRAC)
  ) U_fRound (
    .CLK(CLK), .RESET(RESET), .EN(EN),
    .DIN({add_result, 1'b0}),
    .DOUT(round_dout),
    .SATUR(round_ovfl),
    .OVFL(), .UDFL()
  );

  FIFOsync_ram #(.INWIDTH(INWIDTH+1), .DEPTH(2**(HEIGHT_WIDTH*2))) U_oFIFO (
    .CLK(CLK), .RESET(RESET), .EN(EN),
    .DI({round_ovfl, round_dout}), .WRITE(ofifo_write),
    .DO(ofifo_dout), .READ(DOUT_RDY),
    .EMPTY(ofifo_empty), .FULL(ofifo_full)
  );
endmodule
