
MEMORY
{
    rom (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    ram (rw) : ORIGIN = 0x80000000, LENGTH = 16K
}
ENTRY(_start)
SECTIONS
{
    . = ORIGIN(rom);
    .text : AT(ORIGIN(rom)) {
        KEEP(*(.init))
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        PROVIDE(__text_en = .);
    } > rom

    . = ALIGN(4);
    .rodata : {
        *(.rodata)
        *(.rodata*)
        PROVIDE(__rodata_end = .);
    } > rom

    . = ORIGIN(ram);
    ram_start = ORIGIN(ram);
    .data : {
        *(.data)
        *(.data*)
        PROVIDE(__rodata_end = .);
    } > ram

    .bss : {
        *(.bss)
        *(.bss*)
    } > ram

    .heap : {
        *(.heap)
    } > ram

}