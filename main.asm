;; This file is meant to be used on 32bit linux
;; The actual compiler is desgned to be usable on bare-metal
format elf executable

SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
SYS_OPEN equ 5
SYS_CLOSE equ 6

O_RDONLY equ 0

MAX_FILE_LEN equ 32 * 1024
MAX_TOKEN_COUNT equ 1024

TOKEN_SIZE equ 9

include "macros.asm"

segment readable executable
entry _start
_start:
    push ebp
    mov ebp, esp

    mov eax, SYS_OPEN
    mov ebx, filename
    mov ecx, O_RDONLY
    mov edx, 0
    int 80h

    cmp eax, -1
    je errorHandle.fileOpen

    mov eax, SYS_READ
    mov ebx, eax
    mov ecx, file_buffer
    mov edx, MAX_FILE_LEN
    int 80h

    cmp eax, -1
    je errorHandle.fileRead

    mov ebx, token_buffer
    mov ecx, file_buffer
    mov edx, eax
    call tokenize

    mov ebx, token_buffer
.tokenPrintLoop:
    cmp eax, 0
    je .tokenPrintLoopEnd
    push eax
    push ebx

    call printToken

    pop ebx
    pop eax
    dec eax
    add ebx, TOKEN_SIZE
    jmp .tokenPrintLoop
.tokenPrintLoopEnd:

    mov eax, SYS_CLOSE
    mov ebx, eax
    int 80h

    cmp eax, -1
    je errorHandle.fileClose

    jmp exit

; printToken(token: *const Token) void
printToken:
    cmp byte [ebx], TOKEN_IDENTIFIER
    je .identifier
    cmp byte [ebx], TOKEN_PLUS
    je .plus
    cmp byte [ebx], TOKEN_MINUS
    je .minus
    cmp byte [ebx], TOKEN_STAR
    je .star
    cmp byte [ebx], TOKEN_SLASH
    je .slash

.unknown:
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, tokenMsg.unknown
    mov edx, tokenMsg.unknown.len
    int 80h
    jmp .end
.identifier:
    push ebx
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, tokenMsg.identifier
    mov edx, tokenMsg.identifier.len
    int 80h
    pop ebx

    mov eax, SYS_WRITE
    mov ecx, dword [ebx+1]
    mov edx, dword [ebx+5]
    mov ebx, 1
    int 80h

    call putN
    jmp .end
.plus:
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, tokenMsg.plus
    mov edx, tokenMsg.plus.len
    int 80h
    jmp .end
.minus:
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, tokenMsg.minus
    mov edx, tokenMsg.minus.len
    int 80h
    jmp .end
.star:
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, tokenMsg.star
    mov edx, tokenMsg.star.len
    int 80h
    jmp .end
.slash:
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, tokenMsg.slash
    mov edx, tokenMsg.slash.len
    int 80h
    jmp .end
.end:
    ret

; fmtInt(buffer: *[10]u8, x: u32) u32
fmtInt:
    push ebp
    mov ebp, esp
    push esi

    mov eax, ecx
    xor ecx, ecx
    add ebx, 10
    mov esi, 10

.loop:
    xor edx, edx
    div esi
    add edx, 48

    inc ecx
    dec ebx
    mov byte [ebx], dl

    cmp eax, 0
    je .end
    jmp .loop

.end:
    mov eax, ecx
    pop esi
    pop ebp
    ret

putN:
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 80h
    ret

errorHandle:
.fileRead:
    mov ecx, errorMsg.fileRead
    mov edx, errorMsg.fileRead.len
    jmp .print

.fileOpen:
    mov ecx, errorMsg.fileOpen
    mov edx, errorMsg.fileOpen.len
    jmp .print

.fileClose:
    mov ecx, errorMsg.fileClose
    mov edx, errorMsg.fileClose.len
    jmp .print

.token:
    mov ecx, errorMsg.token
    mov edx, errorMsg.token.len
    jmp .print

.print:
    mov eax, SYS_WRITE
    mov ebx, 1
    int 80h
    jmp exit

exit:
    pop ebp
    mov eax, SYS_EXIT
    mov ebx, 0
    int 80h

include "token.asm"

segment readable writable
filename strDef "input.con", 0
newline db 10
errorMsg:
.fileRead strDef "[error] Couldn't read file", 10
.fileOpen strDef "[error] Couldn't open file", 10
.fileClose strDef "[error] Couldn't close file", 10
.token strDef "[error] Couldn't tokenize", 10
tokenMsg:
.unknown strDef "[token] Unknown", 10
.identifier strDef "[token] Identifier:", 10
.plus strDef "[token] Plus", 10
.minus strDef "[token] Minus", 10
.star strDef "[token] Star", 10
.slash strDef "[token] Slash", 10

int_buffer rb 10
file_buffer rb MAX_FILE_LEN
token_buffer rb TOKEN_SIZE * MAX_TOKEN_COUNT
