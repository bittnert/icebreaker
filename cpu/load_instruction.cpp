
#include "instructions.hpp"
#include <stdexcept>

enum {
    BYTE,
    HALF_WORD,
    WORD
};
load_instruction::load_instruction(std::string arguments, register_file* registers) : instruction(arguments, registers) {
}

load_instruction::load_instruction(uint32_t instr, register_file* registers, uint32_t* memory){
    if (GET_OPCODE(instr)!= LOAD) {
        throw std::invalid_argument("Invalid opcode for LOAD instruction");
    }

    this->registers = registers;
    this->memory = memory;
    this->rs1_reg = GET_RS1(instr);
    this->target_reg = GET_RD(instr);
    this->imm_value = GET_I_IMM(instr);
    this->width = GET_FUNCT(instr);
    switch (this->width) {
        case BYTE:
            this->name = "lb";
            break;
        case HALF_WORD:
            this->name = "lh";
            break;
        case WORD:
            this->name = "lw";
            break;
        default:
            throw std::invalid_argument("Invalid load width");
            break;
    }
}

uint32_t load_instruction::execute(uint32_t pc) {

    uint32_t address = this->registers->get_register(this->rs1_reg)->read() + this->imm_value;
    uint32_t shift_value = address & 0x3;
    uint32_t mask = 0;
    switch (this->width) {
        case BYTE:
            mask = 0xFF;
            break;
        case HALF_WORD:
            if (shift_value == 1 || shift_value == 3) {
                throw std::invalid_argument("Cannot load a half word from byte aligned address");
            }
            mask = 0xFFFF;
            break;
        case WORD:
            if (shift_value!= 0) {
                throw std::invalid_argument("Cannot load a word from half word aligned address");
            }
            mask = 0xFFFFFFFF;
            break;
        default:
            throw std::invalid_argument("Invalid load width");
            break;
    }

    uint32_t value = ((this->memory[address >> 2] >> (shift_value*8)) & mask);
    this->registers->get_register(this->target_reg)->write(value);

    return pc + 4;
}