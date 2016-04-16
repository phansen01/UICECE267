	.data
promptStr:	.asciiz "\nEnter a string (max 20 characters): "
promptKey:	.asciiz "Enter a key (int): "
rangeInfoDec:	.asciiz "\nRange of characters for decoded string:\n ["
rangeInfoEnc:	.asciiz "\nRange of characters for encoded string:\n ["
newString:	.asciiz "New String: "
commonCharMsgDec:	.asciiz "The most common character for the decoded string: "
commonCharMsgEnc:	.asciiz "The most common character for the encoded string: "
commonFreqMsg:	.asciiz "\nIts frequency: "
strToEncode:	.space 22 #store string input to be encoded
strToDecode:	.space 22 #store string input to be decoded
charCounter:	.byte 0:26 #space for [a,z] in memory to count characters
charCounter2:	.byte 0:26 
charCounter3:	.byte 0:26
charCounter4:	.byte 0:26
mostCommonDecoded:	.byte 0:1 #space for most common character
mostCommonEncoded:	.byte 0:1 #see above
commonDecodedFreq:	.byte 0:1
commonEncodedFreq:	.byte 0:1
largestDecoded:	.byte 1
smallestDecoded:	.byte 127 #initialize smallest to some large value
largestEncoded:		.byte 1
smallestEncoded:	.byte 127
errorstring:	.asciiz "\nReceived empty string. Exiting...\n"
	.text

main:
	#prompt for string and key, store in memory.
	la $t3, strToEncode
	jal promptFunct

	#check if the string is empty, otherwise find
	#the range of characters.
	la $t0, strToEncode
	lb $t1, ($t0)
	beq $t1, '\n', error
	la $t2, largestDecoded
	la $t3, smallestDecoded
	la $s5, charCounter
	jal findMinMax

	#loop through the frequencies to find the
	#most common character.
	la $t0, charCounter
	li $t2, 0 #frequency
	li $t3, 0 #counter
	li $t4, 0 #character (index)
	jal mostCommonChar

	#store the above result
	la $t0, mostCommonDecoded
	la $t1, commonDecodedFreq
	jal storeCommonChar

	#encode the string
	la $t0, strToEncode
	li $s4, 0 #counter
	jal encode

	#find the range of the new string
	la $t0, strToEncode
	la $t2, largestEncoded
	la $t3, smallestEncoded
	la $s5, charCounter2
	jal findMinMax

	#find the most common characters in the new string
	la $t0, charCounter2
	li $t2, 0
	li $t3, 0
	li $t4, 0
	jal mostCommonChar

	#again, store them
	la $t0, mostCommonEncoded
	la $t1, commonEncodedFreq
	jal storeCommonChar

	#display information about the results.
	la $s1, strToEncode
	la $s2, smallestDecoded
	la $s3, largestDecoded
	la $s4, smallestEncoded
	la $s5, largestEncoded
	jal dispInfo

	#repeat all of the above functions, but for an encoded
	#string to be decoded
	la $t3, strToDecode
	jal promptFunct

	la $t0, strToDecode
	la $t2, largestEncoded
	la $t3, smallestEncoded
	la $s5, charCounter3
	lb $s7, ($t0)
	sb $s7, ($t2)
	sb $s7, ($t3)
	jal findMinMax

	la $t0, charCounter3
	li $t2, 0
	li $t3, 0
	li $t4, 0
	jal mostCommonChar

	la $t0, mostCommonEncoded
	la $t1, commonEncodedFreq
	jal storeCommonChar

	la $t0, strToDecode
	li $s4, 0
	jal decode

	la $t0, strToDecode
	la $t2, largestDecoded
	la $t3, smallestDecoded
	la $s5, charCounter4
	lb $s7, ($t0)
	sb $s7, ($t2)
	sb $s7, ($t3)
	jal findMinMax

	la $t0, charCounter4
	li $t2, 0
	li $t3, 0
	li $t4, 0
	jal mostCommonChar

	la $t0, mostCommonDecoded
	la $t1, commonDecodedFreq
	jal storeCommonChar

	la $s1, strToDecode
	la $s2, smallestDecoded
	la $s3, largestDecoded
	la $s4, smallestEncoded
	la $s5, largestEncoded
	jal dispInfo
	j end
decode:
	#wrap back/forward works the same as for encoding,
	#but we swap the conditions since we are decoding, not encoding.
	#see the 'encoding' function for full details.
	lb $t1, ($t0)
	beq $t1, $zero, endDecode
	beq $t1, '\n', skipLineFeed2
	sub $t1, $t1, $s0 #subtract key
	sub $t1, $t1, $s4 #subtract index
	blt $t1, 'a', wrapForward2
	bgt $t1, 'z', wrapBack2
shifted2:	
	sb $t1, ($t0)
skipLineFeed2:	
	addi $t0, $t0, 1
	addi $s4, $s4, 1
	j decode
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
	jr $ra
	
