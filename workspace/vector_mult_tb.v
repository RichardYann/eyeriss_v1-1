//12.15 如何控制加法的溢出问题
`timescale 1ns / 1ps
module vector_mult_tb();
    reg  [15:0] A[0:2];
    reg  [15:0] B[0:2];
    wire [15:0] RES;
vector_mult vector_mult_test
    (
       .A(A),
       .B(B),
       .RES(RES)
    );
    initial begin

        A[0] = 16'b0_000_0011_0000_0000;
        B[0] = 16'b0_000_0011_0000_0000;
        // A0*B0 = 0000_0000_1001_0000//0090
        A[1] = 16'b0_000_0011_0000_0000;
        B[1] = 16'b1_000_0011_0000_0000;
        // A1*B1 = 1000_0000_1001_0000;
        // 1's   = 1111_1111_0110_1111;
        // 2's   = 1111_1111_0111_0000;//ff70
        // actual: 1111_1111_0111_0000;//ff70
        A[2] = 16'b1_000_0011_0000_0000;
        B[2] = 16'b0_000_0011_0000_0000;

        //expected RES = 1111_1111_0111_0000;//ff70

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
