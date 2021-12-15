`timescale 1ns / 1ns
module booth_time_tb();
    reg  [15:0] multiplicand;
    reg  [15:0] multiplier;
    wire [31:0] mul_out;
    reg clk,rstn,vld_in;
    wire done;
booth_time booth_time_test(
       .clk(clk),
       .rstn(rstn),
       .vld_in(vld_in),
       .multiplicand(multiplicand),
       .multiplier(multiplier),
       .mul_out(mul_out),
       .done(done)
    );
        //clk
        initial begin 
            clk = 0;
            vld_in = 1;
            forever
            #50;
            clk = ~clk;
        end
            
        //RESET
        initial begin
            rstn = 1;
            #3;
            rstn = 0;
            #100
            rstn = 1;
        end  
    initial begin
	//test situation without overflow, int part < 8
	//unsigned by unsigned
        multiplicand = 16'b0_011_0011_0000_0000;//13056 ||	3.1875
        multiplier = 16'b0_010_0011_0000_0000;//8960  ||	2.1875
	//expected P = 00_00_0_110_1111_1001_0000_0000_0000_0000

	//unsigned by signed
        #1000;
        multiplicand = 16'b0_011_0011_0000_0000;//
        multiplier = 16'b1_010_0011_0000_0000;//
    //or       P = xx_xx_1_001_0000_0111_0000_0000_0000_0000

	//signed by unsigned
	#1000;
	multiplicand = 16'b1_011_0011_0000_0000;
	multiplier = 16'b0_010_0011_0000_0000;
    //or       P = xx_xx_1_001_0000_0111_0000_0000_0000_0000

	//signed by signed    
	#1000;	
        multiplicand = 16'b1_011_0011_0000_0000;//
        multiplier = 16'b1_010_0011_0000_0000;//
	//expected P = 00_00_0_110_1111_1001_0000_0000_0000_0000
    
        #10000;
        $finish;
    end    
        //dump fsdb
    initial begin
        $fsdbDumpfile("booth_time.fsdb");
        $fsdbDumpvars(0,booth_time_test);
        $fsdbDumpon;
	    $fsdbDumpMDA();
        end  
    
endmodule 
