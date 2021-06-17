
#include <stdlib.h>
#include "uart.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<uart> *tb = new TESTBENCH<uart>();

	char str_buf[] = "Hello World!";
	int str_len = sizeof(str_buf);

	uart* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0], ".vcd"));

	tb->reset();

	int i = 0;
	dut->wren = 1;
	while (i < str_len)
	{
		if( !dut->full)
		{
			dut->data_in = str_buf[i];
			i++;
		}
		tb->tick();
	}

	dut->wren = 0;
	while (dut->fill_lvl > 0)
	{
		tb->tick();
	}
	return 0;
}

