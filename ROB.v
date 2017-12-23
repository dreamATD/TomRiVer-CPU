`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:25:26
// Design Name:
// Module Name: ROB
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
module ROB(
    input clk,
    input rst,

    // with Decoder
    output fifo_full,
    output [`ROB_Entry_Width-1 : 0] out_lock,
    input write,
    input [`ROB_Bus_Width-1   : 0] fifo_in,

    input check1,
    input [`ROB_Entry_Width-1 : 0] check_entry1,
    output [`Data_Width-1     : 0] check_value1,
    output check_value_enable1,
    input check2,
    input [`ROB_Entry_Width-1 : 0] check_entry2,
    output [`Data_Width-1     : 0] check_value2,
    output check_value_enable2,

    // with RegFile
    output reg reg_modify,
    output reg [`Reg_Width-1  : 0] reg_name,
    output reg [`Data_Width-1 : 0] reg_data,
    output reg [`ROB_Entry_Width-1 : 0] reg_entry,
    /*
    // with DataCache
    output reg mem_modify,
    output reg [`Addr_Width-1 : 0] mem_addr,
    output reg [`Data_Width-1 : 0] mem_data,
    */
    // with CDB
    input cdb_write,
    input [`ROB_Entry_Width-1 : 0] cdb_in_entry,
    input [`Data_Width-1      : 0] cdb_in_value
);
    localparam  DATA_WIDTH = `ROB_Bus_Width;
    localparam  ENTRY_NUMBER = 8;
    localparam  ENTRY_WIDTH = 3;

    localparam  Empty_OP    = 2'd0;
    localparam  Branch      = 2'd1;
    localparam  Store       = 2'd2;
    localparam  Normal_Op   = 2'd3;

    reg [DATA_WIDTH-1  : 0] ram [ENTRY_NUMBER-1:0];
    reg [ENTRY_WIDTH-1 : 0] read_ptr, write_ptr, counter;
    wire read_enable;

    assign fifo_full = (counter == ENTRY_NUMBER);
    assign out_lock = write_ptr;

    assign read_enable = (
        counter != 0 && ram[read_ptr][0] ||
        counter == 0 && write && fifo_in[0]
    ) ? 1 : 0;


    assign check_value1 = check1 ? ram[check_entry1][`Data_Width:1] : 0;
    assign check_value_enable1 = check1 ? ram[check_entry1][0] : 0;
    assign check_value2 = check2 ? ram[check_entry2][`Data_Width:1] : 0;
    assign check_value_enable2 = check2 ? ram[check_entry2][0] : 0;

    always @ (posedge clk) begin
        if(rst) begin
            read_ptr   <= 0;
            write_ptr  <= 0;
            counter    <= 0;
            reg_modify <= 0;
        end
        else begin
            case ({read_enable, write})
                2'b00: counter <= counter;
                2'b01: begin
                    ram[write_ptr] <= fifo_in;
                    counter        <= counter + 1;
                    write_ptr      <= write_ptr + 1;
                end
                2'b10: begin
                    counter  <= counter-1;
                    ram[read_ptr] <= 0;
                    read_ptr <= read_ptr + 1;
                end
                2'b11: begin
                    if (counter == 0)
                        read_ptr <= read_ptr;
                    else begin
                        ram[write_ptr] <= fifo_in;
                        write_ptr <= write_ptr + 1;
                        ram[read_ptr] <= 0;
                        read_ptr  <= read_ptr + 1;
                    end
                end
            endcase
        end
    end

    always @ (*) begin
        if (ram[read_ptr][`ROB_Valid_Interval])
            case (ram[read_ptr][`ROB_Op_Interval])
                Normal_Op: begin
                    reg_modify <= 1;
                    //mem_modify <= 0;
                    reg_name   <= ram[read_ptr][`ROB_Reg_Interval];
                    reg_data   <= ram[read_ptr][`ROB_Value_Interval];
                    reg_entry  <= read_ptr;
                end/*
                Store: begin
                    reg_modify <= 0;
                    mem_modify <= 1;
                    mem_addr   <= fifo_out[1+`Data_Width+`Addr_Width-1:1+`Data_Width];
                    mem_data   <= fifo_out[1+`Data_Width-1:1];
                end*/
                default: begin
                    reg_modify <= 0;
                    //mem_modify <= 0;
                end
            endcase
        else reg_modify <= 0;
    end

    integer i;
    always @ (*) begin
        if (cdb_write) begin
            ram[cdb_in_entry][`ROB_Valid_Interval] <= 1;
            ram[cdb_in_entry][`ROB_Value_Interval] <= cdb_in_value;
        end
    end
endmodule
