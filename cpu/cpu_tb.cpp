
#include <stdlib.h>
#include "cpu.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "verilated_vpi.h"
#include "testbench_class.hpp"
#include <fstream>
#include <string>
#include <regex>
#include <iostream>
#include <chrono>
#include "instructions.hpp"
#include <iomanip>  // For std::setw and std::setfill

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

bool fileExists(const std::string& filename) {
    std::ifstream file(filename);
    return file.good();
}

bool process_map_file(char* filename, uint32_t *sig_start, uint32_t *sig_end, uint32_t *code_end) {
	std::ifstream file(filename);
	if (!file.is_open()) {
		printf("Error: Could not open file %s\n", filename);
        return false;
	}

	std::regex sig_start_regex("^\\s*0x([0-9A-Fa-f]{8})\\s*begin_signature");
	std::regex sig_end_regex("^\\s*0x([0-9A-Fa-f]{8})\\s*end_signature");
	std::regex code_end_regex("^\\s*0x([0-9A-Fa-f]{8})\\s*rvtest_code_end");
	std::string line;
	std::smatch matches;
	bool found_sig_start = false;
	bool found_code_end = false;
	bool found_sig_end = false;

	while (std::getline(file, line)) {
		if (std::regex_search(line, matches, sig_start_regex)) {
			std::string hex_str = matches[1].str();
			*sig_start = std::stoul(hex_str, nullptr, 16);
			found_sig_start = true;
			printf("Found signature start: 0x%08x\n", *sig_start);
		}

		if (std::regex_search(line, matches, sig_end_regex)) {
			std::string hex_str = matches[1].str();
			*sig_end = std::stoul(hex_str, nullptr, 16);
			found_sig_end = true;
			printf("Found signature end: 0x%08x\n", *sig_end);
		}
		if (std::regex_search(line, matches, code_end_regex)) {
			std::string hex_str = matches[1].str();
			*code_end = std::stoul(hex_str, nullptr, 16);
			found_code_end = true;
			printf("Found code end: 0x%08x\n", *code_end);
        }
	}

	file.close();

	return found_sig_start && found_sig_end && found_code_end;
}

void copy_file(const std::string& src, const std::string& dest) {
    std::ifstream source(src, std::ios::binary);
    if (!source) {
        printf("Error: Could not open source file %s\n", src.c_str());
        return;
    }
    
    std::ofstream destination(dest, std::ios::binary);
    if (!destination) {
        printf("Error: Could not create destination file %s\n", dest.c_str());
        return;
    }
    
    destination << source.rdbuf();
    printf("Copied memory file from %s to %s\n", src.c_str(), dest.c_str());
}

