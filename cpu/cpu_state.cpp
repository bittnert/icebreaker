#include <stdlib.h>
#include <stdint.h>
#include "cpu_state.hpp"
#include <time.h>
#include <fstream>
#include <string.h>
#include <map>
#include <functional>

reg::reg() {
	srand(time(NULL));
    //this->value = rand()&(0xFFFFFFFF);
    this->value = 0;
    this->used = false;
}

void reg::write(uint32_t data) {
    this->value = data;
    this->used = true;
}

uint32_t reg::read() {
    return this->value;
}

bool reg::is_used() {
    return this->used;
}

reg* register_file::get_register(int index) {
    if (index >= 0 && index < 32) {
        return this->registers[index];
    }
    return NULL;
} 

register_file::register_file() {
    for (int i = 0; i < 32; i++) {
        this->registers[i] = new reg();
    }
    // register 0 is always zero.
    this->registers[0]->write(0);
}

void register_file::write_register(int index, uint32_t data) {
    if (index >= 0 && index < 32) {
        this->registers[index]->write(data);
    }
}

cpu_state::cpu_state(std::string assembler_file) {
    this->registers = new register_file();
    //this->read_assembler_file(assembler_file);
    memset(this->memory, 0, sizeof(this->memory));
    this->read_memory_file(assembler_file);
    this->pc = 0;
}


bool cpu_state::execute() {
    bool retval = false;
    if (this->pc/4 < this->instructions->size()) {
        instruction* current_instruction = this->instructions->at(this->pc/4);
        uint32_t result = current_instruction->execute(this->pc);
        printf("PC: 0x%08x, Instruction: %s, Result: 0x%08x...", this->pc, current_instruction->get_name().c_str(), result);
        this->pc = result;
        retval = true;
    } 
    if (this->pc/4 >= this->instructions->size()) {
        retval = false;
    }
        
    return retval;
}

bool cpu_state::check_state(uint32_t pc, uint32_t* registers, uint32_t* memory) {
    bool retval = true;
    if (this->pc!= pc) {
        printf(" \033[0;31mFAILED\033[0m\nPC mismatch: expected 0x%08x, got 0x%08x\n", this->pc, pc);
        retval = false;
    }

    for (int i = 1; (i < 32 && retval) ; i++) {
#if 0
        if (this->registers->get_register(i)->is_used()) {
            //retval = retval && this->registers->get_register(i)->read() == registers[i];
            if (this->registers->get_register(i)->read()!= registers[i]) {
                printf("Register mismatch: expected 0x%08x, got 0x%08x for register x%d\n", this->registers->get_register(i)->read(), registers[i], i);
                retval = false;
            }
        }
#else
        if (this->registers->get_register(i)->read() != registers[i]) {
            printf(" \033[0;31mFAILED\033[0m\nRegister mismatch: expected 0x%08x, got 0x%08x for register x%d\n", this->registers->get_register(i)->read(), registers[i], i);
            retval = false;
        }
#endif
    }

    if (memory != NULL) {
        if (memcmp(this->memory, memory, sizeof(this->memory))!= 0) {
            printf(" \033[0;31mFAILED\033[0m\nMemory mismatch\n");
            for (int i = 0; i < sizeof(this->memory)/sizeof(uint32_t); i++) {
                if (this->memory[i]!= memory[i]) {
                    printf("Memory mismatch at index %d: expected 0x%08x, got 0x%08x\n", i*sizeof(uint32_t), this->memory[i], memory[i]);
                    break;
                }
            }
            retval = false;
        }

    }


    if (retval) {
        printf(" \033[0;32mPASSED\033[0m\n");
    }
    return retval;
}

// Define a type alias for the constructor function
using InstructionConstructor = std::function<instruction*(const std::string&, register_file*)>;

