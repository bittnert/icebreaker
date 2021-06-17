#include <stdlib.h>
#include "uart_fifo.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<uart_fifo> *tb = new TESTBENCH<uart_fifo>();

	uart_fifo* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0], ".vcd"));

	dut->rst = 1;

	tb->tick();
	tb->tick();
	dut->rst = 0;

	int i = 0;
	dut->wren = 1;

#if 0
	while(!dut->full)
#else
	for(int j = 0; j < 18; j++)
#endif
	{
		printf("writing %d into fifo\n", i);
		dut->data_in = i;
		tb->tick();
		i++;
	}

	dut->wren = 0;
	dut->rden = 1;

	i = 0;
	int j = 0;
#if 0
	while(!dut->empty)
#else
	for(int k= 0; k < 18; k++)
#endif
	{
		j = dut->data_out;
		if (j == i)
		{
			printf("read %d correct\n", j);
		}
		else
		{
			printf("ERROR: read %d expect %d\n", j, i);
		}
		tb->tick();
		i++;
	}
	
	return 0;
#if 0
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
#endif
}

