
#include "instructions.hpp"
#include <boost/algorithm/string.hpp>

using namespace boost::algorithm;

#if 0
std::map<int, InstructionConstructor> instructionConstructors = {

};
#endif

vector<string> split_arguments(string& arguments, char delimiter) {
    vector<string> result;
    size_t pos = 0;
    string token;
    while ((pos = arguments.find(delimiter, 0))!= string::npos) {
        token = arguments.substr(0, pos);
        trim(token);
        result.push_back(token);
        arguments.erase(0, pos + 1);
    }
    trim(arguments);
    result.push_back(arguments);
    
    return result;
}

branch_instruction* get_branch_instruction(vector<string> args, register_file* registers) {
    string arguments(args.at(2));
    for (int i = 3; i < args.size(); i++) {
        arguments.append(", ").append(args[i]);
    }
    int op_code = stoi(args[1], nullptr, 0);
    switch (op_code) {
        case 4:
            return new branch_instruction("blt", arguments, registers);
        default:
            throw std::runtime_error("Invalid branch instruction");
    }
}

instruction* get_insn_instructions(const std::string& instr, register_file* registers) {
    instruction* result = nullptr;
    std::string args(instr);
    printf("args: %s\n", args.c_str());
    vector<string> arguments = split_arguments(args, ',');
    
    for(int i = 0; i < arguments.size(); i++) {
        printf("Instruction %d: %s\n",i, arguments[i].c_str());
    }
    vector<string> instruction_parts = split_arguments(arguments[0], ' ');
    int op_code = stoi(instruction_parts[1], nullptr, 0);

    switch (op_code) {
        case 0x63:
            result = get_branch_instruction(arguments, registers);
            break;
        default:
            throw std::runtime_error("Invalid instruction");
    }
    return result;
}