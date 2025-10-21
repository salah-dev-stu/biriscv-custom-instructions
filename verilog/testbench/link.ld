/* Linker script for BiRiscV test programs */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    /* TCM (Tightly Coupled Memory) starts at 0x80000000 */
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

SECTIONS
{
    . = 0x80000000;

    .text : {
        *(.text)
        *(.text.*)
    } > RAM

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > RAM

    .data : {
        *(.data)
        *(.data.*)
    } > RAM

    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } > RAM

    _end = .;
}
