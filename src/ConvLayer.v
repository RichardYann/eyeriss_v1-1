`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/05 20:18:52
// Design Name: 
// Module Name: ConvLayer
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


module ConvLayer
  (

  );
endmodule


//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2021/08/05 20:21:14
// Module Name: ConvCore3x3
// Author: He Zekai
// Target Devices: 
// Tool Versions: 
// Description: The basic operation for 2d convolution with kernel size 3x3.
//   The inputs of the conv kernel h0~h8 will first be buffered, then multiply by 
//   the buffered data input x0~x8. Then all nine multiplication results will 
//   be summed in a cascaded adder chain starting from 0 to 8 (psum[0] = mul[0], 
//   psum[1] = mul[1] + psum[0], psum[2] = mul[2] + psum[1], ...).
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   The inputs (h0~h8 and x0~x8) need to hold for at least 9 clock cycles to 
//   complete a ConvCore calculation.
//   Latency: 2+9 clock cycles (2 for startup, 9 for later inputs)
//////////////////////////////////////////////////////////////////////////////////

module ConvCore3x3 
  #(
    parameter INWIDTH = 16
  )
  (
    input clk,
    input reset, 
    input en,
    // Convolution kernel
    input signed [INWIDTH-1:0] h0,
    input signed [INWIDTH-1:0] h1,
    input signed [INWIDTH-1:0] h2,
    input signed [INWIDTH-1:0] h3,
    input signed [INWIDTH-1:0] h4,
    input signed [INWIDTH-1:0] h5,
    input signed [INWIDTH-1:0] h6,
    input signed [INWIDTH-1:0] h7,
    input signed [INWIDTH-1:0] h8,
    // Input feature map
    input signed [INWIDTH-1:0] x0,
    input signed [INWIDTH-1:0] x1,
    input signed [INWIDTH-1:0] x2,
    input signed [INWIDTH-1:0] x3,
    input signed [INWIDTH-1:0] x4,
    input signed [INWIDTH-1:0] x5,
    input signed [INWIDTH-1:0] x6,
    input signed [INWIDTH-1:0] x7,
    input signed [INWIDTH-1:0] x8,
    // Convolution output
    output signed [INWIDTH*2+8:0] y
  );
  reg signed [INWIDTH-1:0] h_ibuf[0:8];
  reg signed [INWIDTH-1:0] x_ibuf[0:8];
  genvar ii;
  // Intermediate results: multiplication
  reg signed [INWIDTH*2-1:0] mul[0:8];
  // Intermediate results: partial sum
  reg signed [INWIDTH*2+8:0] psum[0:8];

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      h_ibuf[0] <= 0; h_ibuf[1] <= 0; h_ibuf[2] <= 0;
      h_ibuf[3] <= 0; h_ibuf[4] <= 0; h_ibuf[5] <= 0;
      h_ibuf[6] <= 0; h_ibuf[7] <= 0; h_ibuf[8] <= 0;
      
      x_ibuf[0] <= 0; x_ibuf[1] <= 0; x_ibuf[2] <= 0;
      x_ibuf[3] <= 0; x_ibuf[4] <= 0; x_ibuf[5] <= 0;
      x_ibuf[6] <= 0; x_ibuf[7] <= 0; x_ibuf[8] <= 0;
    end
    else if (en) begin
      h_ibuf[0] <= h0; h_ibuf[1] <= h1; h_ibuf[2] <= h2;
      h_ibuf[3] <= h3; h_ibuf[4] <= h4; h_ibuf[5] <= h5;
      h_ibuf[6] <= h6; h_ibuf[7] <= h7; h_ibuf[8] <= h8;

      x_ibuf[0] <= x0; x_ibuf[1] <= x1; x_ibuf[2] <= x2;
      x_ibuf[3] <= x3; x_ibuf[4] <= x4; x_ibuf[5] <= x5;
      x_ibuf[6] <= x6; x_ibuf[7] <= x7; x_ibuf[8] <= x8;
    end
  end

  generate
    for (ii = 0; ii < 9; ii = ii + 1) begin : mult
      always @(posedge clk) begin
        if (reset == 1'b1) begin
          mul[ii] <= 0;
        end
        else if (en) begin
          mul[ii] <= x_ibuf[ii] * h_ibuf[ii];
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      psum[0] <= 0;
    end
    else if (en) begin
      psum[0] <= mul[0];
    end
  end
  
  generate
    for (ii = 1; ii < 9; ii = ii + 1) begin : partial_sum
      always @(posedge clk) begin
        if (reset == 1'b1) begin
          psum[ii] <= 0;
        end
        else if (en) begin
          psum[ii] <= mul[ii] + psum[ii-1];
        end
      end
    end
  endgenerate

  assign y = psum[8];
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2021/08/17 11:12:00
// Module Name: Vecdot9
// Author: He Zekai
// Target Devices: 
// Tool Versions: 
// Description: Module for calculating vector dot product of length 9.
//   The inputs of the conv kernel (hin) and feature maps (xin) are serial inputted. 
//   The output data is rounded to the same format as input data.
//   The valid flag of output is only reliant to `xin_valid` (regardless of 
//   `hin_valid`). It is recommended to feed `hin` before or along with the first
//   group of `xin`.
// Dependencies: 
// 
// Revision:
// Revision 0.03 - Testbench passed in 2021/8/23.
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module Vecdot9 
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 10
  ) 
  (
    input                       clk       ,
    input                       reset     , 
    input                       en        ,
    input  signed [INWIDTH-1:0] hin       ,
    input                       hin_valid ,
    input  signed [INWIDTH-1:0] xin       ,
    input                       xin_valid ,
    output signed [INWIDTH-1:0] dout      ,
    output                      dout_valid
  );
  localparam VECTOR_LEN = 9;
  localparam CNTWIDTH = $clog2(VECTOR_LEN);
  reg            [CNTWIDTH-1:0] hcounter;
  wire                          shreg_bksh_h;
  wire [INWIDTH*VECTOR_LEN-1:0] pout_h;
  reg            [CNTWIDTH-1:0] xcounter;
  wire                          shreg_bksh_x;
  wire [INWIDTH*VECTOR_LEN-1:0] pout_x;
  reg                    [14:1] xc_wrap_d;

  wire hcounter_wrap;
  wire xcounter_wrap;

  wire signed [INWIDTH*2+8:0] core_out;

  wire round_satu, round_ovfl, round_udfl;

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      hcounter <= 0;
    end
    else if (en) begin
      if (hin_valid)
        if (!hcounter_wrap) 
          hcounter <= hcounter + 1;
        else
          hcounter <= 0;
    end
  end

  assign hcounter_wrap = (hcounter == 4'd8);
  assign xcounter_wrap = (xcounter == 4'd8);

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      xcounter <= 0;
    end
    else if (en) begin
      if (xin_valid)
        if (!xcounter_wrap) 
          xcounter <= xcounter + 1;
        else
          xcounter <= 0;
    end
  end
  
  assign shreg_bksh_h = hcounter_wrap && hin_valid;
  assign shreg_bksh_x = xcounter_wrap && xin_valid;

  always @(posedge clk) begin
    if (reset == 1'b1) 
      xc_wrap_d <= 14'h0000;
    else if (en)
      xc_wrap_d <= {xc_wrap_d[14-1:1], shreg_bksh_x};
  end

  assign dout_valid = xc_wrap_d[14];

  ShiftRegSIPOnB #(
    .INWIDTH(INWIDTH),
    .DEPTH(VECTOR_LEN),
    .NUM_BANKS(2)
  ) U_ifm_shreg (
    .clk(clk), .reset(reset), .en(en),
    .din(xin), .din_valid(xin_valid),
    .bksh(shreg_bksh_x),
    .pout(pout_x),
    .casout()
  );
  
  ShiftRegSIPOnB #(
    .INWIDTH(INWIDTH),
    .DEPTH(VECTOR_LEN),
    .NUM_BANKS(2)
  ) U_ker_shreg (
    .clk(clk), .reset(reset), .en(en),
    .din(hin), .din_valid(hin_valid),
    .bksh(shreg_bksh_h),
    .pout(pout_h),
    .casout()
  );

  ConvCore3x3 #(.INWIDTH(INWIDTH)) U_core (
    .clk(clk), .reset(reset), .en(en),
    .h0(pout_h[INWIDTH*(0+1)-1:INWIDTH*0]), 
    .h1(pout_h[INWIDTH*(1+1)-1:INWIDTH*1]), 
    .h2(pout_h[INWIDTH*(2+1)-1:INWIDTH*2]), 
    .h3(pout_h[INWIDTH*(3+1)-1:INWIDTH*3]), 
    .h4(pout_h[INWIDTH*(4+1)-1:INWIDTH*4]), 
    .h5(pout_h[INWIDTH*(5+1)-1:INWIDTH*5]), 
    .h6(pout_h[INWIDTH*(6+1)-1:INWIDTH*6]), 
    .h7(pout_h[INWIDTH*(7+1)-1:INWIDTH*7]), 
    .h8(pout_h[INWIDTH*(8+1)-1:INWIDTH*8]), 
    .x0(pout_x[INWIDTH*(0+1)-1:INWIDTH*0]),
    .x1(pout_x[INWIDTH*(1+1)-1:INWIDTH*1]),
    .x2(pout_x[INWIDTH*(2+1)-1:INWIDTH*2]),
    .x3(pout_x[INWIDTH*(3+1)-1:INWIDTH*3]),
    .x4(pout_x[INWIDTH*(4+1)-1:INWIDTH*4]),
    .x5(pout_x[INWIDTH*(5+1)-1:INWIDTH*5]),
    .x6(pout_x[INWIDTH*(6+1)-1:INWIDTH*6]),
    .x7(pout_x[INWIDTH*(7+1)-1:INWIDTH*7]),
    .x8(pout_x[INWIDTH*(8+1)-1:INWIDTH*8]),
    .y(core_out)
  );

  FRound #(
    .INWIDTH(INWIDTH*2+9),
    .IN_FRAC(IN_FRAC*2),
    .OUTWIDTH(INWIDTH),
    .OUT_FRAC(IN_FRAC)
  ) U_round (
    .CLK(clk), .EN(en), .RESET(reset),
    .DIN(core_out),
    .DOUT(dout),
    .SATUR(round_satu),
    .OVFL(round_ovfl),
    .UDFL(round_udfl)
  );
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/23 20:34:26
// Design Name: 
// Module Name: CasAdder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Cascaded adder chain 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Latency: CHAIN_LEN clock cycles.
//   din inputs need to gap for at least (CHAIN_LEN-1) clock cycles since the 
//   the partial sum needs to propagate through the chain, this is guaranteed by
//   the ready/valid handshake of din.
//////////////////////////////////////////////////////////////////////////////////

module CasAdder
  #(
    parameter INWIDTH = 16,
              CHAIN_LEN = 45
  )
  (
    input                                 clk       ,
    input                                 reset     , 
    input                                 en        ,
    input         [INWIDTH*CHAIN_LEN-1:0] din       ,
    output                                din_ready ,
    input                                 din_valid ,
    input  signed [INWIDTH-1:0]           scale     , // Should be fixed to 'sh0001
    input                                 scl_valid , // Should be fixed to 1'b1
    output signed [47:0]                  dout      ,
    output                                dout_valid 
  );
  reg  signed [INWIDTH-1:0] din_buffer    [0:CHAIN_LEN-1];
  reg  signed [INWIDTH-1:0] scale_buffer  [0:CHAIN_LEN-1];
  genvar  g;
  integer i;
  
  reg [CHAIN_LEN:1] din_valid_d;
  reg               adder_en;
  reg               din_rdy;
  wire              din_transfer;
  
  reg  signed [47:0] psum [0:CHAIN_LEN-1];
  
  reg  signed [2*INWIDTH-1:0] din_mult_scale [0:CHAIN_LEN-1];

  // initial begin
  //   for (i = 0; i < CHAIN_LEN; i = i + 1)
  //     scale_buffer[i] = $signed({{(INWIDTH-1){1'b0}}, 1'b1});
  // end

  assign din_transfer = din_valid & din_ready;

  generate
    for (g = 0; g < CHAIN_LEN; g = g + 1) begin : buffers
      always @(posedge clk) begin
        if (reset)
          din_buffer[g] = $signed({INWIDTH{1'b0}});
        else if (en)
          if (din_transfer)
            din_buffer[g] = $signed(din[(g+1)*INWIDTH-1:g*INWIDTH]);
      end
      
      always @(posedge clk) begin
        if (reset) begin
          scale_buffer[g] <= 0;//$signed({{(INWIDTH-1){1'b0}}, 1'b1});
        end
        else if (en)
          if (scl_valid) begin
            scale_buffer[g] <= scale;
          end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (reset)
      din_valid_d <= {CHAIN_LEN{1'b0}};
    else if (en)
      din_valid_d <= {din_valid_d[CHAIN_LEN-1:1], din_transfer};
  end

  // assign adder_en = |din_valid_d;
  always @(posedge clk) begin
    if (reset)
      adder_en <= 1'b0;
    else if (en)
      adder_en <= |{din_valid_d[CHAIN_LEN-1:1], din_transfer};
  end

  // assign din_ready = (din_valid_d[CHAIN_LEN-1:1] == {(CHAIN_LEN-1){1'b0}});
  always @(posedge clk) begin
    if (reset)
      din_rdy <= 1'b1;
    else if (en)
      din_rdy <= ({din_valid_d[CHAIN_LEN-2:1], din_transfer} == {(CHAIN_LEN-1){1'b0}});
  end
  assign din_ready = din_rdy;

  generate
    for (g = 0; g < CHAIN_LEN; g = g + 1) begin : adder_chain
      always @(*) begin
        din_mult_scale[g] = din_buffer[g] * scale_buffer[g];
      end

      always @(posedge clk) begin
        if (reset)
          psum[g] <= 0;
        else if (en)
          if (g == 0)
            psum[g] <= din_mult_scale[g]/*din_buffer[g]*/;
          else
            psum[g] <= din_mult_scale[g]/*din_buffer[g]*/ + psum[g-1];
      end
    end
  endgenerate

  assign dout = psum[CHAIN_LEN-1];
  assign dout_valid = din_valid_d[CHAIN_LEN];
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/24 09:39:56
// Design Name: 
// Module Name: ConvCore_nC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Convolution core with n channels.
//   There are n channels in this module. Each channel consists of a Vecdot9 module.
//   The din1 input will be first stored to channel 0's Vecdot9 then channel 1's, etc. 
//   The din0 input is shared among all channels.
//   If the sum_en is 1'b1, the output of each Vecdot9 moduel will be summed
//   together in a CasAdder, otherwise, the outputs will be sent into a FIFOpi.
//   sum_en should not change during the calculation cycle.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ConvCore_nC
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 10,
              NUM_CHANNELS = 20//45
  )
  (
    input                         clk       ,
    input                         reset     ,
    input                         en        ,
    input   signed [INWIDTH-1:0]  din0      ,
    input                         din0_valid,
    input   signed [INWIDTH-1:0]  din1      ,
    input                         din1_valid,
    input                         sum_en    ,
    output  signed [INWIDTH-1:0]  dout      ,
    output                        dout_valid 
  );
  wire  signed  [47:0]  cas_dout;
  wire                  cas_ready;
  wire                  cas_dout_vld;
  genvar g;
  
  wire         [NUM_CHANNELS-1:0] vd_din1_valid;
  wire signed       [INWIDTH-1:0] vd9_dout_wire   [0:NUM_CHANNELS-1];
  reg  signed       [INWIDTH-1:0] vd9_dout_buffer [0:NUM_CHANNELS-1];
  wire [INWIDTH*NUM_CHANNELS-1:0] vd_dout;
  wire         [NUM_CHANNELS-1:0] vd_dout_vld_wire;
  reg          [NUM_CHANNELS-1:0] vd9_dout_vld;
  wire [INWIDTH*NUM_CHANNELS-1:0] vd9_dout_wire_flat;
  
  wire signed [INWIDTH-1:0] round_dout;
  wire        [INWIDTH-1:0] fifo_cas_dout;
  wire        [INWIDTH-1:0] fifopi_dout;
  wire  fifo_cas_write;
  wire  fifo_cas_read ;
  wire  fifo_cas_empty;
  wire  fifo_cas_full ;

  wire fifopi_writing ;
  wire fifopi_read    ;
  wire fifopi_empty   ;
  wire fifopi_full    ;

  reg  [$clog2(NUM_CHANNELS)-1:0] vd9_counter, cas_counter;
  reg  [3:0]                      din1_counter;
  wire d1c_wrap, vd9c_wrap, vd9_counter_pulse;
  wire cas_counter_pulse;
  wire cas_counter_wrap;
  wire cas_idle;
  reg  [3:1] cas_dout_vld_d;

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      din1_counter <= 0;
    end
    else if (en) begin
      if (din1_valid) begin
        if (!d1c_wrap)  din1_counter <= din1_counter + 1;
        else            din1_counter <= 0;
      end
    end
  end

  assign d1c_wrap = (din1_counter == 4'd8);
  assign vd9_counter_pulse = d1c_wrap && din1_valid;
  assign vd9c_wrap = (vd9_counter == (NUM_CHANNELS-1));

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      vd9_counter <= 0;
    end
    else if (en) begin
      if (vd9_counter_pulse) begin
        if (!vd9c_wrap) vd9_counter <= vd9_counter + 1;
        else            vd9_counter <= 0;
      end
    end
  end

  assign cas_counter_pulse = !cas_idle || vd9_dout_vld[NUM_CHANNELS-1];

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      cas_counter <= 0;
    end
    else if (en && sum_en) begin
      if (cas_counter_pulse) begin
        if (!cas_counter_wrap)  cas_counter <= cas_counter + 1;
        else                    cas_counter <= 0;
      end
    end
  end
  assign cas_counter_wrap = (cas_counter == (NUM_CHANNELS-1));
  assign cas_idle = (sum_en == 1'b1) ? (cas_counter == 0) : 1'b1;

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      vd9_dout_vld <= 0;
    end
    else if (en) begin
      vd9_dout_vld <= vd_dout_vld_wire;
    end
  end

  assign fifo_cas_write = cas_dout_vld_d[3];
  assign fifo_cas_read = 1'b1;
  assign fifopi_read = 1'b1;

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      cas_dout_vld_d <= 0;
    end
    else if (en && sum_en) begin
      cas_dout_vld_d <= {cas_dout_vld_d[3-1:1], cas_dout_vld};
    end
  end

  assign dout_valid = (sum_en == 1'b1) ? !fifo_cas_empty : !fifopi_empty;
  assign dout = $signed((sum_en == 1'b1) ? fifo_cas_dout : fifopi_dout);

  generate
    for (g = 0; g < NUM_CHANNELS; g = g + 1) begin : vecdots
      assign vd_din1_valid[g] = (vd9_counter  == g) && din1_valid;

      Vecdot9 #(.INWIDTH(INWIDTH), .IN_FRAC(IN_FRAC)) U_vd9 (
        .clk(clk), .reset(reset), .en(en),
        .xin       ( din0                 ),
        .xin_valid ( din0_valid           ),
        .hin       ( din1                 ),
        .hin_valid ( vd_din1_valid[g]     ),
        .dout      ( vd9_dout_wire[g]     ),
        .dout_valid( vd_dout_vld_wire[g]  ) 
      );

      always @(posedge clk) begin
        if (reset == 1'b1) begin
          vd9_dout_buffer[g] <= 0;
        end
        else if (en) begin
          if (vd_dout_vld_wire[g] && cas_idle) begin
            vd9_dout_buffer[g] <= vd9_dout_wire[g];
          end
        end
      end

      assign vd_dout[(g+1)*INWIDTH-1:g*INWIDTH] = vd9_dout_buffer[g];
      assign vd9_dout_wire_flat[(g+1)*INWIDTH-1:g*INWIDTH] = vd9_dout_wire[g];
    end
  endgenerate

  CasAdder #(.INWIDTH(INWIDTH), .CHAIN_LEN(NUM_CHANNELS)) U_casadd (
    .clk       ( clk                          ),
    .reset     ( reset                        ),
    .en        ( en && sum_en                 ),
    .din       ( vd_dout                      ),
    .din_ready ( cas_ready                    ),
    .din_valid ( vd9_dout_vld[NUM_CHANNELS-1] ),
    .scale     ( 16'sh0001                    ),
    .scl_valid ( 1'b1                         ),
    .dout      ( cas_dout                     ),
    .dout_valid( cas_dout_vld                 ) 
  );

  FRound #(
    .INWIDTH ( 48     +1  ),
    .IN_FRAC ( IN_FRAC+1  ),
    .OUTWIDTH( INWIDTH    ),
    .OUT_FRAC( IN_FRAC    ) 
  ) U_round (
    .CLK  ( clk               ),
    .RESET( reset             ),
    .EN   ( en && sum_en      ),
    .DIN  ( {cas_dout, 1'b0}  ),
    .DOUT ( round_dout        ),
    .SATUR(                   ),
    .OVFL (                   ),
    .UDFL (                   ) 
  );

  FIFOsync #(.INWIDTH(INWIDTH), .DEPTH(4)) U_fifo_cas (
    .CLK  ( clk             ),
    .RESET( reset           ),
    .EN   ( en && sum_en    ),
    .DI   ( round_dout      ),
    .WRITE( fifo_cas_write  ),
    .DO   ( fifo_cas_dout   ),
    .READ ( fifo_cas_read   ),
    .FULL ( fifo_cas_full   ),
    .EMPTY( fifo_cas_empty  )
  );

  FIFOpi #(.INWIDTH(INWIDTH), .INDEPTH(NUM_CHANNELS)) U_fifopi (
    .CLK    ( clk                               ),
    .RESET  ( reset                             ),
    .EN     ( en && !sum_en                     ),
    .DI     ( vd9_dout_wire_flat                ),
    .WRITE  ( vd_dout_vld_wire[NUM_CHANNELS-1]  ),
    .WRITING( fifopi_writing                    ),
    .DO     ( fifopi_dout                       ),
    .READ   ( fifopi_read                       ),
    .EMPTY  ( fifopi_empty                      ),
    .FULL   ( fifopi_full                       ) 
  );
endmodule