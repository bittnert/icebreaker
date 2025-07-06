#include "instructions.hpp"
#include <stdexcept>

enum {
    BYTE,
    HALF_WORD,
    WORD
};

store_instruction::store_instruction(std::string arguments, register_file* registers) : instruction(arguments, registers) {
}

store_instruction::store_instruction(uint32_t instr, register_file* registers, uint32_t* memory){
    if (GET_OPCODE(instr)!= STORE) {
        throw std::invalid_argument("Invalid opcode for STORE instruction");
    }
    this->registers = registers;
    this->memory = memory;
    this->rs1_reg = GET_RS1(instr);
    this->rs2_reg = GET_RS2(instr);
    this->imm_value = GET_S_IMM(instr);
    this->width = GET_FUNCT(instr);
    switch (this->width) {
        case BYTE:
            this->name = "sb";
            break;
        case HALF_WORD:
            this->name = "sh";
            break;
        case WORD:
            this->name = "sw";
            break;
        default:
            throw std::invalid_argument("Invalid store width");
            break;
    }
    
}

uint32_t store_instruction::execute(uint32_t pc) {
    uint32_t address = this->registers->get_register(this->rs1_reg)->read() + this->imm_value;
    uint32_t shift_value = address & 0x3;
    uint32_t mask = 0;
    switch (this->width) {
        case BYTE:
            mask = 0xFF;
            break;
        case HALF_WORD:
            if (shift_value == 1 || shift_value == 3) {
                throw std::invalid_argument("Cannot store a byte into a half-word or word");
            }
            mask = 0xFFFF;
            break;
        case WORD:
            mask = 0xFFFFFFFF;
            if (shift_value != 0) {
                throw std::invalid_argument("Cannot store a word into a half-word or byte");
            }
            break;
        default:
            throw std::invalid_argument("Invalid store width");
            break;
    }

    uint32_t value = this->registers->get_register(this->rs2_reg)->read() & mask;
    uint32_t shifted_value = value << (shift_value * 8);
    this->memory[address >> 2] = (this->memory[address >> 2] & ~(mask << (shift_value * 8))) | shifted_value;
    return pc + 4;
}
