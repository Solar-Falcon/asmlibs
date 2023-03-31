%include "macros.asm"
%include "conv.asm"

section .data
    
section .bss
InBufferLen EQU 32
InBuffer    RESB InBufferLen

OutBufferLen   EQU 64
OutBuffer      RESB OutBufferLen

section .text
    global _start

_start:
    read InBuffer, InBufferLen
    mov esi, InBuffer
    mov ecx, eax ; length of input from calling int 0x80

    mov edi, OutBuffer
    mov ebx, OutBufferLen

.theloop:
    call StrToInt

    cmp eax, 0
    jne .exit_loop

    ; do stuff with edx
    neg edx
    ; end doing stuff

    call IntToStr

    cmp eax, 0
    jne .exit_loop

    mov al, ' '
    stosb

    jmp .theloop

.exit_loop:
    cmp eax, ErrEmptyCode
    je .skip_err

    write0
    exit

.skip_err:
    write OutBuffer, OutBufferLen
    exit