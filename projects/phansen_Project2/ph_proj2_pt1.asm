	.data
promptStr:	.asciiz "Enter a string to be encoded (max 20 characters): "
promptEncStr:	.asciiz "Enter an encoded string to be decoded: "
promptKey:	.asciiz "Enter a key (int): "
rangeInfoDec:	.asciiz "Range of characters for decoded string:\n ["
rangeInfoEnc:	.asciiz "Range of characters for encoded string:\n ["
newString:	.asciiz "New String: "
strToEncode:	.space 22 #store string input to be encoded
strToDecode:	.space 22 #store string input to be decoded
charCounter:	.space 26 #space for [a,z] in memory to count characters
largestDecoded:	.byte 0 #initialize smallest to 0
smallestDecoded:	.byte 127 #initialize smallest to some large value
largestEncoded:		.byte 0
smallestEncoded:	.byte 127
errorstring: .asciiz "\nReceived empty string. Exiting...\n"
	.text
	#prompt for input
	li $v0, 4
	la $a0, promptStr
	syscall
	#store input
	li $v0, 8
	la $a0, strToEncode
	li $a1, 22
	syscall
	#prompt for key
	li $v0, 4
	la $a0, promptKey
	syscall
	#store key
	li $v0, 5
	syscall
	move $s0, $v0 #$s0 now contains key


	#here we are looking to find the character range of the string before we encode it.
	#initialize registers to contain our largest and smallest values, and store the first
	#character of the string as the min and max.
	la $t0, strToEncode
	la $t2, largestDecoded
	la $t3, smallestDecoded
	lb $t4, ($t0)
	beq $t4, '\n', error
	sb $t4, ($t2)
	sb $t4, ($t3)
findMinMaxDecoded:
	#loop through the string. if we reach the null terminator, we're done.
	#if we see a newline character, ignore it and go to the next character.
	#otherwise, check if our current character is greater than the current max,
	#and/or if it is smaller than the current min. if so, store the character
	#accordingly.
	lb $t4, ($t0) #get character
	lb $t5, ($t3) #get current min
	lb $t6, ($t2) #get current max
	beq $t4, $zero, startEncode #go encode the string if we reach the end
	beq $t4, '\n', continueLoop
	blt $t4, $t5, newMinDecoded
checkMaxDecoded:	
	bgt $t4, $t6, newMaxDecoded
continueLoop:
	addi $t0, $t0, 1
	j findMinMaxDecoded

newMinDecoded:
	sb $t4, ($t3)
	j checkMaxDecoded #if the character is min, it might also be max..check for that too.

newMaxDecoded:
	sb $t4, ($t2)
	j continueLoop


startEncode:	
	la $t0, strToEncode

	#to encode, we load the address of our string's first value, and increment the characters
	#by the key amount. If we encounter a newline, ignore it, and if we get to the null
	#terminator, we're done. We also need to check, after each addition, if we are outside
	#of the range [a,z]. If so, we implement 'wrap back'/'wrap forward'
encode:	lb $t1, ($t0)
	beq $t1, $zero, endEncode
	beq $t1, '\n', skipLineFeed
	add $t1, $t1, $s0
	bgt $t1, 'z', wrapBack
	blt $t1, 'a', wrapForward
shifted:	
	sb $t1, ($t0)
skipLineFeed:	
	addi $t0, $t0, 1
	j encode

wrapBack:
	#to wrap back, we get the difference between our character and 'z'. Then, we simply add that
	#amount to 'a'-1. E.g. z + 3 = 122 + 3 = 125. 125 - 'z' = 3. 3 + 96 = 'c', the value we want
	sub $t1, $t1, 'z'
	li $t2, 96 #'a'-1
	add $t1, $t2, $t1 #shift character.
	j shifted
wrapForward:
	#we may also need to wrap 'forward'. We subtract our character from 'a' (results in some negative
	#value), then add that amount to 'z' + 1. e.g. c - 3 = 96. 96 - 'a' = -1. -1 + 123 = 'z', the
	#character we want. 
	sub $t1, $t1, 'a'
	li $t2, 123 #'z'+1
	add $t1, $t2, $t1
	j shifted

	

endEncode:
	#find the range of the new string now,
	#in the exact same manner as before.
	la $t0, strToEncode
	la $t2, largestEncoded
	la $t3, smallestEncoded
	lb $t4, ($t0)
	sb $t4, ($t2)
	sb $t4, ($t3)
findMinMaxEncoded:
	lb $t4, ($t0) #get character
	lb $t5, ($t3) #get current min
	lb $t6, ($t2) #get current max
	beq $t4, $zero, dispInfoDec #we're done here
	beq $t4, '\n', continueLoop2
	blt $t4, $t5, newMinEncoded
checkMaxEncoded:	
	bgt $t4, $t6, newMaxEncoded
continueLoop2:	
	addi $t0, $t0, 1
	j findMinMaxEncoded

newMinEncoded:
	sb $t4, ($t3)
	j checkMaxEncoded

newMaxEncoded:
	sb $t4, ($t2)
	j continueLoop2

