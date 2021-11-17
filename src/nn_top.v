`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/15 16:37:37
// Design Name: 
// Module Name: nn_top
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


module NNTop
  #(
    parameter INWIDTH = 16,
              IN_FRAC = 8
  )
  (
    input                       clk       ,
    input                       reset     ,
    input                       en        ,
    input                       din_valid ,
    input         [       31:0] din_data  ,
    output                      din_ready ,
    input                       din_last  , // for AXI-Stream protocol, not used
    output                      dout_valid,
    output signed [INWIDTH-1:0] dout_data ,
    input                       dout_ready,
    output                      dout_last  
  );
  localparam NUM_CHANNELS = 15;
  localparam RAM_GLB_ADDR_WIDTH = 16;
  localparam ADDLAYER_HEIGHT_WIDTH = 5;  // Enough for 25
  
  // FMAp
  reg  signed [INWIDTH-1:0] fmap_ain;
  reg  signed [INWIDTH-1:0] fmap_din;
  reg  signed [INWIDTH-1:0] fmap_bin;
  reg  signed [INWIDTH-1:0] fmap_cin;
  wire fmap_ain_we;
  wire fmap_din_we;
  wire fmap_bin_we;
  wire fmap_cin_we;

  // Output FIFO
  wire ofifo_empty;
  wire ofifo_last;
  wire [INWIDTH-1:0] ofifo_dout;

  // Global buffers bus (params, ifm & psum)
  wire singed [INWIDTH-1:0] glb_data    ;
  wire        [1:0]         glb_sel     ;
  wire        [INWIDTH-1:0] ram_glb_do1 ;
  wire        [INWIDTH-1:0] ram_glb_do2 ;

  // GLB's din's MUX
  wire        [0:0]         glb_din_sel;
  wire signed [INWIDTH-1:0] ram_glb_din;
  

  // Instruction FIFO
  wire [30:0] instfifo_dout ;
  wire        instfifo_write;
  wire        instfifo_full ;
  wire        instfifo_read ;
  wire        instfifo_empty;
  wire        instfifo_last ;

  // Data (input) FIFO
  wire [15:0] datafifo_dout ;
  wire        datafifo_write;
  wire        datafifo_full ;
  wire        datafifo_read ;
  wire        datafifo_empty;
  wire        datafifo_last ;
  
  // Write-back FIFO
  wire [15:0] wbfifo_dout ;
  wire        wbfifo_write;
  wire        wbfifo_full ;
  wire        wbfifo_read ;
  wire        wbfifo_empty;
  wire        wbfifo_last ;

  // Submoduel output data bus (from ConvCore_15C, PoolingAvg, Dense, AddLayer and FRound)
  wire singed [INWIDTH-1:0] smob_data       ;
  wire        [2:0]         smob_sel        ;
  wire singed [INWIDTH-1:0] cc_dout         ;
  wire                      cc_dout_valid   ;
  wire singed [INWIDTH-1:0] poolavg_dout    ;
  wire singed [INWIDTH-1:0] dense_dout      ;
  wire singed [INWIDTH-1:0] addlayer_dout   ;
  wire                      round_dout_valid;
  wire singed [INWIDTH-1:0] round_dout      ;

  // Write-back data bus (select from ReLU's PASSTHRU and Y output)
  wire signed [INWIDTH-1:0] relu_data     ;
  wire        [0:0]         relu_sel      ;
  wire signed [INWIDTH-1:0] relu_passthru ;
  wire signed [INWIDTH-1:0] relu_y        ;
  
  // NNTopCtrl's signals  
  wire                              ctrl_din_ready          ;
  wire                              ctrl_ram_glb_we         ;
  wire  [RAM_GLB_ADDR_WIDTH-1   :0] ctrl_ram_glb_addr1      ;
  wire  [RAM_GLB_ADDR_WIDTH-1   :0] ctrl_ram_glb_addr2      ;
  wire                              ctrl_cc_din0_valid      ;
  wire                              ctrl_cc_din1_valid      ;
  wire                              ctrl_cc_sum_en          ;
  wire  [1                      :0] ctrl_poolavg_plty       ;
  wire                              ctrl_poolavg_start      ;
  wire                              ctrl_poolavg_din_valid  ;
  wire                              ctrl_poolavg_din_ready  ;
  wire                              ctrl_poolavg_dout_valid ;
  wire                              ctrl_poolavg_dout_ready ;
  wire                              ctrl_dense_din_valid    ;
  wire                              ctrl_dense_win_valid    ;
  wire                              ctrl_dense_dout_ready   ;
  wire                              ctrl_dense_dout_valid   ;
  wire  [ADDLAYER_HEIGHT_WIDTH-1:0] ctrl_addlayer_height    ;
  wire  [ADDLAYER_HEIGHT_WIDTH-1:0] ctrl_addlayer_width     ;
  wire                              ctrl_addlayer_start     ;
  wire                              ctrl_addlayer_din_ready ;
  wire                              ctrl_addlayer_din_valid ;
  wire                              ctrl_addlayer_dout_ready;
  wire                              ctrl_addlayer_dout_valid;
  wire                              ctrl_fmap_a_we          ;
  wire                              ctrl_fmap_b_we          ;
  wire                              ctrl_fmap_c_we          ;
  wire                              ctrl_fmap_d_we          ;
  wire                              ctrl_fmap_din_valid     ;
  wire                              ctrl_relu_xin_valid     ;
  wire                              ctrl_relu_yout_valid    ;
  wire                              ctrl_ofifo_write        ;
  wire  [0                      :0] ctrl_din_sel            ;
  wire  [1                      :0] ctrl_glb_sel            ;
  wire  [0                      :0] ctrl_relu_sel           ;
  wire  [2                      :0] ctrl_smob_sel           ;

  FIFOsync_ram #(.INWIDTH(31), .DEPTH(1024)) U_instfifo (
    .CLK  ( clk             ),
    .RESET( reset           ),
    .EN   ( en              ),
    .DI   ( din_data[30:0]  ),
    .WRITE( instfifo_write  ),
    .DO   ( instfifo_dout   ),
    .READ ( instfifo_read   ),
    .FULL ( instfifo_full   ),
    .EMPTY( instfifo_empty  ),
    .LAST ( instfifo_last   ) 
  );
  
  RAM2P_WF_RO #(.DATA_WIDTH(INWIDTH), .ADDR_WIDTH(RAM_GLB_ADDR_WIDTH)) U_ram_ifm (
    .CLK  ( clk                 ),
    .RESET( reset               ),
    .EN   ( en                  ),
    .WE   ( ctrl_ram_glb_we     ),
    .ADDR1( ctrl_ram_glb_addr1  ),
    .ADDR2( ctrl_ram_glb_addr2  ),
    .DI   ( ram_glb_din         ),
    .DO1  ( ram_glb_do1         ),
    .DO2  ( ram_glb_do2         ) 
  );

  FIFOsync_ram #(.INWIDTH(INWIDTH), .DEPTH(2**16)) U_datafifo (
    .CLK  ( clk                   ),
    .RESET( reset                 ),
    .EN   ( en                    ),
    .DI   ( din_data[INWIDTH-1:0] ),
    .WRITE( datafifo_write        ),
    .DO   ( datafifo_dout         ),
    .READ ( datafifo_read         ),
    .FULL ( datafifo_full         ),
    .EMPTY( datafifo_empty        ),
    .LAST ( datafifo_last         ) 
  );
  
  FIFOsync_ram #(.INWIDTH(INWIDTH), .DEPTH(2**16)) U_writebackfifo (
    .CLK  ( clk           ),
    .RESET( reset         ),
    .EN   ( en            ),
    .DI   ( relu_data     ),
    .WRITE( wbfifo_write  ),
    .DO   ( wbfifo_dout   ),
    .READ ( wbfifo_read   ),
    .FULL ( wbfifo_full   ),
    .EMPTY( wbfifo_empty  ),
    .LAST ( wbfifo_last   ) 
  );

  assign glb_din_sel = ctrl_din_sel;
  always @(*) begin
    case (glb_din_sel)
      1'b0: ram_glb_din = $signed(datafifo_dout);
      1'b1: ram_glb_din = $signed(wbfifo_dout);
    endcase
  end
  
  always @(*) begin
    case (glb_sel)
      2'b00: glb_data = 'sh0000;
      2'b01: glb_data = $signed(ram_glb_do1);
      2'b10: glb_data = $signed(ram_glb_do2);
      2'b11: glb_data = $signed({{(INWIDTH-IN_FRAC-1){1'b0}}, 1'b1, {IN_FRAC{1'b0}}}); // Fixed-point "1"
    endcase
  end

  ConvCore_45C #(
    .INWIDTH(INWIDTH),
    .IN_FRAC(IN_FRAC),
    .NUM_CHANNELS(NUM_CHANNELS)
  ) U_convcore_15c (
    .clk       ( clk                ),
    .reset     ( reset              ),
    .en        ( en                 ),
    .din0      ( glb_data           ),
    .din0_valid( ctrl_cc_din0_valid ),
    .din1      ( glb_data           ),
    .din1_valid( ctrl_cc_din1_valid ),
    .sum_en    ( ctrl_cc_sum_en     ),
    .dout      ( cc_dout            ),
    .dout_valid( cc_dout_valid      ) 
  );

  PoolingAvg #(.INWIDTH(INWIDTH), .IN_FRAC(IN_FRAC), .ACC_WIDTH(28)) U_poolavg (
    .CLK      ( clk                     ),
    .RESET    ( reset                   ),
    .EN       ( en                      ),
    .PLTY     ( ctrl_poolavg_plty       ),
    .START    ( ctrl_poolavg_start      ),
    .DIN      ( glb_data                ),
    .DIN_VLD  ( ctrl_poolavg_din_valid  ),
    .DIN_RDY  ( ctrl_poolavg_din_ready  ),
    .DOUT     ( poolavg_dout            ),
    .DOUT_VLD ( ctrl_poolavg_dout_valid ),
    .DOUT_RDY ( ctrl_poolavg_dout_ready ),
    .DOUT_OVFL() 
  );

  Dense #(
    .INWIDTH ( INWIDTH  ),
    .IN_FRAC ( IN_FRAC  ),
    .VIN_LEN ( 45       ),
    .VOUT_LEN( 10       ) 
  ) U_dense (
    .clk       ( clk                    ),
    .reset     ( reset                  ),
    .en        ( en                     ),
    .din       ( glb_data               ),
    .din_valid ( ctrl_dense_din_valid   ),
    .win       ( glb_data               ),
    .win_valid ( ctrl_dense_win_valid   ),
    .dout      ( dense_dout             ),
    .dout_ready( ctrl_dense_dout_ready  ),
    .dout_valid( ctrl_dense_dout_valid  )  
  );

  AddLayer #(
    .INWIDTH(INWIDTH),
    .IN_FRAC(IN_FRAC),
    .HEIGHT_WIDTH(ADDLAYER_HEIGHT_WIDTH)
  ) U_addlayer (
    .CLK      ( clk                       ),
    .RESET    ( reset                     ),
    .EN       ( en                        ),
    .H        ( ctrl_addlayer_height      ),
    .W        ( ctrl_addlayer_width       ),
    .START    ( ctrl_addlayer_start       ),
    .DIN      ( glb_data                  ),
    .DIN_RDY  ( ctrl_addlayer_din_ready   ),
    .DIN_VLD  ( ctrl_addlayer_din_valid   ),
    .DOUT     ( addlayer_dout             ),
    .DOUT_RDY ( ctrl_addlayer_dout_ready  ),
    .DOUT_VLD ( ctrl_addlayer_dout_valid  ),
    .DOUT_OVFL() 
  );

  FMApFRound #(
    .INWIDTH(INWIDTH),
    .IN_FRAC(IN_FRAC) 
  ) U_fmap (
    .clk      ( clk                 ),
    .reset    ( reset               ),
    .en       ( en                  ),
    .a        ( fmap_ain            ),
    .b        ( fmap_bin            ),
    .c        ( fmap_cin            ),
    .d        ( fmap_din            ),
    .din_valid( ctrl_fmap_din_valid ),
    .y        ( round_dout          ),
    .y_valid  ( round_dout_valid    ) 
  );

  always @(posedge clk) 
    if (reset == 1'b1) fmap_ain <= {INWIDTH{1'b0}};
    else if (en && fmap_ain_we) fmap_ain <= glb_data;
  
  always @(posedge clk) 
    if (reset == 1'b1) fmap_din <= {INWIDTH{1'b0}};
    else if (en && fmap_din_we) fmap_din <= glb_data;
  
  always @(posedge clk) 
    if (reset == 1'b1) fmap_bin <= {INWIDTH{1'b0}};
    else if (en && fmap_bin_we) fmap_bin <= glb_data;
  
  always @(posedge clk) 
    if (reset == 1'b1) fmap_cin <= {INWIDTH{1'b0}};
    else if (en && fmap_cin_we) fmap_cin <= glb_data;

  assign fmap_ain_we = ctrl_fmap_a_we;
  assign fmap_bin_we = ctrl_fmap_b_we;
  assign fmap_cin_we = ctrl_fmap_c_we;
  assign fmap_din_we = ctrl_fmap_d_we;

  always @(*) begin
    case (smob_sel)
      3'd1: smob_data = cc_dout       ;
      3'd2: smob_data = poolavg_dout  ;
      3'd3: smob_data = dense_dout    ;
      3'd4: smob_data = addlayer_dout ;
      3'd5: smob_data = round_dout    ;
      3'd6: smob_data = 'sh0000;
      default smob_data = $signed({INWIDTH{1'b0}});
    endcase
  end

  ReLU #(.INWIDTH(INWIDTH)) U_relu (
    .CLK     ( clk                  ),
    .RESET   ( reset                ),
    .EN      ( en                   ),
    .X       ( smob_data            ),
    .X_VLD   ( ctrl_relu_xin_valid  ),
    .Y       ( relu_y               ),
    .Y_VLD   ( ctrl_relu_yout_valid ),
    .PASSTHRU( relu_passthru        ) 
  );

  always @(*) begin
    case (relu_sel)
      1'b0: relu_data = relu_passthru;
      1'b1: relu_data = relu_y;
    endcase
  end

  assign glb_sel  = ctrl_glb_sel ;
  assign relu_sel = ctrl_relu_sel;
  assign smob_sel = ctrl_smob_sel;

  FIFOsync_ram #(.INWIDTH(INWIDTH), .DEPTH(20)) U_ofifo (
    .CLK  ( clk              ),
    .RESET( reset            ),
    .EN   ( en               ),
    .DI   ( relu_data        ),
    .WRITE( ctrl_ofifo_write ),
    .DO   ( ofifo_dout       ),
    .READ ( dout_ready       ),
    .EMPTY( ofifo_empty      ),
    .LAST ( ofifo_last       ),
    .FULL ()
  );

  NNTopCtrl #(
    .NUM_CHANNELS(NUM_CHANNELS),
    .GLB_ADDR_WIDTH(RAM_GLB_ADDR_WIDTH),
    .HEIGHT_WIDTH(ADDLAYER_HEIGHT_WIDTH)
  ) U_control (
    .clk  ( clk   ),
    .reset( reset ),
    .en   ( en    ),
    .din_ready          ( ctrl_din_ready            ),
    .din_valid          ( din_valid                 ),
    .din_param          ( din_data[31]              ),
    .ram_glb_we         ( ctrl_ram_glb_we           ),
    .ram_glb_addr1      ( ctrl_ram_glb_addr1        ),
    .ram_glb_addr2      ( ctrl_ram_glb_addr2        ),
    .instfifo_write     ( instfifo_write            ),
    .inst_in            ( instfifo_dout             ),
    .instfifo_read      ( instfifo_read             ),
    .instfifo_empty     ( instfifo_empty            ),
    .instfifo_full      ( instfifo_full             ),
    .datafifo_write     ( datafifo_write            ),
    .datafifo_read      ( datafifo_read             ),
    .datafifo_empty     ( datafifo_empty            ),
    .datafifo_full      ( datafifo_full             ),
    .wbfifo_write       ( wbfifo_write              ),
    .wbfifo_read        ( wbfifo_read               ),
    .wbfifo_empty       ( wbfifo_empty              ),
    .wbfifo_full        ( wbfifo_full               ),
    .cc_din0_valid      ( ctrl_cc_din0_valid        ),
    .cc_din1_valid      ( ctrl_cc_din1_valid        ),
    .cc_sum_en          ( ctrl_cc_sum_en            ),
    .cc_dout_valid      ( cc_dout_valid             ),
    .poolavg_plty       ( ctrl_poolavg_plty         ),
    .poolavg_start      ( ctrl_poolavg_start        ),
    .poolavg_din_valid  ( ctrl_poolavg_din_valid    ),
    .poolavg_din_ready  ( ctrl_poolavg_din_ready    ),
    .poolavg_dout_valid ( ctrl_poolavg_dout_valid   ),
    .poolavg_dout_ready ( ctrl_poolavg_dout_ready   ),
    .dense_din_valid    ( ctrl_dense_din_valid      ),
    .dense_win_valid    ( ctrl_dense_win_valid      ),
    .dense_dout_ready   ( ctrl_dense_dout_ready     ),
    .dense_dout_valid   ( ctrl_dense_dout_valid     ),
    .addlayer_height    ( ctrl_addlayer_height      ),
    .addlayer_width     ( ctrl_addlayer_width       ),
    .addlayer_start     ( ctrl_addlayer_start       ),
    .addlayer_din_ready ( ctrl_addlayer_din_ready   ),
    .addlayer_din_valid ( ctrl_addlayer_din_valid   ),
    .addlayer_dout_ready( ctrl_addlayer_dout_ready  ),
    .addlayer_dout_valid( ctrl_addlayer_dout_valid  ),
    .fmap_dout_valid    ( round_dout_valid          ),
    .fmap_a_we          ( ctrl_fmap_a_we            ),
    .fmap_b_we          ( ctrl_fmap_b_we            ),
    .fmap_c_we          ( ctrl_fmap_c_we            ),
    .fmap_d_we          ( ctrl_fmap_d_we            ),
    .fmap_din_valid     ( ctrl_fmap_din_valid       ),
    .relu_xin_valid     ( ctrl_relu_xin_valid       ),
    .relu_yout_valid    ( ctrl_relu_yout_valid      ),
    .ofifo_write        ( ctrl_ofifo_write          ),
    .glb_sel            ( ctrl_glb_sel              ),
    .relu_sel           ( ctrl_relu_sel             ),
    .smob_sel           ( ctrl_smob_sel             ) 
  );
  
  assign din_ready = ctrl_din_ready;
  assign dout_data = $signed(ofifo_dout);
  assign dout_valid = !ofifo_empty;
  assign dout_last = ofifo_last;
endmodule
