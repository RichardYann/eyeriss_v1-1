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
    input clk,rst,en,
    // input signed [INWIDTH-1:0] DATA_IN[0:DI_W-1][0:DI_H], 
    // input signed [INWIDTH-1:0] FILTER [0:FIL_S-1][0:FIL_S-1],
    output signed [INWIDTH-1:0] DATA_OUT[0:DO_W-1],
    output done
);
//wire signed [INWIDTH-1:0] filter_1_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_1_2 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_1_3 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_2_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_2_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_2_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_3_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_3_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_3_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_4_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_4_1 [0:FIL_S-1] ;
//wire signed [INWIDTH-1:0] filter_4_1 [0:FIL_S-1] ;

//wire signed [INWIDTH-1:0] data_2_1 [0:DI_W-1] ;
//wire signed [INWIDTH-1:0] data_2_2 [0:DI_W-1] ;
//wire signed [INWIDTH-1:0] data_2_3 [0:DI_W-1] ;
//wire signed [INWIDTH-1:0] data_2_4 [0:DI_W-1] ;
//wire signed [INWIDTH-1:0] data_3_1 [0:DI_W-1] ;
//wire signed [INWIDTH-1:0] data_3_2 [0:DI_W-1] ;
//wire signed [INWIDTH-1:0] data_3_3 [0:DI_W-1] ;
//wire signed [INWIDTH-1:0] data_3_4 [0:DI_W-1] ;

//wire signed [INWIDTH-1:0] psum_1_1 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_1_2 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_1_3 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_1_4 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_1_5 [0:DO_W-1] ;

//wire signed [INWIDTH-1:0] psum_2_1 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_2_2 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_2_3 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_2_4 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_2_5 [0:DO_W-1] ;

//wire signed [INWIDTH-1:0] psum_3_1 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_3_2 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_3_3 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_3_4 [0:DO_W-1] ;
//wire signed [INWIDTH-1:0] psum_3_5 [0:DO_W-1] ;

//parameter IDLE = 2'b00; INPT = 2'b01; COMP = 2'b10; OUPT = 2'b11;
//reg [1:0] state,state_next;

//always @(clk) begin
//    if(rst)
//    state <= IDLE;
//    else
//    state <= state_next;
//end

//reg read,read_done,com_start,com_done;
//always @(*) begin
//    case (state)
//        IDLE: if(en) state_next = INPT; 
//        INPT: if(read_done) state_next = COMP;
//        COMP: if() state_next = OUPT;
//        OUPT: state_next = IDLE;//Not initialize a ram, output parallized in 1 clk.
//        default: 
//    endcase

//end


////INPT
////In this design, to make the process clear, neglect the 
////optimation when read data and compute data in the same time.
//rom rom_1_1_filter(
//    .clk(clk),
//    .addr(),
//    .read(),
//    .dout()
//);

//assign DATA_OUT = {{data_1_1},{data_1_2},{data_1_3},{data_1_4},{data_1_5}};

////compute series
////clk1  PE_X_1
////clk2  PE_X_2

//// PE unnits interconnection 3*5
//PE #(

//)u_PE_1_1( 
//    .clk(clk),
//    .rst(rst),
//    .en(comp_start),
//    .FILTER_IN(FILTER[0]), //{rom[]}
//    .DATA_IN(DATA_IN[0]),
//    .PSUM_IN(psum_2_1),
//    .FILTER_OUT(filter_1_1),
//    .DATA_OUT(data_1_1),
//    .PSUM_OUT(psum_1_1),
//    .done(done_1_1)
//);

//PE #(

//)u_PE_2_1( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(FILTER[1]),
//    .DATA_IN(DATA_IN[1]),
//    .PSUM_IN(psum_3_1),
//    .FILTER_OUT(filter_2_1),
//    .DATA_OUT(data_2_1),
//    .PSUM_OUT(psum_2_1)
//);

//PE #(

//)u_PE_3_1( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(FILTER[2]),
//    .DATA_IN(DATA_IN[2]),
//    .PSUM_IN(), // 空接
//    .FILTER_OUT(filter_3_1),
//    .DATA_OUT(filter_3_1),
//    .PSUM_OUT(psum_3_1)
//);

//PE #(

//)u_PE_3_2( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_3_1),
//    .DATA_IN(DATA_IN[3]),
//    .PSUM_IN(),
//    .FILTER_OUT(filter_3_2),
//    .DATA_OUT(data_3_2),
//    .PSUM_OUT(psum_3_2)
//);

