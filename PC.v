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
    input stall,
    output reg [`Inst_Addr_Width-1 : 0] pc,
    output reg ce,
    output reg cache_stall,
    // with Decoder
    input [`Reg_Lock_Width-1    : 0] dec_lock,
    input [`Inst_Addr_Width-1   : 0] dec_offset,
    // with CDB
    input [`Reg_Lock_Width-1    : 0] cdb_index,
    input [`Inst_Addr_Width-1   : 0] cdb_result,
    // with ROB
    input rob_modify,
    input [`Inst_Addr_Width - 1 : 0] rob_npc
);

    reg [`Reg_Lock_Width-1  : 0] lock;
    reg [`Inst_Addr_Width-1 : 0] offset;

    always @ (dec_lock, cdb_index, cdb_result, dec_offset) begin
        if (!rst && lock == `Reg_No_Lock && dec_lock == `Reg_No_Lock) begin
            lock <= `Reg_No_Lock;
            offset <= dec_offset;
        end
        if (!rst && lock == `Reg_No_Lock && dec_lock != `Reg_No_Lock) begin
            lock <= dec_lock;
            $display("##");
        end
        if (!rst && lock != `Reg_No_Lock && cdb_index == lock) begin
            lock <= `Reg_No_Lock;
            $display("@@");
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
        end else if (!stall) begin
            pc <= pc;
            cache_stall <= 1;
            if (rob_modify) begin
                pc <= rob_npc;
                cache_stall <= 0;
            end
            if (lock == `Reg_No_Lock && !rob_modify)  begin
                pc <= pc + offset;
                cache_stall <= 0;
            end
        end else begin
            pc <= pc;
            cache_stall <= 0;
        end
    end
endmodule
