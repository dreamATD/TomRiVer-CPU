`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/17 16:22:55
// Design Name:
// Module Name: LoadStore
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
module LoadStore(
    input clk,
    input rst,
    // with Decoder
    input lsm_write,
    input [`Lsm_Bus_Width-1 : 0] lsm_bus,
    // with CDB
    input [`Reg_Lock_Width-1 : 0] cdb_in_index_alu,
    input [`Data_Width-1     : 0] cdb_in_data_alu,
    input [`Reg_Lock_Width-1 : 0] cdb_in_index_lsm,
    input [`Data_Width-1     : 0] cdb_in_data_lsm,
    output reg cdb_out_valid,
    output reg [`Reg_Lock_Width-1 : 0] cdb_out_index,
    output reg [`Data_Width-1      : 0] cdb_out_data,
    output reg [`Addr_Width-1      : 0] cdb_out_addr,
    // with Staller
    output buffer_stall,
    input rob_stall,
    // with DataCache
    output reg dcache_prefetch,
    output reg [`Addr_Width-1 : 0]  dcache_pre_addr,
    output reg dcache_read,
    output reg [`Addr_Width-1 : 0] dcache_read_addr,
    input  dcache_read_done,
    input  [`Data_Width-1 : 0] dcache_read_data
);
    localparam  Lsm_Queue_Entry         = 4;
    localparam  Lsm_Queue_Width         = 2;
    reg [`Lsm_Bus_Width-1   : 0] buffer[Lsm_Queue_Entry-1:0];
    reg [`Simp_Op_Width-1   : 0] queue_op[Lsm_Queue_Entry-1:0];
    reg [`ROB_Entry_Width-1 : 0] queue_aim[Lsm_Queue_Entry-1:0];
    reg [`Addr_Width-1      : 0] queue_addr[Lsm_Queue_Entry-1:0];
    reg [`Reg_Lock_Width-1  : 0] queue_lock[Lsm_Queue_Entry-1:0];
    reg [`Data_Width-1      : 0] queue_data[Lsm_Queue_Entry-1:0];
    reg [Lsm_Queue_Width-1  : 0] qread_ptr, qwrite_ptr, bread_ptr, bwrite_ptr;
    reg [Lsm_Queue_Width  : 0] bcounter, qcounter;

    wire buf_que;
    wire [`Simp_Op_Width-1   : 0] trans_op;
    wire [`ROB_Entry_Width-1 : 0] trans_aim;
    wire [`Addr_Width-1      : 0] trans_addr;
    wire [`Reg_Lock_Width-1  : 0] trans_lock;
    wire [`Data_Width-1      : 0] trans_data;

    wire out_op;
    wire [`Simp_Op_Width-1:0] out_op2;
    wire [`ROB_Entry_Width-1 : 0] out_aim;
    wire [`Addr_Width-1      : 0] out_addr;
    wire [`Reg_Lock_Width-1  : 0] out_lock;
    wire [`Data_Width-1      : 0] out_data;

    integer i;
    always @ (*) begin
        $display ("mark:loadStore2");
        for (i = 0; i < Lsm_Queue_Entry; i = i + 1) begin
            if (buffer[i][`Lsm_Op_Interval] != `NOP && cdb_in_index_alu != `Reg_No_Lock && cdb_in_index_alu == buffer[i][`Lsm_Lock1_Interval]) begin
                buffer[i][`Lsm_Lock1_Interval] <= `Reg_No_Lock;
                buffer[i][`Lsm_Data1_Interval] <= cdb_in_data_alu;
            end
            if (buffer[i][`Lsm_Op_Interval] != `NOP && cdb_in_index_alu != `Reg_No_Lock && cdb_in_index_alu == buffer[i][`Lsm_Lock2_Interval]) begin
                buffer[i][`Lsm_Lock2_Interval] <= `Reg_No_Lock;
                buffer[i][`Lsm_Data2_Interval] <= cdb_in_data_alu;
            end
            if (queue_op[i] != `NOP && cdb_in_index_alu != `Reg_No_Lock && queue_lock[i] == cdb_in_index_alu) begin
                queue_data[i] <= cdb_in_data_alu;
                queue_lock[i] <= `Reg_No_Lock;
            end
        end
    end

    always @ (*) begin
        $display ("mark:loadStore1");
        for (i = 0; i < Lsm_Queue_Entry; i = i + 1) begin
            if (buffer[i][`Lsm_Op_Interval] != `NOP && cdb_in_index_lsm != `Reg_No_Lock && cdb_in_index_lsm == buffer[i][`Lsm_Lock1_Interval]) begin
                buffer[i][`Lsm_Lock1_Interval] <= `Reg_No_Lock;
                buffer[i][`Lsm_Data1_Interval] <= cdb_in_data_lsm;
            end
            if (buffer[i][`Lsm_Op_Interval] != `NOP && cdb_in_index_lsm != `Reg_No_Lock && cdb_in_index_lsm == buffer[i][`Lsm_Lock2_Interval]) begin
                buffer[i][`Lsm_Lock2_Interval] <= `Reg_No_Lock;
                buffer[i][`Lsm_Data2_Interval] <= cdb_in_data_lsm;
            end
            if (queue_op[i] != `NOP && cdb_in_index_lsm != `Reg_No_Lock && queue_lock[i] == cdb_in_index_lsm) begin
                queue_data[i] <= cdb_in_data_lsm;
                queue_lock[i] <= `Reg_No_Lock;
            end
        end
    end



    assign buffer_stall = (bcounter >= Lsm_Queue_Entry - 1);
    assign buf_que = (bcounter && (qcounter < Lsm_Queue_Entry));
    assign trans_op = buffer[bread_ptr][`Lsm_Op_Interval];
    assign trans_aim = buffer[bread_ptr][`Lsm_Rdlock_Interval];
    assign trans_addr = buffer[bread_ptr][`Lsm_Offset_Interval] + buffer[bread_ptr][`Lsm_Data1_Interval];
    assign trans_data = buffer[bread_ptr][`Lsm_Data2_Interval];
    assign trans_lock = buffer[bread_ptr][`Lsm_Lock2_Interval];

    assign out_op = queue_op[qread_ptr] >= `SB ? 1 : 0;
    assign out_op2 = queue_op[qread_ptr];
    assign out_aim = queue_aim[qread_ptr];
    assign out_addr = queue_addr[qread_ptr];
    assign out_data = queue_data[qread_ptr];
    assign out_lock = queue_lock[qread_ptr];

    wire q_read_enable;
    assign q_read_enable = qcounter && ( out_lock == `Reg_No_Lock &&
                                ((!rob_stall && out_op) || (!out_op && dcache_read_done)) );

    task getData;
        input [`Simp_Op_Width-1:0] task_op;
        input [`Data_Width-1:0] task_i_data;
        input [1:0] task_suf_addr;

        begin
            case ({task_op, task_suf_addr})
                {`LB, 2'b00}: cdb_out_data  <= {{24{task_i_data[7]}}, task_i_data[7:0]};
                {`LBU, 2'b00}: cdb_out_data <= {24'd0, task_i_data[7:0]};
                {`LB, 2'b01}: cdb_out_data  <= {{24{task_i_data[15]}}, task_i_data[15:8]};
                {`LBU, 2'b01}: cdb_out_data <= {24'd0, task_i_data[15:8]};
                {`LB, 2'b10}: cdb_out_data  <= {{24{task_i_data[23]}}, task_i_data[23:16]};
                {`LBU, 2'b10}: cdb_out_data <= {24'd0, task_i_data[23:16]};
                {`LB, 2'b11}: cdb_out_data  <= {{24{task_i_data[31]}}, task_i_data[31:24]};
                {`LBU, 2'b11}: cdb_out_data <= {24'd0, task_i_data[31:24]};
                {`LH, 2'b00}: cdb_out_data  <= {{16{task_i_data[15]}}, task_i_data[15:0]};
                {`LHU, 2'b00}: cdb_out_data <= {16'd0, task_i_data[15:0]};
                {`LH, 2'b10}: cdb_out_data  <= {{16{task_i_data[31]}}, task_i_data[31:16]};
                {`LHU, 2'b10}: cdb_out_data <= {16'd0, task_i_data[31:16]};
                {`LW, 2'b00}: cdb_out_data  <= task_i_data;
                default : $display ("Address misaligned!");
            endcase
        end
    endtask

    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < Lsm_Queue_Entry; i = i + 1) begin
                queue_op[i]   <= `NOP;
                queue_addr[i] <= 0;
                queue_lock[i] <= `Reg_No_Lock;
                queue_data[i] <= 0;
                buffer[i]     <= {(`Lsm_Bus_Width){1'b0}};
            end
            bcounter <= 0;
            qcounter <= 0;
            bwrite_ptr <= 0;
            bread_ptr <= 0;
            qwrite_ptr <= 0;
            qread_ptr <= 0;
            dcache_prefetch <= 0;
            dcache_read <= 0;
        end else begin
            if (lsm_write) begin
                buffer[bwrite_ptr] <= lsm_bus;
                bcounter           <= bcounter + 1;
                bwrite_ptr         <= bwrite_ptr + 1;
            end
            if (buf_que && buffer[bread_ptr][`Lsm_Lock1_Interval] == `Reg_No_Lock) begin
                buffer[bread_ptr]      <= {(`Lsm_Bus_Width){1'b0}};
                bread_ptr              <= bread_ptr + 1;
                bcounter <= bcounter - 1;

                dcache_prefetch <= 1;
                dcache_pre_addr <= trans_addr;

                queue_op[qwrite_ptr]   <= trans_op;
                queue_aim[qwrite_ptr]  <= trans_aim;
                queue_addr[qwrite_ptr] <= trans_addr;
                queue_lock[qwrite_ptr] <= trans_lock;
                queue_data[qwrite_ptr] <= trans_data;
                qwrite_ptr             <= qwrite_ptr + 1;
                qcounter               <= qcounter + 1;
            end
            if (q_read_enable) begin
                queue_op[qread_ptr]   <= `NOP;
                queue_lock[qread_ptr] <= `Reg_No_Lock;
                queue_aim[qread_ptr]  <= 0;
                queue_data[qread_ptr] <= 0;
                queue_addr[qread_ptr] <= 0;
                qread_ptr             <= qread_ptr + 1;
                qcounter <= qcounter - 1;
            end
            if (lsm_write && buf_que && buffer[bread_ptr][`Lsm_Lock1_Interval] == `Reg_No_Lock)
                bcounter <= bcounter;
            if (q_read_enable && buf_que && buffer[bread_ptr][`Lsm_Lock1_Interval] == `Reg_No_Lock)
                qcounter <= qcounter;
        end
    end

    always @ (*) begin
        $display ("mark:loadStore0");
        cdb_out_valid <= 0;
        dcache_read <= 0;
        cdb_out_index <= `Reg_No_Lock;
        if (out_lock == `Reg_No_Lock && qcounter) begin
            case (out_op)
                1'b0 : begin
                    dcache_read <= 1;
                    dcache_read_addr <= out_addr & `Addr_Mask;
                    if (dcache_read_done) begin
                        cdb_out_valid <= 1;
                        cdb_out_index <= {1'b0, out_aim};
                        getData(out_op2, dcache_read_data, out_addr[1:0]);
                        cdb_out_addr <= {`Addr_Width{1'bx}};
                    end
                end
                1'b1 : begin
                    cdb_out_valid <= 1;
                    cdb_out_index <= {1'b0, out_aim};
                    cdb_out_data  <= out_data;
                    cdb_out_addr  <= out_addr;
                end
                default : begin
                    cdb_out_valid <= 0;
                    cdb_out_index <= `Reg_No_Lock;
                end
                endcase
            end
    end

endmodule
