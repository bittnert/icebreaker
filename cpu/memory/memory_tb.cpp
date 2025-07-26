#include <stdlib.h>
#include "memory.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "verilated_vpi.h"
#include "testbench_class.hpp"
#include <fstream>
#include <string>
#include "instructions.hpp"

int main(int argc, char *argv[]) {
    
    // Providing a seed value
	srand((unsigned) time(NULL));

	// Get a random number
	int random = rand();

    uint32_t* memory_content_32 = new uint32_t[8*1024];
    uint8_t* memory_content = (uint8_t*) memory_content_32;

	TESTBENCH<memory> *tb = new TESTBENCH<memory>();

    tb->opentrace("memory.vcd");
    //cpu* dut = tb->get_dut();
    memory* top = tb->get_dut();
    //tb->reset();

    for (int i = 0; i < 10000; i++) {
        top->data_in = i & 0xFF;
        top->addr = i;
        top->wr = 1;
        top->en=1;
        top->size = 0;
        tb->tick();
        memory_content[i] = i & 0xFF;
    }
    uint32_t data_out;
    for (int i = 0; i < 10000; i=i+4) {
        top->wr = 0;
        top->addr = i;
        top->size = 2;
        tb->tick();
        data_out = top->data_out;
        if (data_out!= memory_content_32[i/4]) {
            printf("Error at address %d: expected %02x, got %02x\n", i, memory_content_32[i/4], data_out);
        }
        else {
            printf("Success at address %d: %x == %x\n", i, memory_content_32[i/4], data_out);
        }
    }

    return 0;
}