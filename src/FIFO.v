`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/10 15:28:41
// Design Name: 
// Module Name: FIFO
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Synchronous FIFO using RAM2P_WF_RO 
// Problem to solve: Write-and-read to the same addr or we&&(next_head==tail)
module FIFOsync_ram
  #(
    parameter INWIDTH = 17, 
              DEPTH = 325
  )
  (
    input                CLK  ,
    input                RESET,
    input                EN   ,
    input  [INWIDTH-1:0] DI   ,
    input                WRITE,
    output [INWIDTH-1:0] DO   ,
    input                READ ,
    output               FULL ,
    output               EMPTY,
    output               LAST  
  );
  localparam CNT_WIDTH = $clog2(DEPTH+1);
  localparam MAX_COUNT = DEPTH-1;
  localparam PTR_WIDTH = $clog2(DEPTH);

  wire [INWIDTH-1:0]   do_head, do_tail;
  wire                 fiforam_we;
  reg                  fifo_empty_n;
  reg                  fifo_last;
  reg                  get_read_through_dout;
  reg  [CNT_WIDTH-1:0] count, next_count;
  reg  [PTR_WIDTH-1:0] head, tail, next_head; // Wide enough to hold (DEPTH-1) is ok
  integer i;
  

  assign fiforam_we = (!RESET && WRITE && !FULL && EN);

  always @(posedge CLK) begin : update_tail
    if (RESET)
      tail <= 0;
    else if (EN && WRITE && !FULL)
      if (tail != MAX_COUNT)
        tail <= tail + 1;
      else
        tail <= 0;
  end

  always @(posedge CLK) begin : read_from_head
    if (RESET)
      head <= 0;
    else if (EN)
      head <= next_head;
  end

  always @* begin
    next_head = head;
    if (READ && (fifo_empty_n == 1'b1)) begin
      if (head != MAX_COUNT)
        next_head = head + 1;
      else
        next_head = 0;
    end
  end

  always @(posedge CLK) begin
    if (RESET)
      count <= 0;
    else if (EN) begin
      count <= next_count;
    end
  end

  always @(count or READ or WRITE) begin
    next_count = count;
    case ({READ, WRITE}) 
      2'b00 : next_count = count;
      2'b01 :
        if (count != DEPTH)
          next_count = count + 1;
      2'b10 :
        if (count != 0)
          next_count = count - 1;
      2'b11 :
        if (count == DEPTH) // Can't write, but read success
          next_count = count - 1;
        else if (count == 0) // Can't read, but write success
          next_count = count + 1;
        else // Both read and write okay
          next_count = count;
    endcase
  end
  
  always @(posedge CLK) begin : status_flags
    if (RESET) begin
      get_read_through_dout <= 0;
      fifo_empty_n <= 0;
    end
    else if (EN) begin
      get_read_through_dout <= (fiforam_we && (next_head == tail));
      fifo_empty_n <= !(next_count == 0);
    end
  end

  always @(*) begin
    fifo_last = (count != 0) && (next_count == 0);
  end

  assign DO = get_read_through_dout ? (do_tail) : (do_head);
  assign FULL = (count == DEPTH);
  assign EMPTY = (fifo_empty_n == 1'b0);
  assign LAST = fifo_last;
  
  RAM2P_WF_RO #(.DATA_WIDTH(INWIDTH), .ADDR_WIDTH(PTR_WIDTH)) U_fiforam (
    .CLK(CLK), .EN(EN), .RESET(RESET),
    .ADDR1(tail), .WE(fiforam_we), // write to tail
    .ADDR2(next_head), // read from head, or next_head to be precise
    .DI(DI),
    .DO1(do_tail),
    .DO2(do_head)
  );
endmodule

// Synchronous FIFO
module FIFOsync 
  #(
    parameter INWIDTH = 17, 
              DEPTH = 325
  )
  (
    input  CLK,
    input  RESET,
    input  EN,
    input  [INWIDTH-1:0] DI,
    input                WRITE,
    output [INWIDTH-1:0] DO,
    input                READ,
    output               FULL,
    output               EMPTY
  );
  localparam CNT_WIDTH = $clog2(DEPTH+1);
  localparam MAX_COUNT = DEPTH-1;
  localparam PTR_WIDTH = $clog2(MAX_COUNT+1);

  reg  [INWIDTH-1:0]   data [0:MAX_COUNT];
  reg  [INWIDTH-1:0]   dout;
  reg                  fifo_full, fifo_empty;
  reg  [CNT_WIDTH-1:0] count, next_count;
  reg  [PTR_WIDTH-1:0] head, tail, next_head; // Wide enough to hold (DEPTH-1) is ok
  integer i;
  

  always @(posedge CLK) begin : output_register
    if (RESET) begin
      dout <= 0;
    end
    else if (EN) begin
      if ((!RESET && WRITE && !FULL) && (next_head == tail)) // It is going to write, read-through
        dout <= DI;
      else 
        dout <= data[next_head];
      // dout <= ((!RESET && WRITE && !FULL) && (next_head == tail)) ? DI : data[next_head];
    end
  end

  always @(posedge CLK) begin : write_to_tail
    if (!RESET && WRITE && !FULL && EN)
      data[tail] <= DI;
  end

  initial begin
    for (i = 0; i < DEPTH; i = i + 1) begin
      data[i] <= 0; // Mainly to avoid x's in simulation
    end
  end

  always @(posedge CLK) begin : update_tail
    if (RESET)
      tail <= 0;
    else if (EN && WRITE && !FULL)
      if (tail != MAX_COUNT)
        tail <= tail + 1;
      else
        tail <= 0;
  end

  always @(posedge CLK) begin : read_from_head
    if (RESET)
      head <= 0;
    else if (EN)
      head <= next_head;
    // else if (EN && READ && !fifo_empty)
    //   if (head != MAX_COUNT)
    //     head <= head + 1;
    //   else
    //     head <= 0;
  end

  always @* begin
    next_head = head;
    if (READ && !fifo_empty) begin
      if (head != MAX_COUNT)
        next_head = head + 1;
      else
        next_head = 0;
    end
  end

  always @(posedge CLK) begin
    if (RESET)
      count <= 0;
    else if (EN) begin
      count <= next_count;
    end
  end

  always @(count or READ or WRITE) begin
    next_count = count;
    case ({READ, WRITE}) 
      2'b00 : next_count = count;
      2'b01 :
        if (count != DEPTH)
          next_count = count + 1;
      2'b10 :
        if (count != 0)
          next_count = count - 1;
      2'b11 :
        if (count == DEPTH) // Can't write, but read success
          next_count = count - 1;
        else if (count == 0) // Can't read, but write success
          next_count = count + 1;
        else // Both read and write okay
          next_count = count;
    endcase
  end
  
  always @(posedge CLK) begin : status_flags
    if (RESET) begin
      fifo_empty <= 1;
      fifo_full <= 0;
    end
    else if (EN) begin
      fifo_empty <= (next_count == 0); // or (count == 0) ??
      fifo_full <= (next_count == DEPTH);
    end
  end

  assign DO = dout;
  assign FULL = fifo_full;
  assign EMPTY = fifo_empty;
endmodule

// FIFO with parallel input
// Note: Result will not show up on DO until at least 1 clock cycle after
//       WRITE is valid (always check EMPTY flag).
//       It's recommended to read after WRITING.
//       Do NOT write when WRITING, it will cause loss of data.
module FIFOpi 
  #(
    parameter INWIDTH = 16,
              INDEPTH = 9, // Number of parallel inputs
              DEPTH = INDEPTH * 2 + 1
  ) (
    input CLK,
    input RESET,
    input EN,
    input [INWIDTH*INDEPTH-1:0] DI,
    input                       WRITE,
    output                      WRITING, // Writing parallel inputs to the FIFO
    output [INWIDTH-1:0]        DO,
    input                       READ,
    output                      EMPTY,
    output                      FULL
  );
  reg  [INWIDTH-1:0] ishreg [0:INDEPTH-1];
  wire [INWIDTH-1:0] fifo_di;
  reg  [INDEPTH-1:0] iflag;
  reg  [$clog2(INDEPTH+1)-1:0] sr_addr;
  genvar i;
  
  wire fifo_write;

  generate
    for (i = 0; i < INDEPTH; i = i + 1) begin : shift_reg
      always @(posedge CLK) begin
        if (RESET == 1'b1) begin
          ishreg[i] <= {INWIDTH{1'b0}};
        end
        else if (EN) begin
          if (WRITE) begin
            ishreg[i] <= DI[INWIDTH*(i+1)-1:INWIDTH*i];
          end
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < INDEPTH; i = i + 1) begin : flags
      always @(posedge CLK) begin
        if (RESET == 1'b1) begin
          iflag[i] <= 1'b0;
        end
        else if (EN) begin
          if (WRITE)
            iflag[i] <= 1'b1;
          else if (sr_addr == i && !FULL) 
            iflag[i] <= 1'b0;
        end
      end
    end
  endgenerate

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      sr_addr <= 0;
    end
    else if (EN) begin
      if (WRITE)
        sr_addr <= 0;
      else if (WRITING && !FULL)
        if (sr_addr < (INDEPTH-1)) sr_addr <= sr_addr + 1;
        else sr_addr <= 0;
    end
  end
  
  assign fifo_di = ishreg[sr_addr];
  assign fifo_write = iflag[sr_addr];
  
  FIFOsync_ram #(.INWIDTH(INWIDTH), .DEPTH(DEPTH)) U_fifo (
    .CLK(CLK), .RESET(RESET), .EN(EN),
    .DI(fifo_di),
    .WRITE(fifo_write),
    .DO(DO),
    .READ(READ),
    .EMPTY(EMPTY),
    .FULL(FULL)
  );

  assign WRITING = |iflag;
endmodule
