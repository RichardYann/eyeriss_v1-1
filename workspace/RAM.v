//one port ram
module RAM
  #(
    parameter DATA_WIDTH = 16,
              ADDR_WIDTH = 10 // Depth is (2**ADDR_WIDTH) 
  )
  (
    input                   CLK   ,
    input                   RESET ,
    input                   EN    ,
    input                   WE    ,
    input  [ADDR_WIDTH-1:0] ADDR  ,
    input  [DATA_WIDTH-1:0] DIN   ,
    output [DATA_WIDTH-1:0] DOUT   
  );
  localparam DEPTH = 2**ADDR_WIDTH;
  reg [DATA_WIDTH-1:0] content [0:DEPTH-1];
  reg [DATA_WIDTH-1:0] data_out, data_out_d;
  integer i;

  initial begin
    for (i = 0; i < DEPTH; i = i + 1) begin
      content[i] = {DATA_WIDTH{1'b0}};
    end
  end

  always @(posedge CLK) begin
    if (RESET) begin
      data_out <= 0;
      data_out_d <= 0;
    end
    else if (EN) begin
      if (WE) begin
        content[ADDR] <= DIN;
      end
      data_out <= content[ADDR];
      data_out_d <= data_out;
    end
  end

  assign DOUT = data_out_d;
endmodule

