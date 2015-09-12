	.text

	li $v0, 5
	syscall
	beq $v0, $zero, m4 # n=0. no matrix.
	move $t0, $v0 #t0 contains user input
	
	div $s1, $t0, 2 #integer division
	addi $s1, $s1, 1 #s1 contains the 'midpoint' value ((n/2) +1)

	li $t2, 0 #counter for cols
	li $t3, 0 #counter for rows
	add $t5, $t0, 97 #max char we will print
	li $s0, -3 #number of * to print, initially -1 (0)
	
	li $v0 11
m1:	addi $s0, $s0, 4 #before we get to the middle, we want number of stars +=2, afterwards, we want -=2.
star4:
	li $t1, 97 #'a'
	add $t1, $t1, $t3 #first character of a row = 97 (a) + row number
	subi $s0, $s0, 2 #number of * -= 2
m2:	bgt $s0, 0, stars
star3:	#we go here if a star wasnt printed (dont skip the char)
	move $a0, $t1
	syscall
	addi $t1, $t1, 1
	addi $t2, $t2, 1
star2:	#we go here if a star was printed (skip the char)
	li $a0, ' '
	syscall
m5:	beq $t1, $t5, m3 #if we make it to 97 (a) + n, need to start over
	blt $t2, $t0, m2 #loop while (# of cols) < n
	li $a0, '\n' #row is over, print newline and increment row counter
	syscall
	addi $t3, $t3, 1
	li $t2, 0 #new row, need t2 (col #) = 0 again.
	blt $t3, $s1, m1 #go start a new row with more * if rows < midpoint but < n
	blt $t3, $t0, star4 #go start a new row with less stars if rows > midpoint but < n 
	j m4 #we're done if we get here

m3:	li $t1, 97
	j m5 #resume



stars:# we print stars when num of stars is positive. we know where to print them
	#by adding and subtracting (num stars / 2) to the midpoint, $s1
	div $s2, $s0, 2 #s2 = num of * divided by 2
	add $s3, $s2, $s1 #upper bound for printing *
	sub $s4, $s1, $s2 #lower bound for printing *
	add $s5, $t2, 1 #s5 contains a temp representing where a star -would- be printed.
	bge $s5, $s4, printstar #if we are between the bounds, print stars
	j star3 #if we aren't between the bounds, business as usual

printstar:	bgt $s5, $s3, star3 #if we would be printing a star outside the range, print a char instead
	addi $t1, $t1, 1 #we're going to print a star, increment col and char
	addi $t2, $t2, 1
	li $a0, '*'
	syscall
	j star2

m4: 	li $v0, 10
	syscall
	