// Create a map to store constructor functions
std::map<std::string, InstructionConstructor> instructionConstructors = {
    {"lui",   [](const std::string& args, register_file* regs) { return new lui_instruction(args, regs); }},
    {"ori",   [](const std::string& args, register_file* regs) { return new op_imm_instruction("ori", args, regs); }},
    {"addi",  [](const std::string& args, register_file* regs) { return new op_imm_instruction("addi", args, regs); }},
    {"sltiu", [](const std::string& args, register_file* regs) { return new op_imm_instruction("sltiu", args, regs); }},
    {"slti",  [](const std::string& args, register_file* regs) { return new op_imm_instruction("slti", args, regs); }},
    {"andi",  [](const std::string& args, register_file* regs) { return new op_imm_instruction("andi", args, regs); }},
    {"xori",  [](const std::string& args, register_file* regs) { return new op_imm_instruction("xori", args, regs); }},
    {"slli",  [](const std::string& args, register_file* regs) { return new op_imm_instruction("slli", args, regs); }},
    {"srli",  [](const std::string& args, register_file* regs) { return new op_imm_instruction("srli", args, regs); }},
    {"srai",  [](const std::string& args, register_file* regs) { return new op_imm_instruction("srai", args, regs); }},
    {"add",   [](const std::string& args, register_file* regs) { return new op_instruction("add", args, regs); }},
    {"sub",   [](const std::string& args, register_file* regs) { return new op_instruction("sub", args, regs); }},
    {"sll",   [](const std::string& args, register_file* regs) { return new op_instruction("sll", args, regs); }},
    {"slt",   [](const std::string& args, register_file* regs) { return new op_instruction("slt", args, regs); }},
    {"sltu",  [](const std::string& args, register_file* regs) { return new op_instruction("sltu", args, regs); }},
    {"xor",   [](const std::string& args, register_file* regs) { return new op_instruction("xor", args, regs); }}, 
    {"srl",   [](const std::string& args, register_file* regs) { return new op_instruction("srl", args, regs); }},
    {"sra",   [](const std::string& args, register_file* regs) { return new op_instruction("sra", args, regs); }},
    {"or",    [](const std::string& args, register_file* regs) { return new op_instruction("or", args, regs); }},
    {"and",   [](const std::string& args, register_file* regs) { return new op_instruction("and", args, regs); }},
    {"auipc",   [](const std::string& args, register_file* regs) { return new auipc_instruction(args, regs); }},
    {"blt",   [](const std::string& args, register_file* regs) { return new branch_instruction("blt",args, regs); }},
    {".insn", [](const std::string& args, register_file* regs) { return get_insn_instructions(args, regs); }},

};

void cpu_state::read_assembler_file(std::string filename) {
	std::ifstream file(filename);
	std::string line;

	std::vector<std::string> v;

    if (this->instructions == nullptr) {
        this->instructions = new std::vector<instruction*>();
    }

	while (std::getline(file, line)) {
		int split_idx = line.find_first_of(' ');
		std::string instr_function = line.substr(0, split_idx);
#if 0
		printf("Instruction: %s\n", instr_function.c_str());
		printf("Arguments: %s\n", line.substr(split_idx + 1).c_str());
        printf("%s\n", line.c_str());
#endif
#if 0
        if (strncmp(instr_function.c_str(), "lui", 3) == 0) {
            lui_instruction* lui = new lui_instruction(line.substr(split_idx + 1), this->registers);
            this->instructions->push_back(lui);
        }
        else if (strncmp(instr_function.c_str(), "ori", 3) == 0) {
            op_imm_instruction* ori = new op_imm_instruction("ori", line.substr(split_idx + 1), this->registers);
            this->instructions->push_back(ori);
        }
        else if (strncmp(instr_function.c_str(), "addi", 4) == 0) {
            op_imm_instruction* addi = new op_imm_instruction("addi", line.substr(split_idx + 1), this->registers);
            this->instructions->push_back(addi);
        }
        else if (strncmp(instr_function.c_str(), "sltiu", 5) == 0) {
            op_imm_instruction* slti = new op_imm_instruction("sltiu", line.substr(split_idx + 1), this->registers);
            this->instructions->push_back(slti);
        }
        else if (strncmp(instr_function.c_str(), "slti", 4) == 0) {
            op_imm_instruction* slti = new op_imm_instruction("slti", line.substr(split_idx + 1), this->registers);
            this->instructions->push_back(slti);
        }
        else if (strncmp(instr_function.c_str(), "andi", 4) == 0) {
            op_imm_instruction* andi = new op_imm_instruction("andi", line.substr(split_idx + 1), this->registers);
            this->instructions->push_back(andi);
        }
        else if (strncmp(instr_function.c_str(), "xori", 4) == 0) {
            op_imm_instruction* xori = new op_imm_instruction("xori", line.substr(split_idx + 1), this->registers);
            this->instructions->push_back(xori);
        }
#else
        auto it = instructionConstructors.find(instr_function);
        if (it!= instructionConstructors.end()) {
            this->instructions->push_back(it->second(line.substr(split_idx + 1), this->registers));
        } else {
            printf("Invalid instruction: %s\n", instr_function.c_str());
        }
#endif
            
    }
    for (int i = 0; i < this->instructions->size(); i++) {
        printf("Instruction %d: %s\n", i, this->instructions->at(i)->get_name().c_str());
    }
}

