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
    wire icache_instq_enable;
    wire [`Inst_Width-1:0] icache_instq_inst;
    wire pc_icache_ce;
    wire [`Inst_Addr_Width-1:0] icache_addr;
    CPU cpu0(
        .clk (clk),
        .rst (rst),
        .icache_instq_enable (icache_instq_enable),
        .icache_instq_inst (icache_instq_inst),
        .pc_icache_ce (pc_icache_ce),
        .icache_addr (icache_addr)
    );
    InstCache icache0 (
        .ce (pc_icache_ce),
        .addr (icache_addr),
        .inst (icache_instq_inst),
        .cache_enable (icache_instq_enable)
    );
endmodule
