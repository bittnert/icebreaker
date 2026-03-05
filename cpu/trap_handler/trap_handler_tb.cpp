
#include <stdlib.h>
#include "trap_handler.h"
#include "../testbench_class.hpp"

typedef struct {
    CData* input;
    uint32_t cause;
} mcauses_t;


int main (int argc, char *argv[]) {
    TESTBENCH<trap_handler> *tb = new TESTBENCH<trap_handler>();
    tb->opentrace("trap_handler.fst");
    trap_handler* top = tb->get_dut();

    top->trap_irq_enabled = 0;
    top->trap_instr_addr = 0;
    top->trap_instr_access_fault = 0;
    top->trap_illegal_instr = 0;
    top->trap_breakpoint = 0;
    top->trap_load_addr_misaligned = 0;
    top->trap_load_access_fault = 0;
    top->trap_store_addr_misaligned = 0;
    top->trap_store_access_fault = 0;
    top->trap_env_call_m_mode = 0;
    top->trap_timer_irq = 0;

    mcauses_t exception_mcauses[] = {
        {
            .input = &top->trap_instr_addr,
            .cause = 0
        },
        {
            .input = &top->trap_instr_access_fault,
            .cause = 1
        },
        {
            .input = &top->trap_illegal_instr,
            .cause = 2
        },
        {
            .input = &top->trap_breakpoint,
            .cause = 3
        },
        {
            .input = &top->trap_load_addr_misaligned,
            .cause = 4
        },
        {
            .input = &top->trap_load_access_fault,
            .cause = 5
        },
        {
            .input = &top->trap_store_addr_misaligned,
            .cause = 6
        },
        {
            .input = &top->trap_store_access_fault,
            .cause = 7
        },
        {
            .input = &top->trap_env_call_m_mode,
            .cause = 11
        }

    };

    mcauses_t interrupt_mcauses[] = {
        {
            .input = &top->trap_timer_irq,
            .cause = (uint32_t) ((1<<31) | 7)
        }
    };

    tb->eval();

    CData* last_field = NULL;

    for (mcauses_t signal: exception_mcauses) {
        *signal.input = 1;
        if (last_field != NULL) {
            last_field = 0;
        }
        //last_field = signal.input;

        tb->eval();

        if (top->trap_taken != 1) {
            printf("ERROR: Trap taken not indicate although a trap is triggered\n");
        }

        if (top->trap_mcause != signal.cause) {
            printf("ERROR: mcause not set correctly. Expected: 0x%x, read: 0x%x\n", signal.cause, top->trap_mcause);
        }

        *signal.input = 0;

        tb->eval();
        
        if (top->trap_taken == 1) {
            printf("ERROR: Trap taken indicate although no trap is triggered\n");
        }
    }

    for (mcauses_t signal: interrupt_mcauses) {
        *signal.input = 1;
        top->trap_irq_enabled = 1;

        tb->eval();

        if (top->trap_taken != 1) {
            printf("ERROR: Trap taken not indicate although a trap is triggered\n");
        }

        if (top->trap_mcause != signal.cause) {
            printf("ERROR: mcause not set correctly. Expected: 0x%x, read: 0x%x\n", signal.cause, top->trap_mcause);
        }

        top->trap_irq_enabled = 0;

        tb->eval();

        if (top->trap_taken == 1) {
            printf("ERROR: Trap taken indicate although no trap is triggered\n");
        }

        top->trap_irq_enabled = 1;
        *signal.input = 0;

        tb->eval();

        if (top->trap_taken == 1) {
            printf("ERROR: Trap taken indicate although no trap is triggered\n");
        }
    }

    tb->close();
}