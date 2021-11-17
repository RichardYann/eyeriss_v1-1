`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2021/08/07 11:52:10
// Design Name: 
// Module Name: ShiftRegSIPOnB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Serial-in-parallel-out shift register with parameterized data width,
//   depth and number of banks.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   The data movement pattern is shown below.
//   When `din` is valid, it will be shifted into Bank 0, the deepest data on Bank 0 will be
//   lost. When `bksh` is valid, all the data on Bank 0 will be shifted into Bank 1, Bank 1
//   into Bank 2, etc (Bank 0 will be zero-filled; if `din` is valid at the same time, the 
//   element 0 on Bank 1 will be `din`).
//                      +--- `din` passthrough when both `bksh` and `din_valid` are 1'b1
//         +------------+----------------+
//         |   Bank 0   |   Bank 1       |                  Element index
//         |   +-----+  ↓   +-----+      |
//   din >-+---|--+--|----> |     |------+-> \              0
//         |   |__|__|      |_____|      |   |
//         |   |  v  | ---> |     |------+-> |              1
//         |   |__|__|      |_____|      |   +----> pout
//         |   |  v  | ---> |     |------+-> |              2
//         |   |__|__|      |_____|      |   |
//         |   |  v  | ---> |     |------+-> /              3 (DEPTH-1)
//         |   +--+--+  ↑   +-----+      |
//         |      |     |                |
//         +------+-----+----------------+
//                |     |
//                v     +--- shift the whole bank when `bksh` is 1'b1
//              casout
//
//////////////////////////////////////////////////////////////////////////////////


module ShiftRegSIPOnB
  #(
    parameter INWIDTH = 16,
              DEPTH = 9,
              NUM_BANKS = 2
  )
  (
    input clk, 
    input reset,
    input en,
    input [INWIDTH-1:0] din,
    input               din_valid,
    input               bksh, // bank shift (shift the whole bank into the next bank)
    output [INWIDTH*DEPTH-1:0] pout,
    output [INWIDTH-1:0]       casout // The deepest element on Bank 0, for cascading
  );

  reg [INWIDTH-1:0] content [0:DEPTH-1][0:NUM_BANKS-1];
  genvar i, bb;

  generate
    for (i = 0; i < DEPTH; i = i + 1) begin : bank0
      always @(posedge clk) begin
        if (reset) begin
          content[i][0] <= 0;
        end
        else if (en) begin
          if (bksh) begin
            content[i][0] <= {INWIDTH{1'b0}};
          end
          else if (din_valid) begin
            if (i > 0)
              content[i][0] <= content[i-1][0];
            else
              content[i][0] <= din;
          end
        end
      end
    end
  endgenerate

  generate
    if (NUM_BANKS > 1) begin
      for (i = 0; i < DEPTH; i = i + 1) begin : bank1
        always @(posedge clk) begin
          if (reset == 1'b1) 
            content[i][1] <= {INWIDTH{1'b0}};
          else if (en)
            if (bksh) 
              if (!din_valid)
                content[i][1] <= content[i][0];
              else // if din is valid
                if (i == 0)
                  content[i][1] <= din;
                else
                  content[i][1] <= content[i-1][0];
        end
      end
      
      if (NUM_BANKS > 2) begin
        for (bb = 2; bb < NUM_BANKS; bb = bb + 1) begin : bank_n
          for (i = 0; i < DEPTH; i = i + 1) begin : elem
            always @(posedge clk) begin
              if (reset) 
                content[i][bb] <= {INWIDTH{1'b0}};
              else if (en) 
                if (bksh)
                  content[i][bb] <= content[i][bb-1];
            end
          end
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < DEPTH; i = i + 1) begin
      assign pout[INWIDTH*(i+1)-1:INWIDTH*i] = content[i][NUM_BANKS-1];
    end
  endgenerate

  assign casout = content[DEPTH-1][0];
endmodule


//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2021/08/07 17:49:36
// Design Name: 
// Module Name: ShiftRegPISO
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Parallel-in-serial-out shift register with parameterized data width,
//   depth and number of banks.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   The data movement pattern is shown below.
//   When `pin` is valid, it will be shifted into the register. When `shift` is 
//   1'b1, the elements will shift from the deepest index towards 0-index; 
//   `casin` will be shifted into the deepest element.
//   
//                 +----------------+          
//                 |                |          Element index
//                 |    +-----+     |            
//              /--+--> |  ^  |-----+-> dout   0
//              |  |    |__|__|     |            
//              |--+--> |  ^  |     |          1
//    pin  >----+  |    |__|__|     |            
//              |--+--> |  ^  |     |          2
//              |  |    |__|__|     |              
//              \--+--> |  ^  |     |          3 (DEPTH-1)
//                 |    +--+--+     |          
//                 |       |        |          
//                 +-------+--------+                
//                         ^
//                         casin
//////////////////////////////////////////////////////////////////////////////////

module ShiftRegPISO
  #(
    parameter INWIDTH = 16,
              DEPTH = 4
  )
  (
    input clk,
    input reset, 
    input en,
    input  [INWIDTH*DEPTH-1:0] pin,
    input                      pin_valid,
    input  [INWIDTH-1:0]       casin,
    input                      shift,
    output [INWIDTH-1:0]       dout
  );
  reg [INWIDTH-1:0] shreg [0:DEPTH-1];
  genvar ii;

  always @(posedge clk) begin
    if (reset == 1'b1)
      shreg[DEPTH-1] <= 0;
    else if (en) 
      if (pin_valid) 
        shreg[DEPTH-1] <= pin[DEPTH*INWIDTH-1:(DEPTH-1)*INWIDTH];
      else if (shift)
        shreg[DEPTH-1] <= casin;
  end
  
  generate
    for (ii = 0; ii < DEPTH-1; ii = ii + 1) begin : elem
      always @(posedge clk) begin
        if (reset == 1'b1)
          shreg[ii] <= 0;
        else if (en) begin
          if (pin_valid)
            shreg[ii] <= pin[(ii+1)*INWIDTH-1:ii*INWIDTH];
          else if (shift) begin
            shreg[ii] <= shreg[ii+1];
          end
        end
      end
    end
  endgenerate

  assign dout = shreg[0];
endmodule