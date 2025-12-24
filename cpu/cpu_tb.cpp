#include <stdlib.h>
#include "cpu.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_fst_c.h>
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
vpiHandle tx_fill_level;
vpiHandle mem_low_hdl;
vpiHandle mem_high_hdl;

static void get_vpi_handles() {
	vh = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.pc", NULL);
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

	tx_fill_level = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.uart.uart.tx_fifo_fill_lvl", NULL);
    if (!tx_fill_level) vl_fatal(__FILE__, __LINE__, "sim_main", "tx fill level handle not found");

	//mem_low_hdl = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.main_ram.mem_low", NULL);
	//if (!mem_low_hdl) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory low handle not found");

	//mem_high_hdl = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.main_ram.mem_high", NULL);
	//if (!mem_high_hdl) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory high handle not found");
}

#define BAUDRATE 57600
#define FREQUENCY 12500000

void send_char(TESTBENCH<cpu> *tb, char c);
void send_string(TESTBENCH<cpu> *tb, char* buffer);
int main (int argc, char **argv)
{
	t_vpi_value memory_read;// = 0x12345678;
	memory_read.format = vpiIntVal;
	t_vpi_value pc;// = 0x12345678;
	pc.format = vpiIntVal;
	pc.value.integer = 0x12345678;
	Verilated::commandArgs(argc, argv);

	if (argc < 2) {
		printf("Usage: %s <firmware binary file>\n", argv[0]);
	}

    ifstream is;
	is.open (argv[1], ios::binary );
	// get length of file:
	is.seekg (0, ios::end);
	int length = is.tellg();
	is.seekg (0, ios::beg);
	// allocate memory:
	char* buffer = new char [length];
	// read data as a block:
	is.read (buffer,length);
	is.close();

	TESTBENCH<cpu> *tb = new TESTBENCH<cpu>();

    tb->opentrace("cpu.fst");
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
    /* Enough to store for 128 kbyte of size*/
	t_vpi_value tx_fill_level_val;
	tx_fill_level_val.format = vpiIntVal;
	vpi_get_value(tx_fill_level, &tx_fill_level_val);
	printf("Waiting for TX send out\n");
	while (tx_fill_level_val.value.integer > 0) {
		tb->tick();
        vpi_get_value(tx_fill_level, &tx_fill_level_val);
		printf("\rwaiting for TX to be empty: %d", tx_fill_level_val.value.integer);
	}
    char length_array[9];
	snprintf(length_array, 9, "%d\n\0", length);
	send_string(tb, length_array);

	printf("Waiting for TX send out\n");
	vpi_get_value(tx_fill_level, &tx_fill_level_val);
	while (tx_fill_level_val.value.integer > 0) {
		tb->tick();
        vpi_get_value(tx_fill_level, &tx_fill_level_val);
		printf("waiting for TX to be empty: %d\r", tx_fill_level_val.value.integer);
	}

	printf("sending %d bytes\n", length);
	for (int i = 0; i < length; i++) {
		send_char(tb, buffer[i]);
		printf("Sending binary: %f %\r", (float)i*100 / (float)length);
    }
	printf("\nFinished sending\n");

	for (int i = 0; i < 1000000; i++) {
		tb->tick();
		printf("\rWaiting for execution: %f %", (float)i*100 / (float)1000000);
	}
	printf("\nExecution finished\n");
	
	/*
	for (int i = 0; i < (length + 3)/4; i++) {
		vpiHandle low_element = vpi_handle_by_index(mem_low_hdl, i);
		vpiHandle high_element = vpi_handle_by_index(mem_high_hdl, i);
		if (low_element && high_element) {
			s_vpi_value low_value, high_value;
			low_value.format = vpiIntVal;
			high_value.format = vpiIntVal;
			vpi_get_value(low_element, &low_value);
			vpi_get_value(high_element, &high_value);
			printf("Memory element %d: 0x%04x%04x\n", i,  high_value.value.integer, low_value.value.integer);
		}
	}
		*/
    return 0;
}

void send_string(TESTBENCH<cpu> *tb, char* buffer) {
	int i = 0;
	printf("seding length: ");
	while (buffer[i]!= '\0') {
		send_char(tb, buffer[i]);
		printf("%c", buffer[i]);
		i++;
	}
	printf("\n");
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