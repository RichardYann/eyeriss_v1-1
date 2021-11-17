`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/08 09:14:35
// Design Name: 
// Module Name: RAM1P
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Single-port read-first RAM, with enable and write enable signals.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   DOUT will change 2-ticks after ADDR changes when en is 1.
//////////////////////////////////////////////////////////////////////////////////


module RAM1P
  #(
    parameter DATA_WIDTH = 16,
              ADDR_WIDTH = 10 // Depth is (2**ADDR_WIDTH) 
  )
  (
    input                   CLK   ,
    input                   RESET ,
    input                   EN    ,
    input                   WE    ,
    input  [ADDR_WIDTH-1:0] ADDR  ,
    input  [DATA_WIDTH-1:0] DIN   ,
    output [DATA_WIDTH-1:0] DOUT   
  );
  localparam DEPTH = 2**ADDR_WIDTH;
  reg [DATA_WIDTH-1:0] content [0:DEPTH-1];
  reg [DATA_WIDTH-1:0] data_out, data_out_d;
  integer i;

  initial begin
    for (i = 0; i < DEPTH; i = i + 1) begin
      content[i] = {DATA_WIDTH{1'b0}};
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      data_out <= 0;
      data_out_d <= 0;
    end
    else if (EN) begin
      if (WE) begin
        content[ADDR] <= DIN;
      end
      data_out <= content[ADDR];
      data_out_d <= data_out;
    end
  end

  assign DOUT = data_out_d;
endmodule


// Two-port RAM with 1 write-first port and 1 read-only port
// Latency: 1 clock cycle 
module RAM2P_WF_RO 
  #(
    parameter DATA_WIDTH = 16,
              ADDR_WIDTH = 10 // Depth is (2**ADDR_WIDTH) 
  )
  (
    input                   CLK   ,
    input                   RESET ,
    input                   EN    ,
    input                   WE    ,
    input  [ADDR_WIDTH-1:0] ADDR1 , // Write-first port
    input  [ADDR_WIDTH-1:0] ADDR2 , // Read-only port
    input  [DATA_WIDTH-1:0] DI    ,
    output [DATA_WIDTH-1:0] DO1   ,
    output [DATA_WIDTH-1:0] DO2    
  );
  localparam DEPTH = 2**ADDR_WIDTH;
  reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];
  reg [DATA_WIDTH-1:0] dout1, dout2;
  integer i;

  initial begin
    for (i = 0; i < DEPTH; i = i + 1) begin
      ram[i] = {DATA_WIDTH{1'b0}};
    end
  end

  always @(posedge CLK) begin
    if (EN) begin
      if (WE) begin
        ram[ADDR1] <= DI;
        dout1 <= DI;
      end
      else begin
        dout1 <= ram[ADDR1];
      end
    end
  end

  always @(posedge CLK) begin
    if (RESET) 
      dout2 <= 0;
    else if (EN) begin
      dout2 <= ram[ADDR2];
    end
  end

  assign DO1 = dout1;
  assign DO2 = dout2;
endmodule

// Module for global buffer
module RAM_GLB 
  #(
    parameter INWIDTH = 16,
              NUM_ELEM = 295160,
              ADDR_WIDTH = $clog2(NUM_ELEM)
  )
  (
    input                   clk   , 
    input                   reset , 
    input                   en    ,
    input                   we1   ,
    input                   we2   ,
    input  [ADDR_WIDTH-1:0] addr1 ,
    input  [ADDR_WIDTH-1:0] addr2 ,
    input  [INWIDTH-1:0]    di1   ,
    input  [INWIDTH-1:0]    di2   ,
    output [INWIDTH-1:0]    do1   ,
    output [INWIDTH-1:0]    do2 
  );
  reg [INWIDTH-1:0] ram_glb [0:NUM_ELEM-1];
  
  reg [INWIDTH-1:0] dout1, dout1_d;
  reg [INWIDTH-1:0] dout2, dout2_d;

  integer i;
  
  initial begin
    for (i = 0; i < NUM_ELEM; i = i + 1) begin
      ram_glb[i] = {INWIDTH{1'b0}};
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      dout1 <= 0;
    end
    else if (en) begin
      dout1 <= ram_glb[addr1];
      if (we1) begin
        ram_glb[addr1] <= di1;
      end
    end
  end
  
  always @(posedge clk) begin
    if (reset) begin
      dout2 <= 0;
    end
    else if (en) begin
      dout2 <= ram_glb[addr2];
      if (we2) begin
        ram_glb[addr2] <= di2;
      end
    end
  end

  always @(posedge clk) begin
    dout1_d <= dout1;
    dout2_d <= dout2;
  end

  assign do1 = dout1_d;
  assign do2 = dout2_d;
endmodule