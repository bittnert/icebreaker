PROJ := cpu
PIN_DEF := ../icebreaker.pcf
DEVICE := up5k


V_SRC := cpu.v \
		memory/memory.v \
		register/cpu_register.v \
		register/dualport_mem.v \
		mux/mux2.v \
		mux/mux4.v \
		decoder/decoder.v \
		decoder/imm_decoder.v \
		alu/alu.v \
		compare/compare.v \
		#dualport_mem.v

SIM_SRC := /usr/share/verilator/include/verilated.cpp \
		/usr/share/verilator/include/verilated_vcd_c.cpp \
		/usr/share/verilator/include/verilated_threads.cpp \
		/usr/share/verilator/include/verilated_vpi.cpp \
		instructions.cpp \
		op_imm_instruction.cpp \
		op_instruction.cpp \
		cpu_state.cpp \
		branch_instruction.cpp \
		insn_instructions.cpp \
		store_instruction.cpp \
		load_instruction.cpp \
		fence_instruction.cpp \
		../testbench_class.hpp

MEM_FILE := data.mem

INC_DIR := obj_dir \
		/usr/share/verilator/include \
		/usr/share/verilator/include/vltstd \
		..		 

include ../main.mk
