`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/22 16:55:58
// Design Name: 
// Module Name: nntop_ctrl
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

`include "nn_microops.v"

module NNTopCtrl
  #(
    parameter NUM_CHANNELS = 15, // Currently not designed for values other than 15
              GLB_ADDR_WIDTH = 16,
              HEIGHT_WIDTH = 5
  )
  (
    input  clk  ,
    input  reset,
    input  en   ,
    
    // NNTop's outer i/f 
    output din_ready    ,
    input  din_valid    ,
    input  din_param    ,
    
    // Global buffer
    output                      ram_glb_we   ,
    output [GLB_ADDR_WIDTH-1:0] ram_glb_addr1,
    output [GLB_ADDR_WIDTH-1:0] ram_glb_addr2,

    // Instruction FIFO
    input   [30:0]  inst_in       ,
    output          instfifo_write,
    output          instfifo_read ,
    input           instfifo_empty,
    input           instfifo_full ,

    // Data (input) FIFO
    output datafifo_write ,
    output datafifo_read  ,
    input  datafifo_empty ,
    input  datafifo_full  ,

    // Write-back FIFO
    output  wbfifo_write  ,
    output  wbfifo_read   ,
    input   wbfifo_empty  ,
    input   wbfifo_full   ,

    // ConvCore
    output cc_din0_valid,
    output cc_din1_valid,
    output cc_sum_en    ,
    input  cc_dout_valid,
    
    // PoolingAvg
    output [1:0]  poolavg_plty      ,
    output        poolavg_start     ,
    output        poolavg_din_valid ,
    input         poolavg_din_ready ,
    input         poolavg_dout_valid,
    output        poolavg_dout_ready,
    
    // Dense
    output dense_din_valid  ,
    output dense_win_valid  ,
    output dense_dout_ready ,
    input  dense_dout_valid ,

    // AddLayer
    output [HEIGHT_WIDTH-1:0] addlayer_height     ,
    output [HEIGHT_WIDTH-1:0] addlayer_width      ,
    output                    addlayer_start      ,
    input                     addlayer_din_ready  ,
    output                    addlayer_din_valid  ,
    output                    addlayer_dout_ready ,
    input                     addlayer_dout_valid ,
    
    // FMAp
    input  fmap_dout_valid,
    output fmap_a_we      ,
    output fmap_b_we      ,
    output fmap_c_we      ,
    output fmap_d_we      ,
    output fmap_din_valid ,

    // ReLU
    output relu_xin_valid ,
    input  relu_yout_valid,

    // Output FIFO
    output ofifo_write,

    // In-module control
    output [0:0] din_sel  ,
    output [1:0] glb_sel  ,
    output [0:0] relu_sel ,
    output [2:0] smob_sel  
  );
  /******** Definitions ********/
  // Main state machine states
  parameter INST_FETCH  = 3'b000,
            DECODE1     = 3'b001, // Determine has_x
            DECODE2     = 3'b011, // Write configuration registers
            GLB_ACCESS  = 3'b010, // Feed data into submodule
            EXECUTION   = 3'b110, // Wait for data output
            WRITEBACK   = 3'b111; // Write data from wbfifo or ififo back to GLB

  // Main state machine
  reg   [2:0] Sreg, Snext;
  reg         has_ga; // need to access GLB
  reg         has_exec, has_wb;
  wire        done_ga, done_exec, done_wb;

  // GLB access counter
  reg   [GLB_ADDR_WIDTH-1:0]  ga_counter  ;
  reg   [GLB_ADDR_WIDTH-1:0]  ga_maxcount ;
  wire                        ga_wrap     ;
  reg                         gacnt_next  ;

  wire  ififo_write     ;
  wire  ififo_rdtf      ; // instfifo read transfer
  wire  dfifo_write     ;
  reg   ififo_read      ;
  reg   wfifo_write     ;

  // Module status indicator
  reg   busy;
  reg   backwriting;

  // Main machine sub-machine transations
  reg   [5:0] submod_en       ; // One-hot encoded sub-module enable
  wire        submod_ctrl_en  ;
  wire        submod_conv_en  ;
  wire        submod_pool_en  ;
  wire        submod_dense_en ;
  wire        submod_addl_en  ;
  wire        submod_fmar_en  ;

  // Sel signal registers
  reg   [0:0] din_sel_reg ;
  reg   [1:0] glb_sel_reg ;
  reg   [0:0] relu_sel_reg;
  reg   [2:0] smob_sel_reg;

  // Instruction register and bits
  reg   [30 :0] inst_reg;
  wire  [2  :0] inst_submod;
  wire  [3  :0] inst_opcode;
  wire  [5  :0] inst_config;
  wire  [15 :0] inst_baseaddr;

  // Configuration registers
  reg   [HEIGHT_WIDTH-1 :0] addl_h, addl_w;
  reg   [1:0]               pool_plty;
  wire                      is_addl_setx;
  reg   [3:0]               fma_we;
  wire                      is_ctrl_setsel;
  reg                       ofifo_write_enable;

  // Output FIFO
  reg   smob_dout_valid;

  /******** Logic ********/
  assign dfifo_write = din_param;
  assign ififo_write = !din_param;

  always @(posedge clk) begin
    if (reset) 
      Sreg <= INST_FETCH;
    else if (en)
      Sreg <= Snext;
  end

  assign ififo_rdtf = instfifo_read && !instfifo_empty;
  always @(*) begin
    case (Sreg)
      INST_FETCH  : 
        if (ififo_rdtf)  
          Snext = DECODE1;
        else
          Snext = INST_FETCH;
      DECODE1     : Snext = DECODE2;
      DECODE2     :
        casez({has_ga, has_exec, has_wb})
          3'b1??: Snext = GLB_ACCESS;
          3'b01?: Snext = EXECUTION;
          3'b001: Snext = WRITEBACK;
          default Snext = INST_FETCH;
        endcase
      GLB_ACCESS  :
        if (!done_ga)
          Snext = GLB_ACCESS;
        else // GLB access done
          if (has_exec) Snext = EXECUTION;
          else if (has_wb) Snext = WRITEBACK;
          else Snext = INST_FETCH;
      EXECUTION   :
        if (!done_exec)
          Snext = EXECUTION;
        else // Done execution
          if (has_wb) Snext = WRITEBACK;
          else Snext = INST_FETCH;
      WRITEBACK   : 
        if (done_wb) Snext = INST_FETCH;
        else Snext = WRITEBACK;      
      default     : Snext = INST_FETCH;
    endcase
  end

  // Instruction fetch logic
  always @(posedge clk) begin
    if (reset) begin
      inst_reg <= 31'h0000;
    end
    else if (en) begin
      if (ififo_rdtf)
        inst_reg <= inst_in;
    end
  end
  assign inst_baseaddr = inst_reg[NNMICROOPS_BASEADDR_MSB:NNMICROOPS_BASEADDR_LSB];
  assign inst_config = inst_reg[NNMICROOPS_CONFIG_MSB:NNMICROOPS_CONFIG_LSB];
  assign inst_opcode = inst_reg[NNMICROOPS_OPCODE_MSB:NNMICROOPS_OPCODE_LSB];
  assign inst_submod = inst_reg[NNMICROOPS_SUBMOD_MSB:NNMICROOPS_SUBMOD_LSB];

  always @(posedge clk) begin
    if (reset) begin
      ififo_read <= 1'b0;
    end
    else if (en) begin
      if (Sreg == INST_FETCH)
        ififo_read <= 1'b1;
      else if (ififo_rdtf) // TODO: check if this will cause deadlock
        ififo_read <= 1'b0;
    end
  end

  // DECODE1 logic: prepare has_x
  always @(posedge clk) begin
    if (reset)
      has_ga <= 1'b0;
    else if (en) begin
      if (Sreg == DECODE1) begin
        if (inst_submod != NNMICROOPS_SUBMOD_FMAROUND)
          has_ga <= (inst_opcode[3:2] == 2'b00);
        else 
          has_ga <= (inst_opcode[2] == 1'b1);
      end
    end
  end

  always @(posedge clk) begin
    if (reset)
      has_exec <= 1'b0;
    else if (en) begin
      if (Sreg == DECODE1) // Note that configuration is not EXECUTION (config will be done in DECODE2)
        has_exec <= !(inst_opcode[2] == 1'b0);
    end
  end

  always @(posedge clk) begin
    if (reset)
      has_wb <= 1'b0;
    else if (en) begin
      if (Sreg == DECODE1) begin
        if (submod_ctrl_en && inst_opcode == NNMICROOPS_OPCODE_CTRL_WB)
          has_wb <= 1'b1;
        else
          has_wb <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      submod_en <= 6'h00;
    end
    else if (en) begin
      if (Sreg == DECODE1) begin
        case (inst_submod)
          NNMICROOPS_SUBMOD_CTRL    : submod_en <= 6'b000001;
          NNMICROOPS_SUBMOD_CONV    : submod_en <= 6'b000010;
          NNMICROOPS_SUBMOD_POOLAVG : submod_en <= 6'b000100;
          NNMICROOPS_SUBMOD_DENSE   : submod_en <= 6'b001000;
          NNMICROOPS_SUBMOD_ADDLY   : submod_en <= 6'b010000;
          NNMICROOPS_SUBMOD_FMAROUND: submod_en <= 6'b100000;
          default                   : submod_en <= 6'b000000;
        endcase
      end
      else if (Sreg == INST_FETCH)
        submod_en <= 6'b000000;
    end
  end

  // DECODE2 logic: Do the configuration
  always @(posedge clk) begin
    if (reset)
      pool_plty <= 2'b00;
    else if (en) begin
      if (Sreg == DECODE2)
        if (submod_pool_en && inst_opcode[2] == 1'b1)
          pool_plty <= inst_config[1:0];
    end
  end

  assign is_addl_setx = (submod_addly_en) && (inst_opcode[2] == 1'b1);
  always @(posedge clk) begin
    if (reset) begin
      addl_h <= 0;
    end
    else if (en) begin
      if (Sreg == DECODE2 && is_addl_setx && (inst_config[0] == 1'b1))
        addl_h <= inst_baseaddr[4:0];
    end
  end
  always @(posedge clk) begin
    if (reset) begin
      addl_w <= 0;
    end
    else if (en) begin
      if (Sreg == DECODE2 && is_addl_setx && (inst_config[1] == 1'b1))
        addl_w <= inst_baseaddr[9:5];
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      fma_we <= 4'h0;
    end
    else if (en) begin
      if (Sreg == DECODE2 && submod_fmar_en && inst_opcode == NNMICROOPS_OPCODE_SET)
        fma_we <= inst_config[3:0];
    end
  end

  assign is_ctrl_setsel = (submod_ctrl_en && inst_opcode[3:2] == 2'b01);
  always @(posedge clk) begin
    if (reset) begin
      din_sel_reg <= 1'b0;
      glb_sel_reg <= 2'b00;
      relu_sel_reg <= 1'b0;
      smob_sel_reg <= 3'b000;
    end
    else if (en) begin
      if (inst_opcode[1:0] == 2'b00) begin
        din_sel_reg <= inst_config[0:0];
      end
      if (inst_opcode[1:0] == 2'b01) begin
        glb_sel_reg <= inst_config[1:0];
      end
      if (inst_opcode[1:0] == 2'b10) begin
        relu_sel_reg <= inst_config[0:0];
      end
      if (inst_opcode[1:0] == 2'b11) begin
        smob_sel_reg <= inst_config[2:0];
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      ofifo_write_enable <= 1'b0;
    end
    else if (en) begin
      if (Sreg == DECODE2)
        if (submod_ctrl_en && inst_opcode == NNMICROOPS_OPCODE_CTRL_OEN)
          ofifo_write_enable <= 1'b1;
      else if (Sreg == EXECUTION && done_exec) // When execution is done (ofifo_write during EXECUTION) ...
        ofifo_write_enable <= 1'b0; // ... self-reset
    end
  end

  always @(*) begin
    case (smob_sel)
      3'd1: smob_dout_valid = cc_dout_valid       ;
      3'd2: smob_dout_valid = poolavg_dout_valid  ;
      3'd3: smob_dout_valid = dense_dout_valid    ;
      3'd4: smob_dout_valid = addlayer_dout_valid ;
      3'd5: smob_dout_valid = fmap_dout_valid     ;
      3'd6: smob_dout_valid = 1'b1; // Valid constant 0
      default smob_dout_valid = 1'b0; // Non-valid constant 0
    endcase
  end

  // TODO: Trigger some start signal

  // GLB_ACCESS logic: Feed kernels (if any) and ifm


  // EXECUTION logic: Submachines for sub-modules
  //    Each submachine should:
  //    1) Configure sub-modules    (Should complete in DECODE2)
  //    2) Feed kernels (if any)    (Should complete in GLB_ACCESS)
  //    3) Feed input feature maps  (Should complete in GLB_ACCESS)
  //    4) Wait for all the results to output (cannot rely only on valids for 
  //          they are not continous; should reconsider)
  assign submod_ctrl_en = submod_en[NNMICROOPS_SUBMOD_CTRL    ];
  assign submod_conv_en = submod_en[NNMICROOPS_SUBMOD_CONV    ];
  assign submod_pool_en = submod_en[NNMICROOPS_SUBMOD_POOLAVG ];
  assign submod_dense_en = submod_en[NNMICROOPS_SUBMOD_DENSE  ];
  assign submod_addl_en = submod_en[NNMICROOPS_SUBMOD_ADDLY   ];
  assign submod_fmar_en = submod_en[NNMICROOPS_SUBMOD_FMAROUND];

  

  /******** Port connection ********/
  assign din_ready = (!instfifo_empty) && (!datafifo_empty);

  assign ram_glb_we    = ;
  assign ram_glb_addr1 = ;
  assign ram_glb_addr2 = ;

  assign instfifo_write = ififo_write ;
  assign instfifo_read  = ififo_read  ;
  assign datafifo_write = dfifo_write ;
  assign datafifo_read  = ;
  assign wbfifo_write   = wfifo_write ;
  assign wbfifo_read    = ;

  assign cc_din0_valid = ;
  assign cc_din1_valid = ;
  assign cc_sum_en = ;
  
  assign poolavg_plty = pool_plty;
  assign poolavg_start     = ;
  assign poolavg_din_valid = ;
  assign poolavg_dout_ready = ;

  assign dense_din_valid  = ;
  assign dense_win_valid  = ;
  assign dense_dout_ready = ;
  
  assign addlayer_height = addl_h;
  assign addlayer_width  = addl_w;
  assign addlayer_start      = ;
  assign addlayer_din_valid  = ;
  assign addlayer_dout_ready = ;

  assign {fmap_d_we, fmap_c_we, fmap_b_we, fmap_a_we} = fma_we;
  assign fmap_din_valid = ;

  assign relu_xin_valid = smob_dout_valid;

  assign ofifo_write = (ofifo_write_enable) ? relu_yout_valid : 1'b0;

  assign din_sel  = din_sel_reg ;
  assign glb_sel  = glb_sel_reg ;
  assign relu_sel = relu_sel_reg;
  assign smob_sel = smob_sel_reg;
endmodule