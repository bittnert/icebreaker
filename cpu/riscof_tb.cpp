
#include <stdlib.h>
#include "cpu.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_fst_c.h>
#include "verilated_vpi.h"
#include "testbench_class.hpp"
#include <fstream>
#include <string>
#include <regex>
#include <iostream>
#include <chrono>
#include "instructions.hpp"
#include <iomanip>  // For std::setw and std::setfill
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <ctime>

#define FREQUENCY 12000000
#define BAUDRATE  57600
#define MEMORY_SIZE 524288

vpiHandle vh;
vpiHandle reg_mem;
vpiHandle mem_wr;
vpiHandle mem_en;
vpiHandle reg_en;
//vpiHandle low_mem_hdl;
//vpiHandle high_mem_hdl;
vpiHandle mem_hdl;
vpiHandle tx_fill_level;
vpiHandle rx_fill_level;

void wait_for_uart_tx(TESTBENCH<cpu> *tb) {
    t_vpi_value value;
    value.format = vpiIntVal;
    printf("Waiting for UART Tx to be empty...\n");
    vpi_get_value(tx_fill_level, &value);
    while(value.value.integer > 0) {
        tb->tick();
        vpi_get_value(tx_fill_level, &value);
        printf("\rwaiting for UART Tx to be empty... %d", value.value.integer);
    }
}

void log_data(const std::string& log_message) {
    std::ofstream log_file("simulation.log", std::ios::app); // Open in append mode
    if (log_file.is_open()) {
		auto now = std::chrono::system_clock::now();
		std::time_t time_now = std::chrono::system_clock::to_time_t(now);
		log_file << "[" << std::put_time(std::localtime(&time_now), "%Y-%m-%d %H:%M:%S") << "] ";
        log_file << log_message << std::endl;
        log_file.close();
    } else {
        std::cerr << "Unable to open log file" << std::endl;
    }
}

static void send_char(TESTBENCH<cpu> *tb, char c) {
	int clocks_per_bit = FREQUENCY / BAUDRATE;

	//printf("Clocks per bit: %d\n", clocks_per_bit);
    t_vpi_value value;
    value.format = vpiIntVal;
    vpi_get_value(rx_fill_level, &value);
    while (value.value.integer >= 10) {
		//printf("waiting for UART Rx to be empty... %d\r", value.value.integer);
        vpi_get_value(rx_fill_level, &value);
		tb->tick();
    }
	//printf("\n");

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

void load_data(TESTBENCH<cpu> *tb, uint8_t* data, int length) {

    printf("Sending %d bytes of data...\n", length);
    for (int i = 0; i < length; i++) {
        send_char(tb, data[i]);
		printf("Sending binary: %f % (%d)\r", (float)i*100 / (float)length, i);
		log_data("Sending byte " + std::to_string(i) + "/" + std::to_string(length));
    }
    printf("\nData sent successfully!\n");
}

void load_binary_file(TESTBENCH<cpu> *tb, uint8_t* data, int length) {
    uint8_t length_array[9];
    snprintf((char*)length_array, sizeof((char*)length_array), "%d\n\0", length);
    load_data(tb, length_array, strlen((char*)length_array));
    wait_for_uart_tx(tb);
    load_data(tb, data, length);
}


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

	mem_hdl = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.main_ram.mem", NULL);
	if (!mem_hdl) vl_fatal(__FILE__, __LINE__, "sim_main", "Memory handle not found");

#if 0
	low_mem_hdl = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.main_ram.mem_low", NULL);
    if (!low_mem_hdl) {
	vl_fatal(__FILE__, __LINE__, "sim_main", "Memory handle not found");
	}
	else {
		printf("Low memory handle found\n");
		PLI_INT32 type = vpi_get(vpiType, low_mem_hdl);
		printf("Low memory type: %d (vpiRegArray=%d, vpiMemory=%d)\n", type, vpiRegArray, vpiMemory);
	}

	high_mem_hdl = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.main_ram.mem_high", NULL);
    if (!high_mem_hdl) {
		vl_fatal(__FILE__, __LINE__, "sim_main", "Memory handle not found");
	} else {
		printf("High memory handle found\n");
		PLI_INT32 type = vpi_get(vpiType, high_mem_hdl);
		printf("high memory type: %d (vpiRegArray=%d, vpiMemory=%d)\n", type, vpiRegArray, vpiMemory);

	}
#endif

	tx_fill_level = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.uart.uart.tx_fifo_fill_lvl", NULL);
    if (!tx_fill_level) vl_fatal(__FILE__, __LINE__, "sim_main", "tx fill level handle not found");

	rx_fill_level = vpi_handle_by_name((PLI_BYTE8*)"TOP.cpu.load_store_unit.uart.uart.rx_fifo_fill_lvl", NULL);
    if (!rx_fill_level) vl_fatal(__FILE__, __LINE__, "sim_main", "rx fill level handle not found");
}

