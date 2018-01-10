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
    // with Staller
    output fifo_stall,
    output store_stall,
    // with Decoder
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
    // with DataCache
    output reg dcache_write,
    output reg [3:0] dcache_mask,
    output reg [`Addr_Width-1 : 0] dcache_addr,
    output reg [`Data_Width-1 : 0] dcache_data,
    input dcache_write_valid,
    // with CDB
    input cdb_write_alu,
    input [`ROB_Entry_Width-1 : 0] cdb_in_entry_alu,
    input [`Data_Width-1      : 0] cdb_in_value_alu,
    input cdb_write_lsm,
    input [`ROB_Entry_Width-1 : 0] cdb_in_entry_lsm,
    input [`Data_Width-1      : 0] cdb_in_value_lsm,
    input [`Addr_Width-1      : 0] cdb_in_addr_lsm,
    // with Branch_ALU
    input bra_write,
    input [`ROB_Entry_Width-1 : 0] bra_in_entry,
    input [1                  : 0] bra_in_value,
    // with PC
    output reg pc_modify,
    output reg [`Inst_Addr_Width-1   : 0] npc,
    // with Branch_Predictor
    output reg brp_update,
    output reg [`Bra_Addr_Width-1    : 0] brp_addr,
    output reg brp_result
);
    localparam  DATA_WIDTH = `ROB_Bus_Width;
    localparam  ENTRY_NUMBER = 8;
    localparam  ENTRY_WIDTH = 3;

    localparam  Empty_OP    = 3'd0;
    localparam  Branch      = 3'd1;
    localparam  Normal_Op   = 3'd2;
    localparam  S_byte      = 3'd3;
    localparam  S_half      = 3'd4;
    localparam  S_word      = 3'd5;

    reg [DATA_WIDTH-1  : 0] ram [ENTRY_NUMBER-1:0];
    reg [ENTRY_WIDTH-1 : 0] read_ptr, write_ptr;
    reg [ENTRY_WIDTH : 0] counter;
    wire read_enable, fifo_full;
    reg write_enable;
    wire [`ROB_Bus_Width-1   : 0] read_out;

    assign read_out = ram[read_ptr];

    assign fifo_stall = (counter >= ENTRY_NUMBER - 1);
    assign fifo_full = (counter == ENTRY_NUMBER);
    assign out_lock = write_ptr;

    assign read_enable = counter != 0 && ( ram[read_ptr][0] &&
         (ram[read_ptr][`ROB_Op_Interval] < S_byte || ram[read_ptr][`ROB_Op_Interval] >= S_byte && dcache_write_valid)
    ) ? 1 : 0;

    assign store_stall = !(counter && read_out[`ROB_Op_Interval] >= S_byte && dcache_write_valid);

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
            case ({read_enable, write_enable})
                2'b00: counter <= counter;
                2'b01: begin
                    ram[write_ptr] <= fifo_in;
                    counter        <= counter + 1;
                    write_ptr      <= write_ptr + 1;
                end
                2'b10: begin
                    counter  <= counter-1;
                    ram[read_ptr] <= {(`ROB_Bus_Width){1'b0}};
                    read_ptr <= read_ptr + 1;
                end
                2'b11: begin
                    if (counter == 0)
                        read_ptr <= read_ptr;
                    else begin
                        ram[write_ptr] <= fifo_in;
                        write_ptr <= write_ptr + 1;
                        ram[read_ptr] <= {(`ROB_Bus_Width){1'b0}};
                        read_ptr  <= read_ptr + 1;
                    end
                end
            endcase
        end
    end

    task getMask;
        input [`ROB_Op_Width-1:0] op;
        input [1:0] suf_addr;
        input [`Data_Width-1:0] i_data;
        begin
            case ({op, suf_addr})
                {S_byte, 2'b00}: begin
                    dcache_mask <= 4'b0001;
                    dcache_data <= i_data;
                end
                {S_byte, 2'b01}: begin
                    dcache_mask <= 4'b0010;
                    dcache_data <= i_data << 8;
                end
                {S_byte, 2'b10}: begin
                    dcache_mask <= 4'b0100;
                    dcache_data <= i_data << 16;
                end
                {S_byte, 2'b11}: begin
                    dcache_mask <= 4'b1000;
                    dcache_data <= i_data << 24;
                end
                {S_half, 2'b00}: begin
                    dcache_mask <= 4'b0011;
                    dcache_data <= i_data;
                end
                {S_half, 2'b10}: begin
                    dcache_mask <= 4'b1100;
                    dcache_data <= i_data << 16;
                end
                {S_word, 2'b00}: begin
                    dcache_mask <= 4'b1111;
                    dcache_data <= i_data;
                end
                default : $display ("Address misaligned!");
            endcase
        end
    endtask

    always @ (*) begin
        $display ("mark: rob");
        reg_modify   <= 0;
        pc_modify    <= 0;
        brp_update   <= 0;
        write_enable <= write && !fifo_full;
        dcache_write <= 0;
        if (counter &&  ram[read_ptr][0] && read_out[`ROB_Valid_Interval]) begin
            case (read_out[`ROB_Op_Interval])
                Normal_Op: begin
                    reg_modify <= 1;
                    reg_name   <= read_out[`ROB_Reg_Interval];
                    reg_data   <= read_out[`ROB_Value_Interval];
                    reg_entry  <= read_ptr;
                end
                Branch: begin
                    if (read_out[`ROB_Branch_Interval] == 2'b10 || read_out[`ROB_Branch_Interval] == 2'b01) begin
                    $display ("readout: %h, %b", read_out, read_out[`ROB_Branch_Interval]);
                        write_enable <= 0;
                        write_ptr    <= read_ptr + 1;
                        counter      <= 1;
                        pc_modify    <= 1;
                        npc          <= read_out[`ROB_Ins_Interval];
                    end
                    brp_update <= 1;
                    brp_addr <= read_out[`ROB_Baddr_Interval];
                    brp_result <= read_out[1];
                end
                // store
                default: begin
                    dcache_write <= 1;
                    getMask(read_out[`ROB_Op_Interval], read_out[`ROB_Mem_Suf_Interval],
                                read_out[`ROB_Value_Interval]);
                    dcache_addr <= read_out[`ROB_Mem_Interval] & `Addr_Mask;
                end
            endcase
        end
    end

    always @ (negedge clk) begin
        if (cdb_write_alu && !ram[cdb_in_entry_alu][`ROB_Valid_Interval]) begin
            ram[cdb_in_entry_alu][`ROB_Value_Interval] <= cdb_in_value_alu;
            ram[cdb_in_entry_alu][`ROB_Valid_Interval] <= 1;
            $display ("wrong");
        end
        if (cdb_write_lsm && !ram[cdb_in_entry_lsm][`ROB_Valid_Interval]) begin
            ram[cdb_in_entry_lsm][`ROB_Value_Interval] <= cdb_in_value_lsm;
            ram[cdb_in_entry_lsm][`ROB_Valid_Interval] <= 1;
        end
        if (cdb_write_lsm && !ram[cdb_in_entry_lsm][`ROB_Valid_Interval] && ram[cdb_in_entry_lsm][`ROB_Op_Interval] >= S_byte) begin
            ram[cdb_in_entry_lsm][`ROB_Mem_Interval] <= cdb_in_addr_lsm;
        end
        if (bra_write && !ram[bra_in_entry][`ROB_Valid_Interval]) begin
            ram[bra_in_entry][`ROB_Branch_Interval] <= bra_in_value;
            ram[bra_in_entry][`ROB_Valid_Interval]  <= 1;
        end
    end
endmodule
