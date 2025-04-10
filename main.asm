global _start

section .data

msg_D db "Otrzymalem dhcp discover", 0xA, 0x0
len_msgD equ $-msg_D

msg_O db "Wyslalem dhcp offer", 0xA, 0x0
len_msgO equ $-msg_O

msg_R db "Otrzymalem dhcp request", 0xA, 0x0
len_msgR equ $-msg_R

msg_A db "Otrzymalem dhcp ack", 0xA, 0x0
len_msgA equ $-msg_A

nullter db 0xA, 0x0

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
sendbuff: resq 256

clientadr:
resw 1
resw 1
resd 1
resq 1

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

check_for_opcode:
mov byte al, [recbuff]
cmp rax, 0x1
jne main_loop

read_dhcp_type:
push rcx
mov rax, 0
mov rcx, 0
.l:
mov byte rax, [recbuff+rcx]
cmp rax, 0x53
je .opt53
inc rcx
cmp rax, 0xff
jne .l
.opt53:
add rcx, 2
mov byte rax, [recbuff+rcx]
cmp rax, 0x3
call print_req

mov word [clientadr], 0x2
mov word [clientadr+2], 0x4400
mov dword [clientadr+4], 0x0100007F
mov qword [clientadr+8], 0x0

tworzenie_pakietu:
xor rax, rax
mov byte [sendbuff], 0x2			; opcode 1,2 (req,res)
mov byte [sendbuff+1], 0x1			; hw type (eth 1)
mov byte [sendbuff+2], 0x6			; hw length (6 mac)
mov byte [sendbuff+3], 0x0			; hops 0
mov dword eax, [recbuff+4]
mov dword [sendbuff+4], eax			; transaction id
xor eax, eax
mov word [sendbuff+8], 0x0			; jakies sekundy
mov word [sendbuff+10], 0x0			; boottp flags unicast - 0
mov dword eax, [recbuff+12]
mov dword [sendbuff+12], eax			; adres klienta
mov dword [sendbuff+16], eax			; nowy adres
mov dword eax, [adr+4]
mov dword [sendbuff+20], eax			; adres serwera
;xor eax, eax
mov dword [sendbuff+24], 0x0			; relay adres
mov dword eax, [recbuff+28]
mov dword [sendbuff+28], eax			; mac adres
xor eax, eax
mov word ax, [recbuff+32]
mov word [sendbuff+32], ax			; mac adres cz 2
xor ax, ax
mov qword [sendbuff+34], 0x0			; padding mac
mov word [sendbuff+42], 0x0			; padding mac cz 2
mov dword [sendbuff+236], 0x63538263		; ciasteczko dhcp
mov word [sendbuff+240], 0x0135			; opcja 53 dlugosc 1
mov byte [sendbuff+242], 0x05			; 5 - dhcpack
mov word [sendbuff+243], 0x0401			; maska podsieci, dlugosc opcji
mov dword [sendbuff+245], 0x00ffffff		; 
mov word [sendbuff+249], 0x0433			; ip lease time
mov dword [sendbuff+251], 0x40380000			; czas 
mov word [sendbuff+255], 0x0436			; ip servera
mov dword eax, [adr+4]
mov dword [sendbuff+257], eax			;
xor rax, rax
mov byte [sendbuff+261], 0xFF			; koniec opcji,pakietu

wysylanie:
mov rax, 44
mov rdi, [fd]
mov rsi, sendbuff
mov rdx, 262
mov r10, 0
mov r8, clientadr
mov r9, 0x10
syscall

jmp main_loop

end_err:
mov rdi, r12
mov rax, 60
syscall

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
mov rdx, 25
syscall
pop rax
ret
