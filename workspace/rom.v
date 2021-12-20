//深度为8，位宽为16, 7*7+3*3 = 58
module rom_test(clk,addr,cs_en,dout);
parameter DATA_WIDTH=16;		//数据位宽
parameter ADDR_WIDTH=6;		//地址位宽
parameter ADDR_START=0;		//地址起始
parameter ADDR_END  =64;	//地址尾
parameter FILE_NAME="data.mif";		//文件名

  input		clk,rst,read;
  input		[5:0]addr;//地址线 log2(58)
  output	[15:0]dout;//读出的数据

  reg		[15:0] dout;
  reg		[15:0] rom[64:0];
    
//   initial begin
//     rom[0] = 8'b0000_0000;
//     rom[1] = 8'b0000_0001;
//     rom[2] = 8'b0000_0010;
//     rom[3] = 8'b0000_0011;
//     rom[4] = 8'b0000_0100;
//     rom[5] = 8'b0000_0101;
//     rom[6] = 8'b0000_0110;
//     rom[7] = 8'b0000_0111;       
//   end

// //read txt
// integer fp;
// integer i;
// integer n;

// initial begin
// 	fp=$fopen(FILE_NAME,"r");
// 	i=ADDR_START;
// 	while(!($feof(fp)) && i<=ADDR_END) begin
// 		n=$fscanf(fp,"%x",rom[i]);
// 		i=i+1;
// 	end
// 	$fclose(fp);
// end

initial begin  
        $readmemh ("FILE_NAME",rom);  
    end 
  
  always@(posedge clk) begin
    if(rst)    dout <= 0;
    else if(!read)	 dout <= 16'bzzzz_zzzz;
    else		 dout <= rom[addr]; 
  end
endmodule
