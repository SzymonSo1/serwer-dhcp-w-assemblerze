global _start

section .data

msg_D db "Otrzymalem dhcp discover", 0x0
msg_O db "Wyslalem dhcp offer", 0x0
msg_R db "Otrzymalem dhcp request", 0x0
msg_A db "Otrzymalem dhcp ack", 0x0

len_msgD equ $-msg_D
len_msgO equ $-msg_O
len_msgR equ $-msg_R
len_msgA equ $-msg_A

srv_adr:
adr:
dw 0x2
dw 0x4300
db 0x7F
db 0x00
db 0x00
db 0x1
dq 0x0

section .bss

fd: resd 1 
recbuff: resq 256

section .text
;rdi rsi rdx r10 r8 r9
_start:
;socket:
mov rax, 41
mov rdi, 2
mov rsi, 2
mov rdx, 0
syscall

mov [fd], ax;zapisanie file descryptor

;bind:
mov rax, 49
mov rdi, [fd]
mov rsi, adr
mov rdx, 0x10
syscall

;error handle
mov r12, 49
cmp rax, 0
jne end_err
xor r12, r12
;

main_loop:
mov rax, 0
mov rdi, [fd]
mov rsi, recbuff
mov rdx, 1500
syscall

;mov r12, [fd]
;mov r13, [recbuff]
call read_buf
jmp main_loop

end_err:
mov rdi, r12
mov rax, 60
syscall

read_buf:
push rcx
mov rax, 0
mov rcx, 0
.l:
mov rax, [recbuff+rcx]
cmp rax,0
je .opt53
inc rcx
cmp rax, 0xff
jne .l
.ret:
ret
.opt53:
add rcx, 2
mov rax, [recbuff+rcx]
cmp rax, 3
call print_req
mov rax, 0xff
jmp .ret

print_disc:
push rax
mov rax, 1
mov rdi, 1
mov rsi, msg_D 
mov rdx, len_msgD
pop rax
syscall
ret

print_req:
push rax
mov rax,1
mov rdi, 1
mov rsi, msg_R
mov rdx, len_msgR
syscall
pop rax
ret
