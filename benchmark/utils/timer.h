#include <stdint.h>
#define TIMER_BASE_ADDR 0x03000000
#define TIMER_COUNTER_REG *(uint32_t*)(TIMER_BASE_ADDR + 0x00)