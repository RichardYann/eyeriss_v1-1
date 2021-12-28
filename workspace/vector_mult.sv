//向量乘法模块，直接输出16位宽数据
//frac= 12,

//3*3向量乘法,总共需要
module vector_mult
(
input  [15:0] A[0:2],
input  [15:0] B[0:2],
output  [15:0] RES     
);
reg  [15:0] a_3   [0:2];
reg  [15:0] b_3   [0:2];
reg  [15:0] psum   [0:2];
// wire [15:0] mu[0:2];

always @(*)begin
 a_3[0] = A[0] ;
 a_3[1] = A[1] ;
 a_3[2] = A[2] ;
 b_3[0] = B[0] ;
 b_3[1] = B[1] ;
 b_3[2] = B[2] ;
end

genvar i;

generate
    for(i = 0; i < 3; i = i + 1) begin
        mult m1(.a(a_3[i]),.b(b_3[i]),.res(psum[i]));
    end
endgenerate

assign RES = psum[0] + psum[1] + psum[2];
endmodule


module mult 
#(
    parameter INWIDTH = 16 
)
(
input  [15:0] a,
input  [15:0] b,
output  [15:0] res 
);
wire  [31:0] P ;
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

