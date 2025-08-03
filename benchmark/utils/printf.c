#include <stdarg.h>
#include <stdint.h>

#define UART_BASE_ADDR 0x02000000
#define UART_STATUS_OFFSET 0x0
#define UART_TX_OFFSET 0x1
#define UART_STATUS_REG *(volatile uint32_t*)(UART_BASE_ADDR + UART_STATUS_OFFSET)
#define UART_TX_REG *(volatile uint8_t*)(UART_BASE_ADDR + UART_TX_OFFSET)
#define UART_TX_FULL(status) ((status & (1 << 31))!= 0)

static void printchar(char c) {
    uint32_t status = UART_STATUS_REG;
    while (UART_TX_FULL(status)) {
        status = UART_STATUS_REG;
    }

    UART_TX_REG = c;
}

static void printnum(int num) {
    char temp[11];
    int i = 0;
    while(num > 0) {
        temp[i] = num % 10 + '0';
        num /= 10;
        i++;
    }

    for(i--; i >= 0; i--) {
        printchar(temp[i]);
    }
}

static void printstr(const char *str) {
    while(*str) {
        printchar(*str);
        str++;
    }
}

 __attribute__((used)) int printf(const char *format,...) {
    va_list args;

    va_start(args, format);

    while (*format) {
        if (*format == '%') {
            format++;

            switch (*format) {
                case 'c':
                    printchar(va_arg(args, int));
                    break;
                case 'd':
                    printnum(va_arg(args, int));
                    break;
                case 's':
                    printstr(va_arg(args, char *));
                    break;
                default:
                    printchar('%');
                    printchar(*format);
            }
            format++;
        }
        else {
            printchar(*format);
            format++;
        }
    }
    va_end(args);
    return 0;
}