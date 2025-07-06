
#include <stdlib.h>
#include "uart.h"
#include <stdint.h>
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "testbench_class.hpp"

#define LOOP_LIMIT 10000
#define PRESCALER 1301
//#define PRESCALER 5
int char_counter = 0;
bool uart_decoder(uart* dut, TESTBENCH<uart>* tb, int initial_counter, char* buff){
	bool started = false;
	uint8_t retval = 0;
	*buff = 0;
	for(int i=0; i < 5*PRESCALER && !started; i++) {
		if (dut->TX == 0) {
			started = true;
			dut->RX = 1;
		}
		tb->tick();
	}

	if(started) {
		for(int i=0; i < PRESCALER/2;i++){
			if(dut->TX != 0) {
				printf("frameing error in start bit");
				return false;
			}
			tb->tick();
			dut->RX=0;
		}

		for(int i = 0; i < 8; i++) {
			for (int j=0; j < PRESCALER; j++) {
				tb->tick();
			}
			*buff >>= 1;
			*buff |= (dut->TX << 7);
			retval >>= 1;
			retval |= (dut->TX << 7);
		}
		*buff = retval;

		char_counter++;
		for (int i = 0; i < PRESCALER; i++) {
			tb->tick();
		}

		if(dut->TX != 1) {
			printf("Frameing error in stop bit\n");
			return false;
		}

	}
	else{
		printf("no start bit detected\n");
		return false;
	} 


	return true;
}

bool uart_sender(uart* dut, TESTBENCH<uart>* tb, char c) {

	srand(time(NULL));

	double random_number = rand()/(RAND_MAX + 1.0);
	int random_starting_point = random_number * 10 * PRESCALER;

	for (int i = 0; i < random_starting_point; i++) {
		tb->tick();
	}

	//start bit
	for (int i = 0; i < PRESCALER; i++) {
		dut->RX = 0;
        tb->tick();
    }

	for(int i = 0; i < 8; i++) {
		//dut->RX = (c & (1 << i)) >> i;
		dut->RX = c & 1;
		c >>= 1;
		for(int j = 0; j < PRESCALER; j++) {
			tb->tick();
		}
	}

	//stop bit
	for(int i = 0; i < PRESCALER; i++) {
		dut->RX = 1;
        tb->tick();
	}
	return true;
}

bool uart_tx_test(uart* dut, TESTBENCH<uart>* tb)
{
	char str_buf[] = "Hello World!";
	int str_len = sizeof(str_buf);

	bool pass = true;
	//tb->opentrace(strcat("uart", ".tx.vcd"));
	tb->opentrace("uart.tx.vcd");

	tb->reset();

	dut->rst = 1;
	int i = 0;
	dut->wren = 1;
	unsigned int counter = 0;
	while (i < str_len)
	{
		if( !dut->tx_full)
		{
			dut->data_in = str_buf[i];
			i++;
		}
		tb->tick();
		counter++;
	}

	dut->wren = 0;
	char receive_buf[str_len];
	i = 0;
	counter = 0;

	for(int i = 0; (i < str_len) && pass; i++){
		pass = uart_decoder(dut, tb,counter,&receive_buf[i]);
		counter++;
	}

	if(!pass) {

	} else {
		if(strncmp(receive_buf, str_buf, str_len) != 0){
			pass = false;
		}	
	}


	tb->close();

	return pass;
}

bool uart_rx_test(uart* dut, TESTBENCH<uart>* tb) 
{

	char str_buf[] = "Hello World!";
	int str_len = sizeof(str_buf);
	char rec_buf[str_len];

	bool pass = true;
	//tb->opentrace(strcat("uart", ".rx.vcd"));
	tb->opentrace("uart.rx.vcd");
	dut->RX = 1;
	tb->reset();
	dut->rst = 1;

	for(int i = 0; i < str_len; i++){
		uart_sender(dut, tb, str_buf[i]);
	}
    //while(!dut->rx_empty && i < str_len) {
	for(int i = 0; i < str_len; i++) {
		if(!dut->rx_empty) {
			rec_buf[i] = dut->data_out;
			dut->rden = 1;
		}
		tb->tick();
	}
	if(!dut->rx_empty) {
		printf("ERROR: Too much data received\n");
		pass = false;
	}
	
	if(strncmp(rec_buf, str_buf, str_len)!= 0){
		printf("string difference: %d\n", strncmp(rec_buf, str_buf, str_len));
		printf("Received string: %s\n", rec_buf);
		for(int i = 0; i < str_len; i++) {
			printf("%c", str_buf[i]);
		}
		printf("\n");
		for (int i = 0; i < str_len; i++) {
			printf("%c", rec_buf[i]);
		}

		printf("\n");
        pass = false;
    }
	else {
		//printf("Received string: %s\n", rec_buf);
	}

	tb->close();
	return pass;
}



int main (int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH<uart> *tb = new TESTBENCH<uart>();

	bool pass;
	uart* dut = tb->get_dut();


	printf("Testing UART TX... ");

	if (!uart_tx_test(dut, tb)) {
		printf("\033[91m FAIL\033[39m\n");
		pass = false;
	} else {
		printf("\033[92m PASS\033[39m\n");
	}

    printf("Testing UART RX... ");
	if (!uart_rx_test(dut, tb)){
		printf("\033[91m FAIL\033[39m\n");
		pass = false;
	} else {
		printf("\033[92m PASS\033[39m\n");
	}

	//uart_rx_test(dut, tb);
	if (!pass) {
		return -1;
	}
	return 0;
}

