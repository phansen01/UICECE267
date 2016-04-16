prompt:	.asciiz "Please enter a number:"

	li $v0, 4
	la $a0, prompt
	syscall
	
	li $v0, 5
	sycall

	
