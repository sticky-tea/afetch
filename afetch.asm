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

printHostnameFile:
	mov eax, SYSCALL_OPEN
	mov ebx, hostname_path
	mov ecx, 0x00
	mov edx, 0x00
	int SYSCALL

	push eax
	push eax

	mov eax, SYSCALL_READ
	pop ebx
	mov ecx, buf
	mov edx, buf_size
	int SYSCALL

	mov eax, SYSCALL_CLOSE
	pop ebx
	int SYSCALL

	mov ecx, buf
	mov edx, buf_size
	call print
ret


printWhoami:
	mov eax, SYSCALL_EXECVE
	mov ebx, whoami
	mov ecx, whoami_args
	xor edx, edx
	int SYSCALL
ret

printUptime:
	mov eax, SYSCALL_EXECVE
	mov ebx, uptime
	mov ecx, uptime_args
	xor edx, edx
	int SYSCALL

	mov ecx, undefined
	mov edx, 11
	call print
ret

printUname:
	mov eax, SYSCALL_EXECVE
	mov ebx, uname
	mov ecx, uname_args
	xor edx, edx
	int SYSCALL
ret

printColorTest:
	mov ecx, colortest
	mov edx, 65
	call print
	call resetColor
ret

; ------ COLORS ------

resetColor:
	mov eax, SYSCALL_WRITE
	mov ebx, CONSOLE_DESC
	mov ecx, rescolor1
	mov edx, 7;8
	int SYSCALL
ret

setBlueBoldColor:
	mov eax, SYSCALL_WRITE
	mov ebx, CONSOLE_DESC
	mov ecx, bluebold
	mov edx, 8
	int SYSCALL
ret

main:
	call fork
	test eax, eax
	jz os ; if child
	jmp main_s
os:
	call resetColor
	mov ecx, tux_part1
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, osname
	mov edx, osname_len
	call print
	call resetColor

	call printOSname
	call exit
main_s:
	call waitpid
	call resetColor

	call fork
	test eax, eax
	jz phostname
	jmp main_s1
phostname:
	mov ecx, tux_part2
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, hstnm
	mov edx, hstnm_len
	call print
	call resetColor

	call printHostnameFile
	call exit
main_s1:
	call waitpid

	call fork
	test eax, eax
	jz puser
	jmp main_s2
puser:
	mov ecx, tux_part3
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, user
	mov edx, user_len
	call print
	call resetColor

	call printWhoami
	call exit
main_s2:
	call waitpid

	call fork
	test eax, eax
	jz puptime
	jmp main_s3
puptime:
	mov ecx, tux_part4
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, uptime_str
	mov edx, uptime_len
	call print
	call resetColor

	call printUptime
	call exit
main_s3:
	call waitpid

	call fork
	test eax, eax
	jz puname
	jmp main_s4

puname:
	mov ecx, tux_part5
	mov edx, art_len
	call print

	call setBlueBoldColor
	mov ecx, uname_str
	mov edx, uname_len
	call print
	call resetColor

	call printUname
	call exit
main_s4:
	call waitpid

	mov ecx, tux_part6
	mov edx, artn_len
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

rescolor1 db 0x1B, 0x5B, 0x30, 0x3B, 0x30, 0x6D, 0x00
rescolor db 0x1B, 0x5B, 0x31, 0x3B, 0x33, 0x37, 0x6D, 0x00
bluebold db 0x1B, 0x5B, 0x31, 0x3B, 0x33, 0x34, 0x6D, 0x00

;\033[1;41m   \033[1;0m\033[1;42m   \033[1;0m\033[1;43m   \033[1;0m\033[1;44m   \033[1;0m\033[1;45m   \033[1;0m\033[1;46m   \033[1;0m\033[1;47m   \033[0;0m
colortest db 0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x31, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x32, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x33, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x34, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x35, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x36, 0x6D, '  ',\
0x1B, 0x5B, 0x31, 0x3B, 0x34, 0x37, 0x6D, '  ', 0x0A, 0x00

osname db 'OS: ', 0x00

lsb_release db '/usr/bin/lsb_release', 0x00
lsb_arg1 db '-s', 0x00
lsb_arg2 db '-d', 0x00
lsb_args dd progname, lsb_arg1, lsb_arg2, 0x00

hstnm db 'Host name: ', 0x00
hostname_path db '/etc/hostname', 0x00

user db 'User: ', 0x00
whoami db '/usr/bin/whoami', 0x00
whoami_args dd progname, 0x00

uptime_str db 'Uptime: ', 0x00
uptime db '/bin/uptime', 0x00
uptime_arg1 db '-p', 0x00
uptime_args dd progname, uptime_arg1, 0x00

uname_str db 'Kernel: ', 0x00
uname db '/bin/uname', 0x00
uname_arg1 db '-r', 0x00
uname_args dd progname, uname_arg1, 0x00

tux_part1 db '░░░░░░░░░░░░░░░░░ ', 0x00
tux_part2 db '░░░░░▀▄░░░▄▀░░░░░ ', 0x00 
tux_part3 db '░░░░▄█▀███▀█▄░░░░ ', 0x00
tux_part4 db '░░░█▀███████▀█░░░ ', 0x00
tux_part5 db '░░░█░█▀▀▀▀▀█░█░░░ ', 0x00 
tux_part6 db '░░░░░░▀▀░▀▀░░░░░░ ', 0x0A, 0x00
tux_part7 db '░░░░░░░░░░░░░░░░░ ', 0x00

undefined db 'undefined', 0x0A, 0x00

buf db buf_size dup(0)