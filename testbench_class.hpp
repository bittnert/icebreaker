
#include "verilated.h"
#include <verilated_fst_c.h>


template<class MODULE> class TESTBENCH 
{
	unsigned long tickcount;
	MODULE *dut;
	VerilatedFstC *trace;	

public:
	TESTBENCH()
	{
		Verilated::traceEverOn(true);
		dut = new MODULE;
		trace = NULL;
		tickcount = 0;
	}

	~TESTBENCH(void)
	{
		delete dut;
		dut = NULL;
	}

	void reset()
	{
		dut->rst = 0;
		this->tick();
		this->tick();
		dut->rst = 1;
	}

	void opentrace (const char *vcdname) 
	{
		if (!trace)
		{
			trace = new VerilatedFstC;
			dut->trace(trace, 10);
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
		tickcount++;
		dut->CLK = 0;
		dut->eval();
		if (trace) 
		{
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
			if (tickcount % 10000 == 0){
				trace->flush();
			}
		}
	}

	bool done(void)
	{
		return (Verilated::gotFinish());
	}
};
