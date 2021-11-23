//一个PE单元




//一个PE单元例化5个3*3的乘法器，并行计算
parameter FILTER_SIZE = 3;
parameter DATAIN_W = 7;
parameter DATAIN_L = 7;
parameter DATAO_W = 5;
parameter DATAO_L = 5;

module PE_1_1
#(
    parameter INWIDTH = 16
)(
    input clk,rst;

    input signed  [INWIDTH-1:0] PSUM_IN     [0:DATAO_W-1;
    input signed  [INWIDTH-1:0] FILTER_IN   [0:FILTER_SIZE -1];
    input signed  [INWIDTH-1:0] DATA_IN     [0:DAIN_W - 1];

    output signed [INWIDTH-1:0] FILTER_IN   [0:FILTER_SIZE-1];
    output signed [INWIDTH-1:0] DATA_OUT    [0:DATAIN_W-1];
    output signed [INWIDTH-1:0] PSUM_OUT    [0:DATAO_W-1];
)
parameter  = ;
genvar ii,jj;
//实现序列乘法
reg signed [INWIDTH-1:0]data_in     [0:DATAIN_W];
reg signed [INWIDTH-1:0]filter_in   [0:FILTER_SIZE]; 

generate
    for(ii = 0; ii < DATAIN_W; ii = ii + 1)  begin :data_in
        always @(posedge clk) begin
            if(rst) begin
                data_in[ii] <= 0;
            else if (en) begin
                data_in[ii] <= DATA_IN[ii];
            end
            end
        end
endgenerate

generate
    for(ii = 0; ii < FILTER_SIZE; ii = ii + 1)  begin :filter_in
        always @(posedge clk) begin
            if(rst) begin
                filter_in[ii] <= 0;
            else if (en) begin
                filter_in[ii] <= FILTER_IN[ii];
            end
            end
        end
endgenerate


//这个不知道行不行
always @(posedge clk) begin
    if(rst) begin
        data_in <= 0;
        filter_in <= 0;
    else if(en) begin
        data_in <= DATA_IN;
        filter_in <= FILTER_IN;
    end
    end
end
generate
    for(ii; ii < DATAO_W; ii = ii + 1)  begin:psum
        for(jj; jj < FILTER_SIZE; jj = jj + 1)  begin:
            mult m1(.a(filter_in[jj]),.b(data_in[jj]),.res(jj))
        end
    end 
endgenerate






endmodule;


//一个PE单元仅一个3*3的乘法器，串行计算
parameter FILTER_SIZE = 3;
parameter DATAIN_W = 3;
parameter DATAIN_L = 3;
parameter DATAO_W = 5;
parameter DATAO_L = 5;

module PE_1_1(
    input clk,rst;

    input reg [DATAO_W - 1:0]psum_in;
    input reg [FILTER_SIZE -1:0]filter_in;
    input reg [DAIN_W - 1:0]data_in;

    output [FILTER_SIZE-1:0]filter_out;
    output [DATAIN_W-1:0]data_out;
    output [DATAO_W-1:0]psum_out;
)
//实现序列乘法
reg [$clog(FILTER_SIZE)-1:0]cnt_i;
reg [$clog(DATAIN_W)-1:0]cnt_j;
reg [FILTER_SIZE-1:0]sequnce;
    

endmodule;



