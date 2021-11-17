`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/21 11:31:34
// Design Name: 
// Module Name: AddrGenPool
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
//   Assuming input feature maps are stored in 1d array in row-major order.
//////////////////////////////////////////////////////////////////////////////////


module AddrGenPool
  #(
    parameter ADDR_WIDTH = 12,
              HEIGHT_WIDTH = 7,
              KERSIZE_WIDTH = 5
  )
  (
    input                      CLK,
    input                      RESET,
    input                      EN,
    input  [HEIGHT_WIDTH-1:0]  H, // Height of input feature map
    input  [HEIGHT_WIDTH-1:0]  W, // Width of input feature map
    input  [KERSIZE_WIDTH-1:0] K, // Kernel height (pooling kernel)
    input  [KERSIZE_WIDTH-1:0] L, // Kernel width (pooling kernel)
    input                      START, // Start address generation
    output                     BIAS_VALID, // Vaild flag of BIAS and its other flags (esp. BIAS_PACK)
    output [ADDR_WIDTH-1:0]    BIAS,       // The bias address
    output                     BIAS_PACK,  // Flag of the last address of a pooling window
    output                     BIAS_LAST   // Flag of the last address
  );
  localparam [1:0]  IDLE = 2'b00,
                    LOAD = 2'b01,
                    GEN  = 2'b11,
                    LAST = 2'b10;

  reg  [HEIGHT_WIDTH-1:0]  ifmh, ifmw, h_counter, w_counter, h_d;
  reg  [KERSIZE_WIDTH-1:0] kerh, kerw, i_counter, j_counter, i_d;
  reg  [HEIGHT_WIDTH:0]    w_plus_j;
  reg  [1:0]               Sreg, Snext; // State register and next state logic
  // (* use_dsp = "yes" *)
  reg  [ADDR_WIDTH-1:0]    addr;        // The address
  
  wire [HEIGHT_WIDTH*2+1:0] addr_full; // full-width addr

  reg last, valid, window_last; // Register of flags
  reg all_wrap_d, ij_wrap; 
  
  // Wrap conditions for each counter
  wire h_wrap = ((h_counter + kerh*2) > ifmh); // Multiply 2 to avoid out-of-range
  wire w_wrap = ((w_counter + kerw*2) > ifmw);
  wire i_wrap = ((i_counter + 1) >= kerh);
  wire j_wrap = ((j_counter + 1) >= kerw);

  wire in_gen = ((Snext == GEN) || (Snext == LAST)); // In address generation process

  always @(posedge CLK) begin : cache_HWKL
    if (RESET == 1'b1) begin
      ifmh <= 0;
      ifmw <= 0;
      kerh <= 0;
      kerw <= 0;
    end
    else if (EN && (Sreg == IDLE) && START) begin
      ifmh <= H;
      ifmw <= W;
      kerh <= K;
      kerw <= L;
    end
  end

  always @(posedge CLK) begin : state_transition
    if (RESET == 1'b1) Sreg <= 0;
    else if (EN) Sreg <= Snext;
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      all_wrap_d <= 0;
    end
    else if (EN) begin
      all_wrap_d <= h_wrap && w_wrap && i_wrap && j_wrap;
    end
  end

  always @(*) begin : next_state_logic
    case (Sreg)
      IDLE: if (START) Snext = LOAD;
            else Snext = IDLE;
      LOAD: if ((ifmh != 0) && (ifmw != 0) && (kerh != 0) && (kerw != 0)) 
              Snext = GEN;
            else 
              Snext = IDLE;
      GEN : if (all_wrap_d) Snext = LAST;
            else Snext = GEN;
      LAST: Snext = IDLE;
      default: Snext = IDLE;
    endcase
  end


  always @(posedge CLK) begin : addr_gen_variables
    if (RESET == 1'b1) begin
      i_counter <= 0;
      j_counter <= 0;
      h_counter <= 0;
      w_counter <= 0;
    end
    else if (EN) begin
      if (in_gen) begin
        if (!j_wrap) 
          j_counter <= j_counter + 1;
        else 
          j_counter <= 0;
        
        if (j_wrap)
          if (!i_wrap) i_counter <= i_counter + 1;
          else i_counter <= 0;
        else
          i_counter <= i_counter;
        
        if (i_wrap && j_wrap)
          if (!w_wrap) w_counter <= w_counter + kerw;
          else w_counter <= 0;
        else
          w_counter <= w_counter;

        if (w_wrap && i_wrap && j_wrap)
          if (!h_wrap) h_counter <= h_counter + kerh;
          else h_counter <= 0;
        else
          h_counter <= h_counter;
      end
      else begin
        j_counter <= 0;
        i_counter <= 0;
        w_counter <= 0;
        h_counter <= 0;
      end
    end
  end

  always @(posedge CLK) begin : addr_generation
    if (RESET == 1'b1) begin
      addr <= 0;
      h_d <= 0;
      i_d <= 0;
      w_plus_j <= 0;
    end
    else if (EN && in_gen) begin
      h_d <= h_counter;
      i_d <= i_counter;
      w_plus_j <= w_counter + j_counter;
      addr <= (h_d + i_d) * ifmw + w_plus_j; // height is consistent during the process
    end
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) 
      last <= 0;
    else if (EN) 
      last <= (Snext == LAST);
  end
  
  always @(posedge CLK) begin
    if (RESET == 1'b1) 
      valid <= 0;
    else if (EN) 
      valid <= (Sreg == GEN);
  end

  always @(posedge CLK) begin
    if (RESET == 1'b1) begin
      ij_wrap <= 0;
      window_last <= 0;
    end
    else if (EN) begin
      ij_wrap <= i_wrap && j_wrap;
      window_last <= ij_wrap;
    end
  end

  assign BIAS = addr;
  assign BIAS_LAST = last;
  assign BIAS_VALID = valid;
  assign BIAS_PACK = window_last;
endmodule
