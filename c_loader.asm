[org 0x8000]
[bits 16]

start:
    cli             ; Disable interrupts
    
    ; === IMPORTANT: Print a character to verify c_loader was loaded ===
    mov ah, 0x0E        ; BIOS teletype
    mov al, 'C'         ; Print 'C' for c_loader
    int 0x10

    ; Load C kernel (kernel.bin) from sector 10 to 0x20000
    ; Real address 0x20000 = 0x2000:0x0000 (ES:BX)
    mov ax, 0x2000      ; <<< FIX 1: Set segment to 0x2000
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

    ; === DEBUG: Print 'A' before A20 ===
    mov ah, 0x0E
    mov al, 'A'
    int 0x10

    ; Enable A20 Line (via keyboard controller)
    call enable_a20

    ; === DEBUG: Print 'G' before GDT ===
    mov ah, 0x0E
    mov al, 'G'
    int 0x10

    ; Ensure segment registers point to real-mode base 0x0000
    mov ax, 0x0000
    mov ds, ax
    mov es, ax

    ; Load the GDT (descriptor is at absolute address org+offset)
    lgdt [gdt_descriptor]

    ; === DEBUG: Print 'P' before Protected Mode ===
    mov ah, 0x0E
    mov al, 'P'
    int 0x10

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

gdt_code: ; <<< FIX 2: Added 'gdt_code' label
    ; Code Segment Descriptor (Ring 0)
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0x9A         ; Access flags
    db 0xCF         ; Granularity
    db 0x00         ; Base (high)

gdt_data: ; <<< FIX 2: Added 'gdt_data' label
    ; Data Segment Descriptor (Ring 0)
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0x92         ; Access flags
    db 0xCF         ; Granularity
    db 0x00         ; Base (high)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; GDT Limit (size)
    dd gdt_start                ; GDT Base Address (absolute address)

; GDT Segment Selectors (offsets from GDT start)
; RPL = 0 (kernel mode), Table index 1 = code, Table index 2 = data
CODE_SEG equ 0x08           ; (1 * 8) + RPL(0) = Selector for Code segment
DATA_SEG equ 0x10           ; (2 * 8) + RPL(0) = Selector for Data segment

; --- 32-bit Protected Mode Code ---
[bits 32]
init_32:
    ; === DEBUG: We're in 32-bit mode! ===

    ; Set up segment registers for 32-bit mode first
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Can't use BIOS interrupts in protected mode; write to VGA now that DS is valid
    mov dword [0xB8000], 0x0F320F33  ; Print "32" in white on black at 0xB8000

    ; Set up a stack
    mov esp, 0x90000

    ; Jump to the C kernel at linear address 0x20000
    mov eax, 0x20000
    jmp eax              ; Jump to kernel entry (absolute linear jump)

    jmp $           ; Halt