// read [15:0] 7*7 data from dram and output [15:0] 5*5 data back to dram
module conv_top #(
    INWIDTH = 16,
    IN_FRAC = 12,
    DI_W = 7,
    DI_H = 7,
    FIL_S = 3,
    DO_W = 5,
    DO_H = 5
) (
    input clk,rst,
    input signed [INWIDTH-1:0]DI[0:DI_W-1][0:DI_H],     //我不明白这个地方怎么定义，数据的读入应该是串行从ram读取？
    input signed [INWIDTH-1:0] FILTER [0:FIL_S-1][0:FIL_S-1];
    output signed [INWIDTH-1:0]DO[0:DO_W-1],
);
reg

// PE unnits interconnection
PE #(

)u_PE_1_1(
    .CLK(CLK),
    .RST(RST),

    .FIL_I(ram),
    .DI(ram),
    .FIL_O(1_2),
    .DO(x),
    .PSUM_O(row1),
);

PE_2_1 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),

    .FIL_I(ram),
    .DI(ram),
    .FIL_O(2_2),
    .DO(1_2),
    .PSUM_O(row1),
);

PE_3_1 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),

    .FIL_I(ram),
    .DI(ram),
    .FIL_O(3_2),
    .DO(2_2),
    .PSUM_O(row1),
);

PE_1_2 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),

    .FIL_I(1_1),
    .DI(ram),
    .FIL_O(1_3),
    .DO(),
    .PSUM_O(),
);

PE_2_2 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_3_2 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);


PE_1_3 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_2_3 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_3_3 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_1_4 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_2_4 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_3_4 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_1_5 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_2_5 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);

PE_3_5 #(

)u_PE(
    .CLK(CLK),
    .RST(RST),
    .PSUM_I(),
    .FIL_I(),
    .DI(),
    .FIL_I(),
    .DO(),
    .PSUM_O(),
);



endmodule

// caculater row_1 data
// for PE_1_1 to PE_3_1, work parallel
// sum for 3 arrays [15:0] 1*5
// this part worth further optimization **
module acc_row (
    input [INWIDTH-1:0] PSUM_PE_1_[0:DO_W],
    input [INWIDTH-1:0] PSUM_PE_2_[0:DO_W],
    input [INWIDTH-1:0] PSUM_PE_3_[0:DO_W],

    output [INWIDTH-1:0] SUM
);
  reg [INWIDTH-1:0]sum [0:DO_W];
  genvar i;
  generate
      for(i = 0; i< DO_W;i=i+1)
      always(*) begin
          sum[i] = PSUM_PE_1_[i] + PSUM_PE_2_[i] + PSUM_PE_3_[i];
      end  
endgenerate
    assign SUM = sum;
endmodule