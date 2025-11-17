[org 0x7C00]
[bits 16]

start:
    ; Set up segment registers
    mov ax, 0
    mov ds, ax
    mov es, ax
    
    ; Set up the stack
    mov ax, 0x7C00
    mov ss, ax
    mov sp, 0xFFFF

    ; --- NOVO: Mostrar Imagem ---
    call load_logo_image  ; Carrega a imagem para 0x1000:0x0000
    call set_graphics_mode ; Define Modo 13h (320x200, 256c)
    call draw_logo_image   ; Desenha a imagem na tela
    
    ; Espera uma tecla antes de continuar
    mov ah, 0x00
    int 0x16

    ; --- FIM: Mostrar Imagem ---

    ; Restaura o modo de texto
    call set_text_mode

    ; Display the menu (código original)
    mov si, menu_msg
    call print_menu

get_key:
    ; Wait for a keypress
    mov ah, 0x00    ; BIOS wait for key
    int 0x16        ; AL = ASCII character
    
    ; Echo the key
    mov ah, 0x0E    ; BIOS teletype output
    int 0x10

    ; Compare the key
    cmp al, '1'
    je load_math_add
    
    cmp al, '2'
    je load_math_sub
    
    cmp al, '3'
    je load_c_loader

    ; Invalid key, print error and loop
    mov si, invalid_msg
    call print_string
    jmp start

load_math_add:
    ; Load program from Sector 2 (1-indexed)
    call load_sector
    jmp 0x8000          ; Jump to loaded program

load_math_sub:
    ; Load program from Sector 3
    inc byte [sector_to_load] ; sector_to_load becomes 3
    call load_sector
    jmp 0x8000

load_c_loader:
    ; Load program from Sector 4 (16 sectors for c_loader)
    inc byte [sector_to_load] ; sector_to_load becomes 3
    inc byte [sector_to_load] ; sector_to_load becomes 4
    call load_c_loader_sectors
    jmp 0x8000

; Function: load_c_loader_sectors
; Loads 16 sectors from Sector 4 into 0x0000:0x8000 (ES:BX)
load_c_loader_sectors:
    mov ah, 0x02        ; BIOS read sector
    mov al, 16          ; Number of sectors to read
    mov ch, 0           ; Cylinder 0
    mov cl, [sector_to_load] ; Sector number (4)
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive 0 (A:)
    mov bx, 0x8000      ; ES:BX buffer address (ES=0)
    int 0x13
    jc read_error       ; Jump if carry flag (error)
    ret

; Function: load_sector
; Loads 1 sector from [sector_to_load] into 0x0000:0x8000 (ES:BX)
load_sector:
    mov ah, 0x02        ; BIOS read sector
    mov al, 1           ; Number of sectors to read
    mov ch, 0           ; Cylinder 0
    mov cl, [sector_to_load] ; Sector number
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive 0 (A:)
    mov bx, 0x8000      ; ES:BX buffer address (ES=0)
    int 0x13
    jc read_error       ; Jump if carry flag (error)
    ret

read_error:
    mov si, error_msg
    call print_string
    jmp start

; Function: print_string
; Prints a null-terminated string (SI = string address)
print_string:
    mov ah, 0x0E        ; BIOS teletype output
.loop:
    lodsb               ; Load byte [ds:si] into al, increment si
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; Function: print_menu
; Writes a null-terminated string at the top-left of the screen
; using VGA text buffer with attribute BG=blue, FG=white (0x1F)
print_menu:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, 0xB800
    mov es, ax
    xor di, di        ; start at top-left
    xor cx, cx        ; char count

.pm_loop:
    lodsb
    cmp al, 0
    je .pm_done
    cmp al, 0x0D
    je .pm_newline
    cmp al, 0x0A
    je .pm_loop

    mov [es:di], al
    mov al, 0x1F
    mov [es:di+1], al
    add di, 2
    inc cx
    jmp .pm_loop

.pm_newline:
    mov ax, cx
    shl ax, 1         ; ax = cx * 2
    mov bx, 160
    sub bx, ax        ; bx = 160 - cx*2
    add di, bx
    xor cx, cx
    jmp .pm_loop

.pm_done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

set_graphics_mode:
    mov ax, 0x0013  ; Modo 13h: 320x200, 256 cores
    int 0x10
    ret

set_text_mode:
    mov ax, 0x0003  ; Modo de texto padrão 80x25
    int 0x10
    ret

load_logo_image:
    ; Carrega 8 setores (logo.img) do setor 5 para 0x1000:0x0000
    mov ax, 0x1000
    mov es, ax
    mov bx, 0x0000      ; Endereço do buffer (ES:BX)
    
    mov ah, 0x02        ; BIOS read sector
    mov al, 8           ; Número de setores para ler (4096 / 512 = 8)
    mov ch, 0           ; Cylinder 0
    mov cl, 5           ; Setor inicial (1=boot, 2=math_add, 3=math_sub, 4=c_loader, 5=logo)
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive 0 (A:)
    int 0x13
    jc read_error       ; Pula em caso de erro
    ret

draw_logo_image:
    ; Desenha uma imagem 64x64 no canto superior direito
    ; A imagem está em 0x1000:0x0000
    ; A memória de vídeo (Modo 13h) está em 0xA000:0x0000
    
    pusha
    mov ax, 0xA000
    mov es, ax          ; es = Segmento de vídeo
    
    ; --- MUDANÇA ESTÁ AQUI ---
    ; Posição inicial: Y=0, X = (320 - 64) = 256
    mov di, 256         ; di = Posição de destino (tela y=0, x=256)
    ; --- FIM DA MUDANÇA ---

    mov ax, 0x1000
    mov ds, ax          ; ds = Segmento da imagem
    xor si, si          ; si = Posição da fonte (imagem)
    
    mov cx, 64          ; Contador de linhas (Y)
.y_loop:
    push cx
    mov cx, 64          ; Contador de colunas (X)
.x_loop:
    lodsb               ; Carrega byte [ds:si] para al, incrementa si
    mov [es:di], al     ; Escreve byte em [es:di]
    inc di              ; Próximo pixel na tela
    loop .x_loop
    
    ; Pula para a próxima linha na tela (320 - 64)
    ; Esta lógica permanece a mesma.
    add di, (320 - 64) 
    
    pop cx
    loop .y_loop
    
    popa
    ret

; --- Data ---
menu_msg:       db '--- Buti Loarder Menu ---', 0x0D, 0x0A
                db '1. Run Addition Program', 0x0D, 0x0A
                db '2. Run Subtraction Program', 0x0D, 0x0A
                db '3. Run C Kernel', 0x0D, 0x0A
                db '> ', 0
invalid_msg:    db 0x0D, 0x0A, 'Invalid option!', 0x0D, 0x0A, 0
error_msg:      db 0x0D, 0x0A, 'Disk read error!', 0x0D, 0x0A, 0

sector_to_load: db 2    ; Start at sector 2 (1 is bootloader)

; Bootloader signature
times 510-($-$$) db 0   ; Pad with zeros
dw 0xAA55               ; Magic number