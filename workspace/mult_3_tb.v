//12.15 如何控制加法的溢出问题
`timescale 1ns / 1ps
module mult_3_tb();
    reg  [15:0] A;
    reg  [15:0] B;
    wire [15:0] P;
mult_3 mult_3_test
    #(
        parameter INWIDTH = 16
    )
    (
       .A0(A0),
       .A1(A1),
       .A2(A2),
       .B0(B0),
       .B1(B1),
       .B2(B2),
       .RES(RES)
    );
    initial begin
	//test situation without overflow, int part < 8
	//unsigned by unsigned
        A0 = 16'b0_000_0011_0000_0000;//13056 ||	3.1875
        B0 = 16'b0_000_0011_0000_0000;//8960  ||	2.1875
	//expected P = 00_00_0_110_1111_1001_0000_0000_0000_0000
	//unsigned by signed
        A1 = 16'b0_000_0011_0000_0000;//
        B1 = 16'b1_000_0011_0000_0000;//
    //expected P = xx_xx_1_001_0000_0111_0000_0000_0000_0000
	//signed by unsigned
	#100;
        A2 = 16'b1_000_0011_0000_0000;
        B2 = 16'b0_000_0011_0000_0000;
    //expected P = xx_xx_1_001_0000_0111_0000_0000_0000_0000

    //expected RES = xx_xx_1_001_0000_0111_0000_0000_0000_0000
        #1000;
        $finish;
    end    
        //dump fsdb
    initial begin
        $fsdbDumpfile("mult_3.fsdb");
        $fsdbDumpvars(0,mult_3_test);
        $fsdbDumpon;
	    $fsdbDumpMDA();
        end  
    
    endmodule 
