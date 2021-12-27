
module rom_tb();
reg clk,rst,read;
reg [5:0] ADDR;
wire[15:0]dout;
reg[6:0]n;
reg en;
rom rom_test
    (
       .clk(clk),
       .rst(rst),
       .read(read),
       .addr(ADDR),
       .dout(dout)
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
        #3;
        rst = 1;
        #30
        rst = 0;
        #1000;
        $finish;
    end   

        initial begin
        #50
        en = 1;
        #20
        en = 0;
    end   
    initial begin

        read = 1;
    end    

    always @(posedge clk) begin
        if(en) n <= 0;
        else n <= n + 1;
    end
    //add 5 delay to avoid conflict when addr and clk pull high in the same time.
    always @(posedge clk) begin
        if(n == 0) begin #5; ADDR <= 6'd0;end
        else if(n == 7) begin #5; ADDR <= 6'd55;end
        else if(n == 12) begin #5; ADDR <= 6'd7;end
        else if(n == 19) begin #5; ADDR <= 6'd52;end
        else if(n == 24) begin #5; ADDR <= 6'd0;end
        else if(n == 31) begin #5; ADDR <= 6'd49;end
        else if(n == 36) begin #5; ADDR <= 6'd21;end
        else if(n == 45) begin #5; ADDR <= 6'd28;end
        else if(n == 54) begin #5; ADDR <= 6'd35;end
        else if(n == 63) begin #5; ADDR <= 6'd42;end
        else begin #5; ADDR = ADDR + 6'd1;end
    end
        //dump fsdb
    initial begin
        $fsdbDumpfile("rom.fsdb");
        $fsdbDumpvars(0,rom_test);
        $fsdbDumpon;
	    $fsdbDumpMDA();
        end  
    
    endmodule 
