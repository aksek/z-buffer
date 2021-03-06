	.eqv 	MAX_FSIZE 	640000 
	.data
	
fout: 	.asciiz	"zbuffer.bmp"		#input and output filename
fout2:	.asciiz "colored_triangles"	#second output filename
prompt: .asciiz	"Enter point coordinates (z coordinate should not exceed 256): \n"

	.align	2
coors: 	.space	72			#traingle vertex coordinates
pparams:.space	32			#plane parameters
edges: 	.space	48			#edge parameters, AB(a, b), BC, CA x2

skip1:	.space	2
image:	.space	MAX_FSIZE
skip2:	.space	2
colored:.space	MAX_FSIZE
width:	.word	0
height:	.word	0
padding:.word	0

	.globl	main
	.text
#--------------------------------------------------------------------------------------------------
main:

data_input:
	la	$s0, coors
	li	$t2, 6			#outer loop iterator
input_triangle:	
	li	$t3, 3			#inner loop iterator
	la	$a0, prompt
	li	$v0, 4
	syscall				#display prompt
input_coor:
	li 	$v0, 5
	syscall				#input coordinate of a triangle vertex
	sw 	$v0, ($s0)
	addi 	$s0, $s0,  4
	addi 	$t3, $t3,  -1
	bnez 	$t3, input_coor
	
	addi 	$t2, $t2, -1
	bnez 	$t2, input_triangle
#--------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------
	
preprocessing:

	li	$t8, 2			#loop iterator -- repeat for the second triangle
	la 	$s0, coors
	la 	$s1, pparams		#p1*x + p2*y + p3*z + p4 = 0
vectors:				#calculating coordinates of vectors AB (a) and AC (b)
	lw 	$t0, 0($s0)		#(sub-step for computing plane parameters)
	lw 	$t1, 12($s0)
	sub 	$t2, $t1, $t0		#t2 - ux
	lw 	$t1, 24($s0)
	sub 	$t5, $t1, $t0		#t5 - vx
	lw 	$t0, 4($s0)
	lw	$t1, 16($s0)
	sub 	$t3, $t1, $t0		#t3 - uy
	lw 	$t1, 28($s0)
	sub 	$t6, $t1, $t0		#t6 - vy
	lw 	$t0, 8($s0)
	lw	$t1, 20($s0)
	sub	$t4, $t1, $t0		#t4 - uz
	lw	$t1, 32($s0)
	sub	$t7, $t1, $t0		#t7 - vz
	
plane_parameters:
	mul 	$t0, $t3, $t7
	mul 	$t1, $t4, $t6
	sub 	$s2, $t0, $t1
	sw 	$s2, 0($s1)		#p1
	mul 	$t0, $t4, $t5
	mul 	$t1, $t2, $t7
	sub 	$s3, $t0, $t1
	sw 	$s3, 4($s1)		#p2
	mul 	$t0, $t2, $t6
	mul 	$t1, $t3, $t5
	sub 	$s4, $t0, $t1
	sw 	$s4, 8($s1)		#s3
	
	lw 	$t0, 0($s0)		#xA
	mul 	$s2, $s2, $t0		#p1*xA
	lw 	$t0, 4($s0)
	mul 	$s3, $s3, $t0		#p2*yA
	lw 	$t0, 8($s0)
	mul 	$s4, $s4, $t0		#p3*zA
	sub 	$t1, $0, $s2
	sub 	$t1, $t1, $s3
	sub 	$t1, $t1, $s4
	sw 	$t1, 12($s1)		#p4
	
	addi	$t8, $t8, -1
	addi	$s0, $s0, 36
	addi	$s1, $s1, 16
	bnez	$t8, vectors
#--------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------
	
	li	$t8, 2			#loop iterator --repeat for the second triangle
	la	$s0, coors
	la	$s1, edges

