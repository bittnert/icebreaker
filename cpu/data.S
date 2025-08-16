.section .text
.global _start
_start:
main:
lui x1, %hi(0xABAD0000)
lui x2, %hi(0xABAD1000)
lui x3, %hi(0xABAD2000)
lui x4, %hi(0xABAD3000)
lui x5, %hi(0xABAD4000)
lui x6, %hi(0xABAD5000)
lui x7, %hi(0xABAD6000)
lui x8, %hi(0xABAD7ABE)
lui x9, %hi(0xABAD8ABE)
lui x10, %hi(0xABAD9ABE)
lui x11, %hi(0xABADAABE)
lui x12, %hi(0xABADBABE)
lui x13, %hi(0xABADCABE)
lui x14, %hi(0xABADDABE)
lui x15, %hi(0xABADEABE)
lui x16, %hi(0xABADFABE)
ori x17, x1, -1234
ori x18, x2, 100
ori x19, x3, 300
ori x20, x4, 400
ori x21, x5, 500
ori x22, x6, 600
ori x23, x7, 700
ori x24, x8, 800
ori x25, x9, 900
ori x26, x10, 1000
ori x27, x11, 1234
ori x28, x12, 1300
ori x29, x13, 140
addi x30, x1, 100
addi x31, x2, 200
addi x1, x0, 100
slti x2, x1, 100
slti x3, x1, 90
slti x4, x1, 110
slti x5, x1, -100
sltiu x6, x1, 100
sltiu x7, x1, 90
sltiu x8, x1, 110
sltiu x9, x1, -100
xori x10, x1, 100
xori x11, x1, 1111
xori x12, x1, 2047
andi x13, x1, 100
andi x14, x1, 2047
lui x2, %hi(0xFFFFFFFF)
addi x2, x2, %lo(0xFFFFFFFF)
andi x15, x2, 2047
andi x16, x2, -1000
slli x17, x2, 20
slli x18, x2, 31
srli x19, x2, 10
srai x20, x2, 10
lui x1, %hi(0xFFFFFF00)
addi x1, x1, %lo(0xFFFFFF00)
addi x2, x0, 300
add x17, x1, x2
sub x18, x0, x1
sll x19, x4, x5
slt x2, x1, x0
sltu x3, x1, x2
xor x20, x1, x2
srl x21, x1, x2
sra x22, x1, x2
or x23, x1, x2
and x24, x1, x2
auipc x1, %hi(0xDEADBEEF)
addi t0, x0, 0
addi t1, x0, 10
loop:
addi t0, t0, 1
blt t0, t1, loop
addi t2, x0, 1
loop2:
addi t0, t0, -1
bge t0, x0, loop2
addi t0, x0, 10
addi t1, x0, 9
loop3:
addi t1, t1, 1
beq t0, t1, loop3
addi t1, x0, 8
loop4:
addi t1, t1, 1
bne t0, t1, loop4
jal ra, func
j end
nop
nop
nop
nop
nop
nop
nop
func:
addi x2, x0, 100
addi x3, x0, 200
ret
end:
la t0, word_variable
lui t1, %hi(0xABADBABE)
addi t1, t1, %lo(0xABADBABE)
sw t1, 0(t0)
la t0, first_byte
sb t1, 0(t0)
la t0, second_byte
sb t1, 0(t0)
la t0, second_half
sh t1, 0(t0)
la t0, word_variable
lw t4, 0(t0)
la t0, first_byte
lb t1, 0(t0)
la t0, second_half
lh t1, 0(t0)

.section .data
.align 4
word_variable:
    .word 0
.align 1
first_byte: .byte 0
.align 1
second_byte: .byte 0
.align 2
first_half: .half 0
second_half: .half 0
