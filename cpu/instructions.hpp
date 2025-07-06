#ifndef INSTRUCTIONS_HPP
#define INSTRUCTIONS_HPP

#include <string>
#include <map>
#include <vector>
#include <cstdint>
class register_file;
#include "cpu_state.hpp"

using namespace std;

#define GET_OPCODE(instruction) ((instruction) & 0x7F)
#define GET_FUNCT(instruction) (((instruction) >> 12) & 0x7)
#define GET_RD(instruction) (((instruction) >> 7) & 0x1F)
#define GET_RS1(instruction) (((instruction) >> 15) & 0x1F)
#define GET_RS2(instruction) (((instruction) >> 20) & 0x1F)

#define GET_U_IMM(instruction) ((instruction) & 0xFFFFF000)
#define GET_I_IMM(instruction) ((int32_t)((instruction) & 0xFFF00000) >> 20)
#define GET_B_IMM(instr) \
    ((((int32_t)((instr) & 0x80000000)) >> 19) | \
    ((((instr) >> 7) & 0x1e) | \
    (((instr) >> 20) & 0x7e0) | \
    (((instr) << 4) & 0x800)) | \
    (((int32_t)(((instr) >> 31) & 0x1)) << 11))

#define GET_J_IMM(instr) \
    ((((instr) >> 31) & 0x1) << 20 | \
     (((instr) >> 12) & 0xFF) << 12 | \
     (((instr) >> 20) & 0x1) << 11 | \
     (((instr) >> 21) & 0x3FF) << 1 | \
     (((int32_t)((instr) & 0x80000000)) >> 11))

#define GET_S_IMM(instr) \
    ((((int32_t)((instr) & 0xFE000000)) >> 20) | \
     (((instr) >> 7) & 0x1F))

    /*
#define GET_B_IMM(instruction) (uint32_t)((int32_t)(((instruction) & 0x80000000) | \
                               (((instruction) & 0x80) << 23) | \
                                (((instruction) & 0x7E000000) >> 1) | \
                                (((instruction) & 0xF80) << 13)) >> 19)
*/
enum {
    ADD = 0,
    SLL,
    SLT,
    SLTU,
    XOR,
    SRL,
    OR,
    AND
};

typedef enum {
    LUI = 0x37,
    AUIPC = 0x17,
    JAL = 0x6F,
    JALR = 0x67,
    BRANCH = 0x63,
    LOAD = 0x3,
    STORE = 0x23,
    IMM = 0x13,
    OP = 0x33,
    FENCE = 0xF,
    EBREAK = 0x73,
} opcodes;

class instruction {
    public:
        instruction(string arguments, register_file* registers);
        instruction();
        virtual uint32_t execute(uint32_t pc) = 0;
        std::string get_name() { return this->name; }
    protected:
        int get_rd(string register_name);
        vector<string> split_arguments(string arguments);
        map<string, int> register_map;
        int target_reg;
        vector<string> arguments;
        register_file* registers;
        std::string name;
};

class lui_instruction : public instruction {
    public:
        lui_instruction(string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        lui_instruction(uint32_t instr, register_file* registers);

    private:
        uint32_t expected_value;
};

class op_imm_instruction : public instruction {
    public:
        op_imm_instruction(string instr, string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        op_imm_instruction(uint32_t instr, register_file* registers);
    
    private:
        uint32_t imm_value;
        std::string instr;
        int source_reg;
};

class op_instruction : public instruction {
    public:
        op_instruction(string instr, string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        op_instruction(uint32_t instr, register_file* registers);
    private:
        std::string instr;
        uint8_t s1_reg;
        uint8_t s2_reg;
};

class fence_instruction : public instruction {
    public:
        fence_instruction(string instr, string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        fence_instruction(uint32_t instr, register_file* registers);
};

class auipc_instruction : public instruction {
    public:
        auipc_instruction(string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        auipc_instruction(uint32_t instr, register_file* registers);
    private:
        uint32_t imm_value;
};

class jal_instruction : public instruction {
    public:
        jal_instruction(string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        jal_instruction(uint32_t instr, register_file* registers);
    private:
        uint32_t imm_value;
        uint32_t target_reg;
};

class jalr_instruction : public instruction {
    public:
        jalr_instruction(string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        jalr_instruction(uint32_t instr, register_file* registers);
    private:
        uint32_t imm_value;
        uint32_t target_reg;
        uint32_t rs1_reg;
};



class branch_instruction : public instruction {
    public:
        branch_instruction(string instr, string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        branch_instruction(uint32_t instr, register_file* registers);
    private:
        std::string instr;
        uint32_t imm_value;
        uint32_t rs1_reg;
        uint32_t rs2_reg;
};

class store_instruction : public instruction {
    public:
        store_instruction(string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);
        store_instruction(uint32_t instr, register_file* registers, uint32_t* memory);
    private:
        volatile uint32_t* memory;
        uint32_t imm_value;
        uint32_t rs1_reg;
        uint32_t rs2_reg;
        uint32_t width;
};

class load_instruction: public instruction {
    public:
        load_instruction(string arguments, register_file* registers);
        uint32_t execute(uint32_t pc);

        load_instruction(uint32_t instr, register_file* registers, uint32_t* memory);
    private:
        volatile uint32_t* memory;
        uint32_t imm_value;
        uint32_t rs1_reg;
        uint32_t target_reg;
        uint32_t width;
};

instruction* get_insn_instructions(const std::string& instr, register_file* registers);
#endif