triangle_edges:
	lw 	$t1, 0($s0)		#xA
	lw	$t2, 12($s0)		#xB
	lw	$t3, 4($s0)		#yA
	lw	$t4, 16($s0)		#yB
	sub 	$t2, $t2, $t1		#xb-xa
	sub 	$t4, $t4, $t3		#yb-ya
	sll	$t4, $t4, 8		#the last 8 bits will represent the fractional part
	div 	$t4, $t2		#a, AB (a = (yb-ya)/(xb-xa))
	mflo 	$t5
	sw 	$t5, 0($s1)
	mul 	$t6, $t1, $t5		#a*x1
	sra	$t6, $t6, 8		#return to standard format
	sub 	$t6, $t3, $t6		#b, AB (b = ya - a*xa)
	sw 	$t6, 4($s1)
	addi 	$s1, $s1, 8
	
	lw	$t1, 12($s0)		#xB
	lw	$t2, 24($s0)		#xC
	lw	$t3, 16($s0)		#yB
	lw	$t4, 28($s0)		#yC
	sub 	$t2, $t2, $t1		#xc-xb
	sub 	$t4, $t4, $t3		#yc-yb
	sll	$t4, $t4, 8		#the last 8 bits will represent the fractional part
	div 	$t4, $t2		#a, BC (a = (yc-yb)/(xc-xb))
	mflo 	$t5
	sw 	$t5, 0($s1)
	mul 	$t6, $t1, $t5		#a*x1
	sra	$t6, $t6, 8		#return to standard format
	sub 	$t6, $t3, $t6		#b, BC (b = yb - a*xb)
	sw 	$t6, 4($s1)
	addi 	$s1, $s1, 8
	
	lw	$t1, 24($s0)		#xC
	lw	$t2, 0($s0)		#xA
	lw	$t3, 28($s0)		#yC
	lw	$t4, 4($s0)		#yA
	sub 	$t2, $t2, $t1		#xb-xa
	sub 	$t4, $t4, $t3		#yb-ya
	sll	$t4, $t4, 8		#the last 8 bits will represent the fractional part
	div 	$t4, $t2		#a, AB (a = (yb-ya)/(xb-xa))
	mflo 	$t5
	sw 	$t5, 0($s1)
	mul 	$t6, $t1, $t5		#a*x1
	sra	$t6, $t6, 8		#return to standard format
	sub 	$t6, $t3, $t6		#b, AB (b = ya - a*xa)
	sw 	$t6, 4($s1)
	addi 	$s1, $s1, 8
	
	la	$s0, coors + 36
	la	$s1, edges + 24
	addi	$t8, $t8, -1
	bnez	$t8, triangle_edges
#--------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------

read_file:
#open file
	li	$v0, 13
	la	$a0, fout
	li	$a1, 0			#flags (0 - read file)
	li	$a2, 0			#mode is ignored
	syscall				#open
	move 	$s0, $v0		#save the file descriptor
#read file
	li	$v0, 14
	move	$a0, $s0		#file descriptor - s0
	la	$a1, image		#buffer address
	li	$a2, MAX_FSIZE		#buffer length 
	syscall				#read
#close file
	li	$v0, 16
	move	$a0, $s0		# file descriptor
	syscall				# close file
#extract header data
	la	$t0, image + 0xa	#beginning of pixel array - s1
	lw	$s1, ($t0)

	la	$t1, image + 0x16
	lw	$t2, ($t1)
	sw	$t2, height
	
	la	$t1, image + 0x12
	lw	$t2, ($t1)
	sw	$t2, width
	
	andi	$t2, $t2, 3		#remainder from dividing the width by 4
	sw	$t2, padding
#--------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------

fill_in:
	la	$t0, padding
	lw	$s7, ($t0)
	
	la	$t0, width
	lw	$t8, ($t0)
	
	la	$t0, height
	lw	$t9, ($t0)
	
	la	$t4, edges
	la	$t5, coors
	la 	$s0, pparams
	
	
