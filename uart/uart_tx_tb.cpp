#include <stdlib.h>
#include "uart_tx.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<uart_tx> *tb = new TESTBENCH<uart_tx>();

	uart_tx* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0], ".vcd"));
	dut->rst = 1;

	tb->tick();
	tb->tick();
	dut->rst = 0;

	for (int i = 0; i < 10; i++) {
		tb->tick();
	}

	dut->data = 'h';
	dut->rts = 1;
	
	while(dut->cts == 1)
	{
		tb->tick();
	}

		tb->tick();
	//dut->rts = 0;	


	#if 0
	while (!tb->done())
#else
	for (int j = 0; j < LOOP_LIMIT; j++)
#endif
	{
		printf("%f\r",(float)100*j/LOOP_LIMIT);
		fflush(stdout);
		tb->tick();
	} //exit(EXIT_SUCCESS);
}

