#include <stdlib.h>
#include "uart_loopback.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
#define PRESCALER 10

#if 1

void tick(uart_loopback *dut, VerilatedVcdC* trace);
int tickcount = 0;

void send_bit(uart_loopback* dut, bool bit, int prescaler, VerilatedVcdC* trace)
{
	dut->RX = bit;
	printf("sending %d\n", bit);
	for(int i = 0; i < prescaler + 1; i++)
	{
		tick(dut, trace); 
	}
}
void tick(uart_loopback *dut, VerilatedVcdC* trace)
{
	tickcount++;
	dut->CLK = 0;
	dut->eval();
	trace->dump(10*tickcount - 2);
	dut->CLK = 1;
	dut->eval();
	trace->dump(10*tickcount);
	dut->CLK = 0;
	dut->eval();
	trace->dump(10*tickcount + 5);
	trace->flush();
}

int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);
	VerilatedVcdC *trace;

	uart_loopback* dut = new uart_loopback();

	trace = new VerilatedVcdC();

	char c = 0x55;

	printf("trace: 0x%x\n", trace);
	dut->trace(trace, 99);
	trace->open(strcat(argv[0], ".vcd"));
	dut->RX = 1;
	dut->BTN_N = 0;
	tick(dut, trace);
	tick(dut, trace);
	dut->BTN_N = 1;
	
	send_bit(dut, 0, PRESCALER, trace);

	for(int i = 0; i < sizeof(char)*8; i++)
	{
		printf("c: 0x%x\n", c);
		send_bit(dut, (c & 0x1) == 1, PRESCALER, trace);
		c = c >> 1;
	}
	
	send_bit(dut, 1, PRESCALER, trace);

	for (int j = 0; j < LOOP_LIMIT; j++)
	{
		printf("%f\r",(float)100*j/LOOP_LIMIT);
		fflush(stdout);
		tick(dut, trace);
	} //exit(EXIT_SUCCESS);

	tick(dut, trace);
	tick(dut, trace);
	trace->close();

}
#else
void send_bit(TESTBENCH<uart_loopback>* tb, bool bit, int prescaler)
{
	uart_loopback* dut = tb->get_dut();
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
	TESTBENCH<uart_loopback> *tb = new TESTBENCH<uart_loopback>();

	char c = 0x55;

	uart_loopback* dut = tb->get_dut();
	//tb->opentrace(strcat(argv[0], ".vcd"));
	dut->BTN_N = 0;

	printf("test\n");

	//dut->prescaler_in = PRESCALER;
	dut->RX = 1;
	printf("test\n");
	tb->tick();
	printf("test\n");
	tb->tick();
	dut->BTN_N = 1;

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


#if 1
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
#endif
