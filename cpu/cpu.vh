


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

`define COMPARE_INV 3'b011

`define LUI_OPCODE     7'b0110111
`define OP_IMM_OPCODE  7'b0010011
`define OP_OPCODE      7'b0110011
`define AUIPC_OPCODE   7'b0010111
`define BRANCH_OPCODE  7'b1100011
`define JAL_OPCODE     7'b1101111
`define JALR_OPCODE    7'b1100111
`define STORE_OPCODE    7'b0100011
`define LOAD_OPCODE    7'b0000011

`define ROM_SIZE    32'h400
`define RAM_SIZE    32'h1000

`define RD_ADDR_BASE        0
`define RD_ADDR_WIDTH       5
`define JUMP_EN_BASE        (`RD_ADDR_BASE + `RD_ADDR_WIDTH)
`define JUMP_EN_SIZE       1
`define REG_EN_BASE         (`JUMP_EN_BASE + `JUMP_EN_SIZE)
`define REG_EN_WIDTH        1
`define REG_IN_SEL_BASE     (`REG_EN_BASE + `REG_EN_WIDTH)
`define REG_IN_SEL_WIDTH    2 
`define WRITE_BACK_SIZE     (`REG_IN_SEL_BASE + `REG_IN_SEL_WIDTH)
`define MEM_EN_BASE         `WRITE_BACK_SIZE
`define MEM_EN_WIDTH        1
`define MEM_WR_BASE         (`MEM_EN_BASE + `MEM_EN_WIDTH)
`define MEM_WR_WIDTH        1
`define MEM_ADDR_SEL_BASE   (`MEM_WR_BASE + `MEM_WR_WIDTH)
`define MEM_ADDR_SEL_WIDTH  1
`define MEM_SIZE_BASE       (`MEM_ADDR_SEL_BASE + `MEM_ADDR_SEL_WIDTH) 
`define MEM_SIZE_WIDTH      3
`define LOAD_STORE_SIZE     (`MEM_SIZE_BASE + `MEM_SIZE_WIDTH)
`define IMM_MUX_SEL_BASE    `LOAD_STORE_SIZE
`define IMM_MUX_SEL_WIDTH   1
`define ALU_SEL_BASE        (`IMM_MUX_SEL_BASE + `IMM_MUX_SEL_WIDTH)
`define ALU_SEL_WIDTH       3
`define BRANCH_SEL_BASE     (`ALU_SEL_BASE + `ALU_SEL_WIDTH)
`define BRANCH_SEL_WIDTH    3 
`define ALU_A_SEL_BASE      (`BRANCH_SEL_BASE + `BRANCH_SEL_WIDTH)
`define ALU_A_SEL_WIDTH     1 
`define ALU_AUX_BASE        (`ALU_A_SEL_BASE + `ALU_A_SEL_WIDTH) 
`define ALU_AUX_WIDTH       1
`define OP_SIZE             (`ALU_AUX_BASE + `ALU_AUX_WIDTH)
