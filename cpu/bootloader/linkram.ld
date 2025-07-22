
MEMORY
{
    rom (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    ram (rw) : ORIGIN = 0x10000000, LENGTH = 16K
}
ENTRY(_start)
SECTIONS
{
    .text : {
        *(.text)
        *(.text*)
    } > rom

    .rodata : {
        *(.rodata)
        *(.rodata*)
    } > rom

    .data : {
        *(.data)
        *(.data*)
    } > ram

    .bss : {
        *(.bss)
        *(.bss*)
    } > ram

    .heap : {
        *(.heap)
    } > ram

}