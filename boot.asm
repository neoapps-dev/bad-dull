[org 0x7C00]
bits 16
boot:
    jmp 0x0000:setup

setup:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov [disk], dl
    mov ah, 0
    mov al, 3
    int 0x10

main:
    call read
    jc halt
    call draw
    call tick
    inc dword [lba]
    jmp main

halt:
    hlt
    jmp halt

read:
    mov ah, 0x42
    mov dl, [disk]
    mov si, dap
    int 0x13
    ret

draw:
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov si, 0x2000
    mov cx, 25
row:
    push cx
    mov cx, 5
col:
    lodsb
    mov bl, al
    mov bp, 8
bit:
    shl bl, 1
    jc white
black:
    mov word [es:di], 0x0020
    mov word [es:di+2], 0x0020
    add di, 4
    jmp next
white:
    mov word [es:di], 0x0FDB
    mov word [es:di+2], 0x0FDB
    add di, 4
next:
    dec bp
    jnz bit
    loop col
    pop cx
    loop row
    pop es
    ret

tick:
    push es
    push ax
    push bx
    mov ax, 0x40
    mov es, ax
    mov bx, [es:0x6C]
w1:
    mov ax, [es:0x6C]
    cmp ax, bx
    je w1
    mov bx, [es:0x6C]
w2:
    mov ax, [es:0x6C]
    cmp ax, bx
    je w2
    pop bx
    pop ax
    pop es
    ret

align 4
dap:
    db 0x10
    db 0
    dw 1
    dw 0x2000
    dw 0x0000
lba:
    dq 1

disk db 0
times 510-($-$$) db 0
dw 0xAA55
