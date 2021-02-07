format ELF executable 3
entry main
use32

segment readable executable
; Used linux syscalls (int 0x80):
; int open(const char *pathname, int flags, mode_t mode)
; ssize_t read(int fd, void *buf, size_t count)
; ssize_t write(int fd, const void *buf, size_t count)
; int close(int fd)
; int execve(const char *pathname, char *const argv[], char *const envp[])
; pid_t waitpid(pid_t pid, int *status, int options)

SYSCALL equ 0x80
SYSCALL_EXIT equ 1
SYSCALL_FORK equ 2
SYSCALL_READ equ 3
SYSCALL_WRITE equ 4
SYSCALL_OPEN equ 5
SYSCALL_CLOSE equ 6
SYSCALL_WAITPID equ 7
SYSCALL_EXECVE equ 11
SYSCALL_GETUID equ 24
SYSCALL_SYSINFO equ 116
SYSCALL_NEWUNAME equ 122

CONSOLE_DESC equ 1

osname_len equ 4
lsb_release_len equ 17
ps_len equ 8
hstnm_len equ 12
user_len equ 7
uptime_len equ 8
uname_len equ 9
art_len equ 53
artn_len equ 54
buf_size equ 127
sysuname_len equ 65

; ------ SYSCALLS ------

; exit
; exit with status 0
exit:
	mov eax, SYSCALL_EXIT
	xor ebx, ebx
	int SYSCALL
ret

; print
; ecx - str pointer
; edx - length
print:
	mov eax, SYSCALL_WRITE
	mov ebx, CONSOLE_DESC
	int SYSCALL
ret

println:
	call print
	mov ecx, ln
	mov edx, 2
	call print
ret

; fork
; ret value: eax - PID
fork:
	mov eax, SYSCALL_FORK
	int SYSCALL
ret

; waitpid
waitpid:
	mov eax, SYSCALL_WAITPID
	mov ebx, -1
	mov ecx, 0
	mov edx, 0
	int SYSCALL
ret

newuname:
	mov eax, SYSCALL_NEWUNAME
	mov ebx, uname_sysname
	xor ecx, ecx
	xor edx, edx
	int SYSCALL
ret

sysinfo:
	mov eax, SYSCALL_SYSINFO
	mov ebx, s_sysinfo
	xor ecx, ecx
	xor edx, edx
	int SYSCALL
ret	

getuid:
	mov eax, SYSCALL_GETUID
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx	
	int SYSCALL

	mov [uid], eax
ret

; ------ GET STATS ------

printOSname:
	mov eax, SYSCALL_EXECVE
	mov ebx, lsb_release
	mov ecx, lsb_args
	xor edx, edx
	int SYSCALL

	mov ecx, undefined ; On success, execve() does not return,
	mov edx, 11		   ; on error -1 is returned 
	call print
ret

printHostname:
	mov ecx, uname_nodename
	mov edx, 65
	call println
ret

printUptime:
	call uptimeToMin
	mov eax, [uptime]
	mov edi, uptimetostr

	call int2str
	mov ecx, uptimetostr
	mov edx, 255
	call print
ret

printUname:
	mov ecx, uname_release
	mov edx, 65
	call println
ret

; ------ COLORS ------

printColorTest:
	mov ecx, colortest
	mov edx, 71
	call print
ret

resetColor:
	mov eax, SYSCALL_WRITE
	mov ebx, CONSOLE_DESC
	mov ecx, rescolor
	mov edx, 7
	int SYSCALL
ret

setBlueBoldColor:
	mov eax, SYSCALL_WRITE
	mov ebx, CONSOLE_DESC
	mov ecx, bluebold
	mov edx, 8
	int SYSCALL
ret


; ------ FUNC ------

int2str:
    ; EAX = value 
    ; EDI = buffer 
    mov     ecx,10
.stack_dec: 
    xor     edx,edx 
    div     ecx 
    add     edx,'0' 
    push    edx 
    test    eax,eax 
    jz      .purge_dec 
    call    .stack_dec 
.purge_dec: 
    pop     dword[edi] 
    inc     edi 
ret  

uptimeToMin:
	mov eax, [uptime]
	cdq
	mov ebx, 60
	idiv ebx
	mov [uptime], eax
ret

resetName:
	mov edi, name
	mov ecx, 0
lp:
	mov [edi], byte 0x00
	inc edi
	inc ecx

	cmp ecx, 50
	jne lp
ret

; oh.....
getpwuid:
	mov eax, SYSCALL_OPEN
	mov ebx, passwd
	mov ecx, 0x00
	mov edx, 0x00
	int SYSCALL

	mov [fd], eax

	mov ebx, [fd]
.getname:
	call resetName
	mov edi, name
.getsym:
	mov eax, SYSCALL_READ
	mov ebx, [fd]
	mov ecx, curch
	mov edx, 1
	int SYSCALL

	cmp [curch], ':'
	je .getx	

	mov al, [curch]
	mov [edi], eax
	inc edi

	jmp .getsym
.getx:
	mov eax, SYSCALL_READ
	mov ebx, [fd]
	mov ecx, curch
	mov edx, 1
	int SYSCALL

	cmp [curch], ':'
	je .getid

	jmp .getx	
.getid:
	mov edi, curuid
.getid1:
	mov eax, SYSCALL_READ
	mov ebx, [fd]
	mov ecx, curch
	mov edx, 1
	int SYSCALL

	cmp [curch], ':'
	je .checkuid	

	mov al, [curch]
	mov [edi], eax
	inc edi

	jmp .getid1

