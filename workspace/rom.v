//深度为8，位宽为16, 7*7+3*3 = 58
module rom(clk,rst,addr,read,dout);

// parameter FILE_NAME="data.mif";		//文件名
  input		clk,rst,read;
  input		[5:0]addr;//地址线 log2(58)
  output	[15:0]dout;//读出的数据

  wire		[15:0] dout;
  reg   [15:0] rom;
  // reg		[15:0] rom[0:63];

// initial begin  
//         rom = {16'h0000,16'h0000,16'h0070,16'h0757,16'h0F1F,16'h1000,16'h0FDF,
//                16'h01A1,16'h0AAA,16'h0BBB,16'h0FCF,16'h0FCF,16'h0FDF,16'h0FCF,
//                16'h0C8C,16'h0FDF,16'h0FCF,16'h0FCF,16'h0D6D,16'h0A8A,16'h0A8A,
//                16'h0E1E,16'h0FDF,16'h0FCF,16'h0FCF,16'h0282,16'h0000,16'h0000,
//                16'h0E2E,16'h1000,16'h0FDF,16'h0A8A,16'h0000,16'h0000,16'h0000,
//                16'h0969,16'h0FDF,16'h0FCF,16'h0A8A,16'h0000,16'h0000,16'h0000,
//                16'h0717,16'h0FDF,16'h0FCF,16'h0A8A,16'h0000,16'h0000,16'h0000,
//                16'hFD01,16'h01CD,16'hFEFC,
//                16'hFFC4,16'hFF30,16'hFDB4,
//                16'hFEDD,16'hFFBC,16'hFCFD,
//                16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000     };
//     end 
always @(posedge clk) begin
        case (addr)
                 0: rom <= 16'h0000;  1: rom <= 16'h0000;  2: rom <= 16'h0070;  3: rom <= 16'h0757;  4: rom <= 16'h0F1F;  5: rom <= 16'h1000;  6: rom <= 16'h0FDF;
                 7: rom <= 16'h01A1;  8: rom <= 16'h0AAA;  9: rom <= 16'h0BBB; 10: rom <= 16'h0FCF; 11: rom <= 16'h0FCF; 12: rom <= 16'h0FDF; 13: rom <= 16'h0FCF;
                14: rom <= 16'h0C8C; 15: rom <= 16'h0FDF; 16: rom <= 16'h0FCF; 17: rom <= 16'h0FCF; 18: rom <= 16'h0D6D; 19: rom <= 16'h0A8A; 20: rom <= 16'h0A8A;
                21: rom <= 16'h0E1E; 22: rom <= 16'h0FDF; 23: rom <= 16'h0FCF; 24: rom <= 16'h0FCF; 25: rom <= 16'h0282; 26: rom <= 16'h0000; 27: rom <= 16'h0000;
                28: rom <= 16'h0E2E; 29: rom <= 16'h1000; 30: rom <= 16'h0FDF; 31: rom <= 16'h0A8A; 32: rom <= 16'h0000; 33: rom <= 16'h0000; 34: rom <= 16'h0000;
                35: rom <= 16'h0969; 36: rom <= 16'h0FDF; 37: rom <= 16'h0FCF; 38: rom <= 16'h0A8A; 39: rom <= 16'h0000; 40: rom <= 16'h0000; 41: rom <= 16'h0000;
                42: rom <= 16'h0717; 43: rom <= 16'h0FDF; 44: rom <= 16'h0FCF; 45: rom <= 16'h0A8A; 46: rom <= 16'h0000; 47: rom <= 16'h0000; 48: rom <= 16'h0000;
                49: rom <= 16'hFD01; 50: rom <= 16'h01CD; 51: rom <= 16'hFEFC;
                52: rom <= 16'hFFC4; 53: rom <= 16'hFF30; 54: rom <= 16'hFDB4;
                55: rom <= 16'hFEDD; 56: rom <= 16'hFFBC; 57: rom <= 16'hFCFD;
          default:  rom <=  16'h0000;
        endcase
end

assign dout = rom;
  // always@(posedge clk) begin
  //   if(rst)           dout <= rom[6];
  //   else if(!read)	  dout <= 16'bzzzz_zzzz_zzzz_zzzz;
  //   else		          dout <= rom[addr]; 
  // end
endmodule