dispInfoDec:
	#display the ranges for the decoded and encoded strings.
	li $v0, 4
	la $a0, newString
	syscall
	la $a0, strToEncode
	syscall
	li $v0, 11
	li $a0, '\n'
	syscall
	li $v0, 4
	la $a0, rangeInfoDec
	syscall
	la $t0, smallestDecoded
	lb $a0, ($t0)
	li $v0, 11
	syscall
	li $a0, ','
	syscall
	la $t0, largestDecoded
	lb $a0, ($t0)
	syscall
	li $a0, ']'
	syscall
	li $a0, '\n'
	syscall

	li $v0, 4
	la $a0, rangeInfoEnc
	syscall
	la $t0, smallestEncoded
	lb $a0, ($t0)
	li $v0, 11
	syscall
	li $a0, ','
	syscall
	la $t0, largestEncoded
	lb $a0, ($t0)
	syscall
	li $a0, ']'
	syscall
	li $a0, '\n'
	syscall
	

startDecode:
	#just as before, prompt for a string, but this time it will
	#be decoded based on the provided key.
	li $v0, 4
	la $a0, promptEncStr
	syscall

	li $v0 8
	la $a0, strToDecode
	li $a1, 22
	syscall

	li $v0, 4
	la $a0, promptKey
	syscall

	li $v0, 5
	syscall
	move $s0, $v0 #$s0 contains the key

	#find the character range for the encoded string, just as
	#before.
	la $t0, strToDecode
	la $t2, largestEncoded
	la $t3, smallestEncoded
	lb $t4, ($t0)
	sb $t4, ($t2)
	sb $t4, ($t3)
findMinMaxEncoded2:
	lb $t4, ($t0) #get character
	lb $t5, ($t3) #get current min
	lb $t6, ($t2) #get current max
	beq $t4, $zero, decodeStr #we're done here
	beq $t4, '\n', continueLoop3
	blt $t4, $t5, newMinEncoded2
checkMaxEncoded2:	
	bgt $t4, $t6, newMaxEncoded2
continueLoop3:	
	addi $t0, $t0, 1
	j findMinMaxEncoded2

newMinEncoded2:
	sb $t4, ($t3)
	j checkMaxEncoded2

newMaxEncoded2:
	sb $t4, ($t2)
	j continueLoop3
	
decodeStr:	
	la $t0, strToDecode
continueDec:
	#wrap back/forward works the same as before,
	#but we swap the conditions since we are decoding, not encoding.
	lb $t1, ($t0)
	beq $t1, $zero, endDecode
	beq $t1, '\n', skipLineFeed2
	sub $t1, $t1, $s0
	blt $t1, 'a', wrapForward2
	bgt $t1, 'z', wrapBack2
shifted2:	
	sb $t1, ($t0)
skipLineFeed2:	
	addi $t0, $t0, 1
	j continueDec
wrapBack2:
	sub $t1, $t1, 'z'
	li $t2, 96 #'a'-1
	add $t1, $t1, $t2 #shift character.
	j shifted2
wrapForward2:
	sub $t1, $t1, 'a'
	li $t2, 123 #'z'+1
	add $t1, $t2, $t1
	j shifted2
	
endDecode:
	#get char ranges for decoded string.
	la $t0, strToDecode
	la $t2, largestDecoded
	la $t3, smallestDecoded
	lb $t4, ($t0)
	sb $t4, ($t2)
	sb $t4, ($t3)
findMinMaxDecoded2:
	lb $t4, ($t0) #get character
	lb $t5, ($t3) #get current min
	lb $t6, ($t2) #get current max
	beq $t4, $zero, dispInfoFinal #display info if we reach the end.
	beq $t4, '\n', continueLoop4
	blt $t4, $t5, newMinDecoded2
checkMaxDecoded2:	
	bgt $t4, $t6, newMaxDecoded2
continueLoop4:	
	addi $t0, $t0, 1
	j findMinMaxDecoded2

newMinDecoded2:
	sb $t4, ($t3)
	j checkMaxDecoded2

newMaxDecoded2:
	sb $t4, ($t2)
	j continueLoop4

dispInfoFinal:
	#just as before, display the new string and
	#character ranges.
	li $v0, 4
	la $a0, newString
	syscall
	la $a0, strToDecode
	syscall
	li $v0, 11
	li $a0, '\n'
	syscall
	li $v0, 4
	la $a0, rangeInfoDec
	syscall
	la $t0, smallestDecoded
	lb $a0, ($t0)
	li $v0, 11
	syscall
	li $a0, ','
	syscall
	la $t0, largestDecoded
	lb $a0, ($t0)
	syscall
	li $a0, ']'
	syscall
	li $a0, '\n'
	syscall

	li $v0, 4
	la $a0, rangeInfoEnc
	syscall
	la $t0, smallestEncoded
	lb $a0, ($t0)
	li $v0, 11
	syscall
	li $a0, ','
	syscall
	la $t0, largestEncoded
	lb $a0, ($t0)
	syscall
	li $a0, ']'
	syscall
	li $a0, '\n'
	syscall
end:
	li $v0, 10
	syscall #we're done!
	
error:	la $a0, errorstring
	li $v0, 4
	syscall
	j end
