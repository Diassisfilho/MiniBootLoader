; ---------------------------------------------------------
; boot_fpu_add_msg.asm — Boot sector (512 bytes)
; Lê dois dígitos (0–9), imprime mensagens, soma usando FPU
; e imprime o resultado corretamente em decimal.
; ---------------------------------------------------------

BITS 16
ORG 0x8000

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

; ---------------------------------------------------------
; imprime "Digite dois digitos (0-9):"
; ---------------------------------------------------------
    mov si, msg_intro
    call print_string

; ---------------------------------------------------------
; imprime "Primeiro numero:"
; ---------------------------------------------------------
    mov si, msg_first
    call print_string

; lê primeiro dígito
    call read_digit
    mov bl, al

; imprime quebra de linha
    mov si, newline
    call print_string

; ---------------------------------------------------------
; imprime "Segundo numero:"
; ---------------------------------------------------------
    mov si, msg_second
    call print_string

; lê segundo dígito
    call read_digit
    mov bh, al

; pula linha
    mov si, newline
    call print_string

; ---------------------------------------------------------
; coloca valores em memória
; ---------------------------------------------------------
    mov ax, bx
    and ax, 0x00FF
    mov [num1], ax

    mov ax, bx
    shr ax, 8
    mov [num2], ax

; ---------------------------------------------------------
; FPU: soma
; ---------------------------------------------------------
    fild word [num1]
    fild word [num2]
    fadd
    fist word [result]

; ---------------------------------------------------------
; Imprime "Resultado:"
; ---------------------------------------------------------
    mov si, msg_result
    call print_string

; ---------------------------------------------------------
; imprime resultado em decimal
; ---------------------------------------------------------
    mov ax, [result]
    cmp ax, 0
    je .print_zero

    lea si, [numbuf + 6]
    mov cx, 10

.convert_loop:
    xor dx, dx
    div cx
    dec si
    add dl, '0'
    mov [si], dl
    cmp ax, 0
    jne .convert_loop

.print_num:
    mov di, numbuf + 6
.print_loop:
    cmp si, di
    je .done
    mov al, [si]
    mov ah, 0x0E
    int 0x10
    inc si
    jmp .print_loop

.print_zero:
    mov al, '0'
    mov ah, 0x0E
    int 0x10

.done:
    ; ==========================================================
    ; MODIFICAÇÃO: Aguardar 5 segundos e retornar ao Menu
    ; ==========================================================
    
    ; Pular uma linha antes
    mov si, newline
    call print_string

    ; 1. Função BIOS Wait (INT 15h, AH=86h)
    ; 5 segundos = 5.000.000 us = 0x004C4B40 hex
    mov cx, 0x004C
    mov dx, 0x4B40
    mov ah, 0x86
    int 0x15

    ; 2. Retornar ao Menu (Stage 2 em 0x7000)
    jmp 0x0000:0x7000

; ---------------------------------------------------------
; Funções
; ---------------------------------------------------------

; print_string: imprime string até encontrar 0
print_string:
    lodsb
    or al, al
    jz .end
    mov ah, 0x0E
    int 0x10
    jmp print_string
.end:
    ret

; read_digit: lê tecla e retorna AL = 0..9
read_digit:
    mov ah, 0
    int 0x16
    sub al, '0'
    ret

; ---------------------------------------------------------
; Dados
; ---------------------------------------------------------

msg_intro   db "Digite dois digitos (0-9):",0
msg_first   db "Primeiro numero:",0
msg_second  db "Segundo numero:",0
msg_result  db "Resultado:",0
newline     db 13,10,0

num1    dw 0
num2    dw 0
result  dw 0
numbuf  times 6 db 0

; ---------------------------------------------------------
; Boot sector padding + assinatura
; ---------------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55
