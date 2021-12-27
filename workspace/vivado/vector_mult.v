//向量乘法模块，直接输出16位宽数据
//frac= 12,

//3*3向量乘法,总共需要
module vector_mult
#(
    parameter INWIDTH = 16
)
(
input  [INWIDTH-1:0] A0,A1,A2,
input  [INWIDTH-1:0] B0,B1,B2,
output  [INWIDTH-1:0] RES     
);
reg  [INWIDTH-1:0] a_3   [0:2];
reg  [INWIDTH-1:0] b_3   [0:2];
reg  [INWIDTH-1:0] psum   [0:2];
// wire [INWIDTH-1:0] mu[0:2];

always @(*)begin
 a_3[0] = A0 ;
 a_3[1] = A1 ;
 a_3[2] = A2 ;
 b_3[0] = B0 ;
 b_3[1] = B1 ;
 b_3[2] = B2 ;
end

genvar i;

generate
    for(i = 0; i < 3; i = i + 1) begin
        mult m1(.a(a_3[i]),.b(b_3[i]),.res(psum[i]));
        // always @(*) begin
        // psum[i] = mu[i];
        // end
    end
endgenerate

assign RES = psum[0] + psum[1] + psum[2];


endmodule


module mult 
#(
    parameter INWIDTH = 16 
)
(
input  [INWIDTH-1:0] a,
input  [INWIDTH-1:0] b,
output  [INWIDTH-1:0] res 
);
wire  [2*INWIDTH-1:0] P ;
mult_booth booth_0
(
    .A(a),
    .B(b),
    .P(P)
);

truncated truncated_0
(
    .din(P),
    .dout(res)
);


endmodule

module truncated( 
    input [31:0] din,
    output [15:0] dout
);
assign dout = din[27:12];
endmodule

