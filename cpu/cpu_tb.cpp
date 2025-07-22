#include <stdlib.h>
#include "cpu.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "verilated_vpi.h"
#include "testbench_class.hpp"
#include <fstream>
#include <string>
#include "instructions.hpp"

vpiHandle vh;
vpiHandle reg_mem;
vpiHandle mem_wr;
vpiHandle mem_en;
vpiHandle reg_en;
vpiHandle mem_hdl;

static void get_vpi_handles() {
	vh = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.decoder.pc", NULL);
	if (!vh) vl_fatal(__FILE__, __LINE__, "sim_main", "PC handle not found");

	reg_mem = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.register_file.reg_a.mem", NULL);
	if (!reg_mem) vl_fatal(__FILE__, __LINE__, "sim_main", "Register memory handle not found");

	mem_wr = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.mem_wr", NULL);
	if (!mem_wr) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory write handle not found");

	reg_en = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.reg_en", NULL);
	if (!reg_en) vl_fatal(__FILE__, __LINE__, "sim_main", "Register enable handle not found");

	/*mem_en = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.mem_en", NULL);
	if (!mem_en) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory enable handle not found");
*/
	mem_hdl = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.bootloader.mem", NULL);
    if (!mem_hdl) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory handle not found");
}

#define BAUDRATE 9600
#define FREQUENCY 12500000

void send_char(TESTBENCH<cpu> *tb, char c);
int main (int argc, char **argv)
{
	t_vpi_value memory_read;// = 0x12345678;
	memory_read.format = vpiIntVal;
	t_vpi_value pc;// = 0x12345678;
	pc.format = vpiIntVal;
	pc.value.integer = 0x12345678;
	Verilated::commandArgs(argc, argv);

    
	TESTBENCH<cpu> *tb = new TESTBENCH<cpu>();

    tb->opentrace("cpu.vcd");
    //cpu* dut = tb->get_dut();
    cpu* top = tb->get_dut();

	//cpu* top = new cpu;  // Create an instance of the top-level module
	get_vpi_handles();
	//dut->register_file->reg_a->mem[0] = 10;
	//tb->reset();
		top->BTN_N = 0;
		tb->tick();
		tb->tick();
		top->BTN_N = 1;

    /*for (int i = 0; i < 10000000; i++) {
        tb->tick();
    }*/
	send_char(tb, 'H');
	send_char(tb, 'e');
	for (int i = 0; i < 100000; i++) {
		tb->tick();
	}
    return 0;
}

void send_char(TESTBENCH<cpu> *tb, char c) {
	int clocks_per_bit = FREQUENCY / BAUDRATE;

	cpu* top = tb->get_dut();
	/*Set level to one to start with an start bit*/
	top->RX = 1;
	/* Wait for 5 bit width to ensure level was high before we start to send data*/
	for(int i = 0; i < clocks_per_bit*5; i++) {
		tb->tick();
	}

	/* Start bit*/
	top->RX = 0;
	for(int i = 0; i < clocks_per_bit; i++) {
		tb->tick();
	}

	for(int i = 0; i < 8; i++) {
		/* Send bit from the character */
        top->RX = (c >> i) & 1;
        for(int j = 0; j < clocks_per_bit; j++) {
            tb->tick();
        }
	}
	top->RX = 1;
	for(int i = 0; i < clocks_per_bit; i++) {
        tb->tick();
    }
}