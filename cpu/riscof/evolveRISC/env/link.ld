OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

MEMORY
{
    rom (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    ram (rw) : ORIGIN = 0x01000000, LENGTH = 2M
}

SECTIONS
{
    .text : {
        KEEP(*(.text.init))
        *(.text)
        *(.text*)
    } > ram

    .rodata : {
        *(.rodata)
        *(.rodata*)
    } > ram

    .data : {
        *(.data)
        *(.data*)
    } > ram

    .bss : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss)
        *(.bss*)
        . = ALIGN(4);
        __bss_end = .;
    } > ram

    _end = .;
    PROVIDE(end = .);

    .heap : {
        . = ALIGN(4);
        __heap_start = .;
        *(.heap)
        . = . + 0x1000;
        . = ALIGN(4);
        __heap_end = .;
    } > ram

    .stack : {
        . = ORIGIN(ram) + LENGTH(ram) - 0x1000;
        __stack_start = .;
        . = ORIGIN(ram) + LENGTH(ram);
        __stack_end = .;
    } > ram
    
    _stack_top = ORIGIN(ram) + LENGTH(ram);

    ASSERT(__heap_end <= __stack_start, "Heap and stack overlap")
}