clear_bitmap:
	la	$t1, image		#beginning of pixel data
	lw	$t2, 0xa($t1)
	add	$t1, $t1, $t2
	
	la	$t3, colored
	add	$t3, $t3, $t2
	
	li	$s5, 0			#row iterator, y
outer_loop:	
	li	$s6, 0			#column iterator, x
inner_loop:
	li	$t2, 0xff
	sb	$t2, 0($t1)
	sb	$t2, 1($t1)
	sb	$t2, 2($t1)
	
	sb	$t2, 0($t3)
	sb	$t2, 1($t3)
	sb	$t2, 2($t3)
	
	addi	$t1, $t1, 3		#address++
	addi	$t3, $t3, 3
	addi	$s6, $s6, 1		#inner iterator ++
	blt	$s6, $t8, inner_loop
	
	add	$t1, $t1, $s7		#add padding
	addi	$s5, $s5, 1		#outer iterator ++
	blt	$s5, $t9, outer_loop
	
	#-------------------------------------------------------------------
	
	li	$a3, 2
triangle_loop:	
	
	lw	$s1, 0($s0)		#p1
	lw	$s2, 4($s0)		#p2
	lw	$s3, 8($s0)		#p3
	lw	$s4, 12($s0)		#p4
	
	la	$t1, image		#beginning of pixel data
	lw	$t2, 0xa($t1)
	add	$t1, $t1, $t2
	
	la	$ra, colored		#jal instruction is not used in the program, $ra can be used
	add	$ra, $ra, $t2
	
	li	$s5, 0			#row iterator, y
row_loop:	
	li	$s6, 0			#column iterator, x
	mul	$t2, $s2, $s5		#p2 * y
	add	$t2, $t2, $s4		#p2*y + p4
	div	$t2, $s3		#(p2*y + p4)/p3
	mflo	$t2			#value of z for current y and x=0
clmn_loop:
check_AB:
	lw	$t0, 0($t4)		#aAB
	lw	$t3, 24($t5)		#xC
	mul	$t3, $t0, $t3		#0x100*a*x
	sra	$t3, $t3, 8
	lw	$t6, 4($t4)		#bAB
	add	$t3, $t3, $t6		#a*x+b
	lw	$t7, 28($t5)		#yC
	blt	$t7, $t3, yC_less_than_AB
yC_greater_than_AB:
	mul	$t3, $t0, $s6		#0x100a*x
	sra	$t3, $t3, 8
	add	$t3, $t3, $t6		#a*x+b
	blt	$s5, $t3, next_pxl
	j	check_BC
yC_less_than_AB:
	mul	$t3, $t0, $s6		#0x100*a*x
	sra	$t3, $t3, 8
	add	$t3, $t3, $t6		#a*x+b
	bgt	$s5, $t3, next_pxl
	
check_BC:
	lw	$t0, 8($t4)		#aBC
	lw	$t3, 0($t5)		#xA
	mul	$t3, $t0, $t3		#0x100*a*x
	sra	$t3, $t3, 8
	lw	$t6, 12($t4)		#bBC
	add	$t3, $t3, $t6		#a*x+b
	lw	$t7, 4($t5)		#yA
	blt	$t7, $t3, yA_less_than_BC
yA_greater_than_BC:
	mul	$t3, $t0, $s6		#0x100*a*x
	sra	$t3, $t3, 8
	add	$t3, $t3, $t6		#a*x+b
	blt	$s5, $t3, next_pxl
	j	check_CA
yA_less_than_BC:
	mul	$t3, $t0, $s6		#0x100*a*x
	sra	$t3, $t3, 8
	add	$t3, $t3, $t6		#a*x+b
	bgt	$s5, $t3, next_pxl
	
