`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/29 19:47:32
// Design Name: 
// Module Name: ConvCore_45C
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: ConvCore_nC with n (number of channels) fixed to 45 (or 15).
//   This module uses `AdderTree` to sum the outputs of all `Vecdot9`s.
//   The din0 input is shared among all channels like ConvCore_nC.
//   
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ConvCore_45C(clk, reset, en, din0, din0_valid, din1, din1_valid, sum_en, dout, dout_valid);
parameter INWIDTH = 16;
parameter IN_FRAC = 10;
parameter NUM_CHANNELS = 15; // 45 or 15
  input                         clk       ;
  input                         reset     ;
  input                         en        ;
  input   signed [INWIDTH-1:0]  din0      ;
  input                         din0_valid;
  input   signed [INWIDTH-1:0]  din1      ;
  input                         din1_valid;
  input                         sum_en    ;
  output  signed [INWIDTH-1:0]  dout      ;
  output                        dout_valid;
  
  wire  signed [INWIDTH-1:0]  dout      ;
  wire                        dout_valid;

  genvar g;
  
  wire         [NUM_CHANNELS-1:0] vd_din1_valid;
  wire signed       [INWIDTH-1:0] vd9_dout_wire   [0:NUM_CHANNELS-1];
  wire         [NUM_CHANNELS-1:0] vd_dout_vld_wire;
  wire [INWIDTH*NUM_CHANNELS-1:0] vd9_dout_wire_flat;

  wire signed [INWIDTH+6:0] atree_dout;
  wire                      atree_dout_valid;
  
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
  reg  [3:1] atree_dout_valid_d;

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

  assign fifo_cas_write = atree_dout_valid_d[3];
  assign fifo_cas_read = 1'b1;
  assign fifopi_read = 1'b1;

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      atree_dout_valid_d <= 0;
    end
    else if (en && sum_en) begin
      atree_dout_valid_d <= {atree_dout_valid_d[3-1:1], atree_dout_valid};
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

      assign vd9_dout_wire_flat[(g+1)*INWIDTH-1:g*INWIDTH] = vd9_dout_wire[g];
    end
  endgenerate

  AdderTree #(.INWIDTH(INWIDTH), .IN_FRAC(IN_FRAC), .NUM_INPUTS(NUM_CHANNELS)) U_addertree (
    .clk        ( clk                               ),
    .reset      ( reset                             ),
    .en         ( en && sum_en                      ),
    .din        ( vd9_dout_wire_flat                ),
    .din_valid  ( vd_dout_vld_wire[NUM_CHANNELS-1]  ),
    .dout       ( atree_dout                        ),
    .dout_valid ( atree_dout_valid                  ) 
  );

  FRound #(
    .INWIDTH ( INWIDTH+8  ),
    .IN_FRAC ( IN_FRAC+1  ),
    .OUTWIDTH( INWIDTH    ),
    .OUT_FRAC( IN_FRAC    ) 
  ) U_round (
    .CLK  ( clk                 ),
    .RESET( reset               ),
    .EN   ( en && sum_en        ),
    .DIN  ( {atree_dout, 1'b0}  ),
    .DOUT ( round_dout          ),
    .SATUR(                     ),
    .OVFL (                     ),
    .UDFL (                     ) 
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
