
#include <stdint.h>

#define UART_BASE 0x02000000
#define UART_TX_DATA_OFFSET 0x01
#define UART_STATUS_OFFSET 0x00
#define UART_TX_FULL(reg) ((reg) & (1 << 31))

#define UART_TX_DATA_REG *(volatile uint8_t*)(UART_BASE + UART_TX_DATA_OFFSET)
#define UART_STATUS_REG *(volatile uint32_t*)(UART_BASE + UART_STATUS_OFFSET)

void print_string(char *str);
int main() {

    char hello_world[] = "Hello, World!\n";
    while(42) {
        print_string(hello_world);
    }
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