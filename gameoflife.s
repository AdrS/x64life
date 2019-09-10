# as gameoflife.s -o gameoflife.o && ld gameoflife.o -o gameoflife

.section .data
usage_str:
	.ascii "usage: gameoflife <size> <generations>\n"
usage_str_end:
	.set usage_str_len, usage_str_end - usage_str
rng_state:
 	.long 0

.section .text
.globl _start

# Copied from: https://sourceware.org/git/?p=glibc.git;a=blob;f=stdlib/random_r.c;hb=glibc-2.26#l362
srand:
	mov %edi, rng_state
	ret

rand:
	mov rng_state, %eax
	imul $1103515245, %eax
	add $12345, %eax
	and $0x7fffffff, %eax
	mov %eax, rng_state
	ret

# Each row is a c-string ending with "\n" with space for empty, '.' for occupied.
newgrid:
	# TODO:
	ret

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
	# TODO: Check that grid size > 0
	mov %rax, %r12 # Calle save

	# Num generations
	mov 0x18(%rsp), %rdi
	call atoi
	mov %rax, %r13 # Calle save

	# Seed RNG
	mov %r12, %rdi
	call srand

	# For testing RNG code
	xor %r14, %r14
L_rng_loop_start:
	cmp %r13, %r14
	jg L_rng_loop_end
	call rand
	inc %r14
	jmp L_rng_loop_start
L_rng_loop_end:

	mov %rax, %rdi
	mov $60, %rax
	syscall
