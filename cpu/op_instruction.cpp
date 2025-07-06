
#include "instructions.hpp"
#include <stdexcept>
#include <iostream>
#include <boost/algorithm/string.hpp>

op_instruction::op_instruction(std::string instr, std::string arguments, register_file* registers) : instruction(arguments, registers) {
    size_t pos;

    this->instr = instr;

    this->name = instr;
    if (this->arguments.size() != 3) {
        throw std::invalid_argument("Invalid arguments for " + instr + " instruction: " + arguments);
    }

    this->target_reg = this->get_rd(this->arguments[0]);
    this->s1_reg = this->get_rd(this->arguments[1]);
    this->s2_reg = this->get_rd(this->arguments[2]);
}

op_instruction::op_instruction(uint32_t instr, register_file* registers) {
    this->registers = registers;
    if (GET_OPCODE(instr) != OP) {
        throw std::invalid_argument("Invalid opcode for OP instruction");
    }
    this->s1_reg = GET_RS1(instr);
    this->s2_reg = GET_RS2(instr);
    this->target_reg = GET_RD(instr);

    switch (GET_FUNCT(instr)) {
        case ADD:
            if (instr & 0x40000000) {
                this->instr = "sub";
            } else {
                this->instr = "add";
            }
            break;
        case SLL:
            this->instr = "sll";
            break;
        case SLT:
            this->instr = "slt";
            break;
        case SLTU:
            this->instr = "sltu";
            break;
        case XOR:
            this->instr = "xor";
            break;
        case SRL:
            if (instr & 0x40000000) {
                this->instr = "sra";
            } else {
                this->instr = "srl";
            }
            break;
        case OR:
            this->instr = "or";
            break;
        case AND:
            this->instr = "and";
            break; 
    }
    this->name = this->instr;
}

using InstructionExecution = std::function<void(register_file* registers, int, uint32_t, uint32_t)>;

std::map<std::string, InstructionExecution> instruction_execution_map = {
    {"or",   [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, rs1_value | rs2_value); }},
    {"add",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, rs1_value + rs2_value); }},
    {"sub",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, rs1_value - rs2_value); }},
    {"sltu", [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, (rs1_value < rs2_value)? 1 : 0); }},
    {"slt",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, ((int32_t) rs1_value < (int32_t) rs2_value)? 1 : 0); }},
    {"and",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, rs1_value & rs2_value); }},
    {"xor",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, rs1_value ^ rs2_value); }},
    {"sll",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, rs1_value << (rs2_value & 0x1F)); }},
    {"srl",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg, rs1_value >> (rs2_value & 0x1F)); }},
    {"sra",  [](register_file* registers, int target_reg, uint32_t rs1_value, uint32_t rs2_value) { registers->write_register(target_reg,((int32_t) rs1_value) >> (rs2_value & 0x1F)); }},
};


uint32_t op_instruction::execute(uint32_t pc) {
    uint32_t rs1_value = this->registers->get_register(this->s1_reg)->read();
    uint32_t rs2_value = this->registers->get_register(this->s2_reg)->read(); 
    auto it = instruction_execution_map.find(this->instr);
    if (it!= instruction_execution_map.end()) {
        it->second(this->registers, this->target_reg, rs1_value, rs2_value);
    } else {
        printf("Unknown instruction: %s\n", this->instr.c_str());
    }

    return pc + 4;
}