`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/26 08:28:08
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   Definition of NNTop's micro-ops.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// The micro-op flag: if OP[31] is 1'b0, then OP is a micro-op

`define NNMICROOPS_OP_FLAG_MSB  31
`define NNMICROOPS_OP_FLAG_LSB  31
`define NNMICROOPS_OP_FLAG_OP   1'b0

`define NNMICROOPS_SUBMOD_MSB       30
`define NNMICROOPS_SUBMOD_LSB       28
`define NNMICROOPS_SUBMOD_CTRL      3'b000
`define NNMICROOPS_SUBMOD_CONV      3'b001
`define NNMICROOPS_SUBMOD_POOLAVG   3'b010
`define NNMICROOPS_SUBMOD_DENSE     3'b011
`define NNMICROOPS_SUBMOD_ADDLY     3'b100
`define NNMICROOPS_SUBMOD_FMAROUND  3'b101

`define NNMICROOPS_OPCODE_MSB 27
`define NNMICROOPS_OPCODE_LSB 24
`define NNMICROOPS_OPCODE_LOADKER     4'b0001
`define NNMICROOPS_OPCODE_LOADIFM     4'b0010
`define NNMICROOPS_OPCODE_SET         4'b0100
`define NNMICROOPS_OPCODE_FMAR_VALID  4'b1000
`define NNMICROOPS_OPCODE_CTRL_WI     4'b1000
`define NNMICROOPS_OPCODE_CTRL_WB     4'b1001
`define NNMICROOPS_OPCODE_CTRL_OEN    4'b1010

`define NNMICROOPS_CONFIG_MSB 20
`define NNMICROOPS_CONFIG_LSB 16

`define NNMICROOPS_BASEADDR_MSB 15
`define NNMICROOPS_BASEADDR_LSB 0