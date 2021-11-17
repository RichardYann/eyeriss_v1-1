`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/08 09:53:49
// Design Name: 
// Module Name: Dense
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The matrix multiplication module for fully-conected layer in
//   the neural network.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.816 - Test passed.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Dense
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 8,
              VIN_LEN = 45, // Length of input vector (no. rows in weight matrix)
              VOUT_LEN = 10 // Length of output vector (no. cols in weight matrix)
  )
  (
    input                       clk       ,
    input                       reset     ,
    input                       en        ,
    input  signed [INWIDTH-1:0] din       ,
    input                       din_valid ,
    input  signed [INWIDTH-1:0] win       , // Weight input
    input                       win_valid ,
    output signed [INWIDTH-1:0] dout      ,
    input                       dout_ready,
    output                      dout_valid 
  );
  localparam OUTWIDTH = INWIDTH*2 + VOUT_LEN;
  localparam COL_WIDTH = $clog2(VOUT_LEN + 1);
  localparam ROW_WIDTH = $clog2(VIN_LEN + 1);
  reg calc_done, output_done;
  reg [VOUT_LEN-1:0] weight_we;
  reg [COL_WIDTH-1:0] col_counter;
  reg [ROW_WIDTH-1:0] weight_addr, row_counter;
  wire col_counter_wrap, weight_addr_wrap, rc_wrap;
  reg  [4:1] rc_wrap_d;
  reg  signed [INWIDTH-1:0] din_buffer;
  wire signed [INWIDTH-1:0] weight_out [0:VOUT_LEN-1];
  wire signed [INWIDTH-1:0] mac_win [0:VOUT_LEN-1]; // Weight input for MACs
  wire signed [OUTWIDTH-1:0] mac_acc [0:VOUT_LEN-1];
  wire [OUTWIDTH*VOUT_LEN-1:0] fifo_di;
  wire [OUTWIDTH-1:0] fifo_do;
  wire fifo_write, fifo_empty;
  reg [3:1] din_valid_d;
  reg mac_en, mac_reload;
  genvar g;

  wire [INWIDTH-1:0] round_dout, ofifo_dout;
  wire               round_dout_valid, ofifo_empty;
  reg  [2:1]         pififo_not_empty_d;

  assign col_counter_wrap = (col_counter == (VOUT_LEN-1));
  assign weight_addr_wrap = (weight_addr == (VIN_LEN-1));
  assign rc_wrap          = (row_counter == (VIN_LEN-1));
  assign fifo_write       = rc_wrap_d[4];

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      col_counter <= 4'h0;
    end
    else if (en) begin
      if (win_valid) begin
        if (~col_counter_wrap) col_counter <= col_counter + 1;
        else col_counter <= 4'h0;
      end
    end
  end

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      weight_addr <= 6'd0;
    end
    else if (en) begin
      if (col_counter_wrap) begin
        if (~weight_addr_wrap) weight_addr <= weight_addr + 1;
        else weight_addr <= 6'd0;
      end
    end
  end

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      row_counter <= 6'h00;
    end
    else if (en) begin
      if (din_valid) 
        if (!rc_wrap) row_counter <= row_counter + 1;
        else row_counter <= 6'h00;
    end
  end

  generate
    for (g = 0; g < VOUT_LEN; g = g + 1) begin : iXw // Inputs multiply weights
      RAM2P_WF_RO #(.DATA_WIDTH(INWIDTH), .ADDR_WIDTH(ROW_WIDTH)) U_wt_ram (
        .CLK(clk), .RESET(reset), .EN(en),
        .WE(weight_we[g]),
        .ADDR1(weight_addr),
        .DI(win),
        .DO1(weight_out[g]),
        .ADDR2(row_counter), 
        .DO2(mac_win[g])
      );

      always @(*) begin
        weight_we[g] = win_valid && (col_counter == g);
      end

      MAC #(.INWIDTH_A(INWIDTH), .INWIDTH_B(INWIDTH), .ACC_WIDTH(OUTWIDTH)) U_mac (
        .CLK(clk), .RESET(reset), .EN(mac_en && en),
        .CLEAR(mac_reload),
        .A(din_buffer),
        .B(mac_win[g]),
        .ACC(mac_acc[g])
      );

      assign fifo_di[OUTWIDTH*(g+1)-1:g*OUTWIDTH] = mac_acc[g];
    end
  endgenerate

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      din_valid_d <= 3'b0;
    end
    else if (en) begin
      din_valid_d <= {din_valid_d[2:1], din_valid};
    end
  end

  always @(*) begin
    mac_en <= |din_valid_d;
  end
  
  always @(posedge clk)
    if (reset == 1'b1) din_buffer <= {INWIDTH{1'b0}};
    else if (en && din_valid) din_buffer <= din;
  
  always @(posedge clk) begin
    if (reset == 1'b1) 
      mac_reload <= 1'b0;
    else if (en && mac_en) begin
      if (din_valid) // Multiply groups inputed consecutively
        mac_reload <= rc_wrap_d[1];
      else // End of consecutive inputs
        mac_reload <= rc_wrap_d[3] && (row_counter == 0);
    end
  end

  always @(posedge clk)
    if (reset == 1'b1) rc_wrap_d <= 4'h0;
    else if (en) rc_wrap_d <= {rc_wrap_d[3:1], rc_wrap};

  always @(posedge clk) 
    if (reset == 1'b1) pififo_not_empty_d <= 2'b00;
    else if (en) pififo_not_empty_d <= {pififo_not_empty_d[1:1], !fifo_empty};

  assign round_dout_valid = pififo_not_empty_d[2];
  
  FIFOpi #(.INWIDTH(OUTWIDTH), .INDEPTH(VOUT_LEN)) U_pififo (
    .CLK(clk), .RESET(reset), .EN(en),
    .DI(fifo_di),
    .WRITE(fifo_write),
    .WRITING(),
    .DO(fifo_do),
    .READ(1'b1),
    .EMPTY(fifo_empty),
    .FULL()
  );
  
  FRound #(
    .INWIDTH ( OUTWIDTH   ),
    .IN_FRAC ( IN_FRAC*2  ),
    .OUTWIDTH( INWIDTH    ),
    .OUT_FRAC( IN_FRAC    ) 
  ) U_round (
    .CLK  ( clk         ),
    .RESET( reset       ),
    .EN   ( en          ),
    .DIN  ( fifo_do     ),
    .DOUT ( round_dout  ),
    .SATUR(),
    .OVFL (),
    .UDFL () 
  );

  FIFOsync_ram #(.INWIDTH(INWIDTH), .DEPTH(2*VOUT_LEN*VIN_LEN)) U_ofifo (
    .CLK  ( clk               ),
    .RESET( reset             ),
    .EN   ( en                ),
    .DI   ( round_dout        ),
    .WRITE( round_dout_valid  ),
    .DO   ( ofifo_dout        ),
    .READ ( dout_ready        ),
    .FULL (                   ),
    .EMPTY( ofifo_empty       ) 
  );

  assign dout = $signed(ofifo_dout);
  assign dout_valid = !ofifo_empty;
endmodule
