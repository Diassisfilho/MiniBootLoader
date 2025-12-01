[org 0x8000]
[bits 16]

; --- Configuração de Segmentos ---
start:
    ; Desabilita interrupções, configura a pilha e os segmentos de dados
    cli                  
    xor ax, ax           
    mov ss, ax           ; SS = 0
    mov sp, 0x7c00       ; Ponteiro de pilha abaixo do setor de inicialização
    mov ds, ax           ; DS = 0 (Segmento de Dados)
    mov es, ax           ; ES = 0 (Segmento Extra)
    sti                  ; Habilita interrupções

    ; --- Cálculo FPU: z = sin( (x * pi) / y ) ---
    finit               ; Inicializa FPU

    ; 1. Empilha x (30.0)
    fld dword [f_x]     ; ST(0) = 30.0

    ; 2. Empilha pi
    fldpi               ; ST(0) = pi, ST(1) = 30.0

    ; 3. x * pi
    fmulp               ; ST(0) = 30.0 * pi

    ; 4. Divide por y (180.0)
    fdiv dword [f_y]    ; ST(0) = (x * pi) / y

    ; 5. Calcula o Seno
    fsin                ; ST(0) = sin(ângulo) (Deve ser ~0.5)

    ; 6. Armazena o resultado na memória e remove da pilha
    fstp qword [f_z]    ; Resultado (0.5) armazenado em f_z 
    fld qword [f_z]
    fimul word [scale]     ; f_z * 100
    fistp word [tmp_int]   ; AX recebe inteiro

    ; --- Saída de Verificação (usando BIOS INT 10h) ---
    mov si, result_msg  ; SI aponta para a string da mensagem
    call print_string   ; Imprime mensagem
    mov ax, [tmp_int]
    
    ; --- imprimir valor de f_z com 2 casas decimais ---
    fld qword [f_z]       ; ST(0) = resultado
    fimul word [scale]    ; ST(0) = resultado * 100
    fistp word [scaled]   ; scaled = inteiro com as 2 casas

    ; dividir scaled por 100 -> AX = inteiro, DX = fração
    mov ax, [scaled]
    cwd                   ; estender sinal
    mov bx, 100
    idiv bx               ; AX = inteiro, DX = fracção

    ; imprimir inteiro
    push dx
    push ax
    call print_int        ; imprime AX como número
    pop ax
    pop dx

    ; imprimir ponto
    mov al, '.'
    mov ah, 0x0E
    int 0x10

    ; imprimir as duas casas
    mov ax, dx
    cmp ax, 0
    jns .pos_frac
    neg ax
.pos_frac:
    mov bx, 10
    xor dx, dx
    div bx        ; AX = dezenas, DX = unidades
    add al, '0'
    mov ah, 0x0E
    int 0x10
    add dl, '0'
    mov al, dl
    mov ah, 0x0E
    int 0x10

    call print_nl

    ; ==========================================================
    ; Aguardar 5 segundos e retornar ao Menu
    ; ==========================================================
    
    ; 1. Função BIOS Wait (INT 15h, AH=86h)
    ; Entrada: CX:DX = intervalo em microsegundos
    ; 5 segundos = 5.000.000 us = 0x004C4B40 hex
    mov cx, 0x004C      ; Parte alta
    mov dx, 0x4B40      ; Parte baixa
    mov ah, 0x86        ; Função Wait
    int 0x15

    ; 2. Saltar de volta para o Stage 2 (Menu)
    ; O Stage 2 está carregado em 0x7000
    jmp 0x0000:0x7000   

; --- Sub-rotinas (mantidas iguais) ---
print_string:
    pusha
.loop:
    lodsb               ; Carrega byte de [si] para al, incrementa si
    cmp al, 0           ; Verifica o terminador nulo
    je .done            
    
    ; BIOS INT 10h, Função 0Eh: Escrever Caractere no Modo Teletype
    mov ah, 0x0e        
    mov bh, 0           ; Número da página
    mov bl, 0x07        ; Cor (Branco)
    int 0x10            ; Chama o serviço da BIOS
    jmp .loop
.done:
    popa
    ret
; ----------------------------------------------------------
; imprime inteiro em AX (signed)
print_int:
    pusha
    cmp ax, 0
    jge .skip_sign
    mov al, '-'
    mov ah, 0x0E
    int 0x10
    neg ax
.skip_sign:
    xor cx, cx
    mov bx, 10
.print_loop_int:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .print_loop_int
.print_int_digits:
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x0E
    int 0x10
    loop .print_int_digits
    popa
    ret

print_nl:
    mov al, 0x0D
    mov ah, 0x0E
    int 0x10
    mov al, 0x0A
    mov ah, 0x0E
    int 0x10
    ret


scaled dw 0


; --- Dados ---
; O resultado (0.5) é armazenado nos 8 bytes começando no endereço de memória 0x7C21
result_msg db "Setor de Inicializacao FPU em Execucao: Calculo de sin(30 graus) completo! ", 0

; --- Dados Fixos (30 graus / 180 graus) ---
    ; Para evitar I/O complexa de 16-bits, fixamos x e y.
    ; O resultado deve ser sin(30 * pi / 180) = sin(pi/6) = 0.5
    f_x dd 30.0         ; x = 30.0 (float de 32-bits)
    f_y dd 180.0        ; y = 180.0 (float de 32-bits)
    f_z dq 0.0          ; Resultado (float de 64-bits, onde 0.5 é armazenado)
    scale dw 100
    tmp_int dw 0


; --- Preenchimento do Setor de Inicialização e Assinatura ---
;times 510 - ($ - $$) db 0
;dw 0xaa55           ; Assinatura mágica de inicialização