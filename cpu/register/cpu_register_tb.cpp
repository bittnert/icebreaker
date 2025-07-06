
#include <stdlib.h>
#include "cpu_register.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"


int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<cpu_register> *tb = new TESTBENCH<cpu_register>();

    tb->opentrace("register.vcd");
    cpu_register* dut = tb->get_dut();
	srand(time(NULL));

    uint32_t register_data[32];


    register_data[0] = 0;

    for (int i = 1; i < 32; i++) {
        uint32_t value = rand() & 0xFFFFFFFF;
        register_data[i] = value;
        dut->rd = value;
        dut->rd_addr = i;
        dut->rd_en = 1;
        tb->tick();
    }
    bool retval = true;
    for (int i = 0; i < 10000; i++) {
        uint32_t value = rand() & 0xFFFFFFFF;
        uint32_t rs1_addr = rand() & 0x1F;
        uint32_t rs2_addr = rand() & 0x1F;
        uint32_t rd_addr = rand() & 0x1F;
        dut->rs1_addr = rs1_addr;
        dut->rs2_addr = rs2_addr;
        dut->rd_addr = rd_addr;
        dut->rd = value;
        tb->tick();
        if (dut->rs1 != register_data[rs1_addr]) {
            printf("ERROR: rs1 value mismatch at cycle %d (expected: %x got %x)\n", i, dut->rs1, register_data[rs1_addr]);
            retval = false;
        }
        if (dut->rs2 != register_data[rs2_addr]) {
            printf("ERROR: rs2 value mismatch at cycle %d (expected: %x got %x)\n", i, dut->rs2, register_data[rs2_addr]);
            retval = false;
        }
        register_data[rd_addr] = value;
    }

    if (!retval) {
        return -1;
    }

    return 0;
}