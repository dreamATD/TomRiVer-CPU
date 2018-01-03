`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/01/03 09:40:00
// Design Name:
// Module Name: Branch_Predictor
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
module Branch_Predictor (
    input clk,
    input rst,
    // with Decoder
    input [`Bra_History_Width-1 : 0] dec_pattern,
    input [`Bra_Addr_Width-1    : 0] dec_addr,
    output dec_prediction,
    // with ROB
    input brp_update,
    input [`Bra_History_Width-1 : 0] rob_pattern,
    input [`Bra_Addr_Width-1    : 0] rob_addr,
    input rob_prediction
);

    wire [`Bra_Entry_Width-1 : 0] entry;
    reg [1                 : 0] predict_table[`Bra_Entry_Cnt-1 : 0];

    assign entry = {rob_pattern, rob_addr};

    integer i;
    always @ (posedge rst) begin
        for (i = 0; i < `Bra_Entry_Cnt; i = i + 1) predict_table[i] <= 2'b10;
    end
    assign dec_prediction = predict_table[{dec_pattern, dec_addr}][1];

    always @ (posedge clk) begin
        if (brp_update) begin
            case (rob_prediction)
                1'b0: begin
                    if (predict_table[entry] != 2'b00) predict_table[entry] <= predict_table[entry] - 1;
                end
                1'b1: begin
                    if (predict_table[entry] != 2'b11) predict_table[entry] <= predict_table[entry] + 1;
                end
                default: ;
            endcase
        end
    end

endmodule
