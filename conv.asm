section .data
ErrEmpty      DB "Error: empty string provided (or only contains '-')", 10
ErrEmptyLen   EQU $-ErrEmpty
ErrEmptyCode  EQU 2

ErrInvalidSym       DB "Error: invalid symbol encountered while parsing a number: "
ErrInvalidSymLoc    DB ' ', 10
ErrInvalidSymLen    EQU $-ErrInvalidSym
ErrInvalidSymCode   EQU 3

ErrBufferTooSmall       DB "Error: provided buffer is too small to fit the number"
ErrBufferTooSmallLen    EQU $-ErrBufferTooSmall
ErrBufferTooSmallCode   EQU 4

section .text

; input:
;  esi = points to input string
;  ecx = input string length
;
; output if successful:
;  eax = 0
;  ecx = remaining string length after parsing the number
;  edx = converted number
;  esi = points to the symbol after the number
;
; output if error:
;  eax != 0
;  ecx = [error message]
;  edx = error message len
;  esi points to the invalid symbol
;
; assumes number can fit into 32bit signed
; ignores leading spaces
; allows trailing space or newline
StrToInt:
    cld ; direction: left->right

    xor edx, edx ; output

    cmp ecx, 0
    jle .sti_err_empty

.sti_space_loop:
    lodsb
    cmp al, ' '
loope .sti_space_loop

    jcxz .sti_err_empty ; we already checked for <0

    ; save the sym in case it's a '-', we'll deal with this later
    cbw
    push ax

    cmp al, '-'
    jne .sti_main_loop

    lodsb
    dec ecx
    ; спасибо, Никита =)
    sub al, '0'
    cmp al, '9' - '0'
    ja .sti_err_sym_actual
    
    jmp .sti_enter_loop ; don't do the checks twice

.sti_main_loop:
    ; check for valid sym while also converting sym->digit
    sub al, '0'
    cmp al, '9' - '0'
    ja .sti_err_sym

.sti_enter_loop:

    ; god i hate the way mul & div work with a burning passion
    cbw
    push ax
    mov eax, edx
    mov edx, 10
    mul edx
    ; and here's where we assume the number fits into 32bit signed
    mov edx, eax
    pop ax
    cwde
    add edx, eax

    lodsb
loop .sti_main_loop

.sti_loop_end:
    ; NOW we deal with negatives
    pop ax
    
    cmp al, '-'
    jne .sti_success
    
    neg edx
    jmp .sti_success

.sti_err_empty:
    mov eax, ErrEmptyCode
    mov ecx, ErrEmpty
    mov edx, ErrEmptyLen
    jmp .sti_return

.sti_err_sym:
    ; these are allowed
    cmp al, ' ' - '0'
    je .sti_loop_end
    cmp al, 10 - '0' ; newline
    je .sti_loop_end

.sti_err_sym_actual:
    add al, '0' ; convert back digit->sym

    mov [ErrInvalidSymLoc], al
    
    pop ax
    mov eax, ErrInvalidSymCode
    mov ecx, ErrInvalidSym
    mov edx, ErrInvalidSymLen
    jmp .sti_return

.sti_success:
    xor eax, eax ; the sign of success
.sti_return:
    ret

; input:
;  edi = points to the output buffer
;  ebx = output buffer size
;  edx = number to convert
;
; output if successful:
;  eax = 0
;  edi = points to the byte after the end of converted number
;  ebx = remaining output buffer size
;  edx = converted number's length
;
; output if error:
;  eax != 0
;  ecx = [error message]
;  edx = error message len
;  edi points back to the start of the buffer
;  the only possible error is when the provided buffer is too small to fit the number
IntToStr:
    cld ; direction: left->right

    push ecx
    push edi

    mov ecx, ebx
    mov ebx, 10

    cmp edx, 0
    jge .its_skip_neg

    ; better deal with negativity now
    mov al, '-'
    stosb
    neg edx

.its_skip_neg:
    mov eax, edx

.its_main_loop:
    ; lemme check... yep. still hate both mul & div
    xor edx, edx
    div ebx
    xchg al, dl ; save al. (ebx is always 10 and eax is always >0 so the remainder always fits in dl)
    add al, '0'
    stosb
    mov al, dl ; restore al

    cmp eax, 0
loopne .its_main_loop

    jg .its_err_buf
    
    ; commence reversion protocol
    pop ebx ; ebx = old edi (start of buffer)

    mov edx, edi
    sub edx, ebx ; now edx holds the length and we do not touch it ever again

    push edi
    dec edi ; now edi points to the last symbol

    cmp byte[ebx], '-'
    jne .its_rev_loop

    inc ebx ; '-' is already in place

.its_rev_loop:
    cmp ebx, edi
    jge .its_success
    
    mov al, [ebx]
    mov ah, [edi]
    mov [ebx], ah
    mov [edi], al

    inc ebx
    dec edi
    jmp .its_rev_loop

.its_err_buf:
    mov eax, ErrBufferTooSmallCode
    mov ecx, ErrBufferTooSmall
    mov edx, ErrBufferTooSmallLen
    jmp .its_return

.its_success:
    xor eax, eax ; the sign of success again

.its_return:
    pop edi
    mov ebx, ecx
    pop ecx
    ret