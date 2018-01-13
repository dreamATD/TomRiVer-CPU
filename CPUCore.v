`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:22:55
// Design Name:
// Module Name: CPU
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

module CPUCore (
    input clk,
    input rst,
    // with icache
    input icache_dec_enable,
    input [`Inst_Width-1      : 0] icache_dec_inst,
    input [`Inst_Addr_Width-1 : 0] icache_dec_addr,
    output pc_icache_ce,
    input icache_sta_enable,
    output sta_icache_stall,
    output [`Inst_Addr_Width-1 : 0] icache_addr,
    // between dcache and LoadStore
    output lsm_dcache_read,
    output [`Addr_Width-1 : 0] lsm_dcache_read_addr,
    input dcache_lsm_read_done,
    input [`Data_Width-1     : 0] dcache_lsm_read_data,
    // between dcache and rob
    output rob_dcache_write,
    output [3             : 0] rob_dcache_mask,
    output [`Addr_Width-1 : 0] rob_dcache_addr,
    output [`Data_Width-1 : 0] rob_dcache_data,
    input dcache_rob_valid
);
    wire alu_sta_full;
    wire bra_sta_full;
    wire lsm_sta_full;
    wire rob_sta_full;
    wire [`Opcode_Width-1 : 0] dec_sta_op;
    wire pc_sta_locked;
    wire rob_sta_store_stall;
    wire sta_lsm_store_stall;

    wire sta_pc_stall;
    // between ROB and Decoder
    // with ROB, write rd
    wire [`ROB_Entry_Width-1    : 0] rob_dec_rd_lock;
    wire dec_rob_write;
    wire [`ROB_Bus_Width-1 : 0] dec_rob_bus;
    // with ROB, check whether rs1 and rs2 have figured out.
    wire dec_rob_check_rs1;
    wire dec_rob_check_rs2;
    wire [`ROB_Entry_Width-1   : 0] dec_rob_value_entry1;
    wire [`ROB_Entry_Width-1   : 0] dec_rob_value_entry2;
    wire rob_dec_value_enable1;
    wire rob_dec_value_enable2;
    wire [`Data_Width-1         : 0] rob_dec_value1;
    wire [`Data_Width-1         : 0] rob_dec_value2;

    // between RegFile and Decoder
    wire dec_reg_read1;
    wire dec_reg_read2;
    wire [`Reg_Width-1         : 0] dec_reg_name1;
    wire [`Reg_Width-1         : 0] dec_reg_name2;
    wire [`Reg_Lock_Width-1    : 0] reg_dec_lock1;
    wire [`Reg_Lock_Width-1    : 0] reg_dec_lock2;
    wire [`Data_Width-1        : 0] reg_dec_data1;
    wire [`Data_Width-1        : 0] reg_dec_data2;
    wire dec_reg_write;
    wire [`Reg_Bus_Width-1 : 0] dec_reg_bus;

    // between ALU and Decoder
    wire dec_alu_write;
    wire [`Alu_Bus_Width-1   : 0] dec_alu_bus;

    // between Branch_ALU and Decoder
    wire dec_bra_write;
    wire [`Bra_Bus_Width-1 : 0] dec_bra_bus;

    // between LoadStore and Decoder
    wire dec_lsm_write;
    wire [`Lsm_Bus_Width-1 : 0] dec_lsm_bus;

    // between Branch_Predictor and Decoder
    wire [`Bra_Addr_Width-1    : 0] dec_brp_addr;
    wire brp_dec_branch_prediction;

    // between ALU and CDB
    wire [`Reg_Lock_Width-1 : 0] cdb_alu_index;
    wire [`Data_Width-1     : 0] cdb_alu_result;
    wire alu_cdb_valid;
    wire cdb_alu_grnt;
    wire [`Reg_Lock_Width-1 : 0] alu_cdb_index;
    wire [`Data_Width-1     : 0] alu_cdb_result;

    // between LoadStore and CDB
    wire [`Reg_Lock_Width-1 : 0] cdb_lsm_index;
    wire [`Data_Width-1     : 0] cdb_lsm_data;
    wire lsm_cdb_valid;
    wire cdb_lsm_grnt;
    wire [`Reg_Lock_Width-1 : 0] lsm_cdb_index;
    wire [`Data_Width-1     : 0] lsm_cdb_data;
    wire [`Addr_Width-1     : 0] lsm_cdb_addr;

    // between Branch_ALU and CDB
    wire [`Reg_Lock_Width-1 : 0] cdb_bra_index;
    wire [`Data_Width-1     : 0] cdb_bra_result;
    wire bra_cdb_valid;
    wire cdb_bra_grnt;
    wire [`Reg_Lock_Width-1 : 0] bra_cdb_index;
    wire [`Data_Width-1     : 0] bra_cdb_result;

    // between CDB and ROB
    wire [`Reg_Lock_Width-1 : 0] cdb_rob_index;
    wire [`Data_Width-1      : 0] cdb_rob_data;
    wire [`Addr_Width-1      : 0] cdb_rob_addr;
    wire cdb_rob_is_branch;

    // between ROB and RegFile
    wire rob_reg_modify;
    wire [`Reg_Width-1       : 0] rob_reg_name;
    wire [`Data_Width-1      : 0] rob_reg_data;
    wire [`ROB_Entry_Width-1 : 0] rob_reg_entry;

    // between ROB and PC
    wire rob_pc_modify;
    wire [`Inst_Addr_Width-1 : 0] rob_pc_npc;

    // between Branch_Predictor and ROB
    wire rob_brp_update;
    wire [`Bra_Addr_Width-1    : 0] rob_brp_addr;
    wire rob_brp_result;

    // between Decoder and PC
    wire [`Reg_Lock_Width-1  : 0] dec_pc_lock;
    wire [`Inst_Addr_Width-1 : 0] dec_pc_offset;

    // between CDB and PC
    wire [`Reg_Lock_Width-1  : 0] cdb_pc_index;
    wire [`Inst_Addr_Width-1 : 0] cdb_pc_result;

    Staller staller0 (
        .clk (clk),
        .rst (rst),

        .alu_full (alu_sta_full),
        .bra_full (bra_sta_full),
        .lsm_full (lsm_sta_full),
        .rob_full (rob_sta_full),
        .icache_enable (icache_sta_enable),
        // with Decoder
        .op (dec_sta_op),
        // with PC
        .pc_locked (pc_sta_locked),
        .pc_stall (sta_pc_stall),
        // with icache
        .icache_stall (sta_icache_stall),
        // with ROB
        .rob_stall (rob_sta_store_stall),
        // with LoadStore
        .lsm_stall (sta_lsm_store_stall)
    );

    PC pc0 (
        .clk (clk),
        .rst (rst),

        .ce (pc_icache_ce),
        // with Decoder
        .pc (icache_addr),
        .dec_lock (dec_pc_lock),
        .dec_offset (dec_pc_offset),
        // with CDB
        .cdb_index (cdb_pc_index),
        .cdb_result (cdb_pc_result),
        // with ROB
        .rob_modify (rob_pc_modify),
        .rob_npc (rob_pc_npc),
        // with Staller
        .pc_locked (pc_sta_locked),
        .stall (sta_pc_stall)
    );

    Decoder decoder0 (
        .clk (clk),
        .rst (rst),
        // with InstCache
        .inst_in (icache_dec_inst),
        .inst_enable (icache_dec_enable),
        // with PC
        .inst_pc (icache_dec_addr),
        .pc_lock (dec_pc_lock),
        .pc_offset (dec_pc_offset),
        // with ROB, write rd
        .rob_rd_lock (rob_dec_rd_lock),
        .rob_write (dec_rob_write),
        .rob_bus (dec_rob_bus),
        // with ROB, check whether rs1 and rs2 have figured out.
        .rob_check_rs1 (dec_rob_check_rs1),
        .rob_check_rs2 (dec_rob_check_rs2),
        .rob_value_entry1 (dec_rob_value_entry1),
        .rob_value_entry2 (dec_rob_value_entry2),
        .rob_value_enable1 (rob_dec_value_enable1),
        .rob_value_enable2 (rob_dec_value_enable2),
        .rob_value1 (rob_dec_value1),
        .rob_value2 (rob_dec_value2),
        // with RegFile
        .reg_read1 (dec_reg_read1),
        .reg_read2 (dec_reg_read2),
        .reg_name1 (dec_reg_name1),
        .reg_name2 (dec_reg_name2),
        .reg_lock1 (reg_dec_lock1),
        .reg_lock2 (reg_dec_lock2),
        .reg_data1 (reg_dec_data1),
        .reg_data2 (reg_dec_data2),
        .reg_write (dec_reg_write),
        .reg_bus (dec_reg_bus),
        // with ALU
        .alu_write (dec_alu_write),
        .alu_bus (dec_alu_bus),
        // with Bra_ALU
        .bra_write (dec_bra_write),
        .bra_bus (dec_bra_bus),
        // with LoadStore
        .lsm_write (dec_lsm_write),
        .lsm_bus (dec_lsm_bus),
        // with Branch_Predictor
        .brp_addr (dec_brp_addr),
        .branch_prediction (brp_dec_branch_prediction),
        // with Staller
        .op (dec_sta_op)
    );

    Branch_ALU branch_alu0 (
        .clk (clk),
        .rst (rst),
        // with Staller
        .bra_stall (bra_sta_full),
        // with Decoder
        .bra_enable (dec_bra_write),
        .bra_bus (dec_bra_bus),
        // with CDB
        .cdb_in_index (cdb_bra_index),
        .cdb_in_result (cdb_bra_result),
        .cdb_out_valid (bra_cdb_valid),
        .grnt (cdb_bra_grnt),
        .cdb_out_index (bra_cdb_index),
        .cdb_out_result (bra_cdb_result)
    );

    ALU alu0 (
        .clk (clk),
        .rst (rst),
        // with Staller
        .alu_stall (alu_sta_full),
        // with Decoder
        .alu_enable (dec_alu_write),
        .alu_bus (dec_alu_bus),
        // with CDB
        .cdb_in_index (cdb_alu_index),
        .cdb_in_result (cdb_alu_result),
        .grnt (cdb_alu_grnt),
        .cdb_out_valid (alu_cdb_valid),
        .cdb_out_index (alu_cdb_index),
        .cdb_out_result (alu_cdb_result)
    );

    LoadStore loadStore0 (
        .clk (clk),
        .rst (rst),
        // with Decoder
        .lsm_write (dec_lsm_write),
        .lsm_bus (dec_lsm_bus),
        // with CDB
        .cdb_in_index (cdb_lsm_index),
        .cdb_in_data (cdb_lsm_data),
        .grnt (cdb_lsm_grnt),
        .cdb_out_valid (lsm_cdb_valid),
        .cdb_out_index (lsm_cdb_index),
        .cdb_out_data (lsm_cdb_data),
        .cdb_out_addr (lsm_cdb_addr),
        // with Staller
        .buffer_stall (lsm_sta_full),
        .rob_stall (sta_lsm_store_stall),
        // with DataCache
        .dcache_read (lsm_dcache_read),
        .dcache_read_addr (lsm_dcache_read_addr),
        .dcache_read_done (dcache_lsm_read_done),
        .dcache_read_data (dcache_lsm_read_data)
    );
    CDB cdb0 (
        // with ALU
        .alu_req (alu_cdb_valid),
        .alu_grnt (cdb_alu_grnt),
        .alu_in_index (alu_cdb_index),
        .alu_in_data (alu_cdb_result),
        .alu_out_index (cdb_alu_index),
        .alu_out_data (cdb_alu_result),
        // with LSM
        .lsm_req (lsm_cdb_valid),
        .lsm_grnt (cdb_lsm_grnt),
        .lsm_in_index (lsm_cdb_index),
        .lsm_in_data (lsm_cdb_data),
        .lsm_in_addr (lsm_cdb_addr),
        .lsm_out_index (cdb_lsm_index),
        .lsm_out_data (cdb_lsm_data),
        // with BRA
        .bra_req (bra_cdb_valid),
        .bra_grnt (cdb_bra_grnt),
        .bra_in_index (bra_cdb_index),
        .bra_in_data (bra_cdb_result),
        .bra_out_index (cdb_bra_index),
        .bra_out_data (cdb_bra_result),
        // with PC
        .pc_out_index (cdb_pc_index),
        .pc_out_data (cdb_pc_result),
        // with ROB
        .rob_is_branch (cdb_rob_is_branch),
        .rob_out_index (cdb_rob_index),
        .rob_out_data (cdb_rob_data),
        .rob_out_addr (cdb_rob_addr)
    );

    ROB rob0 (
        .clk (clk),
        .rst (rst),
        // with Staller
        .fifo_stall (rob_sta_full),
        .store_stall (rob_sta_store_stall),
        // with Decoder
        .out_lock (rob_dec_rd_lock),
        .write (dec_rob_write),
        .fifo_in (dec_rob_bus),
        .check1 (dec_rob_check_rs1),
        .check_entry1 (dec_rob_value_entry1),
        .check_value1 (rob_dec_value1),
        .check_value_enable1 (rob_dec_value_enable1),
        .check2 (dec_rob_check_rs2),
        .check_entry2 (dec_rob_value_entry2),
        .check_value2 (rob_dec_value2),
        .check_value_enable2 (rob_dec_value_enable2),
        // with RegFile
        .reg_modify (rob_reg_modify),
        .reg_name (rob_reg_name),
        .reg_data (rob_reg_data),
        .reg_entry (rob_reg_entry),
        // with DataCache
        .dcache_write (rob_dcache_write),
        .dcache_mask (rob_dcache_mask),
        .dcache_addr (rob_dcache_addr),
        .dcache_data (rob_dcache_data),
        .dcache_write_valid (dcache_rob_valid),
        // with CDB
        .cdb_in_entry (cdb_rob_index),
        .cdb_in_value (cdb_rob_data),
        .cdb_in_addr (cdb_rob_addr),
        .cdb_is_branch (cdb_rob_is_branch),
        // with PC
        .pc_modify (rob_pc_modify),
        .npc (rob_pc_npc),
        // with Branch_Predictor
        .brp_update (rob_brp_update),
        .brp_addr (rob_brp_addr),
        .brp_result (rob_brp_result)
    );

    Branch_Predictor branch_predictor0(
        .clk (clk),
        .rst (rst),
        // with Decoder
        .dec_addr (dec_brp_addr),
        .dec_prediction (brp_dec_branch_prediction),
        // with ROB
        .brp_update (rob_brp_update),
        .rob_addr (rob_brp_addr),
        .rob_prediction (rob_brp_result)
    );

    RegFile regfile0 (
        .clk (clk),
        .rst (rst),
        // with ROB
        .ROB_we (rob_reg_modify),
        .namew (rob_reg_name),
        .dataw (rob_reg_data),
        .entryw (rob_reg_entry),
        // with Decoder
        .re1 (dec_reg_read1),
        .name1 (dec_reg_name1),
        .lock1 (reg_dec_lock1),
        .data1 (reg_dec_data1),
        .re2 (dec_reg_read2),
        .name2 (dec_reg_name2),
        .lock2 (reg_dec_lock2),
        .data2 (reg_dec_data2),
        .dec_we (dec_reg_write),
        .dec_bus (dec_reg_bus)
    );
endmodule
