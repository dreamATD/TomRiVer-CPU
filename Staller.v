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
    input rst,

    input alu_full,
    input bra_full,
 /*   input lsm_full, */
    input rob_full,
    input [`Opcode_Width-1 : 0] op,
    input pc_locked,

    output reg pc_stall,
    output reg icache_stall
    );

    always @ (*) begin
        if (rst) begin
            pc_stall     = 1;
            icache_stall = 1;
        end else begin
            case (op)
                `BRANCH_ : pc_stall <= rob_full || bra_full;
                default  : pc_stall <= rob_full || alu_full;
            endcase
            icache_stall <= pc_stall || pc_locked;
        end
    end
endmodule
