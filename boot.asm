[org 0x7C00]
[bits 16]

start:
    ; Configuração mínima da stack e segmentos
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov ax, 0x7C00
    mov ss, ax
    mov sp, 0xFFFF

    ; Carrega o Estágio 2 (stage2.bin)
    ; O Estágio 2 começa no Setor 2
    mov ah, 0x02        ; BIOS - ler setor
    mov al, 4           ; Número de setores a ler (4 * 512 = 2048)
    mov ch, 0           ; Cilindro 0
    mov cl, 2           ; Setor inicial (Setor 2)
    mov dh, 0           ; Cabeça 0
    mov dl, 0x00        ; Drive 0 (A:)
    mov bx, 0x7000      ; Endereço do buffer (ES:BX -> 0x0000:0x8000)
    
    int 0x13
    jc load_error       ; Se falhar, congela

    ; Pula para o Estágio 2
    jmp 0x7000

load_error:
    ; Se não conseguir carregar o stage2, não há o que fazer
    mov si, err_msg
    call print_string_simple
    jmp $               ; Loop infinito

print_string_simple:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

err_msg: db 'Erro ao carregar Stage 2!', 0x0D, 0x0A, 0

; Preenchimento e assinatura
times 510-($-$$) db 0
dw 0xAA55