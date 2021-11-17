`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/10 11:00:28
// Design Name: 
// Module Name: ReLU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: ReLU(x) = max(0, x)
//   This is a fully-pipelined module, the latency is 2.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Latency: 2 clock cycles
//////////////////////////////////////////////////////////////////////////////////


module ReLU
  #(
    parameter INWIDTH = 16,
    parameter signed [INWIDTH-1:0] ZERO = 'sh0000
  )
  (
    input                       CLK     ,
    input                       RESET   ,
    input                       EN      ,
    input  signed [INWIDTH-1:0] X       ,
    input                       X_VLD   ,
    output signed [INWIDTH-1:0] Y       ,
    output                      Y_VLD   ,
    output signed [INWIDTH-1:0] PASSTHRU 
  );
  reg signed [INWIDTH-1:0] din;
  reg                      din_valid;
  reg signed [INWIDTH-1:0] dout;
  reg                      dout_valid;

  reg  signed [INWIDTH-1:0] din_d;
  reg  signed [INWIDTH-1:0] din_dd;


  always @(posedge CLK) begin
    if (RESET) begin
      din <= 0;
      dout <= 0;
      din_valid <= 0;
      dout_valid <= 0;
    end else if (EN) begin
      if (X_VLD) begin
        din <= X;
        din_valid = 1;
      end
      else begin
        din <= din;
        din_valid <= 0;
      end
      if (din_valid) begin
        dout <= (din > ZERO) ? din : ZERO;
        dout_valid <= 1;
      end
      else begin
        dout <= dout;
        dout_valid <= 0;
      end
    end
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      din_d  <= {INWIDTH{1'b0}};
      din_dd <= {INWIDTH{1'b0}};
    end
    else if (EN) begin
      din_d  <= X;
      din_dd <= din_d;
    end
  end

  assign Y = dout;
  assign Y_VLD = dout_valid;
  assign PASSTHRU = din_dd;
endmodule
