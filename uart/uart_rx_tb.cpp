#include <stdlib.h>
#include "uart_rx.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
#define PRESCALER 10


void send_bit(TESTBENCH<uart_rx>* tb, bool bit, int prescaler)
{
	uart_rx* dut = tb->get_dut();
	dut->RX = bit;
	printf("sending %d\n", bit);
	for(int i = 0; i < prescaler + 1; i++)
	{
		tb->tick();
	}
}

int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<uart_rx> *tb = new TESTBENCH<uart_rx>();

	char c = 0x55;

	uart_rx* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0], ".vcd"));
	dut->rst_n = 0;

	dut->prescaler_in = PRESCALER;
	dut->RX = 1;
	tb->tick();
	tb->tick();
	dut->rst_n = 1;

	send_bit(tb, 0, PRESCALER);

	for(int i = 0; i < sizeof(char)*8; i++)
	{
		printf("c: 0x%x\n", c);
		send_bit(tb, (c & 0x1) == 1, PRESCALER);
		c = c >> 1;
	}
	
	send_bit(tb, 1, PRESCALER);

	for(int i = 0; i < sizeof(char); i++)
	{
		tb->tick();
	}
#if 0
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

