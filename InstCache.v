`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:22:55
// Design Name:
// Module Name: InstCache
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
module InstCache #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 32,
    parameter BLOCK_OFFSET_WIDTH = 6,
    parameter BLOCK_SIZE = 64,
    parameter INDEX_WIDTH = 7,
    parameter TAG_WIDTH = ADDRESS_WIDTH - INDEX_WIDTH - BLOCK_OFFSET_WIDTH
)(
    input clk,
    input rst,
    // with Staller
    input stall,
    output o_ready,
    // with PC
    input i_ce,
    input [ADDRESS_WIDTH-1 : 0] i_address,
    // with Memory
    output reg o_mem_valid,
    output reg [ADDRESS_WIDTH-1 : 0] o_mem_address,
    input i_mem_valid,
    output [DATA_WIDTH-1 : 0] i_mem_data,
    // with Decoder
    output reg o_valid,
    output reg [`Inst_Addr_Width-1:0] o_data_addr,
    output reg [DATA_WIDTH-1 : 0] o_data
);
    localparam  STATE_READY = 0;
    localparam  STATE_MISS_READ = 1;
    localparam ASSOCIATIVITY = 2;
    localparam ASSOCIATIVITY_WIDTH = 1;
    localparam  TRUE = 1'b1;
    localparam  FALSE = 1'b0;

    wire i_valid;

    reg [(BLOCK_OFFSET_WIDTH - 2)-1 : 0] r_i_blockoffset;
    reg [INDEX_WIDTH-1        : 0] r_i_index;
    reg [TAG_WIDTH-1          : 0] r_i_tag;

    wire [(BLOCK_OFFSET_WIDTH - 2)-1 : 0] i_blockoffset;
    wire [INDEX_WIDTH-1        : 0] i_index;
    wire [TAG_WIDTH-1:0] i_tag;

    reg [TAG_WIDTH-1      : 0] tag_array[(1 << INDEX_WIDTH) - 1 : 0][ASSOCIATIVITY-1:0];
    reg [DATA_WIDTH-1 : 0] data_array0[(1 << INDEX_WIDTH) - 1: 0][(BLOCK_SIZE >> 2) - 1: 0];
    reg [DATA_WIDTH-1 : 0] data_array1[(1 << INDEX_WIDTH) - 1: 0][(BLOCK_SIZE >> 2) - 1: 0];
    reg valid_array[(1 << INDEX_WIDTH) - 1: 0][ASSOCIATIVITY-1:0];

    reg [5 : 0] state;
    reg [5 : 0] next_state;

    integer i;
    integer a;
    reg [BLOCK_OFFSET_WIDTH-3 : 0] gen_count;

    reg location;
    reg r_location;

    assign i_valid = i_ce && !stall;

    assign i_blockoffset = i_address[BLOCK_OFFSET_WIDTH-1:2];
    assign i_index = i_address[INDEX_WIDTH + BLOCK_OFFSET_WIDTH-1:BLOCK_OFFSET_WIDTH];
    assign i_tag = i_address[TAG_WIDTH+INDEX_WIDTH+BLOCK_OFFSET_WIDTH-1:INDEX_WIDTH + BLOCK_OFFSET_WIDTH];

    always @ (*) begin
        location <= 0;
        for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
            if (tag_array[i_index][i] == i_tag) location <= i;
        end
    end

    assign o_ready = state == STATE_READY;

    always @ (*) begin
        next_state    <= state;
        o_valid       <= FALSE;
        o_data        <= {DATA_WIDTH{1'bx}};
        o_mem_valid   <= FALSE;
        o_mem_address <= {TAG_WIDTH+INDEX_WIDTH+BLOCK_OFFSET_WIDTH{1'bx}};
        case (state)
            STATE_READY: begin
                if (i_valid) begin
                    if (valid_array[i_index][location] && tag_array[i_index][location] == i_tag) begin
                        o_valid <= TRUE;
                        o_data_addr <= i_address;
                        case (location)
                            0: o_data <= data_array0[i_index][i_blockoffset];
                            1: o_data <= data_array1[i_index][i_blockoffset];
                        endcase
                    end else begin
                        next_state <= STATE_MISS_READ;
                    end
                end else begin
                    // Invalid output
                end
            end
            STATE_MISS_READ: begin
                o_mem_valid   <= TRUE;
                o_mem_address <= {r_i_tag, r_i_index, gen_count, 2'b00};
                if (i_mem_valid) begin
                    if (gen_count == r_i_blockoffset) begin
                        o_valid <= TRUE;
                        o_data  <= i_mem_data;
                    end
                    if (gen_count + 1 == (BLOCK_SIZE >> 2) || !(i_mem_data[1:0] === 2'b11)) begin
                        next_state <= STATE_READY;
                    end
                end
            end
            default : begin
            end
        endcase
    end

    always @ (posedge clk) begin
        if (rst) begin
            state <= STATE_READY;
            next_state <= STATE_READY;
            for (i = 0; i < (1 << INDEX_WIDTH); i = i + 1) begin
                for (a = 0; a < ASSOCIATIVITY; a = a + 1) begin
                    valid_array[i][a] <= FALSE;
                end
            end
        end else begin
            state <= next_state;
            case (state)
                STATE_READY: begin
                    if (next_state == STATE_MISS_READ) begin
                        gen_count       <= 0;
                        r_i_blockoffset <= i_blockoffset;
                        r_i_index       <= i_index;
                        r_i_tag         <= i_tag;
                        r_location      <= location;
                        o_data_addr     <= i_address;
                        valid_array[i_index][location] <= 0;
                    end
                end
                STATE_MISS_READ: begin
                    if (next_state == STATE_READY) begin
                        tag_array[r_i_index][r_location] <= r_i_tag;
                        valid_array[r_i_index][r_location] <= TRUE;
                    end
                    if (i_mem_valid  && i_mem_data[1:0] === 2'b11) begin
                        case (location)
                            0: data_array0[i_index][gen_count] <= i_mem_data;
                            1: data_array1[i_index][gen_count] <= i_mem_data;
                        endcase
                        gen_count <= gen_count + 1;
                    end
                end
                default : ;
            endcase
        end
    end
endmodule
