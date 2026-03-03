
CFLAGS := -march=rv32izicsr -O3 -DTIME -DNOENUM -Wno-implicit
CFLAGS += -fno-builtin-printf -fno-builtin -nostartfiles -fno-common -falign-functions=4

SRC = bootloader.s

CC = /opt/riscv/bin/riscv32-unknown-elf-gcc
OBJCOPY = /opt/riscv/bin/riscv32-unknown-elf-objcopy
OBJDUMP = /opt/riscv/bin/riscv32-unknown-elf-objdump

CFLAGS += -Tlinkram.ld -Wl,-u,printf -Xlinker -Map=output.map
bootloader: $(SRC)
	$(CC) -march=rv32izicsr -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wa,-mno-arch-attr -mno-save-restore -mno-relax -Tlinkram.ld -o $@ -DXLEN=32 -Wl,-Map=my.elf.map -Wa,-mno-arch-attr -mabi=ilp32 $(SRC)
	# $(CC) $(CFLAGS) $(SRC) -o $@
	$(OBJCOPY) -O binary $@ $@.bin
	$(OBJDUMP) -d $@ > $@.dis



clean:
	rm -f *.i *.o bootloader bootloader.hex *.bin *.dis