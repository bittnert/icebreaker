#
# EvovleRISCV Bootloader
# ======================
#
# This bootloader provides a minimal environment for loading programs into RAM
# and executing them on the EvovleRISCV processor. It operates without using
# a stack, relying only on registers for temporary storage.
#
# Functionality:
# 1. Displays a welcome message via UART
# 2. Prompts user to enter the size of the program image to load
# 3. Receives the size parameter as decimal input
# 4. Loads the specified number of bytes from UART into RAM starting at 0x01000000
# 5. Jumps to the loaded program at 0x01000000 to begin execution
#
# Key components:
# - UART communication (0x02000000): For sending/receiving data
# - RAM storage (0x01000000): Target location for loaded program
# - Register usage: Carefully managed to avoid stack requirements
#
# The bootloader includes utility functions for:
# - Character I/O via UART (send_char, receive_char)
# - String output (send_string)
# - Decimal parameter parsing (get_parameter)
# - Integer printing in hexadecimal format (print_integer)
# - Binary image loading (load_image)
#

.section .text
    .align 2  # aligns to 4 bytes (2^2)
.global _start
_start:
    la a0, hello_string # load the address of the string into a0
    jal send_string # jump to send_string to print welcome message

    # li s2, RAM_START
    li s2, 0x01000000
    /* index of the current byte to store */
    li s3, 0
    /* new line character */
    li s4, 0xa
    jal ra, get_parameter
    mv a1, a0
    la a0, parameter_return_string
    jal ra, send_string
    mv a0, a1
    call print_integer
    mv a0, s6
    call load_image
    # la a0, image_loaded_string
    # jal ra, send_string
    li t0, 0x01000000
    jalr zero, 0(t0)


receive_string:
    jal ra, receive_char # jump to receive_char
    add t1, s2, s3
    sb a0, 0(t1)
    addi s3, s3, 1      # increment index
    beq a0, s4, string_done
    j receive_string

string_done:
    add t1, s2, s3
    sb zero, 0(t1) # store the received character in the string
    mv a0, s2
    jal send_string
    li s3, 0
    j receive_string

end_of_code:
    jal ra, receive_char # jump to receive_char
    jal ra, send_char # jump to send_char, argument is the return value from receive_char
    j end_of_code

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
    mv t5, a0 # save the string address. I know t5 was not used yet. otherwise I would have to save it first
    mv s11, ra # save return address. I know s1 was not used yet. otherwise I would have to save it first
    
print_loop:
    lbu a0, 0(t5) # load the first character from the string
    beqz a0, send_done
    jal ra, send_char

    addi t5, t5, 1 # move to the next character in the string
    j print_loop
send_done:
    mv ra, s11 # restore return address
    ret

get_parameter:
    # Size is first 0, s6 will be used to track the passed in size
    li s6, 0
    li s7, 0x30 # ASCII for "0"
    li s8, 0x3A # ASCII code for one after "9" so bgeu works with this value
    mv s5, ra
parameter_loop:
    jal ra, receive_char # Get one character
    jal ra, send_char # Send the character
    beq a0, s4, finish_parameter
    bltu a0, s7, invalid_parameter
    bgeu a0, s8, invalid_parameter
    addi t4, a0, -0x30 # convert ASCII to decimal
    sll s9, s6, 3 # s6 times 8 
    add s9, s9, s6 # add s6 so s9 contains 9 * s6
    add s9, s9, s6 # add s6 so s9 contains 10*s6
    add s6 , s9, t4 # add the decimal value. s6 now contains the new value for the size parameter
    j parameter_loop
invalid_parameter:
    la a0, invalid_parameter_string
    jal ra, send_string
    mv ra, s5
    j get_parameter
finish_parameter:
    mv ra, s5
    mv a0, s6 # move parameter to a0 to return to the caller
    ret

print_integer:
    mv s5, ra # save return address.
    mv t6, a0
    li t3, 0xF # mask the least significant 4 bits
    li t4, 0xA
print_integer_loop:
    srl t5, t6, 0x1C # shift to look at the upper 4 bits.
    and t5, t5, t3 # get the least significant 4 bits
    bltu t5, t4, decimal_print
    # If the number is above or equal to 10, we need to print a hexadecimal digit.
    # This value can be from 0xA to 0xF. The upper case letters are from 0x41 to 0x46.
    # By adding 0x7, t5 will contain a vlaue from 0x11 to 0x16. Later 0x30 will be added
    # which finishes the conversion to hexadecimal string
    addi t5, t5, 0x7 
decimal_print:
    addi t5, t5, 0x30 # convert decimal to ASCII
    mv a0, t5
    call send_char
    sll t6, t6, 4 # shift left to remove the upper 4 bits which have just been printed
    bnez t6, print_integer_loop
    mv ra, s5
    ret

load_image:
    li s0, 0x01000000
    li s1, 0x1FFFF # mask address, we only support up to 128 kbytes
    mv s2, a0 # store expected size of image
    mv s4, ra
image_load_loop:
    call receive_char
    sb a0, 0(s0)
    addi s0, s0, 1
    and s3, s0, s1
    bltu s3, s2, image_load_loop
    mv ra, s4
    ret


read_back:
    li s0, 0x01000000
    li s1, 0x1FFFF # mask address, we only support up to 128 kbytes
    mv s2, a0 # store expected size of image
    mv s4, ra
image_read_back_loop:
    lw t3, 0(s0)
    li s5, 4
image_read_back_word_loop:
    mv a0, t3
    call send_char
    srl t3, t3, 8
    addi s5, s5, -1
    bltu zero, s5, image_read_back_word_loop
    addi s0, s0, 4
    and s3, s0, s1
    bltu s3, s2, image_read_back_loop
    mv ra, s4
    ret


.section .rodata
hello_string:
    .string "EvovleRISCV bootloader:\nPlese enter Size of image to laod:\0"
invalid_parameter_string:
    .string "Invalid parameter!\n\0"
parameter_return_string:
    .string "Expecting size of:\0"
image_loaded_string:
    .string "Image loaded successfully!\n\0"