int main (int argc, char **argv)
{
	uint32_t sig_start, sig_end, code_end;
	t_vpi_value memory_read;// = 0x12345678;
	memory_read.format = vpiIntVal;
	t_vpi_value pc;// = 0x12345678;
	pc.format = vpiIntVal;
	pc.value.integer = 0x12345678;
	Verilated::commandArgs(argc, argv);

	if (argc < 4) {
		printf("Usage: %s <hex file> <test binary> <test map file>\n", argv[0]);
        return 1;
    }

	if (!process_map_file(argv[argc-1], &sig_start, &sig_end, &code_end)) {
		printf("Error: Failed to parse map file %s\n", argv[argc-1]);
		return 1;
    }

	if (!fileExists(argv[argc-2])) {
		printf("Error: File %s not found\n", argv[argc-2]);
        return 1;
    } else {
		printf("Test binary file %s found\n", argv[argc-2]);
	}

#if 1
	printf("Starting simulation...\n");
	TESTBENCH<cpu> *tb = new TESTBENCH<cpu>();
    tb->opentrace("cpu.vcd");
    cpu* top = tb->get_dut();

	//top->MEMFILE = argv[argc - 3];
	std::string memfile_str = argv[argc - 3];
	std::string memfile_dest = "data.mem";
	copy_file(memfile_str, memfile_dest);



	get_vpi_handles();

	tb->reset();
	std::ifstream file(argv[argc - 2], std::ios::binary|std::ios::ate);

	std::streamsize size = file.tellg();
	file.seekg(0, std::ios::beg);

	uint32_t buffer;
	uint32_t idx = 0;

	uint8_t file_data[size];

	if (!file.read(reinterpret_cast<char*>(file_data), size)) {
		printf("could not read binary file\n");
		return 1;
	}

    file.close();
	printf("Reading memory...\n");
	vpiHandle mem_entry;
	uint32_t memory[2097152/sizeof(uint32_t)] = {0};
	for (uint32_t i = 0; i < 2097152/sizeof(uint32_t); i++) {
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
	printf("comparing %d bytes of memory...\n", size);
	if (memcmp(memory, file_data, size) == 0) {
		printf("Memory contents match!\n");
	} else {
		printf("Memory contents do not match!\n");
		return 1;
	}

	//cpu_state cpu_state("data.mem");

	vpi_get_value(vh, &pc);
	uint32_t counter = 0;
	uint32_t last_pc = pc.value.integer;
	uint32_t registers[32] = {0};
	while ((pc.value.integer < code_end) && !(pc.value.integer & 3 != 0) ) {
		//printf("Counter: %d, PC: 0x%08x\r", counter, pc.value.integer);
		tb->tick();
		counter++;
		vpi_get_value(vh, &pc);
		//printf("PC: 0x%08x, code end: 0x%08x\n", pc.value.integer, code_end);
		#if 0
		if (pc.value.integer!= last_pc) {
			last_pc = pc.value.integer;
			//cpu_state.execute();
			for (uint32_t i = 0; i < 32; i++) {
				vpiHandle element = vpi_handle_by_index(reg_mem, i);
				if (element) {
					s_vpi_value value;
                    value.format = vpiIntVal;
                    vpi_get_value(element, &value);
					registers[i] = value.value.integer;
				}
				else {
					printf("Failed to get register element\n");
				}
			}
#if 0
			if (!cpu_state.check_state(pc.value.integer, registers, NULL)) {
				printf("State mismatch at PC 0x%08x\n", pc.value.integer);
				printf("Registers:\n");
				for (uint32_t i = 0; i < 32; i++) {
					printf("R%d: 0x%08x\n", i, registers[i]);
				}
			}
			#endif
		}
		#endif
	}

	printf("Reading signature...\n");

	printf("dumping memory...\n");
	std::ofstream memory_file("DUT-evolveRISC.mem");
	std::ofstream signature_file("DUT-evolveRISC.signature");
	if (memory_file.is_open() && signature_file.is_open()) {
		memory_file << std::hex;
		memory_file << "sig start: " << sig_start << std::endl;
		memory_file << "sig end: " << sig_end << std::endl;
		memory_file << "code end: " << code_end << std::endl;
		signature_file << std::hex;

		for (uint32_t i = 0; i < (20971512/sizeof(uint32_t)) - 1; i++) {
			mem_entry = vpi_handle_by_index(mem_hdl, i);
			if (mem_entry) {
				s_vpi_value value;
				value.format = vpiIntVal;
				vpi_get_value(mem_entry, &value);
				memory_file << std::setw(8) << std::setfill('0') << i*4 << ": 0x" << std::setw(8) << std::setfill('0') << value.value.integer << std::endl;

				if (i >= sig_start/sizeof(uint32_t) && i < sig_end/sizeof(uint32_t)) {
					signature_file << std::setw(8) << std::setfill('0') << value.value.integer << std::endl;
				}
			}
			else {
				printf("Failed to get memory element %d\n", i);
				break;
			}
		}
		memory_file.close();
		signature_file.close();
	} else {
		printf("Unable to open memory file\n");
	}
#else
	//cpu_state cpu_state("data.S");
	cpu_state cpu_state("data.mem");

	TESTBENCH<cpu> *tb = new TESTBENCH<cpu>();

    tb->opentrace("cpu.vcd");
    //cpu* dut = tb->get_dut();
    cpu* top = tb->get_dut();

	//cpu* top = new cpu;  // Create an instance of the top-level module
	get_vpi_handles();
	//dut->register_file->reg_a->mem[0] = 10;

	tb->reset();
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
	for (uint32_t i = 0; i < 800; i++) {
		if (i % 4 == 0) {
			printf("\n%04x: ", i*4);
		}
		printf("0x%08x ", memory[i]);
	}
#endif
	return 0;
}
