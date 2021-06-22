#include <stdlib.h>
#include "uart_baud_gen.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
#define PRESCALER 4
int main (int argc, char **argv)
{

	TESTBENCH<uart_baud_gen> *tb = new TESTBENCH<uart_baud_gen>();
	uart_baud_gen* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0], ".vcd"));

	dut->rst_n = 0;

	dut->prescaler = PRESCALER;
	tb->tick();
	tb->tick();
	dut->rst_n = 1;

	for (int i = 0; i < PRESCALER/2; i++)
	{
		tb->tick();
	}

	dut->prescaler = PRESCALER/2;

	for (int j = 0; j < LOOP_LIMIT; j++)
	{
		printf("%f\r",(float)100*j/LOOP_LIMIT);
		fflush(stdout);
		tb->tick();
	} //exit(EXIT_SUCCESS);

	printf("\n");

	return 0;
}

