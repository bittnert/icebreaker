PROJ := uart_tx
PIN_DEF := ../icebreaker.pcf
DEVICE := up5k


V_SRC := uart_tx.v \
		uart_fifo.v \
		uart_test.v
#		uart.v \

SIM_SRC := /usr/share/verilator/include/verilated.cpp \
		/usr/share/verilator/include/verilated_vcd_c.cpp



INC_DIR := obj_dir \
		/usr/share/verilator/include \
		..		 

include ../main.mk
