#include "instructions.hpp"
#include <boost/algorithm/string.hpp>


fence_instruction::fence_instruction(uint32_t instr, register_file* registers) {

}


uint32_t fence_instruction::execute(uint32_t pc) {
    return pc + 4;
}