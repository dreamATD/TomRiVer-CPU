`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:25:26
// Design Name:
// Module Name: ALU
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
module ALU (
    input clk,
    input rst,
    // with Staller
    output alu_stall,
    // with Decoder
    input alu_enable,
    input [`Alu_Bus_Width-1   : 0] alu_bus,
    // with CDB
    input [`Reg_Lock_Width-1 : 0] cdb_in_index,
    input [`Data_Width-1     : 0] cdb_in_result,
    input grnt,

    output reg cdb_out_valid,
    output reg [`Reg_Lock_Width-1  : 0] cdb_out_index,
    output reg [`Data_Width-1      : 0] cdb_out_result
);

    localparam  Alu_Queue_Entry         = 4;
    localparam  Alu_Queue_Width         = 2;
    reg [`Alu_Bus_Width-1:0] queue[Alu_Queue_Entry-1:0];

    integer i;
    always @ (*) begin
        for (i = 0; i < Alu_Queue_Entry; i = i + 1) begin
            if (queue[i][`Alu_Op_Interval] != `NOP && cdb_in_index != `Reg_No_Lock && queue[i][`Alu_Lock1_Interval] == cdb_in_index) begin
                queue[i][`Alu_Lock1_Interval] <= `Reg_No_Lock;
                queue[i][`Alu_Data1_Interval] <= cdb_in_result;
            end
            if (queue[i][`Alu_Op_Interval] != `NOP && cdb_in_index != `Reg_No_Lock && queue[i][`Alu_Lock2_Interval] == cdb_in_index) begin
                queue[i][`Alu_Lock2_Interval] <= `Reg_No_Lock;
                queue[i][`Alu_Data2_Interval] <= cdb_in_result;
            end
        end
    end

    wire [Alu_Queue_Width-1:0] find_min[Alu_Queue_Entry-2:0];
    wire [Alu_Queue_Width-1:0] find_empty[Alu_Queue_Entry-2:0];

    genvar j;
    generate
        for (j = Alu_Queue_Entry - 1 - (Alu_Queue_Entry >> 1); j < Alu_Queue_Entry - 1; j = j + 1) begin
            assign find_min[j] = (
                queue[(j << 1) + 2 - Alu_Queue_Entry][`Alu_Op_Interval] != `NOP &&
                queue[(j << 1) + 2 - Alu_Queue_Entry][`Alu_Lock1_Interval] == `Reg_No_Lock &&
                queue[(j << 1) + 2 - Alu_Queue_Entry][`Alu_Lock2_Interval] == `Reg_No_Lock
            )  ? ((j << 1) + 2 - Alu_Queue_Entry) : ((j << 1) + 3 - Alu_Queue_Entry);
            assign find_empty[j] = queue[(j << 1) + 2 - Alu_Queue_Entry][`Alu_Op_Interval] == `NOP ? (j << 1) + 2 - Alu_Queue_Entry : (j << 1) + 3 - Alu_Queue_Entry;
        end
        for (j = 0; j < Alu_Queue_Entry - 1 - (Alu_Queue_Entry >> 1); j = j + 1) begin
            assign find_min[j] = (
                queue[find_min[(j << 1) + 1]][`Alu_Op_Interval] != `NOP &&
                queue[find_min[(j << 1) + 1]][`Alu_Lock1_Interval] == `Reg_No_Lock &&
                queue[find_min[(j << 1) + 1]][`Alu_Lock2_Interval] == `Reg_No_Lock
            ) ? find_min[(j << 1) + 1] : find_min[(j << 1) + 2];
            assign find_empty[j] = queue[find_empty[(j << 1) + 1]][`Alu_Op_Interval] == `NOP ? find_empty[(j << 1) + 1] : find_empty[(j << 1) + 2];
        end
    endgenerate

    assign alu_stall = queue[find_empty[0]][`Alu_Op_Interval] != `NOP;

    integer k;

    always @ (posedge clk) begin
        if (rst) begin
            for (k = 0; k < Alu_Queue_Entry; k = k + 1) begin
                queue[k] <= {`Alu_Bus_Width{1'b0}};
            end
            cdb_out_valid <= 0;
        end else begin
            if (grnt && queue[find_min[0]][`Alu_Op_Interval] != `NOP &&
                queue[find_min[0]][`Alu_Lock1_Interval] == `Reg_No_Lock &&
                queue[find_min[0]][`Alu_Lock2_Interval] == `Reg_No_Lock
            ) queue[find_min[0]] <= {`Alu_Bus_Width{1'b0}};
            if (alu_enable && queue[find_empty[0]][`Alu_Op_Interval] == `NOP) begin
                queue[find_empty[0]] <= alu_bus;
            end
        end
    end

    always @ (*) begin
        cdb_out_valid <= 0;
        if (queue[find_min[0]][`Alu_Op_Interval] != `NOP &&
            queue[find_min[0]][`Alu_Lock1_Interval] == `Reg_No_Lock &&
            queue[find_min[0]][`Alu_Lock2_Interval] == `Reg_No_Lock
        ) begin
            if (queue[find_min[0]][`Alu_Op_Interval] == `NOP ) begin
                cdb_out_valid <= 0;
            end else begin
                cdb_out_valid <= 1;
                cdb_out_index <= {1'b0, queue[find_min[0]][`Alu_Rdlock_Interval]};
            end
            case (queue[find_min[0]][`Alu_Op_Interval])
                `ADD  : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) + $signed(queue[find_min[0]][`Alu_Data2_Interval]);
                `SUB  : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) - $signed(queue[find_min[0]][`Alu_Data2_Interval]);
                `SLT  : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) < $signed(queue[find_min[0]][`Alu_Data2_Interval]) ? 1 : 0;
                `SLTU : cdb_out_result <=        (queue[find_min[0]][`Alu_Data1_Interval]) <        (queue[find_min[0]][`Alu_Data2_Interval]) ? 1 : 0;
                `XOR  : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) ^ $signed(queue[find_min[0]][`Alu_Data2_Interval]);
                `OR   : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) | $signed(queue[find_min[0]][`Alu_Data2_Interval]);
                `AND  : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) & $signed(queue[find_min[0]][`Alu_Data2_Interval]);
                `SLL  : cdb_out_result <=        (queue[find_min[0]][`Alu_Data1_Interval]) <<       (queue[find_min[0]][`Alu_Data2_Low5]);
                `SRL  : cdb_out_result <=        (queue[find_min[0]][`Alu_Data1_Interval]) >>       (queue[find_min[0]][`Alu_Data2_Low5]);
                `SRA  : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) >>>      (queue[find_min[0]][`Alu_Data2_Low5]);
                `AUIPC: cdb_out_result <=        (queue[find_min[0]][`Alu_Data1_Interval]) + $signed(queue[find_min[0]][`Alu_Data2_Interval]);
                `JAL  : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) + $signed(queue[find_min[0]][`Alu_Data2_Interval]);
                `JALR : cdb_out_result <= $signed(queue[find_min[0]][`Alu_Data1_Interval]) + $signed(queue[find_min[0]][`Alu_Data2_Interval]) & 32'hfffffffe;
                default: ;
            endcase
        end
    end

endmodule