check_CA:
	lw	$t0, 16($t4)		#aCA
	lw	$t3, 12($t5)		#xB
	mul	$t3, $t0, $t3		#0x100*a*x
	sra	$t3, $t3, 8
	lw	$t6, 20($t4)		#bCA
	add	$t3, $t3, $t6		#a*x+b
	lw	$t7, 16($t5)		#yB
	blt	$t7, $t3, yB_less_than_CA
yB_greater_than_CA:
	mul	$t3, $t0, $s6		#0x100*a*x
	sra	$t3, $t3, 8
	add	$t3, $t3, $t6		#a*x+b
	blt	$s5, $t3, next_pxl
	j	calc_and_save_pxl
yB_less_than_CA:
	mul	$t3, $t0, $s6		#0x100*a*x
	sra	$t3, $t3, 8
	add	$t3, $t3, $t6		#a*x+b
	bgt	$s5, $t3, next_pxl

calc_and_save_pxl:
	mul	$t3, $s1, $s6		#p1 * x
	div	$t3, $s3		#(p1*x)/p3
	mflo	$t3
	add	$t2, $t2, $t3
	
	#check if the new object is behind the other
	lb	$t7, ($t1)
	bgeu	$t2, $t7, sub_x

	sb	$t2, 0($t1)
	sb	$t2, 1($t1)
	sb	$t2, 2($t1)
	
	beq	$a3, 2, color_second
color_first:
	li	$t7, 0xa0
	sb	$t7, 0($ra)
	sb	$0, 1($ra)
	sb	$0, 2($ra)
	j	sub_x
color_second:
	li	$t7, 0xe0
	sb	$0, 0($ra)
	sb	$t7, 1($ra)
	sb	$0, 2($ra)
sub_x:
	sub	$t2, $t2, $t3
next_pxl:
	addi	$t1, $t1, 3		#address++
	addi	$ra, $ra, 3
	addi	$s6, $s6, 1		#inner iterator ++
	blt	$s6, $t8, clmn_loop
	
	add	$t1, $t1, $s7		#add padding
	addi	$s5, $s5, 1		#outer iterator ++
	blt	$s5, $t9, row_loop
	
	la	$t4, edges + 24		#2nd triangle's edges
	la	$t5, coors + 36		#2nd triangle's coors
	la	$s0, pparams + 16		#2nd triangle's pparams
	
	addi	$a3, $a3, -1
	bnez	$a3, triangle_loop
	
#--------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------
copy_header:
	la	$s1, image
	la	$s2, colored
	lw	$t0, 0xa($s1)
copy_loop:
	lh	$t3, ($s1)
	sh	$t3, ($s2)
	addi	$s1, $s1, 2
	addi	$s2, $s2, 2
	
	addi	$t0, $t0, -2
	bnez	$t0, copy_loop
	
save_file_1:	
#open file
	li	$v0, 13
	la	$a0, fout
	li	$a1, 1			#flags (1 - write to file)
	li	$a2, 0			#mode is ignored
	syscall				#open
	move 	$s0, $v0		#save the file descriptor
#write to file
	li	$v0, 15
	move	$a0, $s0		#file descriptor
	la	$a1, image		#buffer address
	li	$a2, MAX_FSIZE		#buffer length 
	syscall				#read
#close file
	li	$v0, 16
	move	$a0, $s0		# file descriptor
	syscall				# close file
	
save_file_2:	
#open file
	li	$v0, 13
	la	$a0, fout2
	li	$a1, 1			#flags (1 - write to file)
	li	$a2, 0			#mode is ignored
	syscall				#open
	move 	$s0, $v0		#save the file descriptor
#write to file
	li	$v0, 15
	move	$a0, $s0		#file descriptor
	la	$a1, colored		#buffer address
	li	$a2, MAX_FSIZE		#buffer length 
	syscall				#read
#close file
	li	$v0, 16
	move	$a0, $s0		# file descriptor
	syscall				# close file
	
exit:
	li	$v0, 10
	syscall
#--------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------
