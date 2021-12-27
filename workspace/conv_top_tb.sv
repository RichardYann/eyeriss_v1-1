module conv_top_tb();
    reg clk,rst,en;
    reg     [5:0] addr ;
    reg           read ;
    wire   [15:0] DATA_OUT[0:4][0:4];
    reg     [6:0] n;
conv_top conv_top_test(
       .clk(clk),
       .rst(rst),
       .en(en),
       .addr(addr),
       .read(read),
       .DATA_OUT(DATA_OUT)
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
        #5
        rst = 1;
        #30
        rst = 0;
        #2500
        $finish;
    end 

    //start and output
    initial begin
        #55
        en = 1;
        #20
        en = 0;
    end 

    //read
    initial begin
        read = 1;
    end
    // initial begin
    //     // addr = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
    //     //         10,11,12,13,14,15,16,17,18,19,
    //     //         20,21,22,23,24,25,26,27,28,29,
    //     //         30,31,32,33,34,35,36,37,38,39,
    //     //         40,41,42,43,44,45,46,47,48,49,
    //     //         50,51,52,53,54,55,56,57,58,59,
    //     //         60,61,62,63,64,65,66,67,68,69,
    //     //         70,71,72,73,74,75,76,77,78,79,
    //     //         80,81,82,83,84,85,86,87,88,89,
    //     //         90,91,92,93,94,95,96,97,98,99};   
    //     #80// when en down, input
    //     addr = 6'd0;
    //     forever
    //     #20
    //     addr = addr + 6'd1;
    //     read = 1;
    // end   
    always @(posedge clk) begin
        if(en) n <= 0;
        else n <= n + 1;
    end

    always @(posedge clk) begin
        if(n == 0) begin #5; addr <= 6'd14;end
        else if(n == 7) begin #5; addr <= 6'd55;end
        else if(n == 12) begin #5; addr <= 6'd7;end
        else if(n == 19) begin #5; addr <= 6'd52;end
        else if(n == 24) begin #5; addr <= 6'd0;end
        else if(n == 31) begin #5; addr <= 6'd49;end
        else if(n == 36) begin #5; addr <= 6'd21;end
        else if(n == 45) begin #5; addr <= 6'd28;end
        else if(n == 54) begin #5; addr <= 6'd35;end
        else if(n == 63) begin #5; addr <= 6'd42;end
        else begin #5; addr = addr + 6'd1;end
    end

        //dump fsdb
    initial begin
        $fsdbDumpfile("conv.fsdb");
        $fsdbDumpvars(0,conv_top_test);
        $fsdbDumpon;
	    $fsdbDumpMDA();
        end  
    
    endmodule 
