`ifndef __DEFINES__
`define __DEFINES__
`define Addr_Width          32
`define Inst_Width          32
`define Inst_Addr_Width     17

`define Opcode_Interval     6:0
`define Opcode_Width        7
`define Rs1_Interval        19:15
`define Rs2_Interval        24:20
`define Rd_Interval         11:7
`define Reg_Width           5
`define Reg_Cnt             32
`define Func3_Interval      14:12
`define Func3_Width         3
`define Func7_Interval      31:25
`define Func7_Width         7
`define Imm_Interval        31:20
`define Imm_Width           12
`define Data_Width          32

`define ROB_Entry           8
`define ROB_Entry_Width     3
`define Reg_Lock_Width      4
`define Reg_No_Lock         4'b1000
`define Alu_Bus_Width       (`Simp_Op_Width + `Reg_Lock_Width + `Reg_Lock_Width + `ROB_Entry_Width + `Data_Width + `Data_Width)
`define Alu_Rdlock_Interval `ROB_Entry_Width-1:0
`define Alu_Data2_Low5      (`ROB_Entry_Width+4):`ROB_Entry_Width
`define Alu_Data2_Interval  (`Data_Width+`ROB_Entry_Width-1):`ROB_Entry_Width
`define Alu_Lock2_Interval  (`Reg_Lock_Width+`ROB_Entry_Width+`Data_Width-1):(`Data_Width+`ROB_Entry_Width)
`define Alu_Data1_Interval  (`Data_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width-1):(`Reg_Lock_Width+`ROB_Entry_Width+`Data_Width)
`define Alu_Lock1_Interval  (`Reg_Lock_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width+`Data_Width-1):(`Data_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width)
`define Alu_Op_Interval     (`Reg_Lock_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width+`Data_Width+`Simp_Op_Width-1):(`Reg_Lock_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width+`Data_Width)
`define Reg_Bus_Width       (`Reg_Width + `ROB_Entry_Width)
`define Reg_Name_Interval   (`Reg_Width + `ROB_Entry_Width-1):`ROB_Entry_Width
`define Reg_Entry_Interval   `ROB_Entry_Width-1:0
`define ROB_Bus_Width       (2 + `Addr_Width + `Data_Width + 1)
`define ROB_Valid_Interval  0
`define ROB_Value_Interval  `Data_Width:1
`define ROB_Reg_Interval    (`Reg_Width + `Data_Width):(`Data_Width + 1)
`define ROB_Mem_Interval    (`Addr_Width + `Data_Width):(`Data_Width + 1)
`define ROB_Op_Interval     (2 +`Addr_Width+`Data_Width):(`Addr_Width+`Data_Width + 1)

`define StoreOpcode         7'b0100011
`define LoadOpcode          7'b0000011

`define Simp_Op_Width       6
`define Class_Opcode_NOP    7'b0000000
`define Op_Imm              7'b0010011
`define Op_                 7'b0110011

`define NOP                 6'b000000
`define ADD                 6'b000001
`define SUB                 6'b000010
`define SLT                 6'b000011
`define SLTU                6'b000100
`define XOR                 6'b000101
`define OR                  6'b000110
`define AND                 6'b000111
`define SLL                 6'b001000
`define SRL                 6'b001001
`define SRA                 6'b001010
`endif
