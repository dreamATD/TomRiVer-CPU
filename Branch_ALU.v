`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/01/02 22:20:00
// Design Name:
// Module Name: Branch_ALU
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
module Branch_ALU (
    input clk,
    input rst,
    // with Staller
    output bra_stall,
    // with Decoder
    input bra_enable,
    input [`Bra_Bus_Width-1    : 0] bra_bus,
    // with CDB
    input  [`Reg_Lock_Width-1  : 0] cdb_in_index,
    input  [`Data_Width-1      : 0] cdb_in_result,

    output reg cdb_out_valid,
    input grnt,
    output reg [`Reg_Lock_Width-1 : 0] cdb_out_index,
    output reg [`Data_Width-1:0] cdb_out_result
);

    localparam  Bra_Queue_Entry         = 4;
    localparam  Bra_Queue_Width         = 2;
    reg [`Bra_Bus_Width-1:0] queue[Bra_Queue_Entry-1:0];

    integer i;
    always @ (*) begin
        for (i = 0; i < Bra_Queue_Entry; i = i + 1) begin
            if (queue[i][`Bra_Op_Interval] != `NOP && cdb_in_index != `Reg_No_Lock && queue[i][`Bra_Lock1_Interval] == cdb_in_index) begin
                queue[i][`Bra_Lock1_Interval] <= `Reg_No_Lock;
                queue[i][`Bra_Data1_Interval] <= cdb_in_result;
            end
            if (queue[i][`Bra_Op_Interval] != `NOP && cdb_in_index != `Reg_No_Lock && queue[i][`Bra_Lock2_Interval] == cdb_in_index) begin
                queue[i][`Bra_Lock2_Interval] <= `Reg_No_Lock;
                queue[i][`Bra_Data2_Interval] <= cdb_in_result;
            end
        end
    end

    wire [Bra_Queue_Width-1:0] find_min[Bra_Queue_Entry-2:0];
    wire [Bra_Queue_Width-1:0] find_empty[Bra_Queue_Entry-2:0];

    genvar j;
    generate
        for (j = Bra_Queue_Entry - 1 - (Bra_Queue_Entry >> 1); j < Bra_Queue_Entry - 1; j = j + 1) begin
            assign find_min[j] = (
                queue[(j << 1) + 2 - Bra_Queue_Entry][`Bra_Op_Interval] != `NOP &&
                queue[(j << 1) + 2 - Bra_Queue_Entry][`Bra_Lock1_Interval] == `Reg_No_Lock &&
                queue[(j << 1) + 2 - Bra_Queue_Entry][`Bra_Lock2_Interval] == `Reg_No_Lock
            )  ? ((j << 1) + 2 - Bra_Queue_Entry) : ((j << 1) + 3 - Bra_Queue_Entry);
            assign find_empty[j] = queue[(j << 1) + 2 - Bra_Queue_Entry][`Bra_Op_Interval] == `NOP ? (j << 1) + 2 - Bra_Queue_Entry : (j << 1) + 3 - Bra_Queue_Entry;
        end
        for (j = 0; j < Bra_Queue_Entry - 1 - (Bra_Queue_Entry >> 1); j = j + 1) begin
            assign find_min[j] = (
                queue[find_min[(j << 1) + 1]][`Bra_Op_Interval] != `NOP &&
                queue[find_min[(j << 1) + 1]][`Bra_Lock1_Interval] == `Reg_No_Lock &&
                queue[find_min[(j << 1) + 1]][`Bra_Lock2_Interval] == `Reg_No_Lock
            ) ? find_min[(j << 1) + 1] : find_min[(j << 1) + 2];
            assign find_empty[j] = queue[find_empty[(j << 1) + 1]][`Bra_Op_Interval] == `NOP ? find_empty[(j << 1) + 1] : find_empty[(j << 1) + 2];
        end
    endgenerate

    assign bra_stall = queue[find_empty[0]][`Bra_Op_Interval] != `NOP;

    integer k;

    always @ (posedge clk) begin
        if (rst) begin
            for (k = 0; k < Bra_Queue_Entry; k = k + 1) begin
                queue[k] <= {`Bra_Bus_Width{1'b0}};
            end
            cdb_out_valid <= 0;
        end else begin
            if (grnt && queue[find_min[0]][`Bra_Op_Interval] != `NOP &&
                queue[find_min[0]][`Bra_Lock1_Interval] == `Reg_No_Lock &&
                queue[find_min[0]][`Bra_Lock2_Interval] == `Reg_No_Lock
            ) queue[find_min[0]] <= {`Bra_Bus_Width{1'b0}};
            if (bra_enable && queue[find_empty[0]][`Bra_Op_Interval] == `NOP) begin
                queue[find_empty[0]] <= bra_bus;
            end
        end
    end

    always @ (*) begin
        cdb_out_valid <= 0;
        if (queue[find_min[0]][`Bra_Op_Interval] != `NOP &&
            queue[find_min[0]][`Bra_Lock1_Interval] == `Reg_No_Lock &&
            queue[find_min[0]][`Bra_Lock2_Interval] == `Reg_No_Lock
        ) begin
            if (queue[find_min[0]][`Bra_Op_Interval] == `NOP ) begin
                cdb_out_valid <= 0;
            end else begin
                cdb_out_valid <= 1;
                cdb_out_index <= queue[find_min[0]][`Bra_Rdlock_Interval];
            end
            case (queue[find_min[0]][`Bra_Op_Interval])
                `BEQ  : cdb_out_result <= {{`Data_Width-2{1'b0}}, queue[find_min[0]][`Bra_Pre_Interval], (queue[find_min[0]][`Bra_Data1_Interval] == queue[find_min[0]][`Bra_Data2_Interval])};
                `BNE  : cdb_out_result <= {{`Data_Width-2{1'b0}}, queue[find_min[0]][`Bra_Pre_Interval], (queue[find_min[0]][`Bra_Data1_Interval] != queue[find_min[0]][`Bra_Data2_Interval])};
                `BLT  : cdb_out_result <= {{`Data_Width-2{1'b0}}, queue[find_min[0]][`Bra_Pre_Interval], ($signed(queue[find_min[0]][`Bra_Data1_Interval]) < $signed(queue[find_min[0]][`Bra_Data2_Interval]))};
                `BLTU : cdb_out_result <= {{`Data_Width-2{1'b0}}, queue[find_min[0]][`Bra_Pre_Interval], (queue[find_min[0]][`Bra_Data1_Interval] < queue[find_min[0]][`Bra_Data2_Interval])};
                `BGE  : cdb_out_result <= {{`Data_Width-2{1'b0}}, queue[find_min[0]][`Bra_Pre_Interval], ($signed(queue[find_min[0]][`Bra_Data1_Interval]) >= $signed(queue[find_min[0]][`Bra_Data2_Interval]))};
                `BGEU : cdb_out_result <= {{`Data_Width-2{1'b0}}, queue[find_min[0]][`Bra_Pre_Interval], (queue[find_min[0]][`Bra_Data1_Interval] >= queue[find_min[0]][`Bra_Data2_Interval])};
                default: ;
            endcase
        end
    end

endmodule
