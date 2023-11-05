; tokenize(output: [*]Token, input: [*]const u8, input_len: u32) u32
tokenize:
    push ebp
    mov ebp, esp
    xor eax, eax

.loop:
    cmp edx, 0
    je .end

    ; whitespace = { ' ', '\t', '\n', vt, ff, '\r' }
    .whitespaceCheck:
        cmp byte [ecx], 32
        je .whitespace
        cmp byte [ecx], 9
        jl .whitespaceCheckEnd
        cmp byte [ecx], 13
        jg .whitespaceCheckEnd
        jmp .whitespace
    .whitespaceCheckEnd:

    .alphaCheck:
        push eax
        mov al, byte [ecx]
        call isAlpha
        cmp eax, 0
        pop eax
        je .alphaCheckEnd
        jmp .identifier
    .alphaCheckEnd:

    jmp errorHandle.token

.loopRet:
    inc ecx
    dec edx
    jmp .loop

.whitespace:
    jmp .loopRet

.identifier:
    inc ecx
    dec edx
    cmp edx, 0
    je .identifierEnd

    push eax
    mov al, byte [ecx]
    call isAlpha
    cmp eax, 0
    pop eax
    je .identifierEnd
    jmp .identifier
.identifierEnd:
    dec ecx
    inc edx

    inc eax
    mov byte [ebx], 0
    add ebx, TOKEN_SIZE
    jmp .loopRet

.end:
    pop ebp
    ret

; isAlpha(c: u8) bool
; al
isAlpha:
    or al, 0x20
    sub al, 'a'
    cmp al, 'z'-'a'
    ja .end

    mov al, 1
    ret
.end:
    mov al, 0
    ret