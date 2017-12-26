`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:25:26
// Design Name:
// Module Name: CDB
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
module CDB(
    input clk,
    input rst,
    // with ALU
    output [`Reg_Lock_Width-1 : 0] alu_out_index_alu,
    output [`Data_Width-1     : 0] alu_out_result_alu,
    input alu_in_valid,
    input [`Reg_Lock_Width-1 : 0] alu_in_index,
    input [`Data_Width-1     : 0] alu_in_result,
    // with Load
    // with Store
    // with ROB
    output rob_write_alu,
    output [`ROB_Entry_Width-1 : 0] rob_out_entry_alu,
    output [`Data_Width-1      : 0] rob_out_value_alu,
    // with PC
    output [`Reg_Lock_Width-1 : 0] pc_out_index,
    output [`Data_Width-1     : 0] pc_out_result
);
    assign alu_out_index_alu = alu_in_valid ? alu_in_index : `Reg_No_Lock;
    assign alu_out_result_alu = alu_in_valid ? alu_in_result : 0;
    assign pc_out_index = alu_in_valid ? alu_in_index : `Reg_No_Lock;
    assign pc_out_result = alu_in_valid ? alu_in_result : 0;
    assign rob_write_alu = alu_in_valid;
    assign rob_out_entry_alu = alu_in_index;
    assign rob_out_value_alu = alu_in_result;
/*
    always @ (posedge clk) begin
        if (rst) begin
            alu_out_index  <= `Reg_No_Lock;
            alu_out_result <= 0;
            alu_done       <= 0;
            rob_write      <= 0;
        end else begin
            if (alu_in_valid) begin
                alu_out_index  <= alu_in_index;
                alu_out_result <= alu_in_result;
                alu_done       <= 1;
                if (alu_in_index != `Reg_No_Lock) begin
                    rob_write     <= 1;
                    rob_out_entry <= alu_in_index[`ROB_Entry_Width-1:0];
                    rob_out_value <= alu_in_result;
                end else begin
                    rob_write <= 0;
                end
            end else begin
                alu_out_index  <= `Reg_No_Lock;
                alu_out_result <= 0;
                alu_done       <= 0;
            end
        end
    end
*/
endmodule
