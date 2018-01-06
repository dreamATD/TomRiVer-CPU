`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/01/04 08:28:12
// Design Name:
// Module Name: Staller
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

module Staller(
    input clk,
    input rst,

    input alu_full,
    input bra_full,
    input lsm_full,
    input rob_full,
    input icache_enable,
    // with Decoder
    input [`Opcode_Width-1 : 0] op,
    // with PC
    input pc_locked,
    output reg pc_stall,
    // with icache
    output reg icache_stall,
    // with ROB
    input rob_stall,
    // with LoadStore
    output lsm_stall
    );

    always @ (*) begin
        if (rst) begin
            pc_stall     <= 1;
            icache_stall <= 1;
        end else begin
            case (op)
                `BRANCH_ : begin
                    pc_stall <= !icache_enable || rob_full || bra_full;
                    icache_stall <= pc_locked  || rob_full || bra_full;
                end
                `Load_   : begin
                    pc_stall <= !icache_enable || rob_full || lsm_full;
                    icache_stall <= pc_locked  || rob_full || lsm_full;
                end
                `Store_  : begin
                    pc_stall <= !icache_enable || rob_full || lsm_full;
                    icache_stall <= pc_locked  || rob_full || lsm_full;
                end
                default  : begin
                    pc_stall <= !icache_enable || rob_full || alu_full;
                    icache_stall <= pc_locked  || rob_full || alu_full;
                end
            endcase
        end
    end

    assign lsm_stall = rob_stall;
endmodule
