


`define R_TYPE 3'b000
`define I_TYPE 3'b001
`define S_TYPE 3'b010
`define B_TYPE 3'b011
`define U_TYPE 3'b100
`define J_TYPE 3'b101


`define ALU_ADD 3'b000
`define ALU_SLL 3'b001
`define ALU_SLT 3'b010
`define ALU_SLTU 3'b011
`define ALU_XOR 3'b100
`define ALU_SRL 3'b101
`define ALU_OR 3'b110
`define ALU_AND 3'b111

`define COMPARE_EQ 3'b000
`define COMPARE_NE 3'b001
`define COMPARE_LT 3'b100
`define COMPARE_GE 3'b101
`define COMPARE_LTU 3'b110
`define COMPARE_GEU 3'b111

`define LUI_OPCODE     7'b0110111
`define OP_IMM_OPCODE  7'b0010011
`define OP_OPCODE      7'b0110011
`define AUIPC_OPCODE   7'b0010111
`define BRANCH_OPCODE  7'b1100011
`define JAL_OPCODE     7'b1101111
`define JALR_OPCODE    7'b1100111
`define STORE_OPCODE    7'b0100011
`define LOAD_OPCODE    7'b0000011
