`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:22:55
// Design Name:
// Module Name: InstQueue
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

`include "defines.v"
module InstQueue(
    input                               clk,
    input                               rst,
    // with pc
    input [`Inst_Addr_Width-1:0]        pc_in,
    output                              pc_stall,
    // with InstCache
    input                               cache_inst_enable,
    input [`Inst_Width-1:0]             cache_inst,

    // with Decoder
    input                           dec_enable,
    output [`Inst_Addr_Width-1:0]   dec_pc,
    output [`Inst_Width-1:0]        dec_inst,
    output                          dec_stall
);

    localparam Queue_Entry_Number       = 16;
    localparam Queue_Entry_Width        = 4;
    
    assign dec_pc = pc_in;

    FifoQueue #(Queue_Entry_Number, Queue_Entry_Width, `Inst_Width) queue (
        .clk(clk),
        .rst(rst),
        .read(dec_enable),
        .write(cache_inst_enable),
        .fifo_in(cache_inst),
        .fifo_out(dec_inst),
        .fifo_empty(dec_stall),
        .fifo_full(pc_stall)
    );

endmodule
