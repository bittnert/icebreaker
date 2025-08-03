
.section .text.init
    .align 2  # aligns to 4 bytes (2^2)
.global _start
_start:
    la sp, _stack_top

    la t0, __bss_start
    la t1, __bss_end
    j bss_check
bss_loop:
    sw zero, 0(t0) # zero out the memory block
    addi t0, t0, 4
bss_check:
    bltu t0, t1, bss_loop

    la t0, __heap_start
    la t1, __heap_end
    j heap_check
heap_loop:
    sw zero, 0(t0) # zero out the memory block
    addi t0, t0, 4
heap_check:
    bltu t0, t1, heap_loop

    call main
    la a0, hello_string  # load address of hello_string into register a0
    # call send_string  # call the print_string function
    j _start

# send_char:
#    li t1, 0x02000000
#    li t0, 0x80000000      # Mask with bit 31 set (2^30)
# wait_for_uart:
#    lw t2, 0(t1) # load status register of UART
#    and t2, t2, t0         # check if tx_full is set
#    bnez t2, wait_for_uart # if tx_full is set, wait and retry
#    sb a0, 1(t1) # send character to UART
#    ret


# send_string:
#    mv t5, a0 # save the string address. I know t5 was not used yet. otherwise I would have to save it first
#    mv s11, ra # save return address. I know s1 was not used yet. otherwise I would have to save it first
    
# print_loop:
#    lbu a0, 0(t5) # load the first character from the string
#    beqz a0, send_done
#    jal ra, send_char

#    addi t5, t5, 1 # move to the next character in the string
#    j print_loop
# send_done:
#    mv ra, s11 # restore return address
#    ret

.section .rodata
hello_string:
    .string "ASM Hello World!\n\0"
