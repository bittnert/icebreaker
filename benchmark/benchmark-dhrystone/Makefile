DHRY-LFLAGS =

DHRY-CFLAGS := -O3 -DTIME -DNOENUM -Wno-implicit -save-temps 
DHRY-CFLAGS += -fno-builtin-printf -fno-builtin -nostartfiles -fno-common -falign-functions=4

LDFLAGS += -specs=nano.specs --specs=nosys.specs

#Uncomment below for FPGA run, default DHRY_ITERS is 2000 for RTL
DHRY-CFLAGS += -DDHRY_ITERS=100000

SRC = dhry_1.c dhry_2.c strcmp.S startup.S ../utils/timer.c ../utils/printf.c
HDR = dhry.h ../utils/timer.h

CC = /opt/riscv/bin/riscv32-unknown-elf-gcc
OBJCOPY = /opt/riscv/bin/riscv32-unknown-elf-objcopy
OBJDUMP = /opt/riscv/bin/riscv32-unknown-elf-objdump

override CFLAGS += $(DHRY-CFLAGS) $(XCFLAGS) -Tlinkram -Wl,-u,printf -Xlinker -Map=output.map -Xlinker --defsym=__stack_size=0x800 -Xlinker --defsym=__heap_size=0x1000
dhrystone: $(SRC) $(HDR)
	$(CC) $(CFLAGS) $(SRC) $(LDFLAGS) $(LOADLIBES) $(LDLIBS) -o $@
	$(OBJCOPY) -O binary $@ $@.bin
	$(OBJDUMP) -d $@ > $@.dis



clean:
	rm -f *.i *.s *.o dhrystone dhrystone.hex

