//向量乘法模块，直接输出16位宽数据

module mult 
#(
    parameter INWIDTH = 16 
)
(
input signed [INWIDTH-1:0] a,
input signed [INWIDTH-1:0] b,
output signed [INWIDTH-1:0] res 
);
assign res = a + b;

endmodule




//3*3向量乘法
module mult_3#(
    parameter INWIDTH = 16 ,
    parameter NUM = 3
)
(
input signed [INWIDTH-1:0] A0,A1,A2,
input signed [INWIDTH-1:0] B0,B1,B2,
output signed [INWIDTH-1:0] RES     
);
reg signed [INWIDTH-1:0] a_3   [0:NUM-1];
reg signed [INWIDTH-1:0] b_3   [0:NUM-1];
reg signed [INWIDTH-1:0] psum   [0:NUM-1];
wire [INWIDTH-1:0] res,mu;

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
    for(i = 0; i < NUM; i = i + 1) begin
        mult m1(.a(a_3[i]),.b(b_3[i]),.res(mu));
        always @(*) begin
        psum[i] = mu;
        end
    end
endgenerate

assign res = psum[0] + psum[1] + psum[2];
assign RES = res; 

endmodule

