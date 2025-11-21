[org 0x8000]          ; Origin: Code starts at memory address 0x8000
[bits 16]             ; 16-bit real mode assembly

; ==============================================================================
; STAGE 2 BOOTLOADER - Graphics Menu
; ==============================================================================
; This is the second stage bootloader that displays an interactive menu
; allowing the user to select between different programs (Addition, Subtraction,
; or C Kernel). The menu is displayed in graphics mode 13h (320x200 pixels).
; ==============================================================================

start:
    ; Initialize segment registers to match code segment (CS)
    mov ax, cs
    mov ds, ax            ; Set data segment = code segment
    mov es, ax            ; Set extra segment = code segment

    ; Set graphics mode 13h (320x200 resolution, 256 colors)
    ; This is a standard VGA graphics mode for text/graphics display
    mov ax, 0x0013        ; AH=0 (set video mode), AL=0x13 (mode 13h)
    int 0x10              ; BIOS interrupt: set video mode

    ; ==== Display Menu Title ====
    mov si, menu_msg      ; SI = pointer to menu title string
    mov dh, 0             ; DH = Y position (line 5)
    mov dl, 2             ; DL = X position (column 2)
    call print_string_gfx ; Draw string on graphics screen
    
    ; ==== Display Menu Option 1 (Addition) ====
    mov si, menu_opt1     ; SI = pointer to option 1 string
    mov dh, 1             ; DH = Y position (line 7)
    mov dl, 2             ; DL = X position (column 2)
    call print_string_gfx ; Draw string on graphics screen
    
    ; ==== Display Menu Option 2 (Subtraction) ====
    mov si, menu_opt2     ; SI = pointer to option 2 string
    mov dh, 2             ; DH = Y position (line 8)
    mov dl, 2             ; DL = X position (column 2)
    call print_string_gfx ; Draw string on graphics screen

    ; ==== Display Menu Option 3 (C Kernel) ====
    mov si, menu_opt3     ; SI = pointer to option 3 string
    mov dh, 3             ; DH = Y position (line 9)
    mov dl, 2             ; DL = X position (column 2)
    call print_string_gfx ; Draw string on graphics screen

    ; ==== Display User Prompt ====
    mov si, menu_prompt   ; SI = pointer to prompt string
    mov dh, 4            ; DH = Y position (line 11)
    mov dl, 2             ; DL = X position (column 2)
    call print_string_gfx ; Draw string on graphics screen

; ==============================================================================
; KEYBOARD INPUT LOOP - Wait for user selection
; ==============================================================================
get_key:
    mov ah, 0x00         ; BIOS function: wait for keystroke
    int 0x16             ; Call BIOS interrupt (keyboard)
                         ; Returns ASCII code in AL

    ; Check if user pressed '1' (Addition)
    cmp al, '1'
    je load_math_add
    
    ; Check if user pressed '2' (Subtraction)
    cmp al, '2'
    je load_math_sub
    
    ; Check if user pressed '3' (C Kernel)
    cmp al, '3'
    je load_c_loader

    jmp get_key          ; If invalid key, wait for another keystroke

; ==============================================================================
; LOAD PROGRAM ROUTINES - Load selected program from disk
; ==============================================================================

; Load Addition Program (math_add.asm)
; Located at sector 25, size: 1 sector
load_math_add:
    mov ax, 0x0003       ; Set text mode (return to 80x25 text display)
    int 0x10             ; BIOS interrupt: set video mode
    mov byte [sector_to_load], 25  ; Sector number where addition program is stored
    mov byte [sector_count], 1     ; Load 1 sector
    call load_sectors    ; Load the program from disk
    jmp 0x8000           ; Jump to loaded program execution

; Load Subtraction Program (math_sub.asm)
; Located at sector 26, size: 1 sector
load_math_sub:
    mov ax, 0x0003       ; Set text mode
    int 0x10             ; BIOS interrupt: set video mode
    mov byte [sector_to_load], 26  ; Sector number where subtraction program is stored
    mov byte [sector_count], 1     ; Load 1 sector
    call load_sectors    ; Load the program from disk
    jmp 0x8000           ; Jump to loaded program execution

