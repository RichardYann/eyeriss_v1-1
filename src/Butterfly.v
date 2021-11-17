`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/05 16:47:31
// Design Name: 
// Module Name: Butterfly
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The basic "butterfly" structure of DIT-FFT systems.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Butterfly 
  #(
    parameter INWIDTH = 16, // Total bitwidth of input data
              FRACWIDTH = 13 // Bit width of fraction parts (position of binary point)
  ) 
  (
    input  CLK,
    input  RESET,
    input  EN,
    input  signed [INWIDTH-1:0]   XP_R, // Input p, real part
    input  signed [INWIDTH-1:0]   XP_I, // Input p, imaginary part
    input  signed [INWIDTH-1:0]   XQ_R, // Input q
    input  signed [INWIDTH-1:0]   XQ_I,
    input  signed [INWIDTH-1:0]   TF_R, // Twiddle factor, real part
    input  signed [INWIDTH-1:0]   TF_I, // Twiddle factor, imaginary part
    output signed [2*INWIDTH+1:0] YP_R, // Output p
    output signed [2*INWIDTH+1:0] YP_I,
    output signed [2*INWIDTH+1:0] YQ_R, // Output q
    output signed [2*INWIDTH+1:0] YQ_I 
  );

  reg  signed [INWIDTH-1:0]   XP_R_D [1:6];
  reg  signed [INWIDTH-1:0]   XP_I_D [1:6];
  wire signed [2*INWIDTH:0]   XP_R_D5;
  wire signed [2*INWIDTH:0]   XP_I_D5;
  wire signed [2*INWIDTH:0]   xq_mult_r, xq_mult_i;
  // (* use_dsp = "yes" *)
  reg  signed [2*INWIDTH+1:0] yp_real, yp_imag, yq_real, yq_imag;
  genvar gg;

  // Complex multiplier for stage 1
  ComplexMult #(.INWIDTH(INWIDTH)) CM1
    ( 
      .clk(CLK), .reset(RESET), .en(EN),
      .ar(XQ_R), .ai(XQ_I), .br(TF_R), .bi(TF_I),
      .pr(xq_mult_r), .pi(xq_mult_i)
    );

  // delay XP for 6 ticks (ComplexMult need 6 ticks to calculate a result)
  generate
    for (gg = 1; gg <= 6; gg = gg + 1) begin : XP_pipeline
      if (gg == 1) begin
        always @(posedge CLK) 
          if (RESET) begin
            XP_R_D[gg] <= 0;
            XP_I_D[gg] <= 0;
          end else if (EN) begin
            XP_R_D[gg] <= XP_R;
            XP_I_D[gg] <= XP_I;
          end
      end
      else begin 
        always @(posedge CLK) 
          if (RESET) begin
            XP_R_D[gg] <= 0;
            XP_I_D[gg] <= 0;
          end else if (EN) begin
            XP_R_D[gg] <= XP_R_D[gg-1];
            XP_I_D[gg] <= XP_I_D[gg-1];
          end
      end
    end
  endgenerate
  
  assign XP_R_D5 = $signed({XP_R_D[6], {FRACWIDTH{1'b0}}});
  assign XP_I_D5 = $signed({XP_I_D[6], {FRACWIDTH{1'b0}}});

  // Adders for stage 2
  always @(posedge CLK) begin : yp_and_yq
    if (RESET) begin
      yp_real <= 0;
      yp_imag <= 0;
      yq_real <= 0;
      yq_imag <= 0;
    end else if (EN) begin
      yp_real <= XP_R_D5 + xq_mult_r;
      yp_imag <= XP_I_D5 + xq_mult_i;
      yq_real <= XP_R_D5 - xq_mult_r;
      yq_imag <= XP_I_D5 - xq_mult_i;
    end
  end

  assign YP_R = yp_real;
  assign YP_I = yp_imag;
  assign YQ_R = yq_real;
  assign YQ_I = yq_imag;
endmodule
