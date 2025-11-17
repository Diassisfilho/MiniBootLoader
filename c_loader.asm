[org 0x8000]
[bits 16]

start:
    cli             ; Disable interrupts

    ; Load C kernel (kernel.bin) from sector 10 to 0x20000
    mov ax, 0x2000
    mov es, ax
    mov bx, 0x0000
    
    mov ah, 0x02        ; BIOS read sector
    mov al, 16          ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 10          ; Start at sector 10
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive 0
    int 0x13
    jc load_error

    call enable_a20

    mov ax, 0x0000
    mov ds, ax
    mov es, ax

    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_SEG:init_32

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
    jmp $

gdt_start:
    dd 0x0
    dd 0x0

gdt_code:
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0x9A         ; Access flags
    db 0xCF         ; Granularity
    db 0x00         ; Base (high)

gdt_data:
    dw 0xFFFF       ; Limit (low)
    dw 0x0000       ; Base (low)
    db 0x00         ; Base (mid)
    db 0x92         ; Access flags
    db 0xCF         ; Granularity
    db 0x00         ; Base (high)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ 0x08
DATA_SEG equ 0x10

; --- 32-bit Protected Mode Code ---
[bits 32]
init_32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000

    mov eax, 0x20000
    jmp eax

    jmp $