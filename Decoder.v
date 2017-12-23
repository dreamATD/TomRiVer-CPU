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
    // with InstQueue
    input clk,
    input rst,
    input  [`Inst_Width-1:0] inst_in,
    input [`Inst_Addr_Width-1:0] inst_pc,
    input inst_stall,
    output inst_enable,

    // with ROB, write rd
    input rob_stall,
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
    input alu_stall,
    output reg alu_write,
    output reg [`Alu_Bus_Width-1 : 0] alu_bus
);

    localparam  Branch      = 2'd1;
    localparam  Store       = 2'd2;
    localparam  Normal_Op   = 2'd3;

    wire [`Opcode_Width-1  : 0] op;    // opcode
    wire [`Simp_Op_Width-1 : 0] simp_op; // operation defined by myself.
    wire [`Reg_Width-1     : 0] rd, rs1, rs2; // register name
    wire [`Imm_Width-1     : 0] imm1;
    wire [`Func3_Width-1   : 0] func3;
    wire [`Func7_Width-1   : 0] func7;

    assign rd = inst_in[`Rd_Interval];
    assign rs1 = inst_in[`Rs1_Interval];
    assign rs2 = (
        op == `Op_Imm ? `Reg_Width'd0 :
                        inst_in[`Rs2_Interval]
    );
    assign imm1 = inst_in[`Imm_Interval];
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
                                  0
    );


    assign reg_name1 = rs1;
    assign reg_name2 = rs2;
    assign reg_read1 = 1;
    assign reg_read2 = (
        op == `Op_Imm ? 0 :
                        1
    );

    assign rob_check_rs1 = (reg_lock1 == `Reg_No_Lock) ? 0 : 1;
    assign rob_value_entry1 = reg_lock1[`ROB_Entry_Width-1 : 0];
    assign rob_check_rs2 = (reg_lock2 == `Reg_No_Lock) ? 0 : 1;
    assign rob_value_entry2 = reg_lock2[`ROB_Entry_Width-1 : 0];

    wire [`Reg_Lock_Width-1:0] lock1, lock2;
    wire [`Data_Width-1:0] data1, data2;
    assign lock1 = (reg_lock1 == `Reg_No_Lock || reg_lock1 != `Reg_No_Lock && rob_value_enable1) ? `Reg_No_Lock : reg_lock1;
    assign data1 = (reg_lock1 == `Reg_No_Lock) ? reg_data1 : (reg_lock1 != `Reg_No_Lock && rob_value_enable1) ? rob_value1 : 0;
    assign lock2 = (reg_lock2 == `Reg_No_Lock || reg_lock2 != `Reg_No_Lock && rob_value_enable2) ? `Reg_No_Lock : reg_lock2;
    assign data2 = (reg_lock2 == `Reg_No_Lock) ? reg_data2 : (reg_lock2 != `Reg_No_Lock && rob_value_enable2) ? rob_value2 : 0;

    assign inst_enable = (!rob_stall && !(
     //       op == `LoadOpcode   ? ld_stall :
       //     op == `StoreOpcode  ? st_stall :
                                  alu_stall
        )
    );

    always @ (*) begin
        if (rst) begin
            alu_write <= 0;
            rob_write <= 0;
            reg_write <= 0;
        end else begin
            if (!inst_stall) begin
                case (op)
                    `Op_Imm : begin
                        //{alu_enable, ld_enable, st_enable} <= 3'b100;
                        alu_write <= 1;
                        reg_write <= 1;
                        rob_write <= 1;
                        alu_bus   <= {
                            simp_op,
                            lock1, data1,
                            `Reg_No_Lock, {{(`Data_Width-`Imm_Width){imm1[`Imm_Width-1]}},imm1},
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
                    default: begin
                        alu_write <= 0;
                        reg_write <= 0;
                        rob_write <= 0;
                        rob_bus   <= {`ROB_Bus_Width{1'b0}};
                        alu_bus   <= {`Alu_Bus_Width{1'b0}};
                        reg_bus   <= {`Reg_Bus_Width{1'b0}};
                    end
                endcase
            end
        end
    end

endmodule
