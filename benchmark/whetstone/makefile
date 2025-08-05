
# Flag : CC
#	Use this flag to define compiler to use
CC 		= /opt/riscv/bin/riscv32-unknown-elf-gcc
# Flag : LD
#	Use this flag to define compiler to use
LD		= /opt/riscv/bin/riscv32-unknown-elf-ld
# Flag : AS
#	Use this flag to define compiler to use
AS		= /opt/riscv/bin/riscv32-unknown-elf-as

OBJCOPY = /opt/riscv/bin/riscv32-unknown-elf-objcopy

OBJDUMP = /opt/riscv/bin/riscv32-unknown-elf-objdump

SRCS = whetstone.c startup.S ../utils/printf.c ../utils/timer.c
# Flag : CFLAGS
#	Use this flag to define compiler options. Note, you can add compiler options from the command line using XCFLAGS="other flags"
CFLAGS += -O3 -g -march=rv32i -mabi=ilp32 -nostartfiles -Tlinkram -fno-builtin-printf -Xlinker --defsym=__stack_size=0x800 -Xlinker --defsym=__heap_size=0x1000 --specs=nosys.specs -L/opt/riscv/riscv32-unknown-elf/lib
LDFLAGS += -lm 

.PHONY: all clean

all: $(SRCS)
	$(CC) $(CFLAGS) -o whetstone.elf $^ $(LDFLAGS)
	$(OBJCOPY) -O binary whetstone.elf whetstone.bin
	$(OBJDUMP) -d whetstone.elf > whetstone.dis

clean:
	rm -f *.o