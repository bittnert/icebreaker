#include <stdlib.h>
#include "uart_test.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<uart_test> *tb = new TESTBENCH<uart_test>();

	uart_test* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0], ".vcd"));

	dut->BTN_N = 0;

	tb->tick();
	tb->tick();
	dut->BTN_N = 1;

	int i = 0;
	
	for (i = 0; i < LOOP_LIMIT; i++) {
		tb->tick();
	}
	return 0;
}
