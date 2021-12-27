`timescale 1ns / 1ns
module PE_tb();
    reg   clk,rst,en;
    reg   [15:0] filter_in   [0:2];
    reg   [15:0] data_in     [0:6];
    reg   [15:0] psum_in     [0:4];

    wire  [15:0] filter_out  [0:2];
    wire  [15:0] data_out    [0:6];
    wire  [15:0] psum_out    [0:4];
    wire         done;
PE PE_test(
       .clk(clk),
       .rst(rst),
       .en(en),
       .FILTER_IN(filter_in),
       .DATA_IN(data_in),
       .PSUM_IN(psum_in),
       .FILTER_OUT(filter_out),
       .DATA_OUT(data_out),
       .PSUM_OUT(psum_out),
       .DONE(done)
    );

    //clk
    initial begin 
        clk = 0;
        forever
        #10
        clk = ~clk;
    end
        
    //RESET
    initial begin
        rst = 0;
        #3
        rst = 1;
        #30
        rst = 0;
        #2500
        $finish;
    end 

    //start and output
    initial begin
        #53
        en = 1;
        #30
        en = 0;
    end 

    // always @(*) begin
    //     if(done)  begin
    //     en = 1;
    //     #30
    //     en = 0;
    //     end
    // end

    initial begin
        //test:row1*row1, without previous psum
        //expected psum_out ={16'h}
        filter_in = {16'hFEDD,16'hFFBC,16'hFCFD};   //row3
        data_in   = {16'h0C8C,16'h0FDF,16'h0FCF,16'h0FCF,16'h0D6D,16'h0A8A,16'h0A8A};  //row3
        psum_in   = {16'h0,16'h0,16'h0,16'h0,16'h0};
    end 
        //psum_out = a250//,8874,9b90,c523,ef13   
        //dump fsdb
    initial begin
        $fsdbDumpfile("PE.fsdb");
        $fsdbDumpvars(0,PE_test);
        $fsdbDumpon;
	    $fsdbDumpMDA();
        end  
    
    endmodule 
