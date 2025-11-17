/* linker.ld */
ENTRY(_start) /* Set the entry point to our asm '_start' function */
SECTIONS
{
    . = 0x20000; 

    .text :
    {
        *(.text) /* All .text sections (code) */
    }

    .data :
    {
        *(.data) /* All .data sections (initialized data) */
    }

    .bss :
    {
        *(.bss)  /* All .bss sections (uninitialized data) */
    }
}