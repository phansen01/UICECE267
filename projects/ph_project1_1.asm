	.text

	li $v0, 5
	syscall
	move $t0, $v0 #t0 contains user input
	li $t2, 0 #counter for cols
	li $t3, 0 #counter for rows
	li $t4, 97 #counter for char (on a scale of 61 to 61 + n)
	add $t5, $t4, $t0 #max char we will print
	
	li $v0 11
m1:	li $t1, 97 #'a'
	add $t1, $t1, $t3 #first character of a row = 91 (a) + row number
m2:	move $a0, $t1
	syscall
	li $a0, ' '
	syscall
	addi $t1, $t1, 1
	addi $t2, $t2, 1
m5:	beq $t1, $t5, m3 #if we make it to 91 (a) + n, need to start over
	blt $t2, $t0, m2 
	li $a0, '\n' #row is over, print newline and increment row counter
	syscall
	addi $t3, $t3, 1
	li $t2, 0 #new row, need t2 = 0 again.
	blt $t3, $t0, m1 #go start a new row if rows < n
	j m4 #we're done if we get here
	
m3:	li $t1, 97
	j m5 #resume
	#li $t4, 61

m4:	
