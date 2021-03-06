`ifndef __DEFINES__
`define __DEFINES__
`define Addr_Width          32
`define Inst_Width          32
`define Inst_Addr_Width     32

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
`define Jmm_Interval        31:12
`define Jmm_Width           20
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
`define ROB_Op_Width        3
`define ROB_Bus_Width       (`ROB_Op_Width + `Addr_Width + `Data_Width + 1)
`define ROB_Valid_Interval  0
`define ROB_Value_Interval  `Data_Width:1
`define ROB_Branch_Interval 2:1
`define ROB_Baddr_Interval  (`Bra_Addr_Width + 2):3
`define ROB_Reg_Interval    (`Reg_Width + `Data_Width):(`Data_Width + 1)
`define ROB_Mem_Interval    (`Addr_Width + `Data_Width):(`Data_Width + 1)
`define ROB_Mem_Suf_Interval (`Data_Width + 2):(`Data_Width + 1)
`define ROB_Ins_Interval    (`Inst_Addr_Width + `Data_Width):(`Data_Width + 1)
`define ROB_Op_Interval     (`ROB_Op_Width +`Addr_Width+`Data_Width):(`Addr_Width+`Data_Width + 1)
`define Bra_Bus_Width       `Alu_Bus_Width + 1
`define Bra_Pre_Interval    0
`define Bra_Rdlock_Interval `ROB_Entry_Width:1
`define Bra_Data2_Interval  (`Data_Width+`ROB_Entry_Width):(`ROB_Entry_Width + 1)
`define Bra_Lock2_Interval  (`Reg_Lock_Width+`ROB_Entry_Width+`Data_Width):(`Data_Width+`ROB_Entry_Width + 1)
`define Bra_Data1_Interval  (`Data_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width):(`Reg_Lock_Width+`ROB_Entry_Width+`Data_Width + 1)
`define Bra_Lock1_Interval  (`Reg_Lock_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width+`Data_Width):(`Data_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width + 1)
`define Bra_Op_Interval     (`Reg_Lock_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width+`Data_Width+`Simp_Op_Width):(`Reg_Lock_Width+`Reg_Lock_Width+`Data_Width+`ROB_Entry_Width+`Data_Width + 1)
`define Lsm_Bus_Width       (`Simp_Op_Width + `Reg_Lock_Width + `Data_Width + `Reg_Lock_Width + `Data_Width + `Addr_Width + `ROB_Entry_Width)
`define Lsm_Rdlock_Interval (`ROB_Entry_Width-1):0
`define Lsm_Offset_Interval (`ROB_Entry_Width + `Addr_Width - 1) : `ROB_Entry_Width
`define Lsm_Data2_Interval  (`ROB_Entry_Width + `Addr_Width + `Data_Width - 1):(`ROB_Entry_Width + `Addr_Width)
`define Lsm_Lock2_Interval  (`ROB_Entry_Width + `Addr_Width + `Data_Width + `Reg_Lock_Width - 1):(`ROB_Entry_Width + `Addr_Width + `Data_Width)
`define Lsm_Data1_Interval  (`ROB_Entry_Width + `Addr_Width + `Data_Width + `Reg_Lock_Width + `Data_Width - 1):(`ROB_Entry_Width + `Addr_Width + `Data_Width + `Reg_Lock_Width)
`define Lsm_Lock1_Interval  (`ROB_Entry_Width + `Addr_Width + `Data_Width + `Reg_Lock_Width + `Data_Width +`Reg_Lock_Width - 1):(`ROB_Entry_Width + `Addr_Width + `Data_Width + `Reg_Lock_Width + `Data_Width)
`define Lsm_Op_Interval     (`ROB_Entry_Width + `Addr_Width + `Data_Width + `Reg_Lock_Width + `Data_Width +`Reg_Lock_Width + `Simp_Op_Width - 1):(`ROB_Entry_Width + `Addr_Width + `Data_Width + `Reg_Lock_Width + `Data_Width +`Reg_Lock_Width)

`define Bra_Addr_Width      4
`define Bra_History_Width   2
`define Bra_Entry_Cnt       (1 << `Bra_Addr_Width + `Bra_History_Width)
`define Bra_Entry_Width     (`Bra_Addr_Width + `Bra_History_Width)


`define Class_Opcode_NOP    7'b0000000
`define Op_Imm              7'b0010011
`define Op_                 7'b0110011
`define LUI_                7'b0110111
`define AUIPC_              7'b0010111
`define JAL_                7'b1101111
`define JALR_               7'b1100111
`define BRANCH_             7'b1100011
`define Store_              7'b0100011
`define Load_               7'b0000011

`define NOP_Inst            32'b00000000000000000000000000110011

`define Simp_Op_Width       6
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
`define LUI                 6'b001011
`define AUIPC               6'b001100
`define JAL                 6'b001101
`define JALR                6'b001110
`define BEQ                 6'b001111
`define BNE                 6'b010000
`define BLT                 6'b010001
`define BLTU                6'b010010
`define BGE                 6'b010011
`define BGEU                6'b010100
`define LB                  6'b010101
`define LH                  6'b010110
`define LW                  6'b010111
`define LBU                 6'b011000
`define LHU                 6'b011001
`define SB                  6'b011010
`define SH                  6'b011011
`define SW                  6'b011100

`define Addr_Mask           32'd4294967293

`define Block_Offset_Width  6
`endif
