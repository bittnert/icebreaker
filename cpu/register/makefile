PROJ := cpu_register
PIN_DEF := ../../icebreaker.pcf
DEVICE := up5k


V_SRC := cpu_register.v \
		dualport_mem.v

SIM_SRC := /usr/share/verilator/include/verilated.cpp \
		/usr/share/verilator/include/verilated_vcd_c.cpp \
		/usr/share/verilator/include/verilated_threads.cpp \
		../../testbench_class.hpp

INC_DIR := obj_dir \
		/usr/share/verilator/include \
		../..		 

include ../../main.mk
