PROJ := uart
PIN_DEF := ../icebreaker.pcf
DEVICE := up5k


V_SRC := uart_tx.v \
		uart_fifo.v \
		uart_baud_gen.v \
		uart_rx.v \
		uart.v \
		uart_test.v \
		../utils/fifo.v
#		uart_test.v 
#		uart_loopback.v

SIM_SRC := /usr/share/verilator/include/verilated.cpp \
		/usr/share/verilator/include/verilated_vcd_c.cpp \
		/usr/share/verilator/include/verilated_threads.cpp \
		../testbench_class.hpp



INC_DIR := obj_dir \
		/usr/share/verilator/include \
		..		 

include ../main.mk
