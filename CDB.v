`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/01/11 15:35:07
// Design Name:
// Module Name: NewCDB
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
    // with ALU
    input alu_req,
    output reg alu_grnt,
    input [`Reg_Lock_Width-1 : 0] alu_in_index,
    input [`Data_Width-1     : 0] alu_in_data,
    output [`Reg_Lock_Width-1 : 0] alu_out_index,
    output [`Data_Width-1      : 0] alu_out_data,
    // with LSM
    input lsm_req,
    output reg lsm_grnt,
    input [`Reg_Lock_Width-1 : 0] lsm_in_index,
    input [`Data_Width-1      : 0] lsm_in_data,
    input [`Addr_Width-1      : 0] lsm_in_addr,
    output [`Reg_Lock_Width-1 : 0] lsm_out_index,
    output [`Data_Width-1      : 0] lsm_out_data,
    // with BRA
    input bra_req,
    output reg bra_grnt,
    input [`Reg_Lock_Width-1 : 0] bra_in_index,
    input [`Data_Width-1      : 0] bra_in_data,
    output [`Reg_Lock_Width-1 : 0] bra_out_index,
    output [`Data_Width-1      : 0] bra_out_data,
    // with PC
    output [`Reg_Lock_Width-1 : 0] pc_out_index,
    output [`Data_Width-1      : 0] pc_out_data,
    // with ROB
    output rob_is_branch,
    output [`Reg_Lock_Width-1 : 0] rob_out_index,
    output [`Data_Width-1      : 0] rob_out_data,
    output [`Addr_Width-1      : 0] rob_out_addr
);
    localparam  ALU = 2'h1;
    localparam  LSM = 2'h2;
    localparam  BRA = 2'h3;

    reg is_branch;
    reg [`Reg_Lock_Width-1 : 0] out_index;
    reg [`Data_Width-1      : 0] out_data;
    reg [`Addr_Width-1      : 0] out_addr;

    assign alu_out_index = out_index;
    assign alu_out_data = out_data;
    assign lsm_out_index = out_index;
    assign lsm_out_data = out_data;
    assign pc_out_index = out_index;
    assign pc_out_data = out_data;
    assign bra_out_index = out_index;
    assign bra_out_data = out_data;
    assign rob_is_branch = is_branch;
    assign rob_out_index = out_index;
    assign rob_out_data = out_data;
    assign rob_out_addr = out_addr;

    reg [1:0] owner;

    always @ (*) begin
        alu_grnt <= 0;
        lsm_grnt <= 0;
        bra_grnt <= 0;
        out_index <= `Reg_No_Lock;
        is_branch <= 0;
        case (owner)
            ALU : begin
                alu_grnt <= 1;
                out_data <= alu_in_data;
                out_index <= alu_in_index;
            end
            LSM : begin
                lsm_grnt <= 1;
                out_data <= lsm_in_data;
                out_index <= lsm_in_index;
                out_addr <= lsm_in_addr;
            end
            BRA : begin
                bra_grnt <= 1;
                is_branch <= 1;
                out_data <= bra_in_data;
                out_index <= bra_in_index;
            end
            default : begin
                alu_grnt <= 0;
                lsm_grnt <= 0;
                bra_grnt <= 0;
                out_index <= `Reg_No_Lock;
                is_branch <= 0;
            end
        endcase
    end

    always @ (*) begin
        owner <= 0;
        if (!alu_req && !lsm_req && bra_req) begin
            owner <= BRA;
        end
        if (!alu_req && lsm_req) begin
            owner <= LSM;
        end
        if (alu_req) begin
            owner <= ALU;
        end
    end
endmodule
