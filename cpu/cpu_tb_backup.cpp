
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

	mem_en = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.mem_en", NULL);
	if (!mem_en) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory enable handle not found");

	mem_hdl = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.main_ram.mem", NULL);
    if (!mem_hdl) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory handle not found");
}


int main (int argc, char **argv)
{
	t_vpi_value memory_read;// = 0x12345678;
	memory_read.format = vpiIntVal;
	t_vpi_value pc;// = 0x12345678;
	pc.format = vpiIntVal;
	pc.value.integer = 0x12345678;
	Verilated::commandArgs(argc, argv);


	//cpu_state cpu_state("data.S");
	cpu_state cpu_state("data.mem");

	#if 0
    // Initialize simulation inputs
    top->CLK = 0;
    top->rst = 1;

    // Evaluate the model
    top->eval();
	printf("Initial PC: 0x%08x\n", pc.value.integer);
	vpi_get_value(vh, &pc);
	printf("Initial PC: 0x%08x\n", pc.value.integer);
	#endif
	
#if 0

	if (!reg_mem) {
		printf("Failed to get register memory handle\n");
        return 1;
	}

	vpiHandle element = vpi_handle_by_index(reg_mem, 0);
	if (element) {
		s_vpi_value value;
		value.format = vpiIntVal;
		vpi_get_value(element, &value);
		printf("Got register memory handle\n");
		printf("First element: 0x%08x\n", value.value.integer);
		vpi_free_object(element);
	}
	else {
        printf("Failed to get register memory element\n");
	}

	int size = vpi_get(vpiSize, reg_mem);
	int type = vpi_get(vpiType, reg_mem);
	printf("Memory size: %d, type: %d\n", size, type);

	vpiHandle word_iter = vpi_iterate(vpiReg, reg_mem);
	vpiHandle word_handle;
	s_vpi_value word_value;

	if (!word_iter) {
		printf("Failed to get meomry word iterator\n");
	} else {
		printf("Got memory word iterator\n");
	}

	while ((word_handle = vpi_scan(word_iter))) {
		vpi_get_value(word_handle, &word_value);
        printf("Register memory: 0x%08x: 0x%08x\n", word_handle, word_value.value.integer);
	}
#else
	TESTBENCH<cpu> *tb = new TESTBENCH<cpu>();

    tb->opentrace("cpu.vcd");
    //cpu* dut = tb->get_dut();
    cpu* top = tb->get_dut();

	//cpu* top = new cpu;  // Create an instance of the top-level module
	get_vpi_handles();
	//dut->register_file->reg_a->mem[0] = 10;
	tb->reset();
	return 0;
	uint32_t counter = 0;
	memory_read.format = vpiIntVal;
	while(counter == 0) {
		tb->tick();
		vpi_get_value(mem_en, &memory_read);
		if (memory_read.value.integer == 1) {
			counter = 5;
		}
	}
	//for (int i = 0; i < 200; i++) {
	bool exec_ret = true;
	uint32_t registers[32] = {0};
	uint32_t memory[65536] = {0};
	vpiHandle element;
	vpiHandle mem_entry;
	while (exec_ret) {
		t_vpi_value register_write;
		register_write.format = vpiIntVal;
		tb->tick();
		counter--;
		vpi_get_value(vh, &pc);
		if (counter == 0) {
			vpi_get_value(mem_en, &memory_read);
			exec_ret = cpu_state.execute();	
			for (uint8_t i = 1; i < 32; i++) {

				element = vpi_handle_by_index(reg_mem, i);
				if (element) {
					s_vpi_value value;
					value.format = vpiIntVal;
					vpi_get_value(element, &value);
					registers[i] = value.value.integer;
				}
				else {
					printf("Failed to get register memory element\n");
				}

			}

			for (uint32_t i = 0; i < 65536; i++) {
				mem_entry = vpi_handle_by_index(mem_hdl, i);
				if (mem_entry) {
					s_vpi_value value;
                    value.format = vpiIntVal;
                    vpi_get_value(mem_entry, &value);
                    memory[i] = value.value.integer;
                }
				else {
					printf("Failed to get memory element\n");
				}
			}

			vpi_get_value(vh, &pc);
			if (!cpu_state.check_state(pc.value.integer, registers, memory)) {
				printf("ERROR: State check failed %x\n", pc.value.integer);
                exec_ret = false;
                break;
			}
			#if 0
			if (!cpu_state.execute()){
				printf("Execution finished\n");
				break;
			}
			#endif
			counter = 5;
		}
		else {
			#if 0
			if (pc.value.integer > 0x198) {
				for (uint32_t i = 180; i < 200; i++) {
					element = vpi_handle_by_index(mem_hdl, i);
                    if (element) {
                        s_vpi_value value;
                        value.format = vpiIntVal;
                        vpi_get_value(element, &value);
                        printf("Register memory: 0x%08x: 0x%08x\n", i, value.value.integer);
                    }
                    else {
                        printf("Failed to get register memory element\n");
                    }
				}
			}
			#endif
		}

	}
	#if 1
	for (uint32_t i = 0; i < 800; i++) {
		if (i % 4 == 0) {
			printf("\n%04x: ", i*4);
		}
		printf("0x%08x ", memory[i]);
	}
	#endif
#endif
}