//PE #(

//)u_PE_3_3( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_3_2),
//    .DATA_IN(DATA_IN[4]),
//    .PSUM_IN(),
//    .FILTER_OUT(filter_3_3),
//    .DATA_OUT(data_3_3),
//    .PSUM_OUT(psum_3_3)
//);

//PE #(

//)u_PE_3_4( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_3_3),
//    .DATA_IN(DATA_IN[5]),
//    .PSUM_IN(),
//    .FILTER_OUT(filter_3_4),
//    .DATA_OUT(data_3_4),
//    .PSUM_OUT(psum_3_4)
//);

//PE #(

//)u_PE_3_5( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_3_4),
//    .DATA_IN(DATA_IN[6]),
//    .PSUM_IN(),
//    .FILTER_OUT(filter_3_5),
//    .DATA_OUT(data_3_5),
//    .PSUM_OUT(psum_3_5)
//);


//PE #(

//)u_PE_2_2( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_2_1),
//    .DATA_IN(data_3_1),
//    .PSUM_IN(psum_3_2),
//    .FILTER_OUT(filter_2_2),
//    .DATA_OUT(data_2_2),
//    .PSUM_OUT(psum_2_2)
//);

//PE #(

//)u_PE_2_3( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_2_2),
//    .DATA_IN(data_3_2),
//    .PSUM_IN(psum_3_3),
//    .FILTER_OUT(filter_2_3),
//    .DATA_OUT(data_2_3),
//    .PSUM_OUT(psum_2_3)
//);

//PE #(

//)u_PE_2_4( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_2_3),
//    .DATA_IN(data_3_3),
//    .PSUM_IN(psum_3_4),
//    .FILTER_OUT(filter_2_4),
//    .DATA_OUT(data_2_4),
//    .PSUM_OUT(psum_2_4)
//);

//PE #(

//)u_PE_2_5( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_2_4),
//    .DATA_IN(data_3_4),
//    .PSUM_IN(psum_3_5),
//    .FILTER_OUT(filter_2_5),
//    .DATA_OUT(data_2_5),
//    .PSUM_OUT(psum_2_5)
//);

//PE #(

//)u_PE_1_2( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_1_1),
//    .DATA_IN(data_2_1),
//    .PSUM_IN(psum_2_2),
//    .FILTER_OUT(filter_1_2),
//    .DATA_OUT(data_1_2),
//    .PSUM_OUT(psum_1_2)
//);

//PE #(

//)u_PE_1_3( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_1_2),
//    .DATA_IN(data_2_2),
//    .PSUM_IN(psum_2_3),
//    .FILTER_OUT(filter_1_3),
//    .DATA_OUT(data_1_3),
//    .PSUM_OUT(psum_1_3)
//);

//PE #(

//)u_PE_1_4( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_1_3),
//    .DATA_IN(data_2_3),
//    .PSUM_IN(psum_2_4),
//    .FILTER_OUT(filter_1_4),
//    .DATA_OUT(data_1_4),
//    .PSUM_OUT(psum_1_4)
//);

//PE #(

//)u_PE_1_5( 
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .FILTER_IN(filter_1_4),
//    .DATA_IN(data_2_4),
//    .PSUM_IN(psum_2_5),
//    .FILTER_OUT(filter_1_5),
//    .DATA_OUT(data_1_5),
//    .PSUM_OUT(psum_1_5)
//);

//endmodule

//// caculater row_1 data
//// for PE_1_1 to PE_3_1, work parallel
//// sum for 3 arrays [15:0] 1*5
//// this part worth further optimization **
//module acc_row (
//    input [INWIDTH-1:0] PSUM_PE_1_[0:DO_W-1],
//    input [INWIDTH-1:0] PSUM_PE_2_[0:DO_W-1],
//    input [INWIDTH-1:0] PSUM_PE_3_[0:DO_W-1],

//    output [INWIDTH-1:0] SUM
//);
//  reg [INWIDTH-1:0]sum [0:DO_W];
//  genvar i;
//  generate
//      for(i = 0; i< DO_W;i=i+1)
//      always(*) begin
//          sum[i] = PSUM_PE_1_[i] + PSUM_PE_2_[i] + PSUM_PE_3_[i];
//      end  
//endgenerate
//    assign SUM = sum;
endmodule