.section .text
    .align 2  # aligns to 4 bytes (2^2)
.global _start
_start:
    # start address of memory. Couyld also be done using linker file and symbol
    li t0, 0x01000000
    # start address of uart device.
    li t2, 0xFFFFFFFF

    sw t2, 0x00(t0)
    lw t3, 0x00(t0)

end_of_code:
    jal ra, receive_char # jump to receive_char
    jal ra, send_char # jump to send_char, argument is the return value from receive_char
    j end_of_code

# end_of_code:
#    la a0, hello_string
#   jal ra, send_string
#    nop
#    j end_of_code

receive_char:
    li t1, 0x02000000
    li t0, 0x40000000      # Mask with bit 30 set (2^29)
wait_for_uart_rx:
    lw t2, 0(t1) # load status register of UART
    and t2, t2, t0         # check if rx_ready is set
    bnez t2, receive_char # if rx_ready is set, wait and retry
    lb a0, 1(t1) # receive character from UART
    ret

send_char:
    li t1, 0x02000000
    li t0, 0x80000000      # Mask with bit 31 set (2^30)
wait_for_uart:
    lw t2, 0(t1) # load status register of UART
    and t2, t2, t0         # check if tx_full is set
    bnez t2, wait_for_uart # if tx_full is set, wait and retry
    sb a0, 1(t1) # send character to UART
    ret


send_string:
    mv s0, a0 # save the string address. I know s0 was not used yet. otherwise I would have to save it first
    mv s1, ra # save return address. I know s1 was not used yet. otherwise I would have to save it first
    
print_loop:
    lbu a0, 0(s0) # load the first character from the string
    beqz a0, send_done
    jal ra, send_char

    addi s0, s0, 1 # move to the next character in the string
    j print_loop
send_done:
    mv ra, s1 # restore return address
    ret



.section .rodata
hello_string:
    .string "Hello, World!\n"
