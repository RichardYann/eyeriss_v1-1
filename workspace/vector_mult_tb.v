//12.15 如何控制加法的溢出问题
`timescale 1ns / 1ps
module vector_mult_tb();
    reg  [15:0] A0,A1,A2;
    reg  [15:0] B0,B1,B2;
    wire [15:0] RES;
vector_mult vector_mult_test
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

        A0 = 16'b0_000_0011_0000_0000;//768
        B0 = 16'b0_000_0011_0000_0000;//768
        // A0*B0 = 0000_0000_1001_0000
        A1 = 16'b0_000_0011_0000_0000;//
        B1 = 16'b1_000_0011_0000_0000;//
        // A1*B1 = 1000_0000_1001_0000;
        // 2's com:1111_1111_0110_0001;
        // actual:1111_1111_0111_0000;
        A2 = 16'b1_000_0011_0000_0000;
        B2 = 16'b0_000_0011_0000_0000;

    //expected RES = 1111_1111_0110_0001;

        #1000;
        $finish;
    end    
        //dump fsdb
    initial begin
        $fsdbDumpfile("vector_mult.fsdb");
        $fsdbDumpvars(0,vector_mult_test);
        $fsdbDumpon;
	    $fsdbDumpMDA();
        end  
    
    endmodule 
