`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:22:55
// Design Name:
// Module Name: PC
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

module PC (
    input clk,
    input rst,
    // with icache
    output reg ce,
    // with Decoder
    output reg [`Inst_Addr_Width-1 : 0] pc,
    input [`Reg_Lock_Width-1    : 0] dec_lock,
    input [`Inst_Addr_Width-1   : 0] dec_offset,
    // with CDB
    input [`Reg_Lock_Width-1    : 0] cdb_index,
    input [`Inst_Addr_Width-1   : 0] cdb_result,
    // with ROB
    input rob_modify,
    input [`Inst_Addr_Width - 1 : 0] rob_npc,
    // with Staller
    output reg pc_locked,
    input stall
);

    reg [`Reg_Lock_Width-1  : 0] lock;
    reg [`Inst_Addr_Width-1 : 0] offset;

    always @ (*) begin
        if (!rst && lock == `Reg_No_Lock && dec_lock == `Reg_No_Lock) begin
            lock <= `Reg_No_Lock;
            offset <= dec_offset;
        end
        if (!rst && lock == `Reg_No_Lock && dec_lock != `Reg_No_Lock) begin
            lock <= dec_lock;
        end
        if (!rst && lock != `Reg_No_Lock && cdb_index == lock) begin
            lock <= `Reg_No_Lock;
            offset <= cdb_result;
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            ce <= 1'b0;
            lock <= `Reg_No_Lock;
            offset <= 4;
        end else begin
            ce <= 1'b1;
        end
    end

    always @ (posedge clk) begin
        if (ce == 1'b0) begin
            pc <= 32'h000000;
            pc_locked <= 0;
        end else if (!stall) begin
            pc_locked <= (lock != `Reg_No_Lock);
            pc <= pc;
            if (rob_modify) begin
                pc <= rob_npc;
            end
            if (lock == `Reg_No_Lock && !rob_modify)  begin
                pc <= pc + offset;
            end
        end else begin
            pc <= pc;
        end
    end
endmodule
