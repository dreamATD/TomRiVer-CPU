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


module CPU (
    input clk,
    input rst,
    input icache_dec_enable,
    input [`Inst_Width-1:0] icache_dec_inst,
    output pc_icache_ce,
    output pc_icache_stall,
    output [`Inst_Addr_Width-1:0] icache_addr
);
/*
    // between PC and InstQueue
    wire instq_pc_stall;
    wire [`Inst_Addr_Width-1 : 0] pc_instq_addr;

    // between InstQueue and Decoder
    wire dec_instq_clear;
    wire dec_instq_enable;
    wire [`Inst_Addr_Width-1 : 0] instq_dec_pc;
    wire [`Inst_Width-1 : 0] instq_dec_inst;
    wire instq_dec_stall;
*/
    // between ROB and Decoder
    // with ROB, write rd
    wire rob_dec_stall;
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
    wire alu_dec_stall;
    wire dec_alu_write;
    wire [`Inst_Addr_Width-1 : 0] dec_alu_pc;
    wire [`Alu_Bus_Width-1   : 0] dec_alu_bus;

    // between ALU and CDB
    wire [`Reg_Lock_Width-1 : 0] cdb_alu_index;
    wire [`Data_Width-1     : 0] cdb_alu_result;
    wire cdb_alu_done;
    wire alu_cdb_valid;
    wire [`Reg_Lock_Width-1 : 0] alu_cdb_index;
    wire [`Data_Width-1     : 0] alu_cdb_result;

    // between CDB and ROB
    wire cdb_rob_write;
    wire [`ROB_Entry_Width-1 : 0] cdb_rob_out_entry;
    wire [`Data_Width-1      : 0] cdb_rob_out_value;

    // between ROB and RegFile
    wire rob_reg_modify;
    wire [`Reg_Width-1       : 0] rob_reg_name;
    wire [`Data_Width-1      : 0] rob_reg_data;
    wire [`ROB_Entry_Width-1 : 0] rob_reg_entry;

    // between Decoder and PC
    wire dec_pc_stall;
    wire [`Inst_Addr_Width-1 : 0] pc_dec_addr;
    wire [`Reg_Lock_Width-1  : 0] dec_pc_lock;
    wire [`Inst_Addr_Width-1 : 0] dec_pc_offset;
    // between CDB and PC
    wire [`Reg_Lock_Width-1  : 0] cdb_pc_index;
    wire [`Inst_Addr_Width-1 : 0] cdb_pc_result;

    PC pc0 (
        .clk (clk),
        .rst (rst),
        .stall (dec_pc_stall),
        .pc (pc_dec_addr),
        .ce (pc_icache_ce),
        .cache_stall (pc_icache_stall),
        // with Decoder
        .dec_lock (dec_pc_lock),
        .dec_offset (dec_pc_offset),
        // with CDB
        .cdb_index (cdb_pc_index),
        .cdb_result (cdb_pc_result)
    );
    assign icache_addr = pc_dec_addr;
    /*
    InstQueue instQueue0 (
        .clk (clk),
        .rst (rst),
        // with pc
        .pc_in (pc_instq_addr),
        .pc_stall (instq_pc_stall),
        // with InstCache
        .cache_inst_enable (icache_instq_enable),
        .cache_inst (icache_instq_inst),
        // with Decoder
        .clear (dec_instq_clear),
        .dec_enable (dec_instq_enable),
        .dec_pc (instq_dec_pc),
        .dec_inst (instq_dec_inst),
        .dec_stall (instq_dec_stall)
    );
    */
    Decoder decoder0 (
        .clk (clk),
        .rst (rst),
        // with InstCache
        .inst_in (icache_dec_inst),
        .inst_enable (icache_dec_enable),
        // with PC
        .inst_pc (pc_dec_addr),
        .pc_stall (dec_pc_stall),
        .pc_lock (dec_pc_lock),
        .pc_offset (dec_pc_offset),
        // with ROB, write rd
        .rob_stall (rob_dec_stall),
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
        // with Load
        /*
        input ld_stall,
        output reg ld_write,
        output reg [`Load_Bus_Width-1:0] ld_bus,
        //with Store
        input st_stall,
        output reg st_write,
        output reg [`Store_Bus_Width-1:0] st_bus,
        */
        // with ALU
        .alu_stall (alu_dec_stall),
        .alu_write (dec_alu_write),
        .alu_bus (dec_alu_bus)
    );

    ALU alu0 (
        .clk (clk),
        .rst (rst),
        // with Decoder
        .alu_stall (alu_dec_stall),
        .alu_enable (dec_alu_write),
        .alu_bus (dec_alu_bus),

        // with CDB
        .cdb_in_index (cdb_alu_index),
        .cdb_in_result (cdb_alu_result),
        .cdb_out_valid (alu_cdb_valid),
        .cdb_out_index (alu_cdb_index),
        .cdb_out_result (alu_cdb_result)
    );

    CDB cdb0 (
        .clk (clk),
        .rst (rst),
        // with ALU
        .alu_out_index_alu (cdb_alu_index),
        .alu_out_result_alu (cdb_alu_result),
        .alu_in_valid (alu_cdb_valid),
        .alu_in_index (alu_cdb_index),
        .alu_in_result (alu_cdb_result),
        // with Load
        // with Store
        // with ROB
        .rob_write_alu (cdb_rob_write),
        .rob_out_entry_alu (cdb_rob_out_entry),
        .rob_out_value_alu (cdb_rob_out_value),
        // with PC
        .pc_out_index (cdb_pc_index),
        .pc_out_result (cdb_pc_result)
    );

    ROB rob0 (
        .clk (clk),
        .rst (rst),

        // with Decoder
        .fifo_full (rob_dec_stall),
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
        /*
        // with DataCache
        output reg mem_modify,
        output reg [`Addr_Width-1 : 0] mem_addr,
        output reg [`Data_Width-1 : 0] mem_data,
        */
        // with CDB
        .cdb_write (cdb_rob_write),
        .cdb_in_entry (cdb_rob_out_entry),
        .cdb_in_value (cdb_rob_out_value)
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
