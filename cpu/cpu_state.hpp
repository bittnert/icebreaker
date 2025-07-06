#ifndef CPU_STATE_HPP
#define CPU_STATE_HPP

#include <cstdint>
class instruction;
#include "instructions.hpp"


class reg {
    public:
        reg();
        void write(uint32_t data);
        uint32_t read();
        bool is_used();
    private:
        uint32_t value;
        bool used;
};

class register_file{
    public:
        register_file();
        void write_register(int index, uint32_t data);
        reg* get_register(int index);
    private:
        reg* registers[32];
};

class cpu_state {
    public:
        cpu_state(std::string assembler_file);
        ~cpu_state();

        bool execute();
        bool check_state(uint32_t pc, uint32_t* registers, uint32_t* memory);
    private:
        register_file* registers;
        std::vector<instruction*>* instructions;
        uint32_t pc;
        void read_assembler_file(std::string filename);
        void read_memory_file(std::string filename);
        uint32_t memory[65536];
};

#endif