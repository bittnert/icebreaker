
#include <stdint.h>

int main(){
    uint32_t value = 0x2;
    uint32_t *addr = (uint32_t *)0x1;

    asm volatile (
        "sw %0, 0(%1)\n"
        :
        : "r"(value), "r"(addr)
        : "memory"
    );

    asm volatile (
        "csrr a0, sepc\n" // we read a register which is not supported, this should trigger an execption
        //"amoadd.w a0, a1, (a0)\n" // this should trigger an illegal instruction exception from the decoder
    );
}