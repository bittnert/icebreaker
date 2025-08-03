
#include <stdint.h>
#include <stdio.h>

#define UART_BASE 0x02000000
#define UART_TX_DATA_OFFSET 0x01
#define UART_STATUS_OFFSET 0x00
#define UART_TX_FULL(reg) ((reg) & (1 << 31))


#define TIMER_BASE 0x03000000

#define UART_TX_DATA_REG *(volatile uint8_t*)(UART_BASE + UART_TX_DATA_OFFSET)
#define UART_STATUS_REG *(volatile uint32_t*)(UART_BASE + UART_STATUS_OFFSET)

void print_string(char *str);
void add_uint_to_string(char *str, uint32_t num);
int main() {

    char hello_world[] = "Hello, World!\n";
    char buf[100];
    while(42) {
        uint32_t timer_value = *(volatile uint32_t*)(TIMER_BASE);
        //snprintf(buf, sizeof(buf), "Hello World: %s\n", timer_value);
        add_uint_to_string(buf, timer_value);
        print_string(buf);
    }
}

void add_uint_to_string(char *str, uint32_t num) {
    if(num == 0) {
        str[0] = '0';
        str[1] = '\n';
        str[2] = '\0';
        return;
    } 

    char temp[12];
    int i = 0;
    while (num > 0) {
        temp[i++] = '0' + (num % 10);
        num /= 10;
    }

    int j = 0;
    while (i > 0) {
        str[j++] = temp[--i];
    }
    str[j++] = '\n';
    str[j] = '\0';
}

void print_string(char *str) {
    while(*str != '\0') {
        uint32_t uart_status = UART_STATUS_REG;
        while (UART_TX_FULL(uart_status)) {
            uart_status = UART_STATUS_REG;
        }

        UART_TX_DATA_REG = *str;
        str++;
    }
}