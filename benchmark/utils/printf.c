#include <stdarg.h>
#include <stdint.h>
#include <string.h>

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

static void print_replacement(const char *replacement, va_list args) {
    if (strcmp(replacement, "d") == 0 || strcmp(replacement, "ld") == 0) {
        printnum(va_arg(args, int));
    }

    else if (strcmp(replacement, "c") == 0) {
        printchar(va_arg(args, int));
    }
    else if (strcmp(replacement, "s") == 0) {
        printstr(va_arg(args, char *));
    }
    else {
        printchar('%');
        printstr(replacement);
    }
}

static void printfloat(double f) {
    int integer_part;
    double fractional_part;
    int i;
    
    // Handle negative numbers
    if (f < 0) {
        printchar('-');
        f = -f;
    }
    
    // Extract integer and fractional parts
    integer_part = (int)f;
    fractional_part = f - integer_part;
    
    // Print integer part (handle zero case)
    if (integer_part == 0) {
        printchar('0');
    } else {
        printnum(integer_part);
    }
    
    // Print decimal point
    printchar('.');
    
    // Print fractional part (let's say 3 decimal places)
    for (i = 0; i < 3; i++) {
        fractional_part *= 10;
        int digit = (int)fractional_part;
        printchar('0' + digit);
        fractional_part -= digit;
    }
}

 __attribute__((used)) int printf(const char *format,...) {
    va_list args;

    va_start(args, format);

    uint8_t replacement = 0;
    char replacement_string[10];
    int replacement_index = 0;

    while (*format) {
#if 1
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
                case 'f':
                    printfloat(va_arg(args, double));
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
#else
        if (*format == '%') {
            replacement = 1;
            format++;
        }
        if (replacement) {
            if (*format == ' ' || *format == ',') {
                replacement_string[replacement_index] = '\0';
                print_replacement(replacement_string, args);
                printchar(*format);
                format++;
                replacement = 0;
                replacement_index = 0;
            }
            else {
                replacement_string[replacement_index] = *format;
                replacement_index++;
                format++;
            }
        }
        else {
            printchar(*format);
            format++;
        }
#endif
    }
    va_end(args);
    return 0;
}