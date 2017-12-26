`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/21 14:09:34
// Design Name:
// Module Name: Framework
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


module Framework (
    input clk,
    input rst
);
    wire icache_dec_enable;
    wire [`Inst_Width-1:0] icache_dec_inst;
    wire pc_icache_ce;
    wire pc_icache_stall;
    wire [`Inst_Addr_Width-1:0] icache_addr;
    CPU cpu0(
        .clk (clk),
        .rst (rst),
        .icache_dec_enable (icache_dec_enable),
        .icache_dec_inst (icache_dec_inst),
        .pc_icache_ce (pc_icache_ce),
        .pc_icache_stall (pc_icache_stall),
        .icache_addr (icache_addr)
    );
    InstCache icache0 (
        .ce (pc_icache_ce),
        .addr (icache_addr),
        .inst (icache_dec_inst),
        .pc_cache_stall (pc_icache_stall),
        .cache_enable (icache_dec_enable)
    );
endmodule
