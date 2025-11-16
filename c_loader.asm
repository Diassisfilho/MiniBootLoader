[org 0x8000]
[bits 16]

start:
    cli             ; Disable interrupts

    ; Load C kernel (kernel.bin) from sector 10 to 0x100000
    ; Well load 16 sectors (8KB) for this example.
    ; Real address 0x100000 = 0x10000:0x0000 (ES:BX)
    mov ax, 0x10000
    mov es, ax
    mov bx, 0x0000
    
    mov ah, 0x02        ; BIOS read sector
    mov al, 16          ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 10          ; Start at sector 10
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive 0
    int 0x13
    jc load_error       ; Halt on error

    ; Enable A20 Line (via keyboard controller)
    call enable_a20

    ; Load the GDT
    lgdt [gdt_descriptor]

    ; Set the PE (Protection Enable) bit in CR0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Far jump to 32-bit code
    ; This flushes the CPU pipeline and loads CS
    jmp CODE_SEG:init_32

; --- A20 Line Enable ---
enable_a20:
    in al, 0x64     ; Wait for keyboard controller
    test al, 2
    jnz enable_a20
    
    mov al, 0xD1    ; Command: Write output port
    out 0x64, al
    
    in al, 0x64     ; Wait again
    test al, 2
    jnz enable_a20

    mov al, 0xDF    ; Data: Enable A20
    out 0x60, al
    ret

load_error:
    jmp $           ; Halt on error

; --- Global Descriptor Table (GDT) ---
gdt_start:
    ; Null Descriptor
    dd 0x0
    dd 0x0

    ; Code Segment Descriptor (Ring 0)
    ; base=0, limit=0xFFFFF, 4KB granularity
    ; flags: 0x9A (Present, Ring 0, Code, Exec/Read)
    ; gran: 0xCF (4KB Granularity, 32-bit)
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0x9A         ; Access flags
    db 0xCF         ; Granularity
    db 0x00         ; Base (high)

    ; Data Segment Descriptor (Ring 0)
    ; base=0, limit=0xFFFFF, 4KB granularity
    ; flags: 0x92 (Present, Ring 0, Data, Read/Write)
    ; gran: 0xCF (4KB Granularity, 32-bit)
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0x92         ; Access flags
    db 0xCF         ; Granularity
    db 0x00         ; Base (high)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; GDT Limit (size)
    dd gdt_start                ; GDT Base Address

; GDT Segment Selectors (offsets from GDT start)
CODE_SEG equ gdt_start.code - gdt_start
DATA_SEG equ gdt_start.data - gdt_start

; --- 32-bit Protected Mode Code ---
[bits 32]
init_32:
    ; Set up segment registers for 32-bit mode
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Set up a stack
    mov esp, 0x90000

    ; Call the C kernel at 1MB!
    call 0x100000

    jmp $           ; Halt