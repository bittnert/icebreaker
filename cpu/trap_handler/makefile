PROJ := cpu
PIN_DEF := ../icebreaker.pcf
DEVICE := up5k

FREQ := 12

V_SRC := trap_handler.v 

SIM_SRC := /usr/share/verilator/include/verilated.cpp \
		/usr/share/verilator/include/verilated_vcd_c.cpp \
		/usr/share/verilator/include/verilated_fst_c.cpp \
		/usr/share/verilator/include/verilated_threads.cpp \
		/usr/share/verilator/include/verilated_vpi.cpp \

INC_DIR := obj_dir \
		/usr/share/verilator/include \
		/usr/share/verilator/include/vltstd \
		..		 

TOP := trap_handler

include ../../main.mk
