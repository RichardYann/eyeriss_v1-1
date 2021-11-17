`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/12 11:34:03
// Design Name: 
// Module Name: FRound
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Round one fixed-point repersentation into a shorter one.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Tie to infinity (MATLAB's "Round" roundmode).
///  Overflow behavior: Saturate
//   Latency: 2 ticks (results will show up 1 tick after it is fed into this module)
//////////////////////////////////////////////////////////////////////////////////


module FRound
  #(
    parameter INWIDTH = 33,
              IN_FRAC = 26,
              OUTWIDTH = 16,
              OUT_FRAC = 13
  )
  (
    input                        CLK  ,
    input                        RESET,
    input                        EN   ,
    input  signed [INWIDTH-1:0]  DIN  ,
    output signed [OUTWIDTH-1:0] DOUT ,
    output                       SATUR, // Saturation flag (the input is out of the range of the output, i.e. "overflow" in common language)
    output                       OVFL , // Overflow flag (true if SATUR is true and the input is a postitive number)
    output                       UDFL   // Underflow flag (input is too close to 0)
  );
  localparam EXTRA_FRAC = IN_FRAC - OUT_FRAC; // The difference of the fractional parts of input and output format
  
  reg  signed [INWIDTH-1:0]            din_d;
  reg         [OUTWIDTH-2:0]           din_pre_add;
  reg  signed [OUTWIDTH-1:0]           dout_reg;
  wire signed [INWIDTH-EXTRA_FRAC-1:0] din_trunc   = $signed(din_d[INWIDTH-1:EXTRA_FRAC]);
  wire        [EXTRA_FRAC-1:0]         din_extra   = din_d[EXTRA_FRAC-1:0];
  
  reg  satu_reg, ovfl_reg, udfl_reg;

  wire carryin     = din_d[EXTRA_FRAC-1];
  wire signbit     = din_d[INWIDTH-1];
  wire extra_has_1 = (|din_extra);

  always @(posedge CLK) begin
    if (RESET) begin
      din_d <= 0;
      din_pre_add <= 0;
    end
    else if (EN) begin
      din_d <= DIN;
      din_pre_add <= DIN[EXTRA_FRAC+OUTWIDTH-2:EXTRA_FRAC] + DIN[EXTRA_FRAC-1];
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      dout_reg <= 0;
      satu_reg <= 0;
      ovfl_reg <= 0;
      udfl_reg <= 0;
    end
    else if (EN) begin
      if (signbit == 0) begin // din is a positive number
        if ((din_trunc == 0) // Test if underflow: 0s at the MSBs ...
          && (extra_has_1)) begin// and there's "1" in the "extra" bits
          udfl_reg <= 1'b1;
          ovfl_reg <= 1'b0;
          satu_reg <= 1'b0;
          dout_reg <= 0; // Underflow, set to 0
        end 
        else begin
          udfl_reg <= 1'b0;
          if (din_trunc > $signed({signbit, {(OUTWIDTH-1){1'b1}}})) begin // test if overflow
            satu_reg <= 1'b1;
            ovfl_reg <= 1'b1;
            dout_reg <= $signed({signbit, {(OUTWIDTH-1){1'b1}}});
          end 
          else begin // if no overflow by din itself
            if (carryin) begin // if has carry
              if (din_trunc == $signed({signbit, {(OUTWIDTH-1){1'b1}}})) begin // still overflow
                satu_reg <= 1'b1;
                ovfl_reg <= 1'b1;
                dout_reg <= $signed({signbit, {(OUTWIDTH-1){1'b1}}});
              end else begin
                satu_reg <= 1'b0;
                ovfl_reg <= 1'b0;
                dout_reg <= $signed({signbit, din_pre_add});
              end
            end 
            else begin // if no carry
              ovfl_reg <= 1'b0;
              satu_reg <= 1'b0;
              dout_reg <= $signed({signbit, din_pre_add});
            end
          end
        end
      end 
      else begin // din is a negative number: test if underflow
        ovfl_reg <= 1'b0;
        if ( (din_trunc == $signed({(INWIDTH-EXTRA_FRAC){1'b1}})) && ( extra_has_1 ) ) begin // if it underflows
          udfl_reg <= 1'b1;
          satu_reg <= 1'b0;
          dout_reg <= 0;
        end 
        else begin // if no underflow
          udfl_reg <= 1'b0;
          if (din_trunc < $signed({1'b1, {(OUTWIDTH-1){1'b0}}})) begin // if input small than output's lowerbound
            satu_reg <= 1'b1;
            dout_reg <= $signed({1'b1, {(OUTWIDTH-1){1'b0}}}); // Lower bound of output format
          end 
          else begin // input is not out of range (> lowerbound)
            satu_reg <= 1'b0;
            dout_reg <= $signed({signbit, din_pre_add});
          end 
        end
      end
    end
  end

  assign DOUT = dout_reg;
  assign OVFL = ovfl_reg;
  assign UDFL = udfl_reg;
  assign SATUR = satu_reg;
endmodule
