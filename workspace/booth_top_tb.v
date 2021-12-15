`timescale 1ns / 1ps
module booth_top_tb();
    reg  [15:0] A;
    reg  [15:0] B;
    wire [31:0] P;
booth_top booth_top_test(
       .A(A),
       .B(B),
       .P(P)
    );
    initial begin
	//test situation without overflow, int part < 8
	//unsigned by unsigned
        A = 16'b0_011_0011_0000_0000;//13056 ||	3.1875
        B = 16'b0_010_0011_0000_0000;//8960  ||	2.1875
	//expected P = 00_00_0_110_1111_1001_0000_0000_0000_0000

	//unsigned by signed
        #100;
        A = 16'b0_011_0011_0000_0000;//
        B = 16'b1_010_0011_0000_0000;//
    //or       P = xx_xx_1_001_0000_0111_0000_0000_0000_0000

	//signed by unsigned
	#100;
	A = 16'b1_011_0011_0000_0000;
	B = 16'b0_010_0011_0000_0000;
    //or       P = xx_xx_1_001_0000_0111_0000_0000_0000_0000

	//signed by signed    
	#100;	
        A = 16'b1_011_0011_0000_0000;//
        B = 16'b1_010_0011_0000_0000;//
	//expected P = 00_00_0_110_1111_1001_0000_0000_0000_0000
    
        #1000;
        $finish;
    end    
        //dump fsdb
    initial begin
        $fsdbDumpfile("booth_top.fsdb");
        $fsdbDumpvars(0,booth_top_test);
        $fsdbDumpon;
	    $fsdbDumpMDA();
        end  
    
    endmodule 