; Load C Kernel Loader (c_loader.asm)
; Located at sector 27, size: 16 sectors
load_c_loader:
    mov ax, 0x0003       ; Set text mode
    int 0x10             ; BIOS interrupt: set video mode
    mov byte [sector_to_load], 27  ; Sector number where C kernel starts
    mov byte [sector_count], 16    ; Load 16 sectors for the C kernel
    call load_sectors    ; Load the program from disk
    jmp 0x8000           ; Jump to loaded program execution

; ==============================================================================
; DISK I/O ROUTINE - Load sectors from disk
; ==============================================================================
; Function: load_sectors
; Loads specified sectors from disk into memory at address 0x8000
; Uses variables: sector_to_load (sector number), sector_count (number of sectors)
; ==============================================================================
load_sectors:
    mov ah, 0x02         ; BIOS function: read disk sectors
    mov al, [sector_count]      ; AL = number of sectors to read
    mov ch, 0            ; CH = cylinder number (0)
    mov cl, [sector_to_load]    ; CL = starting sector number
    mov dh, 0            ; DH = head number (0 = first head)
    mov dl, 0x00         ; DL = drive number (0x00 = floppy drive A:)
    mov bx, 0x8000       ; BX = destination address (where data will be loaded)
    int 0x13             ; BIOS interrupt: disk I/O
    jc disk_error        ; If carry flag set, disk error occurred
    ret

; ==============================================================================
; ERROR HANDLING - Display disk error message
; ==============================================================================
disk_error:
    mov ax, 0x0003       ; Set text mode (clear screen)
    int 0x10             ; BIOS interrupt: set video mode
    mov si, error_msg    ; SI = pointer to error message string
    call print_string_bios  ; Display error message using BIOS
    jmp $                ; Infinite loop (system halted)

; ==============================================================================
; TEXT OUTPUT ROUTINE - Print string in BIOS text mode
; ==============================================================================
; Function: print_string_bios
; Displays a null-terminated string using BIOS teletype function
; Input: SI = pointer to null-terminated string
; Affects: AX, SI (consumed during execution)
; ==============================================================================
print_string_bios:
    mov ah, 0x0E         ; BIOS function: teletype output (write character in TTY mode)
.loop:
    lodsb                ; Load byte from [SI] into AL and increment SI
    cmp al, 0            ; Check if null terminator reached
    je .done             ; If yes, exit function
    int 0x10             ; BIOS interrupt: display character in AL
    jmp .loop            ; Continue with next character
.done:
    ret

; ==============================================================================
; GRAPHICS OUTPUT ROUTINE - Print string in VGA graphics mode 13h with font
; ==============================================================================
; Function: print_string_gfx
; Draws a null-terminated string using bitmap font data from font_data
; Each character is 8x8 pixels, rendered using bit patterns
;
; Input:  SI = pointer to null-terminated string
;         DH = Y line number in character units (0-24)
;         DL = X column number in character units (0-39)
; 
; Mode 13h specifics:
;   - Resolution: 320x200 pixels
;   - Linear video memory at segment 0xA000
;   - Each pixel = 1 byte (color index 0-255)
;   - Each scanline = 320 bytes
;   - Character = 8x8 pixels
;   - Font data: each character has 8 bytes, each byte = 1 pixel row
;   - In each byte: bit 7=leftmost pixel, bit 0=rightmost pixel
;
; The function draws white (0x0F) pixels for set bits, black (0x00) for clear bits
; ==============================================================================
print_string_gfx:
    pusha                ; Save all general-purpose registers
    push ds              ; Save DS register

    mov ax, 0xA000       ; AX = VGA graphics memory segment address
    mov es, ax           ; ES = segment register pointing to video memory
    
    ; DS points to font data
    mov ax, cs           ; Load code segment
    mov ds, ax           ; DS = CS (font data in code segment)

    ; Calculate starting pixel offset: (Y_line * 8 * 320) + (X_col * 8)
    ; Y coordinate in pixels = DH * 8, X coordinate in pixels = DL * 8
    mov al, dh           ; AL = line number
    mov bl, 8            ; BL = pixels per character vertically
    mul bl               ; AX = line * 8 (Y pixel offset multiplier)
    mov bx, 320          ; BX = scanline width (320 pixels)
    mul bx               ; AX = (line * 8) * 320 (Y pixel offset)
    
    ; Add X offset: column * 8 pixels
    mov bx, 0
    mov bl, dl           ; BL = column number
    mov cl, 3            ; CL = 3 (shift by 3 = multiply by 8)
    shl bx, cl           ; BX = column * 8 (X pixel offset)
    add ax, bx           ; AX = final starting offset

    mov bp, ax           ; BP = base offset for current line of text