dispInfo:	
	#display the ranges for the decoded and encoded strings.
	li $v0, 4
	la $a0, newString
	syscall
	move $a0, $s1
	syscall
	li $v0, 11
	li $a0, '\n'
	syscall
	li $v0, 4
	la $a0, rangeInfoDec
	syscall
	move $t0, $s2
	lb $a0, ($t0)
	li $v0, 11
	syscall
	li $a0, ','
	syscall
	move $t0, $s3
	lb $a0, ($t0)
	syscall
	li $a0, ']'
	syscall
	li $a0, '\n'
	syscall
	li $v0, 4
	la $a0, commonCharMsgDec
	syscall
	li $v0, 11
	la $t0, mostCommonDecoded
	lb $a0, ($t0)
	syscall
	la $a0, commonFreqMsg
	li $v0, 4
	syscall
	li $v0, 1
	la $t0, commonDecodedFreq
	lb $a0, ($t0)
	syscall
	

	li $v0, 4
	la $a0, rangeInfoEnc
	syscall
	move $t0, $s4
	lb $a0, ($t0)
	li $v0, 11
	syscall
	li $a0, ','
	syscall
	move $t0, $s5
	lb $a0, ($t0)
	syscall
	li $a0, ']'
	syscall
	li $a0, '\n'
	syscall
	li $v0, 4
	la $a0, commonCharMsgEnc
	syscall
	li $v0, 11
	la $t0, mostCommonEncoded
	lb $a0, ($t0)
	syscall
	la $a0, commonFreqMsg
	li $v0, 4
	syscall
	li $v0, 1
	la $t0, commonEncodedFreq
	lb $a0, ($t0)
	syscall
	jr $ra

encode:	#iterate over the string. If we reach a line feed or
	#null terminator, we're done. shift each character by
	#k plus the index of the character as specified, being
	#sure to wrap back/forward appropriately.
	lb $t1, ($t0)
	beq $t1, $zero, endEncode
	beq $t1, '\n', skipLineFeed
	add $t1, $t1, $s0 #shift by k
	add $t1, $t1, $s4 #shift by index 
	bgt $t1, 'z', wrapBack
	blt $t1, 'a', wrapForward
shifted:	
	sb $t1, ($t0)
skipLineFeed:	
	addi $t0, $t0, 1
	addi $s4, $s4, 1
	j encode
wrapBack:
	#to wrap back, we get the difference between our character and 'z'.
	#Then, we simply add that
	#amount to 'a'-1. E.g. z + 3 = 122 + 3 = 125.
	#125 - 'z' = 3. 3 + 96 = 'c', the value we want
	sub $t1, $t1, 'z'
	li $t2, 96 #'a'-1
	add $t1, $t2, $t1 #shift character.
	j shifted
wrapForward:
	#we may also need to wrap 'forward'. We subtract our character
	#from 'a' (results in some negative
	#value), then add that amount to 'z' + 1. e.g. c - 3 = 96.
	#96 - 'a' = -1. -1 + 123 = 'z', the
	#character we want. 
	sub $t1, $t1, 'a'
	li $t2, 123 #'z'+1
	add $t1, $t2, $t1
	j shifted
endEncode:
	jr $ra

storeCommonChar:	
	add $t3, $t4, 'a' #add the most common char index to 'a' to get the most
	#common character
	sb $t3, ($t0)
	sb $t2, ($t1) #store the character's frequency.
	jr $ra
	
mostCommonChar:
	#loop through our array of frequencies and simply store the
	#value and its index.
commonCharLoop:	
	lb $t1, ($t0)
	beq $t3, 26, commonCharEnd
	bgt $t1, $t2, newCommonChar
commonCharContinue:	
	addi $t3, $t3, 1
	addi $t0, $t0, 1
	j commonCharLoop

newCommonChar:
	add $t2, $t1, $zero #new max frequency
	add $t4, $t3, $zero #new max index
	j commonCharContinue

commonCharEnd:
	jr $ra

promptFunct:	
	#prompt for input
	li $v0, 4
	la $a0, promptStr
	syscall
	#store input
	li $v0, 8
	move $a0, $t3
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
checkKey:
	#if our key is bigger than the range, adjust it to behave equivalently,
	#but fall within the range.
	bgt $s0, 26, bigKey
	blt $s0, -26, smallKey
	jr $ra

bigKey:	subi $s0, $s0, 26
	j checkKey
smallKey:
	addi $s0, $s0, 26
	j checkKey

findMinMax:
	#loop through the string. if we reach the null terminator, we're done.
	#if we see a newline character, ignore it and go to the next character.
	#otherwise, check if our current character is greater than the current max,
	#and/or if it is smaller than the current min. if so, store the character
	#accordingly.
	
	move $s2, $s5 #go back to the start of the char counter
	lb $t4, ($t0) #get character
	lb $t5, ($t3) #get current min
	lb $t6, ($t2) #get current max
	beq $t4, $zero, endMinMax
	beq $t4, '\n', endMinMax
	blt $t4, $t5, newMin
checkMax:	
	bgt $t4, $t6, newMax
continueLoop:
	sub $s3, $t4, 'a' #s3 = current char - 'a'
	add $s2, $s2, $s3 #load the index corresponding to the correct
	#character (by subtracting 'a' from current character)
	lb $s3, ($s2) 
	addi $s3, $s3, 1
	sb $s3, ($s2) #increment the count of that character
	addi $t0, $t0, 1
	j findMinMax

newMin:
	sb $t4, ($t3)
	j checkMax #if the character is min, it might also be max..check for that too.

newMax:
	sb $t4, ($t2)
	j continueLoop
endMinMax:
	jr $ra
	
error:	#user entered empty string.
	la $a0, errorstring
	li $v0, 4
	syscall
	j end
end:
	li $v0, 10
	syscall
