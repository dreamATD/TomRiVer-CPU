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
module InstCache(
    input ce,
    input [`Inst_Addr_Width-1 : 0] addr,
    output reg [`Inst_Width-1 : 0] inst,
    output reg cache_enable
);
    reg [`Inst_Width-1 : 0] inst_mem[0:127];

    initial $readmemh ("E:/dreamATD/homework/myCPU/myCPU.srcs/sources_1/new/test4.data", inst_mem);

    always @ (*) begin
        if (!ce) begin
            inst <= 0;
            cache_enable <= 0;
        end else begin
            inst <= {inst_mem[addr[`Inst_Addr_Width-1:2]][7:0], inst_mem[addr[`Inst_Addr_Width-1:2]][15:8], inst_mem[addr[`Inst_Addr_Width-1:2]][23:16], inst_mem[addr[`Inst_Addr_Width-1:2]][31:24]};
            cache_enable <= 1;
        end
    end
endmodule