void cpu_state::read_memory_file(std::string filename) {
	std::ifstream file(filename);
	std::string line;

    if (this->instructions == nullptr) {
        this->instructions = new std::vector<instruction*>();
    }
    uint32_t i = 0;
    while (std::getline(file, line)) {
        uint32_t instr = std::stoul(line, nullptr, 16);
        this->memory[i++] = instr;
        if (instr == 0) {
            //printf("Skipping zero instruction\n");
            break;
            continue;
        }
        uint8_t op_code = GET_OPCODE(instr);
        switch(op_code) {
            case LUI:
                {
                    lui_instruction* lui = new lui_instruction(instr, this->registers);
                    this->instructions->push_back(lui);
                    break;
                }
            case opcodes::AUIPC:
                {
                    auipc_instruction* auipc = new auipc_instruction(instr, this->registers);
                    this->instructions->push_back(auipc);
                    break;
                }
            case JAL:
                {
                    jal_instruction* jal = new jal_instruction(instr, this->registers);
                    this->instructions->push_back(jal);
                    break;
                }
            case JALR:
                {
                    jalr_instruction* jalr = new jalr_instruction(instr, this->registers);
                    this->instructions->push_back(jalr);
                    break;
                }
            case BRANCH:
                {
                    branch_instruction* branch = new branch_instruction(instr, this->registers);
                    this->instructions->push_back(branch);
                    break;
                }
            case LOAD:
                {
                    load_instruction* load = new load_instruction(instr, this->registers, this->memory);
                    this->instructions->push_back(load);
                    break;
                }
            case STORE:
                {
                    store_instruction* store = new store_instruction(instr, this->registers, this->memory);
                    this->instructions->push_back(store);
                    break;
                }
                break;
            case IMM:
                {
                    op_imm_instruction* imm = new op_imm_instruction(instr, this->registers);
                    this->instructions->push_back(imm);
                    break;
                }
            case OP:
                {
                    op_instruction* op = new op_instruction(instr, this->registers);
                    this->instructions->push_back(op);
                    break;
                }
            case FENCE:
            case EBREAK:
                {
                    //throw std::invalid_argument("Fence and EBREAK instructions are not implemented yet.");
                    fence_instruction* fence = new fence_instruction(instr, this->registers);
                    this->instructions->push_back(fence);
                    break;
                }
            default:
                printf("Invalid opcode: 0x%x\n", op_code);
                printf("Instruction: %s\n", line.c_str());
                printf("line: %d\n", i);
                throw std::invalid_argument("Invalid instruction.");
                break;
        }
    }
}

cpu_state::~cpu_state() {
    free(this->instructions);
}