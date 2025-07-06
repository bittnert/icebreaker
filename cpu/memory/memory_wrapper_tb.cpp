#include <stdlib.h>
#include "memory_wrapper.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

char* memory_size[] = {"8-bit", "16-bit", "32-bit"};

uint32_t memory_read(memory_wrapper* dut, TESTBENCH<memory_wrapper>* tb, int addr) {
    dut->addr = addr & ~0x3;
    dut->size = 2;
    dut->wr_rd = 0;
    dut->en = 1;
    tb->tick();
    return dut->data_out;
}

bool memory_test(memory_wrapper* dut, TESTBENCH<memory_wrapper>* tb, int size) {
    int addr = rand()/(RAND_MAX + 1.0) * 32;
    int data = rand()&(0xFFFFFFFF);

    unsigned int mask[] = {
        0xFF,
        0xFFFF,
        0xFFFFFFFF
     };
    
    uint8_t offset = addr & 0x3;

    uint32_t old_value = memory_read(dut, tb, addr);

    uint32_t expected_value = (old_value & ~(mask[size] << (8*offset))) | (data & mask[size]) << (8*offset);

    dut->addr = addr;
    dut->size = size;
    dut->data_in = data;
    dut->wr_rd = 1;
    tb->tick();
    uint32_t exception = dut->exception_out;
    int new_value = memory_read(dut, tb, addr);

    if (size == 1 && (offset == 1 || offset == 3)) {
        if (!exception) {
            printf("ERROR: expected exception at address %d\n", addr);
            return false;
        }
        if (new_value!= old_value) {
            printf("ERROR: Write operation should have failed but changed data");
            return false;
        }
        /*We should get an exception here*/
    }
    else if (size == 2 && offset != 0) {
        if (!exception) {
            printf("ERROR: expected exception at address %d\n", addr);
            return false;
        }
        if (new_value!= old_value) {
            printf("ERROR: Write operation should have failed but changed data");
            return false;
        }
        /*We should get an exception here*/
    } else {
        if (new_value != expected_value) {
            printf("ERROR: Memory write mismatch at address %d (written %x, expected %x, got %x, size %s, old: %x)\n", addr, data, expected_value, new_value, memory_size[size], old_value);
            return false;
        }
    }
    return true;
}

int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<memory_wrapper> *tb = new TESTBENCH<memory_wrapper>();

	srand(time(NULL));

	memory_wrapper* dut = tb->get_dut();
    tb->opentrace("memory_wrapper.vcd");

    for(int i = 0; i < 10000; i++){
        for(int j = 0; j < 3; j++){
            memory_test(dut, tb, j);
        }
    }
}