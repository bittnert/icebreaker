
SRC := startup.s \
	main.c

LINKERSCRIPT := linkram

.PHONY: all

all: firmware.bin

%.bin: %.elf
	/opt/riscv/bin/riscv32-unknown-elf-objdump -d $< > $@.dis
	/opt/riscv/bin/riscv32-unknown-elf-objcopy -O binary $< $@

%.elf: ${SRC}
	/opt/riscv/bin/riscv32-unknown-elf-gcc -nostartfiles -O3 -Wa,-mno-arch-attr -mno-relax -march=rv32i -mabi=ilp32 -T${LINKERSCRIPT} -o $@ ${SRC}

clean:
	rm -f *.bin *.elf *.dis