.checkuid:
	mov eax, [uid]
	mov edi, uid_s
	call int2str

	; strcmp(uid_s, curuid)

	mov edi, uid_s
	mov esi, curuid
.checksym:
	mov eax, [edi]
	cmp eax, [esi]
	jne .readline

	inc edi
	inc esi

	cmp [edi], byte 0
	je .ifeq

	jmp .checksym

	je .close
.ifeq:
	cmp [esi], byte 0
	je .close

	jmp .getname

.readline:
	mov eax, SYSCALL_READ
	mov ebx, [fd]
	mov ecx, curch
	mov edx, 1
	int SYSCALL

	cmp eax, 0x00
	je .close

	cmp [curch], 0x0A
	je .getname
	jmp .readline

.close:
	mov eax, SYSCALL_CLOSE
	mov ebx, [fd]
	int SYSCALL
ret

; ------ MAIN ------

main:
	call newuname
	call sysinfo
	call getuid

	call fork
	test eax, eax
	jz os
	jmp main_s1
os:
	mov ecx, tux_part1
	mov edx, art_len
	call print
	; OS
	call setBlueBoldColor
	mov ecx, osname
	mov edx, osname_len
	call print
	call resetColor

	call printOSname
	call exit
main_s1:
	call waitpid

	mov ecx, tux_part2
	mov edx, art_len
	call print

	; hostname
	call setBlueBoldColor
	mov ecx, hstnm
	mov edx, hstnm_len
	call print
	call resetColor

	call printHostname

	; user
	mov ecx, tux_part3
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, user
	mov edx, user_len
	call print
	call resetColor

	call getpwuid
	mov ecx, name
	mov edx, 50
	call println

	; uptime
	mov ecx, tux_part4
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, uptime_str
	mov edx, uptime_len
	call print 
	call resetColor

	call printUptime
	mov ecx, mins
	mov edx, 6
	call println

	; kernel
	mov ecx, tux_part5
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, uname_str
	mov edx, uname_len
	call print 
	call resetColor

	call printUname

	mov ecx, tux_part6
	mov edx, art_len
	call print

	mov ecx, tux_part7
	mov edx, art_len
	call print

	call printColorTest

call exit


segment readable writeable

progname db 'afetch', 0x00

; using ANSI: \033[1;34
;
; ESC = 0x1B
; [ = 0x5B
; 1 = 0x31
; 4 = 0x34
; ; = 0x3B
; m = 0x6D

rescolor db 0x1B, 0x5B, 0x30, 0x3B, 0x30, 0x6D, 0x00
bluebold db 0x1B, 0x5B, 0x31, 0x3B, 0x33, 0x34, 0x6D, 0x00

;\033[1;41m   \033[1;0m\033[1;42m   \033[1;0m\033[1;43m   \033[1;0m\033[1;44m   \033[1;0m\033[1;45m   \033[1;0m\033[1;46m   \033[1;0m\033[1;47m   \033[0;0m
colortest db 0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x31, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x32, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x33, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x34, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x35, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x36, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x37, 0x6D, '  ',\
0x1B, 0x5B, 0x30, 0x3B, 0x30, 0x6D, 0x0A, 0x00

osname db 'OS: ', 0x00

lsb_release db '/usr/bin/lsb_release', 0x00
lsb_arg1 db '-s', 0x00
lsb_arg2 db '-d', 0x00
lsb_args dd progname, lsb_arg1, lsb_arg2, 0x00

hstnm db 'Host name: ', 0x00
user db 'User: ', 0x00
uptime_str db 'Uptime: ', 0x00
uname_str db 'Kernel: ', 0x00
mins db ' mins', 0x00
ln db 0x0A, 0x00

passwd db '/etc/passwd', 0x00
curch db 0
curuid db 20 dup(0)

fd dd 0
username db 50 dup(0)

buf db buf_size dup(0)

; struct new_utsname
uname_sysname db 65 dup(0)
uname_nodename db 65 dup(0)
uname_release db 65 dup(0)
uname_version db 65 dup(0)
uname_machine db 65 dup(0)
uname_domainname db 65 dup(0)

; struct sysinfo
s_sysinfo:
	uptime 	  dd 0
	loads 	  dd 3 dup(0)
	totalram  dd 0
	freeram   dd 0
	sharedram dd 0
	bufferram dd 0
	totalswap dd 0
	freeeswap dd 0
	proc 	  dw 0
	_f		  db 22 dup(0)

s_passwd:
	name db 50 dup(0)

name_len db 50

uid dd 0
uid_s db 20 dup(0)

uptimetostr db 255 dup(0)
undefined db 'undefined', 0x0A, 0x00

tux_part1 db '░░░░░░░░░░░░░░░░░ ', 0x00
tux_part2 db '░░░░░▀▄░░░▄▀░░░░░ ', 0x00 
tux_part3 db '░░░░▄█▀███▀█▄░░░░ ', 0x00
tux_part4 db '░░░█▀███████▀█░░░ ', 0x00
tux_part5 db '░░░█░█▀▀▀▀▀█░█░░░ ', 0x00 
tux_part6 db '░░░░░░▀▀░▀▀░░░░░░ ', 0x0A, 0x00
tux_part7 db '░░░░░░░░░░░░░░░░░ ', 0x00