#include <stdlib.h>
#include "uart_tx.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
#if 0
int main(int argc, char **argv) {
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);

	// Create an instance of our module under test
	hello *tb = new hello();

	Verilated::traceEverOn(true);
	VerilatedVcdC* vcd = new VerilatedVcdC;
	
	tb->trace(vcd, 99);
	vcd->open("wave.vcd");

	int i = 0;
	// Tick the clock until we are done
	while(!Verilated::gotFinish()) {
		tb->CLK = 1;
		tb->eval();
		vcd->dump(i);
		i++;
		tb->CLK = 0;
		tb->eval();
		vcd->dump(i);
		vcd->flush();
		printf("%d\r", i);
		fflush(stdout);
		i++;
	} exit(EXIT_SUCCESS);

	vcd->close();
	tb->final();
}
#else
int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<uart_tx> *tb = new TESTBENCH<uart_tx>();

	uart_tx* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0],".vcd"));
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

#endif
