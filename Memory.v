`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/01/04 22:34:05
// Design Name:
// Module Name: memory
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


module InstMemory(
    input read,
    input [`Inst_Addr_Width-1 : 0] addr,
    output reg inst_valid,
    output reg [`Inst_Width-1 : 0] inst
);
    reg [`Inst_Width-1 : 0] inst_mem[0:128];

    initial $readmemh ("E:/dreamATD/homework/TomRiVer-CPU-master/TomRiVer-CPU/TomRiVer-CPU.srcs/sources_1/new/test11.data", inst_mem);

    always @ (*) begin
        $display ("mark: InstMemory0");
        if (read) begin
            inst_valid <= 1;
            inst <= {inst_mem[addr[`Inst_Addr_Width-1:2]][7:0], inst_mem[addr[`Inst_Addr_Width-1:2]][15:8], inst_mem[addr[`Inst_Addr_Width-1:2]][23:16], inst_mem[addr[`Inst_Addr_Width-1:2]][31:24]};
        end else begin
            inst_valid <= 0;
            inst       <= 0;
        end
    end
endmodule

module DataMemory(
    input clk,
    input rst,

    output free,
    output reg read_valid,
    input [`Data_Width-1:0] i_data,
    input [1:0] rw_flag,
    input [`Addr_Width-1:0] addr,
    output reg [`Data_Width-1:0] o_data,
    input [3:0] i_mask
);
    reg [`Data_Width-1 : 0] data_mem[0:128];

    initial $readmemh ("E:/dreamATD/homework/myCPU/myCPU.srcs/sources_1/new/data.txt", data_mem);

    localparam  STATE_WIDTH = 3;
    localparam  STATE_READY = 3'd1;
    localparam  STATE_READ = 3'd2;
    localparam  STATE_WRITE = 3'd3;

    reg [1:0] delay;
    reg [STATE_WIDTH-1:0] state, next_state;

    assign free = (state == STATE_READY);

    task modifyData;
        input [3:0] mask;
        input [`Addr_Width-1:0] addr;
        input [`Data_Width-1:0] data;
        begin
            if (mask[0]) data_mem[addr>>2][7:0] <= data[7:0];
            if (mask[1]) data_mem[addr>>2][15:8] <= data[15:8];
            if (mask[2]) data_mem[addr>>2][23:16] <= data[23:16];
            if (mask[3]) data_mem[addr>>2][31:24] <= data[31:24];
        end
    endtask

    always @ (posedge clk) begin
        if (rst) begin
            read_valid <= 0;
            delay      <= 0;
            state <= STATE_READY;
            next_state <= STATE_READY;
        end else begin
            read_valid <= 0;
            case (state)
                STATE_READY: begin
                    delay <= 0;
                    case (1'b1)
                        rw_flag[1]: begin
                            delay <= 1;
                            state <= STATE_READ;
                        end
                        rw_flag[0]: begin
                            delay <= 1;
                            state <= STATE_WRITE;
                        end
                    endcase
                end
                STATE_READ: begin
                    case (delay)
                        0 : begin
                            state      <= STATE_READY;
                            read_valid <= 1;
                            o_data       <= data_mem[addr>>2];
                        end
                        default : begin
                            delay <= delay - 1;
                        end
                    endcase
                end
                STATE_WRITE: begin
                    case (delay)
                        0 : begin
                            state          <= STATE_READY;
                            modifyData (i_mask, addr, i_data);
                        end
                        default : begin
                            delay <= delay - 1;
                        end
                    endcase
                end
                default : ;
            endcase
        end
    end
endmodule
