
#include "verilated.h"
#include <verilated_vcd_c.h>


template<class MODULE> class TESTBENCH 
{
	unsigned long tickcount;
	MODULE *dut;
	VerilatedVcdC *trace;	

public:
	TESTBENCH()
	{
		Verilated::traceEverOn(true);
		dut = new MODULE;
		tickcount = 0;
	}

	~TESTBENCH(void)
	{
		delete dut;
		dut = NULL;
	}

	void reset()
	{
		dut->rst = 1;
		this->tick();
		this->tick();
		dut->rst = 0;
	}

	void opentrace (const char *vcdname) 
	{
		if (!trace)
		{
			trace = new VerilatedVcdC;
			dut->trace(trace, 99);
			trace->open(vcdname);
		}
	}
	
	void close (void)
	{
		if (trace) 
		{
			trace->close();
			trace = NULL;
		}
	}	


	MODULE* get_dut()
	{
		return dut;
	}

	void tick(void)
	{
		printf("tick start");
		tickcount++;

		dut->CLK = 0;
		dut->eval();
		if (trace) 
		{
			printf("dumping");
			trace-> dump(10*tickcount - 2);
		}

		dut->CLK = 1;
		dut->eval();

		if (trace) 
		{
			trace-> dump(10*tickcount);
		}

		dut->CLK = 0;
		dut->eval();

		if (trace) 
		{
			trace-> dump(10*tickcount + 5);
			trace->flush();
		}
	}

	bool done(void)
	{
		return (Verilated::gotFinish());
	}
};