bool fileExists(const std::string& filename) {
    std::ifstream file(filename);
    return file.good();
}

bool process_map_file(char* filename, uint32_t *sig_start, uint32_t *sig_end, uint32_t *code_end, uint32_t *ram_base) {
	std::ifstream file(filename);
	if (!file.is_open()) {
		printf("Error: Could not open file %s\n", filename);
        return false;
	}

	std::regex sig_start_regex("^\\s*0x([0-9A-Fa-f]{8})\\s*begin_signature");
	std::regex sig_end_regex("^\\s*0x([0-9A-Fa-f]{8})\\s*end_signature");
	std::regex code_end_regex("^\\s*0x([0-9A-Fa-f]{8})\\s*rvtest_code_end");
	std::regex ram_base_regex("^\\s*ram\\s+0x([0-9A-Fa-f]{8})"); // Regex to match the RAM base address
	std::string line;
	std::smatch matches;
	bool found_sig_start = false;
	bool found_code_end = false;
	bool found_sig_end = false;
	bool found_ram_base = false;

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
		if (std::regex_search(line, matches, ram_base_regex)) {
            std::string hex_str = matches[1].str();
            *ram_base = std::stoul(hex_str, nullptr, 16);
		
            found_ram_base = true;
            printf("Found RAM base: 0x%08x\n", ram_base);
        }
	}

	file.close();

	if (found_sig_end && found_code_end && found_sig_start && found_ram_base) {
		return true;
	}

	return false;
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
	uint32_t sig_start, sig_end, code_end, ram_base;
	t_vpi_value memory_read;// = 0x12345678;
	memory_read.format = vpiIntVal;
	t_vpi_value pc;// = 0x12345678;
	pc.format = vpiIntVal;
	pc.value.integer = 0x12345678;
	Verilated::commandArgs(argc, argv);

	if (argc < 3) {
		printf("Usage: %s <test binary> <test map file>\n", argv[0]);
        return 1;
    }

	std::filesystem::path exePath = std::filesystem::current_path() / argv[0];
	std::filesystem::path parentPath = exePath.parent_path();

	std::cout << "Executable path: " << exePath << "\n";
	std::cout << "Parent path: " << parentPath << "\n";

	std::filesystem::path sourcePath = parentPath / "bootloader/bootloader.mem";
	std::filesystem::path destinationPath = "./bootloader/bootloader.mem";

	std::filesystem::path destinationDir = destinationPath.parent_path();
	try {
		if (!std::filesystem::exists(destinationDir)) {
			std::filesystem::create_directories(destinationDir);
        }
		std::filesystem::copy(sourcePath, destinationPath);
        printf("Copied bootloader memory file from %s to %s\n", sourcePath.string().c_str(), destinationPath.string().c_str());
	} catch (const std::filesystem::filesystem_error& e) {
		std::cout << "Error: " << e.what() << '\n';
    }

	if (!process_map_file(argv[argc-1], &sig_start, &sig_end, &code_end, &ram_base)) {
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

	//tb->reset();
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
	std::ofstream outfile("firmware.mem");
	if (!outfile.is_open()) {
		printf("could not open output file\n");
        return 1;
    }
	outfile << std::hex << std::setfill('0');
	for (size_t i = 0; i < size; i += 4) {
		uint32_t value = 0;
		for (size_t j = 0; j < 4 && i + j < size; j++) {
			value |= static_cast<uint32_t>(file_data[i + j]) << (8 * j);
		}
		outfile << std::setw(8) << value << std::endl;
	}
	TESTBENCH<cpu> *tb = new TESTBENCH<cpu>();
    tb->opentrace("cpu.fst");
    cpu* top = tb->get_dut();

	get_vpi_handles();
	outfile.close();
	top->BTN_N = 0;
	tb->tick();
	tb->tick();
	tb->tick();
	top->BTN_N = 1;
	//wait_for_uart_tx(tb);
	//printf("Reading memory...\n");

	//load_binary_file(tb, file_data, size);

	vpiHandle mem_entry;
	uint32_t memory[2097152/sizeof(uint32_t)] = {0};
	for (uint32_t i = 0; i < MEMORY_SIZE; i++) {
		mem_entry = vpi_handle_by_index(mem_hdl, i);
		if (mem_entry) {
			s_vpi_value value;
			value.format = vpiIntVal;
			vpi_get_value(mem_entry, &value);
			memory[i] = value.value.integer;
		}
		char temp_str[100];
		snprintf(temp_str, 100, "Reading back memory: %d/%d\n", i, MEMORY_SIZE);
		log_data(temp_str);
	}
	printf("comparing %d bytes of memory...\n", size);
	if (memcmp(memory, file_data, size) == 0) {
		printf("Memory contents match!\n");
		log_data("Memory contents match!\n");
	} else {
		for (int i = 0; i < 100; i++) {
			printf("%d: 0x%08x vs 0x%08x\n", i, memory[i], file_data[i]);
		}
		printf("Memory contents do not match!\n");
		return 1;
	}

	//cpu_state cpu_state("data.mem");

	vpi_get_value(vh, &pc);
	uint32_t counter = 0;
	uint32_t last_pc = pc.value.integer;
	uint32_t registers[32] = {0};
	auto start_time = std::chrono::steady_clock::now();
	printf("PC: 0x%08x, code end: 0x%08x\n", pc.value.integer, code_end);
	while ((pc.value.integer < code_end) && !(pc.value.integer & 3 != 0) ) {
		//printf("Counter: %d, PC: 0x%08x\r", counter, pc.value.integer);
		tb->tick();
		counter++;
		vpi_get_value(vh, &pc);

		auto current_time = std::chrono::steady_clock::now();

		auto elapsed_time = std::chrono::duration_cast<std::chrono::microseconds>(current_time - start_time).count();

		if (elapsed_time >= 1 ) {
			log_data("PC: 0x" + std::to_string(pc.value.integer));
			start_time = current_time;
		}
	}

	printf("Reading signature...\n");

	printf("dumping memory...\n");
	std::ofstream memory_file("DUT-evolveRISC.mem");
	std::ofstream signature_file("DUT-evolveRISC.signature");
	if (memory_file.is_open() && signature_file.is_open()) {
		uint32_t mem;
		memory_file << std::hex;
		memory_file << "sig start: " << sig_start << std::endl;
		memory_file << "sig end: " << sig_end << std::endl;
		memory_file << "code end: " << code_end << std::endl;
		signature_file << std::hex;
		
		for (uint32_t i = 0; i < MEMORY_SIZE; i++) {
			mem_entry = vpi_handle_by_index(mem_hdl, i);
			if (mem_entry) {
				s_vpi_value value;
				value.format = vpiIntVal;
				vpi_get_value(mem_entry, &value);
				mem = value.value.integer;
			}
			else {
				printf("Failed to get memory element %d\n", i);
				break;
			}
			memory_file << std::setw(8) << std::setfill('0') << i*4 << ": 0x" << std::setw(8) << std::setfill('0') << mem << std::endl;

			if (i >= (sig_start - ram_base)/sizeof(uint32_t) && i < (sig_end - ram_base)/sizeof(uint32_t)) {
				signature_file << std::setw(8) << std::setfill('0') << mem << std::endl;
			}
			char temp_str[100];
			snprintf(temp_str, 100, "Dumping memory: %d/%d\n", i, MEMORY_SIZE);
			log_data(temp_str);
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
