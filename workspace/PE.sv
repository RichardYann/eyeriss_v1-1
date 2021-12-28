`timescale 1ns / 1ns
module PE
//Edit Suggestion,12.28. change the en to a step signal rather than a pulse.
(
    input clk,rst,en,

    input   [15:0] FILTER_IN   [0:2],
    input   [15:0] DATA_IN     [0:6],
    input   [15:0] PSUM_IN     [0:4],

    output  [15:0] FILTER_OUT  [0:2],
    output  [15:0] DATA_OUT    [0:6],
    output  [15:0] PSUM_OUT    [0:4],
    output         DONE
);

//实现序列乘法
reg  [15:0]data_in     [0:6];
reg  [15:0]filter   [0:2]; 
reg  [15:0]psum     [0:4];

reg [15:0] data [0:2];

wire [15:0]res;
reg done;
reg [1:0] state,state_next;

parameter [1:0] IDLE = 2'd0, //初始
                INPT = 2'd1, //输入
                COMP = 2'd2, //计算
                OUPT = 2'd3; //输出
reg [2:0]counter;

reg flag;
always @(posedge clk) begin
    if(rst) flag <= 0;
    else if(en) flag <= 1;
    else if(done) flag <= 0;
end
//state switch
always @(posedge clk) begin
    if(rst||en) begin
        state <= IDLE;
    end
    else begin
        state <= state_next;
    end
end

always @(*) begin
    if(rst) state_next = IDLE;
    else begin
    case (state) 
         IDLE: if(en) state_next = INPT ;
         INPT: if(flag) state_next = COMP;    
         COMP: if(counter == 4) state_next = OUPT;
         OUPT: state_next = IDLE;
        default: state_next = IDLE;
    endcase  
    end  
end
//INPT

always @(posedge clk) begin
    if(rst) begin
        data_in <= {0,0,0,0,0,0,0};
        filter  <= {0,0,0};
    end
    else if(state_next == INPT) begin
        data_in <= DATA_IN;
        filter <= FILTER_IN;
    end
end

//COMP
always @(posedge clk) begin
    if(rst||en) begin
        counter <= 0;
    end
    else if((state_next ==  COMP) && flag) begin
        counter <= counter + 1;
    end
end
// input data to the input array seriesly
always @(*) begin 
    if(rst) data = {0,0,0};
    else begin
    case (counter)
        0: data = {data_in[0],data_in[1],data_in[2]} ;
        1: data = {data_in[1],data_in[2],data_in[3]} ;
        2: data = {data_in[2],data_in[3],data_in[4]} ;
        3: data = {data_in[3],data_in[4],data_in[5]} ;
        4: data = {data_in[4],data_in[5],data_in[6]} ;
        default: data = {0,0,0};
    endcase
    end
end
//deposit data from the multipiler_3
always @(posedge clk) begin
    if(rst) psum <= {0,0,0,0,0};
    else if(state_next == INPT) psum <= PSUM_IN;
    else
    case(counter)
        0: if(state_next == COMP)psum[0] <= psum[0] + res;
        1: psum[1] <= psum[1] + res;
        2: psum[2] <= psum[2] + res;
        3: psum[3] <= psum[3] + res;
        4: if(state_next == OUPT) psum[4] <= psum[4] + res; 
        default: psum <= {0,0,0,0,0};
    endcase
end

vector_mult m1(.A(filter),.B(data),.RES(res));

//OUPT  en, psum 
always @(posedge clk) begin
    if(rst) done <= 0;
    else  if(state_next == OUPT)
        done <= 1;
    else    
        done <= 0;

end


assign  DATA_OUT = data_in;
assign  PSUM_OUT = psum;
assign  FILTER_OUT = filter;
assign  DONE = done;

endmodule;
