`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/25 14:49:27
// Design Name: 
// Module Name: AdderTree
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Deprecated and not tested. DO NOT USE THIS MODULE.
//   Adder tree to sum all inputs. 
//   NUM_INPUTS can be 15 or 45.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module AdderTree
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 10,
              NUM_INPUTS = 45
  )
  (
    input                           clk       ,
    input                           reset     ,
    input                           en        ,
    input  [INWIDTH*NUM_INPUTS-1:0] din       ,
    input                           din_valid ,
    output signed [INWIDTH+6:0]     dout      ,
    output                          dout_valid 
  );
  wire signed [INWIDTH+4:0] addertree15_dout;
  wire signed [INWIDTH+6:0] addertree45_dout;

  generate
    if (NUM_INPUTS == 15) begin
      AdderTree15 U_atree (
        .clk       ( clk              ),
        .reset     ( reset            ),
        .en        ( en               ),
        .din       ( din              ),
        .din_valid ( din_valid        ),
        .dout      ( addertree15_dout ),
        .dout_valid( dout_valid       ) 
      );

      assign dout = addertree15_dout;
    end
    else if (NUM_INPUTS == 45) begin
      AdderTree45 U_atree (
        .clk       ( clk              ),
        .reset     ( reset            ),
        .en        ( en               ),
        .din       ( din              ),
        .din_valid ( din_valid        ),
        .dout      ( addertree45_dout ),
        .dout_valid( dout_valid       ) 
      );

      assign dout = addertree45_dout;
    end
  endgenerate
endmodule

// Latency: 5
module AdderTree15
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 10
  )
  (
    input                       clk       ,
    input                       reset     ,
    input                       en        ,
    input  [15*INWIDTH-1:0]     din       ,
    input                       din_valid ,
    output signed [INWIDTH+4:0] dout      ,
    output                      dout_valid 
  );
  localparam NUM_INPUTS = 15;
  reg   [5:1] din_valid_d;
  wire        add_en;
  genvar      g;
  
  wire signed [INWIDTH-1:0] din_buf  [0:14] ;
  wire signed [INWIDTH+1:0] add_l1_y [0:5]  ;
  wire signed [INWIDTH+3:0] add_l2_y [0:1]  ;
  reg  signed [INWIDTH+4:0] add_l3_y        ;

  generate
    for (g = 0; g < NUM_INPUTS; g = g + 1) begin : input_buffer
      assign din_buf[g] = $signed(din[(g+1)*INWIDTH-1:g*INWIDTH]);
    end

    for (g = 0; g < NUM_INPUTS/3; g = g + 1) begin : l1
      Add3 #(.INWIDTH(INWIDTH), .IN_FRAC(IN_FRAC)) U_add3_l1 (
        .clk  ( clk             ),
        .reset( reset           ),
        .en   ( add_en && en    ),
        .a    ( din_buf[g*3]    ),
        .d    ( din_buf[g*3+1]  ),
        .c    ( din_buf[g*3+2]  ),
        .y    ( add_l1_y[g]     )
      );
    end

    for (g = 0; g < 2; g = g + 1) begin : L2
      Add3 #(.INWIDTH(INWIDTH+2), .IN_FRAC(IN_FRAC)) U_add3_l2 (
        .clk  ( clk             ),
        .reset( reset           ),
        .en   ( add_en && en    ),
        .a    ( add_l1_y[g*3]   ),
        .d    ( add_l1_y[g*3+1] ),
        .c    ( add_l1_y[g*3+2] ),
        .y    ( add_l2_y[g]     )
      );
    end

    always @(posedge clk) begin
      if (reset)
        din_valid_d <= 0;
      else if (en)
        din_valid_d <= {din_valid, din_valid_d[5:2]};
    end

    assign add_en = |{din_valid, din_valid_d};
  endgenerate

  assign add_l1_y[5] = $signed({(INWIDTH+2){1'b0}});

  always @(posedge clk) begin
    if (reset)
      add_l3_y <= 0;
    else if (en && add_en)
      add_l3_y <= add_l2_y[0] + add_l2_y[1];
  end

  assign dout = add_l3_y;
  assign dout_valid = din_valid_d[1];
endmodule

// Latenecy: 7 clock cycles
module AdderTree45
  #(
    parameter INWIDTH = 16, 
              IN_FRAC = 10
  )
  (
    input                       clk       ,
    input                       reset     ,
    input                       en        ,
    input      [45*INWIDTH-1:0] din       ,
    input                       din_valid ,
    output signed [INWIDTH+6:0] dout      ,
    output                      dout_valid 
  );
  localparam NUM_INPUTS = 45;
  reg   [2:1] din_valid_d;
  wire        add_en;
  genvar      g;
  genvar      i;
  
  wire signed [INWIDTH-1:0] din_buf       [0:44];
  wire signed [INWIDTH+1:0] add_l0_y      [0:14];
  wire [(INWIDTH+2)*15-1:0] addtree15_din       ;
  wire signed [INWIDTH+6:0] addtree15_dout      ;
  wire                      addtree15_ovld      ;
   
  generate
    for (g = 0; g < NUM_INPUTS; g = g + 1) begin : inputs
      assign din_buf[g] = $signed(din[(g+1)*INWIDTH-1:g*INWIDTH]);
    end

    for (g = 0; g < 15; g = g + 1) begin : L0
      Add3 #(.INWIDTH(INWIDTH), .IN_FRAC(IN_FRAC)) U_add3_L0 (
        .clk  ( clk             ),
        .reset( reset           ),
        .en   ( en && add_en    ),
        .a    ( din_buf[g*3]    ),
        .d    ( din_buf[g*3+1]  ),
        .c    ( din_buf[g*3+2]  ),
        .y    ( add_l0_y[g]     ) 
      );
      
      assign addtree15_din[(g+1)*(INWIDTH+2)-1:(INWIDTH+2)*g] = add_l0_y[g];
    end
  endgenerate

  assign add_en = |{din_valid, din_valid_d};

  always @(posedge clk) begin
    if (reset)
      din_valid_d <= 0;
    else if (en)
      din_valid_d <= {din_valid_d[1:1], din_valid};
  end

  AdderTree15 #(.INWIDTH(INWIDTH+2), .IN_FRAC(IN_FRAC)) U_atree (
    .clk       ( clk              ),
    .reset     ( reset            ),
    .en        ( en               ),
    .din       ( addtree15_din    ),
    .din_valid ( din_valid_d[2]   ),
    .dout      ( addtree15_dout   ),
    .dout_valid( addtree15_ovld   ) 
  );

  assign dout_valid = addtree15_ovld;
  assign dout = addtree15_dout;
endmodule