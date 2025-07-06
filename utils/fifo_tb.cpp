#include <stdlib.h>
#include "fifo.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
#define FIFO_DEPTH 16
int main (int argc, char **argv)
{

	TESTBENCH<fifo> *tb = new TESTBENCH<fifo>();
	fifo* dut = tb->get_dut();
	tb->opentrace(strcat(argv[0], ".vcd"));


	dut->rst_in = 0;

	tb->tick();
	tb->tick();
	dut->rst_in = 1;

	// Try to write 17 elements into the FIFO. This should not be possible (only 15 entries are allowed).
	// Therefore, this should cause the FIFO to drop 2 values.
	for (int i = 0; i <= FIFO_DEPTH; i++) {
		dut->datain = i;
		dut->wr_in = 1;
		tb->tick();
	}
	// Disable wr_in to stop the FIFO from latching the data.
	dut->wr_in = 0;

	// FIFO should be full now
	if (!dut->full_out) {
		printf("ERROR: FIFO not full\n");
	}
	int i = 0;
	dut->rd_in = 1;
	while (!dut->empty_out) {
		tb->tick();
		if (i != dut->dataout) {
			printf("ERROR: FIFO data out mismatch at index %d (expected %d, got %d)\n", i, i, dut->dataout);
		}
		if (i > FIFO_DEPTH) {
			printf("ERROR: FIFO data out out of range\n");
			break;
        }
		i++;
	}

	// Try to read next value even if FIFO is empty.
	tb->tick();

	dut->datain = 0xFF;
	dut->wr_in = 1;

	tb->tick();
	tb->tick();

#if 0
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

#endif
	printf("\n");

	return 0;
}

