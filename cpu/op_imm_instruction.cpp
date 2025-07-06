
#include "instructions.hpp"
#include <stdexcept>
#include <iostream>
#include <boost/algorithm/string.hpp>


op_imm_instruction::op_imm_instruction(std::string instr, std::string arguments, register_file* registers) : instruction(arguments, registers) {
    size_t pos;

    this->instr = instr;

    this->name = instr;
    if (this->arguments.size() != 3) {
        throw std::invalid_argument("Invalid arguments for " + instr + " instruction: " + arguments);
    }

    if (this->arguments[2].rfind("\%lo(") != std::string::npos) {
        this->imm_value = stol(this->arguments[2].substr(4, this->arguments[2].size() - 1).c_str(), &pos, 0);
    }
    else {
        this->imm_value = stoi(this->arguments[2], nullptr, 0);
    }
    this->target_reg = this->get_rd(this->arguments[0]);
    this->source_reg = this->get_rd(this->arguments[1]);
    this->imm_value = this->imm_value & 0xFFF;

    if (this->imm_value & 0x800) {
        this->imm_value |= 0xFFFFF000;
    }
}

op_imm_instruction::op_imm_instruction(uint32_t instr, register_file* registers) {
    if (GET_OPCODE(instr) != IMM) {
        throw std::invalid_argument("Invalid opcode for OP instruction");
    }
    this->registers = registers;
    this->source_reg = GET_RS1(instr);
    this->target_reg = GET_RD(instr);

    switch (GET_FUNCT(instr)) {
        case ADD:
            this->instr = "addi";
            break;
        case SLL:
            this->instr = "slli";
            break;
        case SLT:
            this->instr = "slti";
            break;
        case SLTU:
            this->instr = "sltiu";
            break;
        case XOR:
            this->instr = "xori";
            break;
        case SRL:
            if (instr & 0x40000000) {
                this->instr = "srai";
            } else {
                this->instr = "srli";
            }
            break;
        case OR:
            this->instr = "ori";
            break;
        case AND:
            this->instr = "andi";
            break; 
    }

    this->name = this->instr;

    this->imm_value = GET_I_IMM(instr);
} 

using InstructionExecution = std::function<void(register_file* registers, int, uint32_t, uint32_t)>;

std::map<std::string, InstructionExecution> imm_instruction_execution_map = {
    {"ori",   [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, rs1_value | imm_value); }},
    {"addi",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, rs1_value + imm_value); }},
    {"sltiu", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, (rs1_value < imm_value)? 1 : 0); }},
    {"slti",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, ((int32_t) rs1_value < (int32_t) imm_value)? 1 : 0); }},
    {"andi",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, rs1_value & imm_value); }},
    {"xori",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, rs1_value ^ imm_value); }},
    {"slli",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, rs1_value << (imm_value & 0x1F)); }},
    {"srli",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg, rs1_value >> (imm_value & 0x1F)); }},
    {"srai",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t imm_value) { registers->write_register(target_reg,((int32_t) rs1_value) >> (imm_value & 0x1F)); }},
};

uint32_t op_imm_instruction::execute(uint32_t pc) {
    uint32_t rs1_value = this->registers->get_register(this->source_reg)->read();
    auto it = imm_instruction_execution_map.find(this->instr);
    if (it!= imm_instruction_execution_map.end()) {
        it->second(this->registers, this->target_reg, rs1_value, this->imm_value);
    } else {
        printf("Unknown instruction: %s\n", this->instr.c_str());
    }

    return pc + 4;
}