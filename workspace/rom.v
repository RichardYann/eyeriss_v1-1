//深度为8，位宽为16, 7*7+3*3 = 58
module rom(clk,rst,addr,read,dout);

// parameter FILE_NAME="data.mif";		//文件名
  input		clk,rst,read;
  input		[5:0]addr;//地址线 log2(58)
  output	[15:0]dout;//读出的数据

  reg		[15:0] dout;
  reg		[15:0] rom[0:63];

initial begin  
        rom = {16'h0000,16'h0000,16'h0070,16'h0757,16'h0F1F,16'h1000,16'h0FDF,
               16'h01A1,16'h0AAA,16'h0BBB,16'h0FCF,16'h0FCF,16'h0FDF,16'h0FCF,
               16'h0C8C,16'h0FDF,16'h0FCF,16'h0FCF,16'h0D6D,16'h0A8A,16'h0A8A,
               16'h0E1E,16'h0FDF,16'h0FCF,16'h0FCF,16'h0282,16'h0000,16'h0000,
               16'h0E2E,16'h1000,16'h0FDF,16'h0A8A,16'h0000,16'h0000,16'h0000,
               16'h0969,16'h0FDF,16'h0FCF,16'h0A8A,16'h0000,16'h0000,16'h0000,
               16'h0717,16'h0FDF,16'h0FCF,16'h0A8A,16'h0000,16'h0000,16'h0000,
               16'hFD01,16'h01CD,16'hFEFC,
               16'hFFC4,16'hFF30,16'hFDB4,
               16'hFEDD,16'hFFBC,16'hFCFD,
               16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000     };
    end 
  reg [15:0] d_test;
  always@(posedge clk) begin
    d_test <= rom[addr];
    if(rst)           dout <= rom[6];
    else if(!read)	  dout <= 16'bzzzz_zzzz_zzzz_zzzz;
    else		          dout <= rom[addr]; 
  end
endmodule