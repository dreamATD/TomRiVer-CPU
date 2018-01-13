`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/01/13 13:31:58
// Design Name:
// Module Name: TransInfo
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

module TransInfo(
    input clk,
    input rst,

    // with InstCache
    input icache_read,
    input [`Addr_Width-1:0] icache_addr,
    output reg icache_valid,
    output reg [`Inst_Width-1:0] icache_inst,
    // with DataCache
    input [1:0] dcache_rw_flag,
    input [`Addr_Width-1:0] dcache_addr,
    output reg dcache_read_valid,
    output reg [`Data_Width-1:0] dcache_read_data,
    input [`Data_Width-1:0] dcache_write_data,
    input [3:0] dcache_write_mask,
    output reg dcache_write_valid,
    // with Uart
    output reg send_flag,
	output reg [7:0] send_data,
	output reg recv_flag,
	input [7:0] recv_data,

	input sendable,
	input receivable
);
    localparam  NOPT = 3;
    localparam  ICACHE = 0;
    localparam  DCACHE_READ = 1;
    localparam  DCACHE_WRITE = 2;
    localparam  READ_BYTE = 5;
    localparam  WRITE_BYTE = 9;
    localparam  READ_WIDTH = READ_BYTE * 8;
    localparam  WRITE_WIDTH = WRITE_BYTE * 8;
    localparam  STATE_READY = 0;
    localparam  STATE_READ = 1;
    localparam  STATE_WRITE = 3;
    localparam  STATE_WIDTH = 2;

    reg [READ_WIDTH-1:0] read_send;
    reg [WRITE_WIDTH-1:0] write_send;
    reg [STATE_WIDTH-1:0] state;
    reg [3:0] gen_counter;
    reg [1:0] read_counter;
    reg [`Data_Width-1:0] tmp_data;
    reg [1:0] current_opt;

    reg read_buffer_in, read_buffer_out;
    reg read_buffer_in_data;
    wire read_buffer_out_data;
    wire read_buffer_empty, read_buffer_full;

    reg send_buffer_in, send_buffer_out;
    reg [7:0] send_buffer_in_data;
    wire [7:0] send_buffer_out_data;
    wire send_buffer_empty, send_buffer_full;

    fifo #(.WIDTH(1)) read_buffer (
        .CLK (clk),
    	.RST (rst),
    	.read_flag (read_buffer_out),
    	.read_data (read_buffer_out_data),
    	.write_flag (read_buffer_in),
    	.write_data (read_buffer_in_data),
    	.empty (read_buffer_empty),
    	.full (read_buffer_full)
    );

    fifo send_buffer (
        .CLK (clk),
    	.RST (rst),
    	.read_flag (send_buffer_out),
    	.read_data (send_buffer_out_data),
    	.write_flag (send_buffer_in),
    	.write_data (send_buffer_in_data),
    	.empty (send_buffer_empty),
    	.full (send_buffer_full)
    );

    always @ (*) begin
        current_opt <= NOPT;
        if (icache_read) current_opt <= ICACHE;
        else begin
            case (1'b1)
                dcache_rw_flag[1]: current_opt <= DCACHE_READ;
                dcache_rw_flag[0]: current_opt <= DCACHE_WRITE;
            endcase
        end
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            send_flag <= 0;
            recv_flag <= 0;
            icache_valid <= 0;
            dcache_read_valid <= 0;
            dcache_write_valid <= 0;
            gen_counter <= 0;
            send_buffer_in <= 0;
            read_buffer_in <= 0;
            send_buffer_out <= 0;
            read_buffer_out <= 0;
            read_counter <= 0;
        end else begin
            send_flag <= 0;
            recv_flag <= 0;
            send_buffer_in <= 0;
            read_buffer_in <= 0;
            send_buffer_out <= 0;
            read_buffer_out <= 0;
            dcache_write_valid <= 0;
            icache_valid <= 0;
            dcache_read_valid <= 0;
            case (state)
                STATE_READY : begin
                    case (current_opt)
                        ICACHE: begin
                            if (!read_buffer_full) begin
                                gen_counter <= 0;
                                read_send <= {icache_addr, 8'h1};
                                read_buffer_in <= 1;
                                read_buffer_in_data <= current_opt;
                                state <= STATE_READ;
                            end
                        end
                        DCACHE_READ: begin
                            if (!read_buffer_full) begin
                                gen_counter <= 0;
                                read_send <= {dcache_addr, 8'h5};
                                read_buffer_in <= 1;
                                read_buffer_in_data <= current_opt;
                                state <= STATE_READ;
                            end
                        end
                        DCACHE_WRITE: begin
                            gen_counter <= 0;
                            write_send <= {dcache_write_data, dcache_addr, dcache_write_mask, 4'h9};
                            state <= STATE_WRITE;
                        end
                    endcase
                end
                STATE_READ: begin
                    if (!send_buffer_full) begin
                        send_buffer_in <= 1;
                        send_buffer_in_data <= read_send[7:0];
                        read_send <= read_send >> 8;
                        gen_counter <= gen_counter + 1;
                        if (gen_counter == READ_BYTE - 1)
                            state <= STATE_READY;
                    end
                end
                STATE_WRITE: begin
                    if (!send_buffer_full) begin
                        send_buffer_in <= 1;
                        send_buffer_in_data <= write_send[7:0];
                        write_send <= write_send >> 8;
                        gen_counter <= gen_counter + 1;
                        if (gen_counter == WRITE_BYTE - 1) begin
                            dcache_write_valid <= 1;
                            state <= STATE_READY;
                        end
                    end
                end
            endcase

            if (sendable) begin
                send_buffer_out <= 1;
                send_flag <= 1;
            	send_data <= send_buffer_out_data;
            end
            if (receivable) begin
                recv_flag <= 1;
                tmp_data = {recv_data, tmp_data[7:0]};
                read_counter <= read_counter + 1;
                if (read_counter == 0 && !read_buffer_empty) begin
                    read_buffer_out <= 1;
                    case (read_buffer_out_data)
                        ICACHE: begin
                            icache_valid <= 1;
                            icache_inst <= tmp_data;
                        end
                        default: begin
                            dcache_read_valid <= 1;
                            dcache_read_data <= tmp_data;
                        end
                    endcase
                end
            end
        end
    end
endmodule
