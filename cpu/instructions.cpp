#include "instructions.hpp"
#include <stdexcept>
#include <boost/algorithm/string.hpp>
#include <iostream>

using namespace boost::algorithm;

lui_instruction::lui_instruction(std::string arguments, register_file* registers) : instruction(arguments, registers) {
    if (this->arguments.size() != 2) {
        throw std::invalid_argument("Invalid arguments for LUI instruction: " + arguments);
    }
    this->name = "lui";
    this->target_reg = this->get_rd(this->arguments[0]);
    size_t pos;
    /* argument has form of "%hi(<integer value>)"  */
    uint32_t int_argument = stol(this->arguments[1].substr(4, this->arguments[1].size() - 1).c_str(), &pos, 0 );
    uint16_t lo_value = int_argument & 0xFFF;
    if (lo_value > 0x800) {
        int_argument += 0x800;
    }
    this->expected_value = (int_argument & 0xFFFFF000); 
}

lui_instruction::lui_instruction(uint32_t instr, register_file* registers){
    this->registers = registers;
    this->name = "lui";
    this->target_reg = GET_RD(instr);
    this->expected_value = GET_U_IMM(instr);
}

uint32_t lui_instruction::execute(uint32_t pc) {
    this->registers->write_register(this->target_reg, this->expected_value);//get_register(this->target_reg)->write(this->expected_value);
    return pc + 4;
}


int instruction::get_rd(string register_name) {
    if (this->register_map.find(register_name) == this->register_map.end()) {
        throw std::invalid_argument("Invalid register name: " + register_name);
    }
    return this->register_map[register_name];
}

vector<string> instruction::split_arguments(string arguments) {
    vector<string> result;
    size_t pos = 0;
    string token;
    while ((pos = arguments.find(',', pos))!= string::npos) {
        token = arguments.substr(0, pos);
        trim(token);
        result.push_back(token);
        arguments.erase(0, pos + 1);
    }
    trim(arguments);
    result.push_back(arguments);
    
    return result;
}

auipc_instruction::auipc_instruction(string arguments, register_file* registers) : instruction(arguments, registers) {
    this->name = "auipc";

    this->target_reg = this->get_rd(this->arguments[0]);
    size_t pos;
    /* argument has form of "%hi(<integer value>)"  */
    uint32_t int_argument = stol(this->arguments[1].substr(4, this->arguments[1].size() - 1).c_str(), &pos, 0 );
    uint16_t lo_value = int_argument & 0xFFF;
    if (lo_value > 0x800) {
        int_argument += 0x800;
    }
    this->imm_value = (int_argument & 0xFFFFF000); 
}

auipc_instruction::auipc_instruction(uint32_t instr, register_file* registers) {
    this->name = "auipc";
    this->registers = registers;
    this->target_reg = GET_RD(instr);
    this->imm_value = GET_U_IMM(instr);
}

uint32_t auipc_instruction::execute(uint32_t pc) {
    this->registers->write_register(this->target_reg, pc + this->imm_value);  //get_register(this->target_reg)->write(pc + this->imm_value
    return pc + 4;
}

jal_instruction::jal_instruction(string arguments, register_file* registers) : instruction(arguments, registers) {

}

jal_instruction::jal_instruction(uint32_t instr, register_file* registers) {
    if (GET_OPCODE(instr) != JAL) {
        throw std::invalid_argument("Invalid opcode for OP instruction");
    }
    this->registers = registers;
    this->name = "jal";
    this->target_reg = GET_RD(instr);
    this->imm_value = GET_J_IMM(instr);
}

uint32_t jal_instruction::execute(uint32_t pc) {
    this->registers->write_register(this->target_reg, pc + 4);
    return pc + this->imm_value;
}

jalr_instruction::jalr_instruction(string arguments, register_file* registers) : instruction(arguments, registers) {
}

jalr_instruction::jalr_instruction(uint32_t instr, register_file* registers) {
    if (GET_OPCODE(instr)!= JALR) {
        throw std::invalid_argument("Invalid opcode for JALR instruction");
    }
    this->registers = registers;
    this->name = "jalr";
    this->target_reg = GET_RD(instr);
    this->rs1_reg = GET_RS1(instr);
    this->imm_value = GET_I_IMM(instr);
}

uint32_t jalr_instruction::execute(uint32_t pc) {
    //printf("write to register %d with value %d\n", this->target_reg, pc + this->imm_value);
    //this->registers->write_register(this->target_reg, pc + 4);

    uint32_t rs1_value = this->registers->get_register(this->rs1_reg)->read();
    this->registers->write_register(this->target_reg, pc + 4);
    return rs1_value + this->imm_value;
}

instruction::instruction() {
}
instruction::instruction(string arguments, register_file* registers) {
    this->registers = registers;
    this->arguments = split_arguments(arguments);
    //this->name = "LUI";
    for (int i = 0; i < 32; i++) {
        this->register_map["x" + to_string(i)] = i;
    }
    this->register_map["zero"] = 0;
    this->register_map["ra"] = 1;
    this->register_map["sp"] = 2;
    this->register_map["gp"] = 3;
    this->register_map["tp"] = 4;
    this->register_map["fp"] = 8;

    for (int i = 0; i < 3; i++) {
        this->register_map["t" + to_string(i)] = 5 + i;
    }

    for (int i = 0; i < 2; i++) {
        this->register_map["s" + to_string(i)] = 8 + i;
    }

    for (int i = 0; i < 8; i++) {
        this->register_map["a" + to_string(i)] = 10 + i;
    }

    for (int i = 2; i < 12; i++) {
        this->register_map["s" + to_string(i)] = 16 + i;
    }

    for (int i = 3; i < 7; i++) {
        this->register_map["t" + to_string(i)] = 25 + i;
    }
}