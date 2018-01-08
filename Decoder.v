`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 17:10:05
// Design Name:
// Module Name: Decoder
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
module Decoder (
    input clk,
    input rst,
    // with InstCache
    input [`Inst_Width-1:0] inst_in,
    input inst_enable,
    // with PC
    input [`Inst_Addr_Width-1:0] inst_pc,
    output [`Reg_Lock_Width-1 : 0] pc_lock,
    output [`Data_Width-1     : 0] pc_offset,
    // with ROB, write rd
    input [`ROB_Entry_Width-1 : 0] rob_rd_lock,
    output reg rob_write,
    output reg [`ROB_Bus_Width-1 : 0] rob_bus,
    // with ROB, check whether rs1 and rs2 have figured out.
    output rob_check_rs1,
    output rob_check_rs2,
    output [`ROB_Entry_Width-1 : 0] rob_value_entry1,
    output [`ROB_Entry_Width-1 : 0] rob_value_entry2,
    input rob_value_enable1,
    input rob_value_enable2,
    input [`Data_Width-1 : 0] rob_value1,
    input [`Data_Width-1 : 0] rob_value2,
    // with RegFile
    output reg_read1,
    output reg_read2,
    output [`Reg_Width-1     : 0] reg_name1,
    output [`Reg_Width-1     : 0] reg_name2,
    input [`Reg_Lock_Width-1 : 0] reg_lock1,
    input [`Reg_Lock_Width-1 : 0] reg_lock2,
    input [`Data_Width-1     : 0] reg_data1,
    input [`Data_Width-1     : 0] reg_data2,
    output reg reg_write,
    output reg [`Reg_Bus_Width-1 : 0] reg_bus,
    // with ALU
    output reg alu_write,
    output reg [`Alu_Bus_Width-1 : 0] alu_bus,
    // with Branch_ALU
    output reg bra_write,
    output reg [`Bra_Bus_Width-1 : 0] bra_bus,
    // with LoadStore
    output reg lsm_write,
    output reg [`Lsm_Bus_Width-1 : 0] lsm_bus,
    // with Branch_Predictor
    output [`Bra_Addr_Width-1    : 0] brp_addr,
    input branch_prediction,
    // with Staller
    output [`Opcode_Width-1 : 0] op
);

    localparam  Empty_OP    = 3'd0;
    localparam  Branch      = 3'd1;
    localparam  Normal_Op   = 3'd2;
    localparam  S_byte      = 3'd3;
    localparam  S_half      = 3'd4;
    localparam  S_word      = 3'd5;

    wire [`Simp_Op_Width-1   : 0] simp_op; // operation defined by myself.
    wire [`Reg_Width-1       : 0] rd, rs1, rs2; // register name
    wire [`Imm_Width-1       : 0] imm;
    wire [`Jmm_Width-1       : 0] jmm;
    wire [`Inst_Addr_Width-1 : 0] bmm;
    wire [`Inst_Width-1      : 0] smm;
    wire [`Func3_Width-1     : 0] func3;
    wire [`Func7_Width-1     : 0] func7;

    // decode
    assign rd = inst_in[`Rd_Interval];
    assign rs1 = inst_in[`Rs1_Interval];
    assign rs2 = (
        op == `Op_Imm ? `Reg_Width'd0 :
                        inst_in[`Rs2_Interval]
    );
    assign imm = inst_in[`Imm_Interval];
    assign jmm = inst_in[`Jmm_Interval];
    assign bmm = {{(`Inst_Addr_Width - 12){inst_in[31]}}, inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0};
    assign smm = {{(`Addr_Width - 12){inst_in[31]}}, inst_in[31:25], inst_in[11:7]};
    assign func3 = inst_in[`Func3_Interval];
    assign func7 = inst_in[`Func7_Interval];
    assign op = inst_in[`Opcode_Interval];
    assign simp_op = (
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b000 ? `ADD :
        (                 op == `Op_ && func7 == 7'b0100000) && func3 == 3'b000 ? `SUB :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b010 ? `SLT :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b011 ? `SLTU :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b100 ? `XOR :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b110 ? `OR  :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b111 ? `AND :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b001 ? `SLL :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0000000) && func3 == 3'b101 ? `SRL :
        (op == `Op_Imm || op == `Op_ && func7 == 7'b0100000) && func3 == 3'b101 ? `SRA :
        (op == `LUI_                                       )                    ? `LUI :
        (op == `AUIPC_                                     )                    ? `AUIPC :
        (op == `JAL_                                       )                    ? `JAL :
        (op == `JALR_                                      ) && func3 == 3'b000 ? `JALR :
        (op == `BRANCH_                                    ) && func3 == 3'b000 ? `BEQ :
        (op == `BRANCH_                                    ) && func3 == 3'b001 ? `BNE :
        (op == `BRANCH_                                    ) && func3 == 3'b100 ? `BLT :
        (op == `BRANCH_                                    ) && func3 == 3'b101 ? `BGE :
        (op == `BRANCH_                                    ) && func3 == 3'b110 ? `BLTU :
        (op == `BRANCH_                                    ) && func3 == 3'b111 ? `BGEU :
        (op == `Load_                                      ) && func3 == 3'b000 ? `LB :
        (op == `Load_                                      ) && func3 == 3'b001 ? `LH :
        (op == `Load_                                      ) && func3 == 3'b010 ? `LW :
        (op == `Load_                                      ) && func3 == 3'b100 ? `LBU :
        (op == `Load_                                      ) && func3 == 3'b101 ? `LHU :
        (op == `Store_                                     ) && func3 == 3'b000 ? `SB :
        (op == `Store_                                     ) && func3 == 3'b001 ? `SH :
        (op == `Store_                                     ) && func3 == 3'b010 ? `SW :
                                                                                    0
    ); // wait to be optimized.

    // check the reg's lock and whether it has been caculated and recoded in rob.
    assign reg_name1 = rs1;
    assign reg_name2 = rs2;
    assign reg_read1 = 1;
    assign reg_read2 = 1;

    assign rob_check_rs1 = (reg_lock1 == `Reg_No_Lock) ? 0 : 1;
    assign rob_value_entry1 = reg_lock1[`ROB_Entry_Width-1 : 0];
    assign rob_check_rs2 = (reg_lock2 == `Reg_No_Lock) ? 0 : 1;
    assign rob_value_entry2 = reg_lock2[`ROB_Entry_Width-1 : 0];

    wire [`Reg_Lock_Width-1 : 0] lock1, lock2;
    wire [`Data_Width-1     : 0] data1, data2;

    assign lock1 = (reg_lock1 == `Reg_No_Lock || reg_lock1 != `Reg_No_Lock && rob_value_enable1) ? `Reg_No_Lock : reg_lock1;
    assign data1 = (reg_lock1 == `Reg_No_Lock) ? reg_data1 : (reg_lock1 != `Reg_No_Lock && rob_value_enable1) ? rob_value1 : 0;
    assign lock2 = (reg_lock2 == `Reg_No_Lock || reg_lock2 != `Reg_No_Lock && rob_value_enable2) ? `Reg_No_Lock : reg_lock2;
    assign data2 = (reg_lock2 == `Reg_No_Lock) ? reg_data2 : (reg_lock2 != `Reg_No_Lock && rob_value_enable2) ? rob_value2 : 0;

    wire [`Inst_Addr_Width-1  : 0] branch_offset, branch_wrong;
    wire branch_taken;

/*    assign brp_pattern = bra_history; */
    assign brp_addr = inst_pc[`Bra_Addr_Width-1 : 0];
/*
    always @ (posedge clk) begin
        if (rst) bra_history = 0;
        else if (op == `BRANCH_)
            bra_history <= bra_history << 1 | branch_taken;
        else
            bra_history <= bra_history;
    end
*/
    //jump
    assign branch_taken = (
        simp_op == `BEQ ? (
            (lock1 == `Reg_No_Lock && lock2 == `Reg_No_Lock) ? (data1 == data2 ? 1 : 0) : branch_prediction
        ) :
        simp_op == `BNE ? (
            (lock1 == `Reg_No_Lock && lock2 == `Reg_No_Lock) ? (data1 != data2 ? 1 : 0) : branch_prediction
        ) :
        simp_op == `BLT ? (
            (lock1 == `Reg_No_Lock && lock2 == `Reg_No_Lock) ? ($signed(data1) < $signed(data2) ? 1 : 0) : branch_prediction
        ) :
        simp_op == `BLTU ? (
            (lock1 == `Reg_No_Lock && lock2 == `Reg_No_Lock) ? (data1 < data2 ? 1 : 0) : branch_prediction
        ) :
        simp_op == `BGE ? (
            (lock1 == `Reg_No_Lock && lock2 == `Reg_No_Lock) ? ($signed(data1) >= $signed(data2) ? 1 : 0) : branch_prediction
        ) :
        simp_op == `BGEU ? (
            (lock1 == `Reg_No_Lock && lock2 == `Reg_No_Lock) ? (data1 >= data2 ? 1 : 0) : branch_prediction
        ) : 0
    );
    assign branch_offset = branch_taken ? bmm : 4;
    assign branch_wrong = branch_taken ? inst_pc + 4 : inst_pc + bmm;
    assign pc_lock   = !inst_enable ? `Reg_No_Lock : simp_op == `JALR && lock1 != `Reg_No_Lock ? rob_rd_lock : `Reg_No_Lock;
    assign pc_offset = !inst_enable ? 4 : (
        op == `JAL_ ? {{(`Inst_Addr_Width - `Jmm_Width - 1){jmm[`Jmm_Width-1]}}, jmm[7:0], jmm[8], jmm[18:9], 1'b0} :
        op == `JALR_ ? data1 + {{(`Data_Width-`Imm_Width){imm[`Imm_Width-1]}}, imm} :
        op == `BRANCH_ ? branch_offset : 4
    );

    wire [`ROB_Op_Width-1:0] store_op;
    assign store_op = (
        simp_op == `SB ? S_byte :
        simp_op == `SH ? S_half :
                         S_word
    );

    always @ (negedge clk) begin
        if (rst) begin
            bra_write <= 0;
            alu_write <= 0;
            rob_write <= 0;
            reg_write <= 0;
            lsm_write <= 0;
        end else begin
            if (inst_enable) begin
                bra_write <= 0;
                alu_write <= 0;
                reg_write <= 0;
                rob_write <= 0;
                lsm_write <= 0;
                bra_bus <= {(`Bra_Bus_Width){1'b0}};
                alu_bus <= {(`Alu_Bus_Width){1'b0}};
                reg_bus <= {(`Reg_Bus_Width){1'b0}};
                rob_bus <= {(`ROB_Bus_Width){1'b0}};
                case (op)
                    `Op_Imm : begin
                        //{alu_enable, ld_enable, st_enable} <= 3'b100;
                        alu_write <= 1;
                        reg_write <= 1;
                        rob_write <= 1;
                        alu_bus   <= {
                            simp_op,
                            lock1, data1,
                            `Reg_No_Lock, {{(`Data_Width-`Imm_Width){imm[`Imm_Width-1]}}, imm},
                            rob_rd_lock
                        };
                        rob_bus <= {
                            Normal_Op,
                            {{(`Addr_Width-`Reg_Width){1'b0}}, rd},
                            {`Data_Width{1'b0}}, 1'b0
                        };
                        reg_bus <= {
                            rd, rob_rd_lock
                        };
                    end
                    `Op_ : begin
                        //{alu_enable, ld_enable, st_enable} <= 3'b100;
                        alu_write <= 1;
                        reg_write <= 1;
                        rob_write <= 1;
                        alu_bus   <= {
                            simp_op,
                            lock1, data1,
                            lock2, data2,
                            rob_rd_lock
                        };
                        rob_bus <= {
                            Normal_Op,
                            {{(`Addr_Width-`Reg_Width){1'b0}}, rd},
                            {`Data_Width{1'b0}}, 1'b0
                        };
                        reg_bus <= {
                            rd, rob_rd_lock
                        };
                    end
                    `LUI_ : begin
                        //{alu_enable, ld_enable, st_enable} <= 3'b100;
                        reg_write <= 1;
                        rob_write <= 1;
                        rob_bus <= {
                            Normal_Op,
                            {{(`Addr_Width-`Reg_Width){1'b0}}, rd},
                            {jmm, {(`Data_Width - `Jmm_Width){1'b0}}}, 1'b1
                        };
                        reg_bus <= {
                            rd, rob_rd_lock
                        };
                    end
                    `AUIPC_ : begin
                        //{alu_enable, ld_enable, st_enable} <= 3'b100;
                        alu_write <= 1;
                        reg_write <= 1;
                        rob_write <= 1;
                        alu_bus   <= {
                            simp_op,
                            `Reg_No_Lock, inst_pc,
                            `Reg_No_Lock, {jmm, {(`Data_Width - `Jmm_Width){1'b0}}},
                            rob_rd_lock
                        };
                        rob_bus <= {
                            Normal_Op,
                            {{(`Addr_Width-`Reg_Width){1'b0}}, rd},
                            32'd0, 1'b0
                        };
                        reg_bus <= {
                            rd, rob_rd_lock
                        };
                    end
                    `JAL_ : begin
                        //{alu_enable, ld_enable, st_enable} <= 3'b100;
                        alu_write <= 1;
                        reg_write <= 1;
                        rob_write <= 1;
                        alu_bus   <= {
                            simp_op,
                            `Reg_No_Lock, inst_pc,
                            `Reg_No_Lock, 32'd4,
                            rob_rd_lock
                        };
                        rob_bus <= {
                            Normal_Op,
                            {{(`Addr_Width-`Reg_Width){1'b0}}, rd},
                            32'd0, 1'b0
                        };
                        reg_bus <= {
                            rd, rob_rd_lock
                        };
                    end
                    `JALR_ : begin
                        //{alu_enable, ld_enable, st_enable} <= 3'b100;
                        if (lock1 != `Reg_No_Lock) begin
                            alu_write <= 1;
                            alu_bus   <= {
                                simp_op,
                                lock1, data1,
                                `Reg_No_Lock, {{{(`Data_Width-`Imm_Width){imm[`Imm_Width-1]}}, imm} - inst_pc},
                                rob_rd_lock
                            };
                        end
                        rob_write <= 1;
                        reg_write <= 1;
                        rob_bus <= {
                            Normal_Op,
                            {{(`Addr_Width-`Reg_Width){1'b0}}, rd},
                            inst_pc + 32'd4, 1'b1
                        };
                        reg_bus <= {
                            rd, rob_rd_lock
                        };
                    end
                    `BRANCH_ : begin
                        if (lock1 != `Reg_No_Lock || lock2 != `Reg_No_Lock) begin
                            bra_write <= 1;
                            rob_write <= 1;
                            bra_bus   <= {
                                simp_op,
                                lock1, data1,
                                lock2, data2,
                                rob_rd_lock,
                                branch_taken
                            };
                            rob_bus <= {
                                Branch,
                                branch_wrong,
                                {(`Data_Width - 2 - `Bra_Addr_Width){1'b0}}, inst_pc[`Bra_Addr_Width-1 : 0], 2'b00,
                                1'b0
                            };
                        end else begin
                            rob_write <= 1;
                            rob_bus <= {
                                Branch,
                                branch_wrong,
                                {(`Data_Width - 2 - `Bra_Addr_Width){1'b0}}, inst_pc[`Bra_Addr_Width-1 : 0], branch_taken, branch_taken,
                                1'b1
                            };
                        end
                    end
                    `Load_ : begin
                        lsm_write <= 1;
                        rob_write <= 1;
                        reg_write <= 1;
                        lsm_bus <= {
                            simp_op,
                            lock1, data1,
                            `Reg_No_Lock, {`Data_Width{1'b0}},
                            {`Addr_Width - `Imm_Width{imm[`Imm_Width - 1]}}, imm,
                            rob_rd_lock
                        };
                        rob_bus <= {
                            Normal_Op,
                            {{(`Addr_Width-`Reg_Width){1'b0}}, rd},
                            {(`Data_Width){1'b0}}, 1'b0
                        };
                        reg_bus <= {
                            rd, rob_rd_lock
                        };
                    end
                    `Store_ : begin
                        lsm_write <= 1;
                        rob_write <= 1;
                        lsm_bus <= {
                            simp_op,
                            lock1, data1,
                            lock2, data2,
                            smm,
                            rob_rd_lock
                        };
                        rob_bus <= {
                            store_op,
                            {`Addr_Width{1'b0}},
                            {`Data_Width{1'b0}}, 1'b0
                        };
                    end
                    default: ;
                endcase
            end else begin
                alu_write <= 0;
                reg_write <= 0;
                rob_write <= 0;
                bra_write <= 0;
                lsm_write <= 0;
                rob_bus   <= {`ROB_Bus_Width{1'b0}};
                alu_bus   <= {`Alu_Bus_Width{1'b0}};
                reg_bus   <= {`Reg_Bus_Width{1'b0}};
                lsm_bus <= {`Lsm_Bus_Width{1'b0}};
                bra_bus <= {`Bra_Bus_Width{1'b0}};
            end
        end
    end

endmodule
