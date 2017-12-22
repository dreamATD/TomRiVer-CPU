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

module PC(
    input clk,
    input rst,
    input stall,
    output reg [`Inst_Addr_Width-1 : 0] pc,
    output reg ce
);
    always @ (posedge clk) begin
        if (rst || stall) begin
            ce <= 1'b0;
        end else begin
            ce <= 1'b1;
        end
    end

    always @ (posedge clk) begin
        if (ce == 1'b0) begin
            pc <= 32'h000000;
        end else begin
            pc <= pc + 4'h4;
        end
    end
endmodule
