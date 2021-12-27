// read [15:0] 7*7 data from dram and output [15:0] 5*5 data back to dram
module conv_top  (
    input clk,rst,en,
    input     [5:0] addr,
    input           read,
    output   [15:0] DATA_OUT[0:4][0:4]
);
wire   [15:0] filter_1_1 [0:2] ;
wire   [15:0] filter_1_2 [0:2] ;
wire   [15:0] filter_1_3 [0:2] ;
wire   [15:0] filter_1_4 [0:2] ;
wire   [15:0] filter_1_5 [0:2] ;
wire   [15:0] filter_2_1 [0:2] ;
wire   [15:0] filter_2_2 [0:2] ;
wire   [15:0] filter_2_3 [0:2] ;
wire   [15:0] filter_2_4 [0:2] ;
wire   [15:0] filter_2_5 [0:2] ;
wire   [15:0] filter_3_1 [0:2] ;
wire   [15:0] filter_3_2 [0:2] ;
wire   [15:0] filter_3_3 [0:2] ;
wire   [15:0] filter_3_4 [0:2] ;
wire   [15:0] filter_3_5 [0:2] ;


wire   [15:0] data_1_1 [0:6] ;
wire   [15:0] data_1_2 [0:6] ;
wire   [15:0] data_1_3 [0:6] ;
wire   [15:0] data_1_4 [0:6] ;
wire   [15:0] data_1_5 [0:6] ;
wire   [15:0] data_2_1 [0:6] ;
wire   [15:0] data_2_2 [0:6] ;
wire   [15:0] data_2_3 [0:6] ;
wire   [15:0] data_2_4 [0:6] ;
wire   [15:0] data_2_5 [0:6] ;
wire   [15:0] data_3_1 [0:6] ;
wire   [15:0] data_3_2 [0:6] ;
wire   [15:0] data_3_3 [0:6] ;
wire   [15:0] data_3_4 [0:6] ;
wire   [15:0] data_3_5 [0:6] ;

wire   [15:0] psum_1_1 [0:4] ;
wire   [15:0] psum_1_2 [0:4] ;
wire   [15:0] psum_1_3 [0:4] ;
wire   [15:0] psum_1_4 [0:4] ;
wire   [15:0] psum_1_5 [0:4] ;

wire   [15:0] psum_2_1 [0:4] ;
wire   [15:0] psum_2_2 [0:4] ;
wire   [15:0] psum_2_3 [0:4] ;
wire   [15:0] psum_2_4 [0:4] ;
wire   [15:0] psum_2_5 [0:4] ;

wire   [15:0] psum_3_1 [0:4] ;
wire   [15:0] psum_3_2 [0:4] ;
wire   [15:0] psum_3_3 [0:4] ;
wire   [15:0] psum_3_4 [0:4] ;
wire   [15:0] psum_3_5 [0:4] ;

wire    done_1_1,done_1_2,done_1_3,done_1_4,done_1_5,
        done_2_1,done_2_2,done_2_3,done_2_4,done_2_5,
        done_3_1,done_3_2,done_3_3,done_3_4,done_3_5;

reg en1,en2,en3,en4,en5,en6,en7;
reg [15:0]filter_buff[0:2];
reg [15:0]data_buff[0:6];

wire    [15:0]data_in;
reg     [15:0]data_out[0:4][0:4];

rom u_rom(
    .clk(clk),
    .rst(rst),
    .addr(addr),
    .read(read),
    .dout(data_in)  
);

wire en_c;
reg en_d,en_dd;
reg [3:0]counter;//control the read dataflow
always @(posedge clk) begin
    en_d <= en;
    en_dd <= en_d;
end
assign en_c = en_dd||en1||en2||en3||en4||en5||en6||en7;
always @(posedge clk) begin
    if(rst||en_c) counter <= 0;
    else  counter <= counter + 1;
end
always @(posedge clk) begin
    if(counter < 7) begin//read data F1,D1
        data_buff <= {data_buff[1:6],data_in};
    end
    else if(counter < 10) begin
        filter_buff <= {filter_buff[1:2],data_in};
    end
end

reg [3:0] state,state_next;
parameter   IDLE = 4'd0,
            READ1 = 4'd1,
            READ2 = 4'd2,
            READ3 = 4'd3,
            READ4 = 4'd4,
            READ5 = 4'd5,
            READ6 = 4'd6,
            READ7 = 4'd7,
            COMP  = 4'd8,
            OUPT  = 4'd9;
