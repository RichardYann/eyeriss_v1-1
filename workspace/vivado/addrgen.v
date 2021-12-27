//附加的模块，可以暂时先不设计
module addrgen
  (
    input                      clk,rst,en,
    input                   ENCODE,
    input            [2:0]     LEN,//Length of data series read $clog2(ADDR_WIDTH)
    output [8-1:0]    ADDR,//
    output                     ADD_VALID //Enable read signal of ROM
  );

//counter
always @(posedge clk) begin:counter
    if(rst) 
        counter <= 0;
    else if(en)
        counter <= counter + 1;
end
endmodule 