[org 0x7C00]    ; Origin address set by BIOS
[bits 16]       ; We are in 16-bit real mode

start:
    ; Set up segment registers
    mov ax, 0
    mov ds, ax
    mov es, ax
    
    ; Set up the stack
    mov ax, 0x7C00
    mov ss, ax
    mov sp, 0xFFFF

    ; Display the menu
    mov si, menu_msg
    call print_string

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

; --- Data ---
menu_msg:       db '--- My Bootloader Menu ---', 0x0D, 0x0A
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