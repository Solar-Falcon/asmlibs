section .data
_ExitMsg     DB "Press Enter to exit", 10
_ExitMsgLen  EQU $-_ExitMsg

section .bss
_InputBuf    RESB 16
_InputBufLen EQU $-_InputBuf

%macro write 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

%macro write0 0
    mov eax, 4
    mov ebx, 1
    int 0x80
%endmacro

%macro read 2
    mov eax, 3
    mov ebx, 0
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

%macro read0 0
    mov eax, 3
    mov ebx, 0
    int 0x80
%endmacro

%macro exit 0
    write _ExitMsg, _ExitMsgLen
    read _InputBuf, _InputBufLen

    mov eax, 1
    xor ebx, ebx
    int 0x80
%endmacro
