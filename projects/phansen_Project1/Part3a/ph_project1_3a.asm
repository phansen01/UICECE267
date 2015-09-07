	.text
	li $v0, 5
	syscall

	move $t0, $v0 #v0 contains user input
	add $t1, $t0, 0 #rows = n
	add $t2, $t0, $t0 #cols = 2n
	li $t3, 0 #row counter
	li $t4, 0 #col counter
	li $s0, 0 #counts number of #'s
	
m2:	li $a1, 1001 #upper bound for RNG
	li $v0, 42 
	syscall #a0 contains random int  0 - 1000
	bge $a0, 500, pound #print a # for 500-1000, space for 0-499
	li $a0, ' '
	li $v0, 11
	syscall
m1:	addi $t4, $t4, 1
	blt $t4, $t2, m2 #new col if cols < 2n
	li $a0, '\n' #row is over, print newline and increment rows
	syscall
	addi $t3, $t3, 1
	li $t4, 0
	blt $t3, $t1, m2 #start a new row if rows < n
	j end #we're done if we get here

pound:	li $a0, '#'
	li $v0, 11
	syscall
	addi $s0, $s0, 1
	j m1
	
end:	li $a0, '\n'
	li $v0, 11
	syscall
	move $a0, $s0 #print the number of #'s / spaces available
	li $v0, 1
	syscall
	li $a0, '/'
	li $v0, 11
	syscall
	li $v0, 1
	mult $t1, $t2
	mflo $a0
	syscall
	li $v0, 10
	syscall
