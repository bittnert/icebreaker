
.macro SAVE_TRAP_FRAME base
    addi \base, \base, -136
    SAVE_GPRS \base

    # Read CSRs
    csrr a0, mepc
    sw a0, 124(\base)
    csrr a1, mcause
    sw a1, 128(\base)
    csrr a2, mtval
    sw a2, 132(\base)
.endm

.macro RESTORE_TRAP_FRAME base
    RESTORE_GPRS \base
    addi \base, \base, 136
.endm

.macro SAVE_GPRS base
    sw x1, 0(\base)
    sw x2, 4(\base)
    sw x3, 8(\base)
    sw x4, 12(\base)
    sw x5, 16(\base)
    sw x6, 20(\base)
    sw x7, 24(\base)
    sw x8, 28(\base)
    sw x9, 32(\base)
    sw x10, 36(\base)
    sw x11, 40(\base)
    sw x12, 44(\base)
    sw x13, 48(\base)
    sw x14, 52(\base)
    sw x15, 56(\base)
    sw x16, 60(\base)
    sw x17, 64(\base)
    sw x18, 68(\base)
    sw x19, 72(\base)
    sw x20, 76(\base)
    sw x21, 80(\base)
    sw x22, 84(\base)
    sw x23, 88(\base)
    sw x24, 92(\base)
    sw x25, 96(\base)
    sw x26, 100(\base)
    sw x27, 104(\base)
    sw x28, 108(\base)
    sw x29, 112(\base)
    sw x30, 116(\base)
    sw x31, 120(\base)
.endm

.macro RESTORE_GPRS base
    lw x1, 0(\base)
    lw x2, 4(\base)
    lw x3, 8(\base)
    lw x4, 12(\base)
    lw x5, 16(\base)
    lw x6, 20(\base)
    lw x7, 24(\base)
    lw x8, 28(\base)
    lw x9, 32(\base)
    lw x10, 36(\base)
    lw x11, 40(\base)
    lw x12, 44(\base)
    lw x13, 48(\base)
    lw x14, 52(\base)
    lw x15, 56(\base)
    lw x16, 60(\base)
    lw x17, 64(\base)
    lw x18, 68(\base)
    lw x19, 72(\base)
    lw x20, 76(\base)
    lw x21, 80(\base)
    lw x22, 84(\base)
    lw x23, 88(\base)
    lw x24, 92(\base)
    lw x25, 96(\base)
    lw x26, 100(\base)
    lw x27, 104(\base)
    lw x28, 108(\base)
    lw x29, 112(\base)
    lw x30, 116(\base)
    lw x31, 120(\base)
.endm

.section .text
    .align 2  # aligns to 4 bytes (2^2)
.global _start
_start:
    la sp, _stack_top
    la t0, trap_entry
    csrw mtvec, t0 # Write trap handler to mtvec register
    call main
    la a0, hello_string  # load address of hello_string into register a0
    # call send_string  # call the print_string function
    j _start

.global trap_entry
trap_entry:
    # Save context (registers) if necessary
    # Handle the trap (e.g., print an error message)
    # SAVE_TRAP_FRAME sp

    # mv a0, sp
    # la t0, trap_handler
    # jalr t0

    # RESTORE_TRAP_FRAME sp

    addi sp, sp, -4
    sw t0, 0(sp)        # Save t0
    csrr t0, mepc
    addi t0, t0, 4     # Advance mepc to next instruction
    csrw mepc, t0
    lw t0, 0(sp)       # Restore t0
    addi sp, sp, 4

    mret

.section .rodata
hello_string:
    .string "ASM Hello World!\n\0"
