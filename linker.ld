/* linker.ld */
ENTRY(main) /* Set the entry point to our C 'main' function */
SECTIONS
{
    . = 0x100000; /* Set the load address to 1MB */

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