
#include "instructions.hpp"
#include <stdexcept>
#include <iostream>
#include <boost/algorithm/string.hpp>

enum {
    BEQ = 0,
    BNE,
    BLT = 4,
    BGE,
    BLTU,
    BGEU
};

branch_instruction::branch_instruction(std::string instr, std::string arguments, register_file* registers) : instruction(arguments, registers) {
    if (this->arguments.size() != 3) {
        throw std::invalid_argument("Invalid arguments for BRANCH instruction: " + arguments);
    }
    this->name = instr;
    this->instr = instr;
    this->imm_value = stoi(this->arguments[2], nullptr, 10);
    this->rs1_reg = this->get_rd(this->arguments[0]);
    this->rs2_reg = this->get_rd(this->arguments[1]);
}

branch_instruction::branch_instruction(uint32_t instr, register_file* registers) {
    this->registers = registers;
    if (GET_OPCODE(instr) != BRANCH) {
        throw std::invalid_argument("Invalid opcode for BRANCH instruction");
    }

    switch (GET_FUNCT(instr)) {
        case BEQ:
            this->instr = "beq";
            break;
        case BNE:
            this->instr = "bne";
            break;
        case BLT:
            this->instr = "blt";
            break;
        case BGE:
            this->instr = "bge";
            break;
        case BLTU:
            this->instr = "bltu";
            break;
        case BGEU:
            this->instr = "bgeu";
            break;
        default:
            throw std::invalid_argument("Invalid function code for BRANCH instruction");
    }

    this->rs1_reg = GET_RS1(instr);
    this->rs2_reg = GET_RS2(instr);
    this->imm_value = GET_B_IMM(instr);
    this->name = this->instr;
}

using InstructionExecution = std::function<bool(register_file* registers, int, uint32_t, uint32_t)>;

std::map<std::string, InstructionExecution> branch_instruction_execution_map = {
    {"beq", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { return rs1_value == rs2_value; }},
    {"bne", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { return rs1_value != rs2_value; }},
    {"blt", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { return (int32_t) rs1_value < (int32_t) rs2_value; }},
    {"bge", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { return (int32_t) rs1_value >= (int32_t) rs2_value; }},
    {"bltu", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { return rs1_value < rs2_value; }},
    {"bgeu", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { return rs1_value >= rs2_value; }},
};

uint32_t branch_instruction::execute(uint32_t pc) {
    uint32_t rs1_value = this->registers->get_register(this->rs1_reg)->read();
    uint32_t rs2_value = this->registers->get_register(this->rs2_reg)->read(); 
    auto it = branch_instruction_execution_map.find(this->instr);

    if (it!= branch_instruction_execution_map.end() && it->second(this->registers, this->rs1_reg, rs1_value, rs2_value)) {
        return pc + this->imm_value;
    } else {
        return pc + 4;
    }
}