//read data F2,D2
always @(posedge clk) begin
    if(rst)
    state <= IDLE;
    else
    state <= state_next;
end






always @(*) begin
    case (state)
        IDLE: if(en) state_next = READ1; 
        READ1: if(counter == 10) state_next = READ2;//F_row1,D_row1
        READ2: if(counter == 10) state_next = READ3;//F_row1,D_row1
        READ3: if(counter == 10) state_next = READ4;//F_row1,D_row1
        READ4: if(counter == 7)  state_next = READ5;//D_row4
        READ5: if(counter == 7)  state_next = READ6;//D_row5
        READ6: if(counter == 7) state_next = READ7;//D_row6
        READ7: if(counter == 7) state_next = COMP;//D_row7
        COMP:if(done_1_5) state_next = OUPT;
        OUPT: state_next = IDLE;
        default: state_next = IDLE;
    endcase

end


always @(posedge clk) begin
     en1 <= (state == READ1 && state_next == READ2);//加一个delay，防止延时错误
     en2 <= (state == READ2 && state_next == READ3);
     en3 <= (state == READ3 && state_next == READ4);
     en4 <= (state == READ4 && state_next == READ5);
     en5 <= (state == READ5 && state_next == READ6);
     en6 <= (state == READ6 && state_next == READ7);
     en7 <= (state == READ7 && state_next == COMP);
end

//compute series


// PE unnits interconnection 3*5
PE u_PE_1_1( 
    .clk(clk),
    .rst(rst),
    .en(en3),
    .FILTER_IN(filter_buff), 
    .DATA_IN(data_buff),
    .PSUM_IN(psum_2_1),
    .FILTER_OUT(filter_1_1),
    .DATA_OUT(data_1_1),
    .PSUM_OUT(psum_1_1),
    .DONE(done_1_1)
);

PE u_PE_2_1( 
    .clk(clk),
    .rst(rst),
    .en(en2),
    .FILTER_IN(filter_buff),
    .DATA_IN(data_buff),
    .PSUM_IN(psum_3_1),
    .FILTER_OUT(filter_2_1),
    .DATA_OUT(data_2_1),
    .PSUM_OUT(psum_2_1),
    .DONE(done_2_1)
);

PE u_PE_3_1( 
    .clk(clk),
    .rst(rst),
    .en(en1),
    .FILTER_IN(filter_buff),
    .DATA_IN(data_buff),
    .PSUM_IN({0,0,0,0,0}), // 空接
    .FILTER_OUT(filter_3_1),
    .DATA_OUT(data_3_1),
    .PSUM_OUT(psum_3_1),
    .DONE(done_3_1)
);

PE u_PE_3_2( 
    .clk(clk),
    .rst(rst),
    .en(en4),
    .FILTER_IN(filter_3_1),
    .DATA_IN(data_buff),
    .PSUM_IN({0,0,0,0,0}),
    .FILTER_OUT(filter_3_2),
    .DATA_OUT(data_3_2),
    .PSUM_OUT(psum_3_2),
    .DONE(done_3_2)
);

PE #(

)u_PE_3_3( 
    .clk(clk),
    .rst(rst),
    .en(en5),
    .FILTER_IN(filter_3_2),
    .DATA_IN(data_buff),
    .PSUM_IN({0,0,0,0,0}),
    .FILTER_OUT(filter_3_3),
    .DATA_OUT(data_3_3),
    .PSUM_OUT(psum_3_3),
    .DONE(done_3_3)
);

PE #(

)u_PE_3_4( 
    .clk(clk),
    .rst(rst),
    .en(en6),
    .FILTER_IN(filter_3_3),
    .DATA_IN(data_buff),
    .PSUM_IN({0,0,0,0,0}),
    .FILTER_OUT(filter_3_4),
    .DATA_OUT(data_3_4),
    .PSUM_OUT(psum_3_4),
    .DONE(done_3_4)
);

PE #(

)u_PE_3_5( 
    .clk(clk),
    .rst(rst),
    .en(en7),
    .FILTER_IN(filter_3_4),
    .DATA_IN(data_buff),
    .PSUM_IN({0,0,0,0,0}),
    .FILTER_OUT(filter_3_5),
    .DATA_OUT(data_3_5),
    .PSUM_OUT(psum_3_5),
    .DONE(done_3_5)
);


PE u_PE_2_2( 
    .clk(clk),
    .rst(rst),
    .en(en5),
    .FILTER_IN(filter_2_1),
    .DATA_IN(data_3_1),
    .PSUM_IN(psum_3_2),
    .FILTER_OUT(filter_2_2),
    .DATA_OUT(data_2_2),
    .PSUM_OUT(psum_2_2),
    .DONE(done_2_2)
);

