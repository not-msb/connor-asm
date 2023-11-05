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

TOKEN_SIZE equ 1

include "macros.asm"

segment readable executable
entry _start
_start:
    mov ebx, int_buffer
    mov ecx, 1234567890
    call fmtInt

    mov edx, eax
    lea ecx, [int_buffer+10]
    sub ecx, edx

    mov eax, SYS_WRITE
    mov ebx, 1
    int 80h

    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, msg
    mov edx, msg.len
    int 80h

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

    mov edx, eax
    mov eax, SYS_WRITE
    mov ebx, 1
    mov ecx, file_buffer
    int 80h

    mov ebx, token_buffer
    mov ecx, file_buffer
    mov edx, eax
    call tokenize

    mov ebx, int_buffer
    mov ecx, eax
    call fmtInt

    mov edx, eax
    lea ecx, [int_buffer+10]
    sub ecx, edx

    mov eax, SYS_WRITE
    mov ebx, 1
    int 80h

    mov eax, SYS_CLOSE
    mov ebx, eax
    int 80h

    cmp eax, -1
    je errorHandle.fileClose

    jmp exit

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

fmtBytes:
.end:
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
    mov eax, SYS_EXIT
    mov ebx, 0
    int 80h

include "token.asm"

segment readable writable
msg strDef 10, "Hello, World!", 10
filename strDef "input.con", 0
errorMsg:
.fileRead strDef "[error] Couldn't read file", 10
.fileOpen strDef "[error] Couldn't open file", 10
.fileClose strDef "[error] Couldn't close file", 10
.token strDef "[error] Couldn't tokenize", 10

int_buffer rb 10
file_buffer rb MAX_FILE_LEN
token_buffer rb TOKEN_SIZE * MAX_TOKEN_COUNT