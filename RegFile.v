`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:22:55
// Design Name:
// Module Name: RegFile
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
module RegFile (
    input clk,
    input rst,
    // with ROB
    input ROB_we,
    input [`Reg_Width-1       : 0] namew,
    input [`Data_Width-1      : 0] dataw,
    input [`ROB_Entry_Width-1 : 0] entryw,
    // with Decoder
    input re1,
    input [`Reg_Width-1           : 0] name1,
    output reg [`Reg_Lock_Width-1 : 0] lock1,
    output reg [`Data_Width-1     : 0] data1,
    input re2,
    input [`Reg_Width-1           : 0] name2,
    output reg [`Reg_Lock_Width-1 : 0] lock2,
    output reg [`Data_Width-1     : 0] data2,
    input dec_we,
    input [`Reg_Bus_Width-1 : 0] dec_bus
);

    reg [`Data_Width-1     : 0] dat[`Reg_Cnt-1 : 0];
    reg [`Reg_Lock_Width-1 : 0] loc[`Reg_Cnt-1 : 0];
    reg val[`Reg_Cnt-1 : 0];

    integer i;
    always @ (posedge rst) begin
        dat[0] <= 0;
        for (i = 0; i < `Reg_Cnt; i = i + 1) begin
            loc[i] <= `Reg_No_Lock;
            val[i] <= i == 0 ? 1 : 0;
        end
    end

    always @ (posedge clk) begin
        if (ROB_we && namew) begin
                dat[namew] <= dataw;
                val[namew] <= 1;
                if (loc[namew] == {1'b0, entryw} && (!dec_we || dec_we && dec_bus[`Reg_Name_Interval] != namew)) begin
                    $display("preg_name: %b, reg_lock: %b\n", dec_bus[`Reg_Name_Interval], {1'b0, dec_bus[`Reg_Entry_Interval]});
                    loc[namew] <= `Reg_No_Lock;
                end
        end
        if (dec_we && dec_bus[`Reg_Name_Interval]) begin
            $display("reg_name: %b, reg_lock: %b\n", dec_bus[`Reg_Name_Interval], {1'b0, dec_bus[`Reg_Entry_Interval]});
            loc[dec_bus[`Reg_Name_Interval]] <= {1'b0, dec_bus[`Reg_Entry_Interval]};
        end
    end

    always @ (*) begin
        if (re1) begin
            if (ROB_we && namew == name1) begin
                data1 <= dataw;
                lock1 <= entryw;
            end else begin
                lock1 <= loc[name1];
                data1 <= dat[name1];
            end
        end else begin
            lock1 <= `Reg_No_Lock;
            data1 <= 0;
        end

        if (re2) begin
            if (ROB_we && namew == name2) begin
                data2 <= dataw;
                lock2 <= entryw;
            end else begin
                lock2 <= loc[name2];
                data2 <= dat[name2];
            end
        end else begin
            lock2 <= `Reg_No_Lock;
            data2 <= 0;
        end
    end
endmodule
