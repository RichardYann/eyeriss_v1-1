// read [15:0] 7*7 data from dram and output [15:0] 5*5 data back to dram
module conv_top  (
    input clk,rst,en,
    input     [5:0] addr,
    input           read,
    output   [15:0] DATA_OUT,
    output          VALID
    // output   [15:0] DATA_OUT [0:4][0:4]
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
reg     [15:0]data_out;

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
    en_dd <= en_d;//two delay to match the speed of the input address.
end
assign en_c = en_dd||en1||en2||en3||en4||en5||en6||en7;

always @(posedge clk) begin
    if(rst||en_c) counter <= 0;
    else  counter <= counter + 1;
end

//verdi not support unpacked array contennation.
// always @(posedge clk) begin
//     if(counter < 7) begin//read data F1,D1
//         data_buff <= {data_buff[1:6],data_in};
//     end
//     else if(counter < 10) begin
//         filter_buff <= {filter_buff[1:2],data_in};
//     end
// end


always @(posedge clk) begin
    if(rst||en) begin
    data_buff[0] <= 16'd0;
    data_buff[1] <= 16'd0;
    data_buff[2] <= 16'd0;
    data_buff[3] <= 16'd0;
    data_buff[4] <= 16'd0;
    data_buff[5] <= 16'd0;
    data_buff[6] <= 16'd0;
    filter_buff[0] <= 16'd0;
    filter_buff[1] <= 16'd0;
    filter_buff[2] <= 16'd0;        
    end

    else if(counter < 7) begin//read data F1,D1
        data_buff[0] <= data_buff[1];
        data_buff[1] <= data_buff[2];
        data_buff[2] <= data_buff[3];
        data_buff[3] <= data_buff[4];
        data_buff[4] <= data_buff[5];
        data_buff[5] <= data_buff[6];
        data_buff[6] <= data_in;
    end
    else if(counter < 10) begin
        filter_buff[0] <= filter_buff[1];
        filter_buff[1] <= filter_buff[2];
        filter_buff[2] <= data_in;       
    end
end

//state switch
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

always @(posedge clk) begin
    if(rst)
    state <= IDLE;
    else
    state <= state_next;
end

always @(*) begin
    if(rst)
    state_next = IDLE;
    else begin
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
end

always @(posedge clk) begin
    if(rst||en) begin
        en1 <= 0;
        en2 <= 0;
        en3 <= 0;
        en4 <= 0;
        en5 <= 0;
        en6 <= 0;
        en7 <= 0;
    end
    else begin
     en1 <= (state == READ1 && state_next == READ2);//add a delay, to avoid time conflict
     en2 <= (state == READ2 && state_next == READ3);
     en3 <= (state == READ3 && state_next == READ4);
     en4 <= (state == READ4 && state_next == READ5);
     en5 <= (state == READ5 && state_next == READ6);
     en6 <= (state == READ6 && state_next == READ7);
     en7 <= (state == READ7 && state_next == COMP);
    end
end

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
    .PSUM_IN({16'd0,16'd0,16'd0,16'd0,16'd0}), // 空接
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
    .PSUM_IN({16'd0,16'd0,16'd0,16'd0,16'd0}),
    .FILTER_OUT(filter_3_2),
    .DATA_OUT(data_3_2),
    .PSUM_OUT(psum_3_2),
    .DONE(done_3_2)
);

PE u_PE_3_3( 
    .clk(clk),
    .rst(rst),
    .en(en5),
    .FILTER_IN(filter_3_2),
    .DATA_IN(data_buff),
    .PSUM_IN({16'd0,16'd0,16'd0,16'd0,16'd0}),
    .FILTER_OUT(filter_3_3),
    .DATA_OUT(data_3_3),
    .PSUM_OUT(psum_3_3),
    .DONE(done_3_3)
);

PE u_PE_3_4( 
    .clk(clk),
    .rst(rst),
    .en(en6),
    .FILTER_IN(filter_3_3),
    .DATA_IN(data_buff),
    .PSUM_IN({16'd0,16'd0,16'd0,16'd0,16'd0}),
    .FILTER_OUT(filter_3_4),
    .DATA_OUT(data_3_4),
    .PSUM_OUT(psum_3_4),
    .DONE(done_3_4)
);

PE u_PE_3_5( 
    .clk(clk),
    .rst(rst),
    .en(en7),
    .FILTER_IN(filter_3_4),
    .DATA_IN(data_buff),
    .PSUM_IN({16'd0,16'd0,16'd0,16'd0,16'd0}),
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

PE u_PE_1_2( 
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

// //Parrallel output
// always @(posedge clk) begin
//     if(rst||en) data_out <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
//     else if(state_next == OUPT)
//     data_out <= {psum_1_1, psum_1_2, psum_1_3, psum_1_4, psum_1_5};
// end

//2's com convert to origin code. 
// genvar ii,jj;
// wire     [15:0]data_out_com[0:4][0:4];
// for(ii = 0; ii < 5;ii = ii + 1) begin
//         for(jj = 0; jj < 5; jj = jj + 1) begin
                //an easy but source-wasted way
//             assign data_out_com[ii][jj] = data_out[ii][jj][15] ? (~(data_out[ii][jj] - 16'b1000_0000_0000_0001)) : data_out[ii][jj];
//         end
// end

//series output
reg [15:0] data_out_series [0:4];
always @(posedge clk) begin
    if(rst||en) data_out_series <= {0,0,0,0,0};
    else if(done_1_1)
    data_out_series <= psum_1_1;
    else if(done_1_2)
    data_out_series <= psum_1_2;
    else if(done_1_3)
    data_out_series <= psum_1_3;
    else if(done_1_4)
    data_out_series <= psum_1_4;
    else if(done_1_5)
    data_out_series <= psum_1_5;
end
//because parallel output from PE units, Forcing to make it output sequentially 
//waste space about a counter and 5 clock delay.
reg [4:0]num1;
reg [2:0]num2;
wire valid;
always @(posedge clk) begin
    if(rst||en) begin    num1 <=0; num2<=0;    end
        else if(done_1_1||done_1_2||done_1_3||done_1_4||done_1_5) begin num1 <=0; num2 <= num2+1; end
    else    begin
        num1 <= num1 + 1;
    if(num2==1) begin
        case (num1)
            1: begin data_out <= psum_1_1[0]; end
            2: data_out <= psum_1_1[1]; 
            3: data_out <= psum_1_1[2]; 
            4: data_out <= psum_1_1[3]; 
            5: data_out <= psum_1_1[4]; 
            default: data_out <= 16'h0000;
        endcase
    end
    else if(num2==2) begin
        case (num1)
            1: begin data_out <= psum_1_2[0]; end
            2: data_out <= psum_1_2[1]; 
            3: data_out <= psum_1_2[2]; 
            4: data_out <= psum_1_2[3]; 
            5: data_out <= psum_1_2[4]; 
            default: data_out <= 16'h0000;
        endcase
    end
    else if(num2==3) begin
        case (num1)
            1: begin data_out <= psum_1_3[0];  end
            2: data_out <= psum_1_3[1]; 
            3: data_out <= psum_1_3[2]; 
            4: data_out <= psum_1_3[3]; 
            5: data_out <= psum_1_3[4]; 
            default: data_out <= 16'h0000;
        endcase
    end
    else if(num2==4) begin
        case (num1)
            1: begin data_out <= psum_1_4[0];  end
            2: data_out <= psum_1_4[1]; 
            3: data_out <= psum_1_4[2]; 
            4: data_out <= psum_1_4[3]; 
            5: data_out <= psum_1_4[4]; 

            default: data_out <= 16'h0000;
        endcase
    end
    if(num2==5) begin
        case (num1)
            1: begin data_out <= psum_1_5[0];  end
            2: data_out <= psum_1_5[1]; 
            3: data_out <= psum_1_5[2]; 
            4: data_out <= psum_1_5[3]; 
            5: data_out <= psum_1_5[4]; 
            default: data_out <= 16'h0000;
        endcase
    end
    end
end
assign valid = (num1==2||num1==3||num1==4||num1==5||num1==6);

// assign DATA_OUT_SERIES = data_out_series;
assign DATA_OUT = data_out;
assign VALID = valid;
endmodule