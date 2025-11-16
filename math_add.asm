[org 0x8000]
[bits 16]

start:
    mov si, msg
    call print_string

    mov ax, 100
    mov bx, 50
    add ax, bx      ; ax = 100 + 50 = 150

    ; We'd need a "print number" routine here,
    ; but for simplicity, we'll just halt.
    mov si, done_msg
    call print_string

    jmp $           ; Infinite loop

; Function: print_string (copied from bootloader)
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

msg:      db '--- Addition Program ---', 0x0D, 0x0A, 0
done_msg: db '100 + 50 = 150. Halting.', 0x0D, 0x0A, 0