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

`include "defines.v"

module Framework (
    input clk,
    input rst
);
    // between pc and icache
    wire pc_icache_ce;
    wire [`Inst_Addr_Width-1:0] icache_addr;
    wire [`Inst_Addr_Width-1:0] icache_dec_addr;

    // between staller and icache
    wire sta_icache_stall;
    wire icache_sta_enable;

    // between Decoder and icache
    wire icache_dec_enable;
    wire [`Inst_Width-1:0] icache_dec_inst;

    // between dcache and loadStore
    wire lsm_dcache_prefetch;
    wire [`Addr_Width-1 : 0]  lsm_dcache_pre_addr;
    wire lsm_dcache_read;
    wire [`Addr_Width-1 : 0] lsm_dcache_read_addr;
    wire dcache_lsm_read_done;
    wire [`Data_Width-1     : 0] dcache_lsm_read_data;

    // between dcache and rob
    wire rob_dcache_write;
    wire [3             : 0] rob_dcache_mask;
    wire [`Addr_Width-1 : 0] rob_dcache_addr;
    wire [`Data_Width-1 : 0] rob_dcache_data;
    wire dcache_rob_valid;

    // between icache and InstMemory
    wire icache_mem_valid;
    wire [`Inst_Addr_Width-1 : 0] icache_mem_addr;
    wire mem_icache_valid;
    wire [`Inst_Width-1      : 0] mem_icache_data;

    // between dcache and DataMemory
    wire mem_dcache_free;
    wire mem_dcache_read_valid;
    wire [1:0] dcache_mem_rw_flag;
    wire [`Addr_Width-1:0] dcache_mem_addr;
    wire [`Data_Width-1:0] dcache_mem_i_data;
    wire [3:0] dcache_mem_i_mask;
    wire [`Data_Width-1:0] mem_dcache_o_data;

    CPU cpu0(
        .clk (clk),
        .rst (rst),
        // with icache
        .icache_dec_enable (icache_dec_enable),
        .icache_dec_inst (icache_dec_inst),
        .icache_dec_addr (icache_dec_addr),
        .pc_icache_ce (pc_icache_ce),
        .icache_sta_enable (icache_sta_enable),
        .sta_icache_stall (sta_icache_stall),
        .icache_addr (icache_addr),
        // between dcache and LoadStore
        .lsm_dcache_prefetch (lsm_dcache_prefetch),
        .lsm_dcache_pre_addr (lsm_dcache_pre_addr),
        .lsm_dcache_read (lsm_dcache_read),
        .lsm_dcache_read_addr (lsm_dcache_read_addr),
        .dcache_lsm_read_done (dcache_lsm_read_done),
        .dcache_lsm_read_data (dcache_lsm_read_data),
        // between dcache and ROB
        .rob_dcache_write (rob_dcache_write),
        .rob_dcache_mask (rob_dcache_mask),
        .rob_dcache_addr (rob_dcache_addr),
        .rob_dcache_data (rob_dcache_data),
        .dcache_rob_valid (dcache_rob_valid)
    );

    InstCache icache0 (
        .clk (clk),
        .rst (rst),
        // with Staller
        .stall (sta_icache_stall),
        .o_ready (icache_sta_enable),
        // with PC
        .i_ce (pc_icache_ce),
        .i_address (icache_addr),
        // with Memory
        .o_mem_valid (icache_mem_valid),
        .o_mem_address (icache_mem_addr),
        .i_mem_valid (mem_icache_valid),
        .i_mem_data (mem_icache_data),
        // with Decoder
        .o_valid (icache_dec_enable),
        .o_data_addr (icache_dec_addr),
        .o_data (icache_dec_inst)
    );

    DataCache dcache0 (
        .clk (clk),
        .rst (rst),
        // with LoadStore
        .prefetch (lsm_dcache_prefetch),
        .pre_addr (lsm_dcache_pre_addr),
        .read (lsm_dcache_read),
        .read_addr(lsm_dcache_read_addr),
        .read_done (dcache_lsm_read_done),
        .read_data (dcache_lsm_read_data),
        // with ROB
        .write (rob_dcache_write),
        .write_addr (rob_dcache_addr),
        .write_data (rob_dcache_data),
        .write_mask (rob_dcache_mask),
        .write_done (dcache_rob_valid),
        // with Memory
        .mem_free (mem_dcache_free),
        .mem_read_valid (mem_dcache_read_valid),
        .mem_i_data (mem_dcache_o_data),
        .mem_rw_flag (dcache_mem_rw_flag),
        .mem_addr (dcache_mem_addr),
        .mem_o_data (dcache_mem_i_data),
        .mem_o_mask (dcache_mem_i_mask)
    );

    InstMemory imem0 (
        .read (icache_mem_valid),
        .addr (icache_mem_addr),
        .inst_valid (mem_icache_valid),
        .inst (mem_icache_data)
    );

    DataMemory dmem0 (
        .clk (clk),
        .rst (rst),

        .free (mem_dcache_free),
        .read_valid (mem_dcache_read_valid),
        .i_data (dcache_mem_i_data),
        .rw_flag (dcache_mem_rw_flag),
        .addr (dcache_mem_addr),
        .o_data (mem_dcache_o_data),
        .i_mask (dcache_mem_i_mask)
    );
endmodule
