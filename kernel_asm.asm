[bits 32]

extern main         ; Declare main as external (defined in kernel.c)
global do_math      ; Make this function visible to the C linker
global _start       ; Entry point for the kernel

_start:
    ; Entry point: call C main function
    call main
    ; If main returns, halt
    jmp $

do_math:
    ; --- Cdecl Stack Frame ---
    push ebp        ; Save old base pointer
    mov ebp, esp    ; Set new base pointer

    ; Arguments are on the stack:
    ; [ebp + 8]  -> First argument (a)
    ; [ebp + 12] -> Second argument (b)
    
    mov eax, [ebp + 8]  ; Move 'a' into eax
    mov ebx, [ebp + 12] ; Move 'b' into ebx
    
    add eax, ebx        ; eax = a + b

    ; Return value is placed in EAX (already done)
    
    ; --- Tear down stack and return ---
    mov esp, ebp    ; Restore stack pointer
    pop ebp         ; Restore old base pointer
    ret             ; Return to C