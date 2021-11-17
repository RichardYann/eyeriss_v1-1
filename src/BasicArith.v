`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/21 11:32:55
// Design Name: 
// Module Name: BasicArith
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Basic arithmetic modules, including FMA, MAC and ComplexMult
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Latency: 3 clock cycles
module MAC
  #(
    parameter INWIDTH_A = 16,
              INWIDTH_B = 16,
              ACC_WIDTH = 42
  )
  (
    input                         CLK,   // Clock input
    input                         RESET, // Synchronous reset
    input                         EN,    // Clock enable
    input                         CLEAR, // Clear accumulation and load corresponding (A*B) into ACC
    input  signed [INWIDTH_A-1:0] A,     // Input A
    input  signed [INWIDTH_B-1:0] B,     // Input B
    output signed [ACC_WIDTH-1:0] ACC    // Accumulation output
  );

  reg signed [INWIDTH_A-1:0] ain;
  reg signed [INWIDTH_B-1:0] bin;
  reg signed [ACC_WIDTH-1:0] sum;
  reg signed [INWIDTH_A+INWIDTH_B-1:0] mult;
  
  reg clr_d;    // CLEAR delay 1 tick
  reg clr_n_dd; // CLEAR delay by 2 ticks and converted to active-low

  always @(posedge CLK) begin
    if (RESET) begin
      ain <= 0;
      bin <= 0;
      clr_d <= 0;
    end
    else if (EN) begin
      ain <= A;
      bin <= B;
      clr_d <= CLEAR;
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      mult <= 0;
      clr_n_dd <= 0;
    end
    else if (EN) begin
      mult <= ain * bin;
      clr_n_dd <= ~clr_d; // Invert clr_d to make it active-low
    end
  end

  always @(posedge CLK) begin
    if (RESET)
      sum <= 0;
    else if (EN) 
      if (!clr_n_dd) // Active-low
        sum <= mult;
      else
        sum <= sum + mult;
  end

  assign ACC = sum;
endmodule

// Fixed-point consideration: Since the common term, the real part and the 
//     imaginary part have the same calculation pattern, the binary point is 
//     automatically aligned as long as ar,ai,br and bi have 
//     the same fixed-point structure.
// Latency: 6 clock cycles
module ComplexMult 
  #( 
    parameter INWIDTH = 16 
  )
  (
    input clk, reset, en,
    input signed [INWIDTH-1:0]    ar, ai, br, bi,
    output signed [2*INWIDTH:0]   pr, pi
  );

  reg signed [INWIDTH-1:0] ar_d, ar_d2, ar_d3, ar_d4;
  reg signed [INWIDTH-1:0] ai_d, ai_d2, ai_d3, ai_d4;
  reg signed [INWIDTH-1:0] br_d, br_d2, br_d3, br_d4;
  reg signed [INWIDTH-1:0] bi_d, bi_d2, bi_d3, bi_d4;
  reg signed [INWIDTH:0]   common_add;
  reg signed [2*INWIDTH:0] common_mult, common, common_d_1, common_d_2;
  reg signed [INWIDTH:0] pr_add, pi_add;
  reg signed [2*INWIDTH:0] pr_mult, pi_mult, pr_ppln, pi_ppln;

  always @(posedge clk)
    if (reset) begin
      ar_d  <= 0;
      ar_d2 <= 0;
      ar_d3 <= 0;
      ar_d4 <= 0;
      ai_d  <= 0;
      ai_d2 <= 0;
      ai_d3 <= 0;
      ai_d4 <= 0;
      br_d  <= 0;
      br_d2 <= 0;
      br_d3 <= 0;
      br_d4 <= 0;
      bi_d  <= 0;
      bi_d2 <= 0;
      bi_d3 <= 0;
      bi_d4 <= 0;
    end else if (en) begin
      ar_d  <= ar;
      ar_d2 <= ar_d;
      ar_d3 <= ar_d2;
      ar_d4 <= ar_d3;
      ai_d  <= ai;
      ai_d2 <= ai_d;
      ai_d3 <= ai_d2;
      ai_d4 <= ai_d3;
      br_d  <= br;
      br_d2 <= br_d;
      br_d3 <= br_d2;
      br_d4 <= br_d3;
      bi_d  <= bi;
      bi_d2 <= bi_d;
      bi_d3 <= bi_d2;
      bi_d4 <= bi_d3;
    end

  // Each of the following always blocks uses 1 DSP.
  // Calculate the common term: common = (ar-ai)*bi 
  always @(posedge clk)
    if (reset) begin
      common_add <= 0;
      common_mult <= 0;
      common <= 0;
    end else if (en) begin
      common_add <= ar_d - ai_d;
      common_mult <= common_add * bi_d2;
      common <= common_mult;
    end

  // The real part of the product: pr = ar*br - ai*bi = common + (br-bi)*ar
  always @(posedge clk)
    if (reset) begin
      pr_add <= 0;
      pr_mult <= 0;
      pr_ppln <= 0;
      common_d_1 <= 0;
    end else if (en) begin
      pr_add <= br_d3 - bi_d3; // pre-add
      pr_mult <= pr_add * ar_d4; // multiplication
      common_d_1 <= common;
      pr_ppln <= pr_mult + common_d_1; // post-add
    end

  // The imaginary part of the product: pi = ar*bi + ai*br = common + (br+bi)*ai
  always @(posedge clk)
    if (reset) begin
      pi_add <= 0;
      pi_mult <= 0;
      pi_ppln <= 0;
      common_d_2 <= 0;
    end else if (en) begin
      pi_add <= br_d3 + bi_d3; // pre-add
      pi_mult <= pi_add * ai_d4; // multiplication
      common_d_2 <= common;
      pi_ppln <= pi_mult + common_d_2; // post-add
    end

  assign pr = pr_ppln;
  assign pi = pi_ppln;
endmodule

// Latency: 2 clock cycles
module FMA
  #(
    parameter INWIDTH_A = 16,   // Total bit width of input A
              FRACWIDTH_A = 13, // Fraction-part bit width of input A
              INWIDTH_B = 16,
              FRACWIDTH_B = 13,
              INWIDTH_C = 16,
              FRACWIDTH_C = 13
  )
  (
    input                        CLK,
    input                        RESET,
    input                        EN,
    input signed [INWIDTH_A-1:0] A,
    input signed [INWIDTH_B-1:0] B,
    input signed [INWIDTH_C-1:0] C,
    output signed [INWIDTH_A+INWIDTH_B:0] Y
  );
  localparam EXT_WIDTH = FRACWIDTH_A + FRACWIDTH_B - FRACWIDTH_C;
 
  reg  signed [INWIDTH_A-1:0] ain;
  reg  signed [INWIDTH_B-1:0] bin;
  reg  signed [INWIDTH_A+INWIDTH_B-1:0] cin; // cin extended to the same format as a_mul_b
  wire signed [INWIDTH_A+INWIDTH_B-1:0] a_mul_b; // extract A*B for debugging
  reg  signed [INWIDTH_A+INWIDTH_B:0] a_mul_b_plus_c_ext;

  always @(posedge CLK) begin : buffer_input
    if (RESET) begin
      ain <= 0;
      bin <= 0;
      cin <= 0;
    end else if (EN) begin
      ain <= A;
      bin <= B;
      cin <= $signed({C, {EXT_WIDTH{1'b0}}}); // append 0s so that C's binary point is aligned with (A*B)'s
    end
  end

  assign a_mul_b = ain * bin;
  always @(posedge CLK) begin : multiply_add
    if (RESET) begin
      a_mul_b_plus_c_ext <= 0;
    end else if (EN) begin
      a_mul_b_plus_c_ext <= a_mul_b + cin;
    end
  end

  assign Y = a_mul_b_plus_c_ext;
endmodule


//////////////////////////////////////////////////////////////////////////////////
// Module Name: Acc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Accumulator.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Latency: 2 (Result will show up at ACC 1 tick after DIN fed into the module)
//   Testbench in "MAC_tb.v".
//////////////////////////////////////////////////////////////////////////////////

module Acc
  #(
    parameter INWIDTH   = 16, 
              ACC_WIDTH = 47
  )
  (
    input                         CLK,
    input                         RESET,
    input                         EN,
    input                         CLEAR, // Clear the accumulation result, higher priority than LOAD
    input                         LOAD, // Load current input data into the accumulator, ie start a new accumulation round
    input  signed [INWIDTH-1:0]   DIN,
    output signed [ACC_WIDTH-1:0] ACC
  );
  // (* use_dsp = "yes" *)
  reg signed [ACC_WIDTH-1:0] sum;
  reg signed [INWIDTH-1:0]   din_reg;
  reg                        clear_reg;
  reg                        load_reg; 

  always @(posedge CLK) begin
    if (RESET) begin
      sum <= 0;
      din_reg <= 0;
      load_reg <= 0;
      clear_reg <= 0;
    end else if (EN) begin
      din_reg <= DIN;
      load_reg <= LOAD;
      clear_reg <= CLEAR;
      if (clear_reg)
        sum <= 0;
      else if (load_reg) // if the accompanying LOAD was valid
        sum <= din_reg;
      else
        sum <= sum + din_reg;
    end
  end

  assign ACC = sum;
endmodule


//////////////////////////////////////////////////////////////////////////////////
// Module Name: FMAp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Fused multiply add with pre-add, i.e. ((a+d) * b + c).
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Latency: The same as FMA (2 clock cycles).
//////////////////////////////////////////////////////////////////////////////////


module FMAp
  #(
    parameter INWIDTH_A   = 16,   // Total bit width of input A
              FRACWIDTH_A = 13, // Fraction-part bit width of input A
              INWIDTH_B   = 16,
              FRACWIDTH_B = 13,
              INWIDTH_C   = 16,
              FRACWIDTH_C = 13,
              INWIDTH_D   = 16,
              FRACWIDTH_D = 13
  )
  (
    input                                 CLK  ,
    input                                 RESET,
    input                                 EN   ,
    input  signed [INWIDTH_A-1:0]         A    ,
    input  signed [INWIDTH_B-1:0]         B    ,
    input  signed [INWIDTH_C-1:0]         C    ,
    input  signed [INWIDTH_D-1:0]         D    ,
    output signed [INWIDTH_A+INWIDTH_B:0] Y     
  );
  localparam EXT_WIDTH = FRACWIDTH_A + FRACWIDTH_B - FRACWIDTH_C;
  localparam ADWIDTH_MAX = (INWIDTH_A > INWIDTH_D) ? INWIDTH_A : INWIDTH_D;
 
  reg  signed [INWIDTH_A-1:0] ain;
  reg  signed [INWIDTH_B-1:0] bin;
  reg  signed [INWIDTH_D-1:0] din;
  reg  signed [INWIDTH_A+INWIDTH_B-1:0] cin; // cin extended to the same format as a_mul_b
  wire signed [ADWIDTH_MAX+INWIDTH_B:0] a_mul_b; // extract A*B for debugging
  reg  signed [ADWIDTH_MAX+INWIDTH_B:0] a_mul_b_plus_c_ext;

  always @(posedge CLK) begin : buffer_input
    if (RESET) begin
      ain <= 0;
      bin <= 0;
      cin <= 0;
      din <= 0;
    end else if (EN) begin
      ain <= A;
      bin <= B;
      cin <= $signed({C, {EXT_WIDTH{1'b0}}}); // append 0s so that C's binary point is aligned with (A*B)'s
      din <= D;
    end
  end

  assign a_mul_b = (ain + din) * bin;
  always @(posedge CLK) begin : multiply_add
    if (RESET) begin
      a_mul_b_plus_c_ext <= 0;
    end else if (EN) begin
      a_mul_b_plus_c_ext <= a_mul_b + cin;
    end
  end

  assign Y = a_mul_b_plus_c_ext;
endmodule

// FMAp and then FRound, provide a valid interface for easy control
// Latency: 4 clock cycles
module FMApFRound
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 8
  )
  (
    input                         clk       ,
    input                         reset     ,
    input                         en        ,
    output  signed [INWIDTH-1:0]  y         ,
    output                        y_valid   ,
    input   signed [INWIDTH-1:0]  a         ,
    input   signed [INWIDTH-1:0]  b         ,
    input   signed [INWIDTH-1:0]  c         ,
    input   signed [INWIDTH-1:0]  d         ,
    input                         din_valid  
  );
  reg [4:1] din_valid_d;
  
  wire signed [2*INWIDTH:0] fma_yout;
  
  FMAp #(INWIDTH, IN_FRAC, INWIDTH, IN_FRAC, INWIDTH, IN_FRAC, INWIDTH, IN_FRAC) U_fmap (
    .CLK  ( clk       ),
    .RESET( reset     ),
    .EN   ( en        ),
    .A    ( a         ),
    .B    ( b         ),
    .C    ( c         ),
    .D    ( d         ),
    .Y    ( fma_yout  ) 
  );

  FRound #(
    .INWIDTH(INWIDTH*2+1),
    .IN_FRAC(IN_FRAC*2),
    .OUTWIDTH(INWIDTH),
    .OUT_FRAC(IN_FRAC)
  ) U_fround (
    .CLK  ( clk       ),
    .RESET( reset     ),
    .EN   ( en        ),
    .DIN  ( fma_yout  ),
    .DOUT ( y         ),
    .SATUR(),
    .OVFL (),
    .UDFL () 
  );

  always @(posedge clk) begin
    if (reset)
      din_valid_d <= 0;
    else if (en) 
      din_valid_d <= {din_valid_d[3:1], din_valid};
  end

  assign y_valid = din_valid_d[4];
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/10 10:16:53
// Design Name: 
// Module Name: Max4
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Get the maximum number of 4 input numbers.
//   This is a fully-pipelined module.
//   If the numbers are fixed-point numbers, they should have the same binary point.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Latency: 3
//////////////////////////////////////////////////////////////////////////////////


module Max4
  #(
    parameter INWIDTH = 16
  )
  (
    input                       CLK,
    input                       RESET,
    input                       EN,
    input  signed [INWIDTH-1:0] DIN0,
    input  signed [INWIDTH-1:0] DIN1,
    input  signed [INWIDTH-1:0] DIN2,
    input  signed [INWIDTH-1:0] DIN3,
    output signed [INWIDTH-1:0] MAX
  );
  reg signed [INWIDTH-1:0] din [0:3];
  reg signed [INWIDTH-1:0] max01, max23, max;

  wire signed [INWIDTH-1:0] max01_w = (din[0] > din[1]) ? din[0] : din[1];
  wire signed [INWIDTH-1:0] max23_w = (din[2] > din[3]) ? din[2] : din[3];
  wire signed [INWIDTH-1:0] max4_w = (max01 > max23) ? max01 : max23;

  always @(posedge CLK)
    if (RESET) begin
      din[0] <= 0;
      din[1] <= 0;
      din[2] <= 0;
      din[3] <= 0;
    end else if (EN) begin
      din[0] <= DIN0;
      din[1] <= DIN1;
      din[2] <= DIN2;
      din[3] <= DIN3;
    end

  always @(posedge CLK) begin
    if (RESET) begin
      max01 <= 0;
      max23 <= 0;
    end else if (EN) begin
      max01 <= max01_w;
      max23 <= max23_w;
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      max <= 0;
    end else if (EN) begin
      max <= max4_w;
    end
  end

  assign MAX = max;
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Module Name: Add3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Add three inputs, i.e. y = ((a+d) * 1 + c) using FMAp
//   The parameter `INWIDTH` is at most 25 bits due to the constraint on input `d`, 
//   wider input will cause a drop on the QoR of synthesis.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Latency: 2 clock cycles
//////////////////////////////////////////////////////////////////////////////////

module Add3(clk, reset, en, a, d, c, y);
parameter INWIDTH = 48,
          IN_FRAC = 22;
input                       clk   ;
input                       reset ;
input                       en    ;
input  signed [INWIDTH-1:0] a     ;
input  signed [INWIDTH-1:0] d     ;
input  signed [INWIDTH-1:0] c     ;
output signed [INWIDTH+1:0] y     ;

FMAp #(
  .INWIDTH_A(INWIDTH),
  .INWIDTH_D(INWIDTH),
  .INWIDTH_C(INWIDTH),
  .FRACWIDTH_A(IN_FRAC),
  .FRACWIDTH_D(IN_FRAC),
  .FRACWIDTH_C(IN_FRAC),
  .INWIDTH_B(INWIDTH),
  .FRACWIDTH_B(0)
) U_fmap (
  .CLK(clk),
  .RESET(reset),
  .EN(en),
  .A(a),
  .D(d),
  .C(c),
  .B('sh01),
  .Y(y)
);

endmodule