; Main loop: process each character in the string
.char_loop:
    lodsb                ; Load character byte from [SI] into AL, increment SI
    cmp al, 0            ; Check if null terminator reached
    je .done             ; If yes, exit function

    ; Save current string position (SI) for next character
    push si              ; Save SI on stack for next iteration

    ; Calculate font data address for this character
    ; Font address = font_start + (ASCII value * 8)
    xor ah, ah           ; AH = 0 (clear upper byte of character code)
    mov bx, 8            ; BX = bytes per character
    mul bx               ; AX = ASCII * 8 (offset to character in font)
    
    add ax, font_start   ; AX = font_start + (ASCII * 8) = font data address
    mov bx, ax           ; BX = font data address
    
    mov di, bp           ; DI = base offset for current character

    ; Draw all 8 rows of the character
    mov cx, 8            ; CX = 8 pixel rows per character
.row_loop:
    mov al, [ds:bx]      ; Load one row of font bitmap (8 bits = 8 pixels)
    inc bx               ; Move to next row in font data

    ; Process 8 pixels in this row from left to right
    mov ah, 8            ; AH = 8 pixels per row
.pixel_loop_x:
    test al, 0x80        ; Test leftmost bit (bit 7)
    je .pixel_off        ; If bit is 0, draw black pixel
    mov byte [es:di], 0x00  ; Draw white pixel (0x0F)
    jmp .pixel_advance
.pixel_off:
    mov byte [es:di], 0x0F   ; Draw black pixel (0x00)
.pixel_advance:
    inc di               ; Move to next pixel horizontally
    shl al, 1            ; Shift character bitmap left (next bit to bit 7)
    dec ah               ; Decrement pixel counter
    jnz .pixel_loop_x    ; Repeat for all 8 pixels

    ; Move to next row
    add di, 312          ; DI += 312 (320 - 8 pixels already drawn)
    loop .row_loop       ; Repeat for all 8 rows

    ; Move to next character position (8 pixels to the right, same Y)
    mov ax, bp           ; AX = base offset
    add ax, 8            ; Add 8 pixels (next character position)
    mov bp, ax           ; Update base offset
    
    ; Restore string pointer for next character
    pop si               ; Restore SI from stack
    jmp .char_loop       ; Process next character

.done:
    pop ds               ; Restore DS register
    popa                 ; Restore all general-purpose registers
    ret

; ==============================================================================
; DATA SECTION - Variables and strings
; ==============================================================================

; Variables used by load_sectors routine
sector_to_load: db 0   ; Stores the sector number to load from disk
sector_count: db 0     ; Stores the count of sectors to load

; Menu strings displayed in graphics mode
menu_msg:    db 'Menu Grafico', 0        ; Main menu title
menu_opt1:   db '1. Adicao', 0           ; Option 1: Addition program
menu_opt2:   db '2. Subtracao', 0        ; Option 2: Subtraction program
menu_opt3:   db '3. Kernel C', 0         ; Option 3: C Kernel program
menu_prompt: db '> ', 0                  ; User input prompt
error_msg:   db 'Erro de Disco!', 0x0D, 0x0A, 0  ; Disk error message
                                         ; 0x0D = carriage return
                                         ; 0x0A = line feed

; ==============================================================================
; FONT DATA - Include font bitmap from external file
; ==============================================================================
%include "font.asm"