PE u_PE_2_3( 
    .clk(clk),
    .rst(rst),
    .en(en6),
    .FILTER_IN(filter_2_2),
    .DATA_IN(data_3_2),
    .PSUM_IN(psum_3_3),
    .FILTER_OUT(filter_2_3),
    .DATA_OUT(data_2_3),
    .PSUM_OUT(psum_2_3),
    .DONE(done_2_3)
);

PE u_PE_2_4( 
    .clk(clk),
    .rst(rst),
    .en(en7),
    .FILTER_IN(filter_2_3),
    .DATA_IN(data_3_3),
    .PSUM_IN(psum_3_4),
    .FILTER_OUT(filter_2_4),
    .DATA_OUT(data_2_4),
    .PSUM_OUT(psum_2_4),
    .DONE(done_2_4)
);

PE u_PE_2_5( 
    .clk(clk),
    .rst(rst),
    .en(done_2_4 && done_3_5),
    .FILTER_IN(filter_2_4),
    .DATA_IN(data_3_4),
    .PSUM_IN(psum_3_5),
    .FILTER_OUT(filter_2_5),
    .DATA_OUT(data_2_5),
    .PSUM_OUT(psum_2_5),
    .DONE(done_2_5)
);

PE #(

)u_PE_1_2( 
    .clk(clk),
    .rst(rst),
    .en(en6),
    .FILTER_IN(filter_1_1),
    .DATA_IN(data_2_1),
    .PSUM_IN(psum_2_2),
    .FILTER_OUT(filter_1_2),
    .DATA_OUT(data_1_2),
    .PSUM_OUT(psum_1_2),
    .DONE(done_1_2)
);

PE u_PE_1_3( 
    .clk(clk),
    .rst(rst),
    .en(en7),
    .FILTER_IN(filter_1_2),
    .DATA_IN(data_2_2),
    .PSUM_IN(psum_2_3),
    .FILTER_OUT(filter_1_3),
    .DATA_OUT(data_1_3),
    .PSUM_OUT(psum_1_3),
    .DONE(done_1_3)
);

PE u_PE_1_4( 
    .clk(clk),
    .rst(rst),
    .en(done_1_3 && done_2_4),
    .FILTER_IN(filter_1_3),
    .DATA_IN(data_2_3),
    .PSUM_IN(psum_2_4),
    .FILTER_OUT(filter_1_4),
    .DATA_OUT(data_1_4),
    .PSUM_OUT(psum_1_4),
    .DONE(done_1_4)
);

PE u_PE_1_5( 
    .clk(clk),
    .rst(rst),
    .en(done_1_4 && done_2_5),
    .FILTER_IN(filter_1_4),
    .DATA_IN(data_2_4),
    .PSUM_IN(psum_2_5),
    .FILTER_OUT(filter_1_5),
    .DATA_OUT(data_1_5),
    .PSUM_OUT(psum_1_5),
    .DONE(done_1_5)
);

//OUPT
always @(posedge clk) begin
    if(rst) data_out <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
    else if(state_next == OUPT)
    data_out <= {psum_1_1, psum_1_2, psum_1_3, psum_1_4, psum_1_5};
end

genvar ii,jj;
wire     [15:0]data_out_com[0:4][0:4];
for(ii = 0; ii < 5;ii = ii + 1) begin
        for(jj = 0; jj < 5; jj = jj + 1) begin
            assign data_out_com[ii][jj] = data_out[ii][jj][15] ? (~(data_out[ii][jj] - 16'b1000_0000_0000_0001)) : data_out[ii][jj];
        end
end


 
assign DATA_OUT = data_out;
endmodule

// caculater row_1 data
// for PE_1_1 to PE_3_1, work parallel
// sum for 3 arrays [15:0] 1*5
// this part worth further optimization **
// module acc_row (
//     input [15:0] PSUM_PE_1_[0:4],
//     input [15:0] PSUM_PE_2_[0:4],
//     input [15:0] PSUM_PE_3_[0:4],

//     output [15:0] SUM
// );
//   reg [15:0]sum [0:4];
//   genvar i;
//   generate
//       for(i = 0; i< 5;i=i+1)
//       always(*) begin
//           sum[i] = PSUM_PE_1_[i] + PSUM_PE_2_[i] + PSUM_PE_3_[i];
//       end  
// endgenerate
//     assign SUM = sum;
// endmodule