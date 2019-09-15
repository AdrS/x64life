# as gameoflife.s -o gameoflife.o && ld gameoflife.o -o gameoflife

.section .data
usage_str:
	.ascii "usage: gameoflife <size> <seed> <generations>\n\0"
mmap_error:
	.ascii "error: could not allocate memory\n\0"
rng_state:
 	.long 0

# TODO: pointers for cur and old grids

.section .text
.globl _start

# rdi - fd
# rsi - string
# Note: does not add newline
fprint:
	push %rsi
	push %rdi
	mov %rsi, %rdi
	call strlen
	mov %rax, %rdx
	pop %rdi
	pop %rsi
	mov $1, %rax
	syscall
	ret

# rdi - string
fatal:
	# Print message to stderr
	mov %rdi, %rsi
	mov $2, %rdi
	call fprint

	# exit(1)
	mov $60, %rax
	mov $1, %rdi
	syscall

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

# Input: rdi = pointer to grid, rsi = side length (not including border)
cleargrid:
	# r8 = num rows (including border)
	mov %rsi, %r8
	add $2, %r8
	# r9 = num cols (excluding newline)
	mov %rsi, %r9
	inc %r9

	# rcx = cur row index, rdx = cur col index
	xor %ecx, %ecx
	# for each row
L_cleargrid_row_loop:
	cmp %r8, %rcx
	jge L_cleargrid_end

	# for each column
	xor %edx, %edx
L_cleargrid_col_loop:
	cmp %r9, %rdx
	jge L_cleargrid_col_end
	# Make cell empty
	movb $0x20, (%rdi)
	inc %rdi
	inc %rdx
	jmp L_cleargrid_col_loop
L_cleargrid_col_end:
	# Add newline
	movb $0xa, (%rdi)
	inc %rdi

	inc %rcx
	jmp L_cleargrid_row_loop
L_cleargrid_end:

	# Add null terminator
	movb $0, (%rdi)
	ret

# Input: rdi = side length of grid
# Ouput: rax = pointer to allocated grid
# Use spaces for top, bottom, and left border. Use newline for right border. Null terminated
newgrid:
	push %rdi        # save side length of grid

	# r11 = total size of grid (and border)
	mov %rdi, %r11
	# add space for border
	add $2, %r11
	imul %r11, %r11
	# space for null terminator
	inc %r11
	
	# mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0)
	# see: https://code.woboq.org/userspace/glibc/sysdeps/unix/sysv/linux/bits/mman-linux.h.html
	# for definitions of constants
	mov $9, %rax      # syscall number
	xor %edi, %edi    # addr
	mov %r11, %rsi    # len - does not need to be multiple of page size
	shl $1, %rsi      # (we need two grids, so double the length)
	movl $3, %edx     # protection
	movl $0x22, %r10d # flags
	xor %r8d, %r8d    # fd
	xor %r9d, %r9d    # offset
	syscall

	# Check that allocation succeed
	cmp $0, %rax
	jge L_newgrid_alloc_succeeded
	mov $mmap_error, %rdi
	call fatal

L_newgrid_alloc_succeeded:
	mov %rax, %rdi
	pop %rsi   # restore side length of grid
	push %rax  # save grid pointer
	push %rsi  # save side length
	call cleargrid

	pop %rsi # restore side length of grid
	inc %rsi

	# rdi = current cell in grid
	mov %rax, %rdi
	# skip the border
	add %rsi, %rdi
	inc %rdi

	# rcx = cur row index, rdx = cur col index
	mov $1, %rcx

	# for each row
L_init_row_loop:
	cmp %rsi, %rcx
	jge L_init_end

	# skip border
	inc %rdi

	# for each column
	mov $1, %rdx
L_init_col_loop:
	cmp %rsi, %rdx
	jge L_init_col_end

	# Randomly initialize cell
	call rand
	shr $29, %rax

	# # Compute rax mod 5
	# xor %edx, %edx
	# mov $5, %rbx
	# div %rbx

	cmp $0, %rax
	jne L_init_no_life
	movb $0x41, (%rdi)
L_init_no_life:
	inc %rdi

	inc %rdx
	jmp L_init_col_loop
L_init_col_end:
	# Skip over border
	inc %rdi

	inc %rcx
	jmp L_init_row_loop
L_init_end:
	pop %rax # restore grid pointer
	ret

usage:
	mov $usage_str, %rdi
	call fatal

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
	# Check argc = 4
	cmpq $4, (%rsp)
	jz L_main_parse_args
	call usage

L_main_parse_args:
	# Grid size
	mov 0x10(%rsp), %rdi
	call atoi
	# TODO: Check that grid size > 0
	mov %rax, %r12 # Calle save

	# Seed
	mov 0x18(%rsp), %rdi
	call atoi
	mov %rax, %rdi
	call srand

	# Num generations
	mov 0x20(%rsp), %rdi
	call atoi
	mov %rax, %r13 # Calle save

	# Make new grid
	mov %r12, %rdi
	call newgrid
	push %rax       #save pointer to grid

	# Print grid
	mov $0, %rdi
	mov %rax, %rsi
	call fprint

	# exit(0)
	mov $60, %rax
	xor %edi, %edi
	syscall
