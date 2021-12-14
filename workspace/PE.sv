//一个PE单元




//一个PE单元例化5个3*3的乘法器，并行计算
parameter FIL_S = 3;
parameter DI_W = 7;
parameter DI_L = 7;
parameter DO_W = 5;
parameter DO_H = 5;

module PE
#(
    parameter INWIDTH = 16
)(
    input clk,rst,en;

    input signed  [INWIDTH-1:0] PSUM_IN     [0:DO_W-1;
    input signed  [INWIDTH-1:0] FILTER_IN   [0:FIL_S -1];
    input signed  [INWIDTH-1:0] DATA_IN     [0:DI_W - 1];

    output signed [INWIDTH-1:0] FILTER_IN   [0:FIL_S-1];
    output signed [INWIDTH-1:0] DATA_OUT    [0:DI_W-1];
    output signed [INWIDTH-1:0] PSUM_OUT    [0:DO_W-1];
)
parameter  = ;
genvar ii,jj;
//实现序列乘法
reg signed [INWIDTH-1:0]data_in     [0:DI_W];
reg signed [INWIDTH-1:0]filter   [0:FIL_S]; 
reg signed [INWIDTH-1:0]psum     [0:DO_W]
reg en;
reg [2:0] state,state_next;
parameter [2:0] IDLE = 3'd0; //初始态
                INPT = 3'd1; //输入
                COMP1 = 3'd2; //计算
                COMP2 = 3'd3;
                COMP3 = 3'd4;
                COMP4 = 3'd5;
                COMP5 = 3'd6;
                OUPT = 3'd7;//输出

always @(*) begin
    case (state)
        IDLE: if(en) state_next = INPT ;
        INPT: state_next = COMP1;
        COMP1:
        COMP2:
        COMP3:
        COMP4:
        COMP5:
        OUPT:
        default: 
    endcase
    
end


generate
    for(ii = 0; ii < DI_W; ii = ii + 1)  begin :data_in
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
    for(ii = 0; ii < FIL_S; ii = ii + 1)  begin :filter
        always @(posedge clk) begin
            if(rst) begin
                filter[ii] <= 0;
            else if (en) begin
                filter[ii] <= FILTER_IN[ii];
            end
            end
        end
endgenerate

generate
    for(ii = 0; ii < DO_W; ii = ii + 1)  begin :psum

endgenerate


//这个不知道行不行
always @(posedge clk) begin
    if(rst) begin
        data_in <= 0;
        filter <= 0;
    else if(en) begin
        data_in <= DATA_IN;
        filter <= FILTER_IN;
    end
    end
end


//counter
always @(posedge clk) begin:counter
    if(rst) 
    counter <= 0;
    else if()
    counter <= counter + 1;
    
end
always @(*) begin
  
        else case (counter)
            0: data ={data_in[0],data_in[1],data_in[2]};
            1: data ={data_in[1],data_in[2],data_in[3]};
            2: data ={data_in[2],data_in[3],data_in[4]};
            3: data ={data_in[3],data_in[4],data_in[5]};
            4: data ={data_in[4],data_in[5],data_in[6]};
            5: PSUM_OUT = psum;
            default:
        endcase
    end
end

generate
    for(ii; ii < DO_W; ii = ii + 1)  begin:psum
            mult_3 m1(.a(filter),.b(data),.res(psum[ii]));
        end
    end 
endgenerate






endmodule;

