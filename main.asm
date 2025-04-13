global _start

section .data

msg_D db "Otrzymalem dhcp discover", 0xA, 0x0
len_msgD equ $-msg_D

msg_O db "Wyslalem dhcp offer", 0xA, 0x0
len_msgO equ $-msg_O

msg_R db "Otrzymalem dhcp request", 0xA, 0x0
len_msgR equ $-msg_R

msg_A db "Wyslalem dhcp ack", 0xA, 0x0
len_msgA equ $-msg_A

msg_Rel db "Otrzymalem dhcp release", 0xA, 0x0
len_msgRel equ $-msg_Rel

msg_I db "Otrzymalem dhcp inform", 0xA, 0x0
len_msgI equ $-msg_I

ip_err db "Niepoprawny zakres ip", 0xA, 0x0
len_iperr equ $-ip_err

adr:
dw 0x2
dw 0x4300
db 0xff;0x7F
db 0xff;0x00
db 0xff;0x00
db 0xff;0x1
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

pocz_adr: resd 1
konc_adr: resd 1
ilosc_ip: resd 1
nast_ip: resd 1
brama: resd 1
nieof_ip: resd 1

section .text
;rdi rsi rdx r10 r8 r9
_start:
;inicjalizacja adresow:
xor rax, rax
mov dword [nieof_ip], 0x0101A8C0
mov dword [pocz_adr], 0xC0A80164
mov dword [konc_adr], 0xC0A80167

mov eax, [pocz_adr]
mov ebx, [konc_adr]
mov dword [nast_ip], eax

sub ebx, eax
inc ebx
cmp ebx, 0
jle ilosc_ip_err
mov dword [ilosc_ip], eax
xor eax, eax
mov dword [brama], 0x0101A8C0
otwarcie_socketu:
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
cmp al, 0x1
jne main_loop

read_dhcp_type:
push rcx
mov rax, 0
mov rcx, 236
.l:
xor rax, rax
mov byte al, [recbuff+rcx]
cmp al, 0x35
je .opt53
inc rcx
cmp al, 0xff
jne .l
.opt53:
xor dl, dl
add rcx, 2
mov byte al, [recbuff+rcx]
cmp al, 0x1
je print_disc
cmp al, 0x3
je print_req
cmp al, 0x7
je print_rel

tworzenie_pakietu:
mov word [clientadr], 0x2
mov word [clientadr+2], 0x4400
mov dword [clientadr+4], 0x0;0x0100007F
mov qword [clientadr+8], 0x0 ; cos z adresem klienta inicjalizacja chyba nie wiem juz zapomnialem

xor rax, rax
mov byte [sendbuff], 0x2                        ; opcode 1,2 (req,res)
mov byte [sendbuff+1], 0x1                      ; hw type (eth 1)
mov byte [sendbuff+2], 0x6                      ; hw length (6 mac)
mov byte [sendbuff+3], 0x0                      ; hops 0
mov dword eax, [recbuff+4]
mov dword [sendbuff+4], eax                     ; transaction id
xor eax, eax
mov word [sendbuff+8], 0x0                      ; jakies sekundy
mov word [sendbuff+10], 0x0                     ; boottp flags unicast - 0
mov dword eax, [recbuff+12]
mov dword [sendbuff+12], eax                    ; adres klienta
mov dword eax, [nast_ip]
rol ax, 8
rol eax, 16
rol ax, 8
mov dword [sendbuff+16], eax                    ; nowy adres
mov dword eax, [adr+4]
mov dword [sendbuff+20], eax                    ; adres serwera
;xor eax, eax
mov dword [sendbuff+24], 0x0                    ; relay adres
mov dword eax, [recbuff+28]
mov dword [sendbuff+28], eax                    ; mac adres
xor eax, eax
mov word ax, [recbuff+32]
mov word [sendbuff+32], ax                      ; mac adres cz 2
xor ax, ax                                      ;
mov qword [sendbuff+34], 0x0                    ; padding mac
mov word [sendbuff+42], 0x0                     ; padding mac cz 2
mov dword [sendbuff+236], 0x63538263            ; ciasteczko dhcp
xor rcx, rcx
mov rcx, 240
mov word [sendbuff+rcx], 0x0135                 ; opcja 53 dlugosc 1
add rcx, 2
mov byte [sendbuff+rcx], r15b                   ; typ
inc rcx
mov word [sendbuff+rcx], 0x0401                 ; maska podsieci, dlugosc opcji
add rcx, 2
mov dword [sendbuff+rcx], 0x00ffffff            ;
add rcx, 4
cmp r15b, 0x2
je .reszta
mov word [sendbuff+rcx], 0x0433                 ; ip lease time
add rcx, 2
mov dword [sendbuff+rcx], 0x40380000            ; czas
add rcx, 4
.reszta:
mov word [sendbuff+rcx], 0x0436                 ; ip servera
add rcx, 2
mov dword eax, [nieof_ip]
mov dword [sendbuff+rcx], eax                   ;
add rcx, 4
xor rax, rax
mov byte [sendbuff+rcx], 0xFF                   ; koniec opcji,pakietu
inc rcx
mov r13, rcx
xor rcx, rcx

wysylanie:
mov rax, 44
mov rdi, [fd]
mov rsi, sendbuff
mov rdx, r13
mov r10, 0
mov r8, clientadr
mov r9, 0x10
syscall
xor r13, r13

cmp r15b, 0x5
jne finish_info

next_adr:
xor rax, rax
mov eax, [nast_ip]
cmp eax, [konc_adr]
je .r
inc eax
mov [nast_ip], eax
jmp finish_info
.r:
mov eax, [pocz_adr]
dec eax
mov [nast_ip], eax
jmp next_adr

finish_info:
cmp r15b, 0x0
je main_loop

cmp r15b, 0x2
je print_offer
cmp r15b, 0x5
je print_offer

ilosc_ip_err:
mov r12, 1
mov rax, 1
mov rdi, 1
mov rsi, ip_err
mov rdx, len_iperr
syscall

end_err:
mov rdi, r12
mov rax, 60
syscall

print_disc:
mov r15, 0x2
mov rax, 1
mov rdi, 1
mov rsi, msg_D
mov rdx, len_msgD
syscall
jmp tworzenie_pakietu

print_req:
mov r15b, 0x5
mov rax, 1
mov rdi, 1
mov rsi, msg_R
mov rdx, len_msgR
syscall
jmp tworzenie_pakietu

print_offer:
xor r15b, r15b
mov rax, 1
mov rdi, 1
mov rsi, msg_O
mov rdx, len_msgO
syscall
jmp finish_info

print_ack:
xor r15b, r15b
mov rax, 1
mov rdi, 1
mov rsi, msg_A
mov rdx, len_msgA
syscall
jmp finish_info

print_rel:
mov rax, 1
mov rdi, 1
mov rsi, msg_Rel
mov rdx, len_msgRel
syscall
jmp main_loop
