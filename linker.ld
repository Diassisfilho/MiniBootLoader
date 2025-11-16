/* linker.ld */
ENTRY(main) /* Set the entry point to our C 'main' function */
SECTIONS
{
    /* <<< FIX: Changed load address to 0x20000 to match c_loader.asm */
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