# as gameoflife.s -o gameoflife.o && ld gameoflife.o -o gameoflife

.section .data
usage_str:
	.ascii "usage: gameoflife <size> <generations>\n"
usage_str_end:
	.set usage_str_len, usage_str_end - usage_str

.section .text
.globl _start

usage:
	# Write usage message to stderr
	mov $1, %rax
	mov $1, %rdi
	mov $usage_str, %rsi
	mov $usage_str_len, %rdx
	syscall

	# exit(1)
	mov $60, %rax
	mov $1, %rdi
	syscall

strlen:
	mov %rdi, %rax
L_strlen_loop_start:
	cmpb $0, (%rax)
	jz L_strlen_end
	inc %rax
	jmp L_strlen_loop_start
L_strlen_end:
	sub %rdi, %rax
	ret

atoi:
	xor %rax, %rax
L_atoi_loop_start:
	movzx (%rdi), %r10
	# Is current byte after '9'?
	cmpb $0x39, %r10b
	jg L_atoi_end
	# Is current byte before '0'?
	cmpb $0x30, %r10b
	jl L_atoi_end
	# rax = 10*rax + cur digit
	sub $0x30, %r10
	imul $10, %rax
	add %r10, %rax
	inc %rdi
	jmp L_atoi_loop_start
L_atoi_end:
	ret

_start:
	# Check argc = 3
	cmpq $3, (%rsp)
	jz L_main_parse_args
	call usage

L_main_parse_args:
	# Grid size
	mov 0x10(%rsp), %rdi
	call atoi
	mov %rax, %r12 # Calle save

	# Num generations
	mov 0x18(%rsp), %rdi
	call atoi
	mov %rax, %r13 # Calle save

	mov %r12, %rdi
	add %r13, %rdi
	mov $60, %rax
	syscall
