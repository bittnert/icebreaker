
SRC := startup.s

LINKERSCRIPT := linkram

.PHONY: all

all: firmware.bin

%.bin: %.elf
	riscv32-unknown-elf-objdump -d $< > $@.dis
	riscv32-unknown-elf-objcopy -O binary $< $@

%.elf: ${SRC}
	riscv32-unknown-elf-gcc -nostartfiles -nostdlib -Wa,-mno-arch-attr -mno-relax -march=rv32i -mabi=ilp32 -T${LINKERSCRIPT} -o $@ $<

clean:
	rm -f *.bin *.elf *.dis
