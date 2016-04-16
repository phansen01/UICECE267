	.data
dbMaxSize:	.word -1 #user defined DB size
dbCurrSize:	.word 0 #stores current db size for utility in sorting function
list1:		.word -1:512 #256 account nodes with 256 pointers (max)
list1head:	.word 0 #store the head of the list
listRA_temp:	.word 0 #utility -- temp return address for nested calls
insertionT1Temp:	.word 0 #temp storage
nodeStack:	.word -1:256 #buffer of equal size to the max number of accounts -- stores empty addresses for
			     #potential nodes
nodeStackEnd:	.word 0 #points to the end of the node stack (used for sorting)
nodeStackPtr:	.word 0 #stack pointer for operations on the node stack
sortedAccs:	.word 0:256 #max size
sortedAccsEnd:	.word 0 #another utility for sorting
LRUDisplayBuffer: .word 0:256 #buffer used to display LRU in the correct order
LRUDisplayBufferEnd: .word 0
sortRA_temp:	.word 0 
sortS0_temp:	.word 0
sortS1_temp:	.word 0 
dbSizePrompt: .asciiz "\nEnter the max DB size (no greater than 256): "
dbAccPrompt: .asciiz "\nEnter account for insertion/lookup/delete: "
emptyListStr: .asciiz "\nError: empty list"
nodeNotFoundStr: .asciiz "\nError: node not found to delete"
foundAccStr: .asciiz "\nFound account (LRU modified)"
accInsertedStr: .asciiz "\nInserted account."
replacedLRUStr: .asciiz "\nInserted and replaced LRU"
sortedAccsStr: .asciiz "\nAccounts (min to max): \n"
LRUStr: .asciiz "\nMost to least recently used: \n"
delNodeStr: .asciiz "\nAccount deleted."

	.text	
Main:
	la $a0, dbSizePrompt
	li $v0, 4
	syscall
	li $v0, 5
	syscall #get db size from user
	sw $v0, dbMaxSize #store in memory.
	
	jal populateStack #populate stack of empty nodes based on db size.
	
dbPromptLoop:
	la $a0, dbAccPrompt
	li $v0, 4
	syscall
	li $v0, 5
	syscall #get account to insert/delete/lookup
	
	bgt $v0, $zero, accInsertLookup
	beq $v0, $zero, displayAccs
	blt $v0, $zero, deleteAcc
	
accInsertLookup:
	lw $t0, list1head
	move $t1, $v0
	jal listInsertion
	j dbPromptLoop
	
deleteAcc:
	lw $t0, list1head
	abs $t1, $v0 #just take the positive version of v0 for account lookup.
	jal listDeletion
	j dbPromptLoop
	
displayAccs:
	lw $t0, list1head
	jal sortAccounts #sort the accounts and reverse the LRU structure before display
	la $a0, sortedAccsStr
	li $v0, 4
	syscall
	
	la $t0, sortedAccs #sourted acc list pointer
	lw $t1, dbCurrSize #get current DB size after sorting
	li $t2, 1 #counter
displayLoop1:
	bge $t2, $t1, dispLRU
	lw $a0, ($t0)
	li $v0, 1
	syscall
	li $a0, ','
	li $v0, 11
	syscall
	addi $t2, $t2, 1
	addi $t0, $t0, 4
	j displayLoop1
dispLRU:
	la $a0, LRUStr
	li $v0, 4
	syscall
	la $t0, LRUDisplayBuffer
	li $t2, 1 #counter
displayLoop2:	
	bge $t2, $t1, dbPromptLoop
	lw $a0, ($t0)
	li $v0, 1
	syscall
	li $a0, ','
	li $v0, 11
	syscall
	addi $t2, $t2, 1
	addi $t0, $t0, 4
	j displayLoop2

swap:
	#expects the two adresses of values to swap in s0 and s1
	lw $t0, ($s0)
	lw $t1, ($s1)
	sw $t1, ($s0)
	sw $t0, ($s1)
	jr $ra

findMin:
	#expects s0 = array beginning index, s1 = array end
	#returns min address in s2.

	move $s2, $s0
	lw $t2, ($s0)
minLoop:
	lw $t0, ($s0)
	bge $t0, $t2, minSkip
	move $t2, $t0 #new min
	move $s2, $s0 #new min address
minSkip:
	addi $s0, $s0, 4
	ble $s0, $s1, minLoop #loop while we havent reached the end.
	jr $ra
	
sortAccounts:
	###Assumes list head in t0###
	###basic selection sort###

	#first check if the list is empty. we can do this by checking if the
	#node stack pointer points 4 bytes behind the nodeStackEnd address.
	#i.e. the node stack is full
	lw $t3, nodeStackPtr
	lw $t4, nodeStackEnd
	addi $t3, $t3, 4
	beq $t3, $t4, sortEmptyList #the list is empty (the node stack is full)!
	
	

	#list is not empty -- business as usual. 
	la $t2, sortedAccs
	li $s1, 1 #store database size
sortCopyLoop: #copy nodes to buffer	
	beq $t0, $zero, beginSort
	lw $t3, 4($t0) # t3 = head.next

	
sortTrav: 
	lw $s0, ($t0) #s0 = head.value
	sw $s0, ($t2) #store account in buffer
	move $t0, $t3 #head = head.next
	#lw $t3, 4($t0) #grab the next pointer of head
	addi $t2, $t2, 4 #increment array pointer
	addi $s1, $s1, 1
	j sortCopyLoop

beginSort:
	sw $s1, dbCurrSize
	#before we begin sort, we will copy the nodes of the linked list backward
	#into a different buffer. This is to save us from having to copy all of the nodes again
	#when the user asks to display the LRU and accounts from min to max.
	move $t3, $t2
	subi $t3, $t3, 4
	la $t6, sortedAccs
	la $t4, LRUDisplayBuffer
LRUBufferLoop:
	blt $t3, $t6, sortAccs

	lw $t5, ($t3) 
	sw $t5, ($t4)#copy the values over
	addi $t4, $t4, 4 #move pointers
	subi $t3, $t3, 4
	j LRUBufferLoop
	
sortAccs:
	#selection sort -- all node values are copied to the buffer at this point
	la $s0, sortedAccs #s0 points to the beginning of the array
	subi $t2, $t2, 4
	sw $t2, sortedAccsEnd #t2 points to the end of the account array
	move $s1, $t2
	sw $ra, sortRA_temp #backup RA until we're done sorting

sortLoop:
	beq $s0, $s1, doneSorting #we've finished our selection sort

	sw $s0, sortS0_temp #backup
	sw $s1, sortS1_temp
	jal findMin #min will be in s2

	lw $s0, sortS0_temp #restore s0
	move $s1, $s2 
	jal swap

	lw $s0, sortS0_temp #restore s0 and s1
	lw $s1, sortS1_temp
	addi $s0, $s0, 4 #increment array index pointer
	j sortLoop
	
doneSorting:
	lw $ra, sortRA_temp #restore ra and return
	jr $ra
sortEmptyList:
	#nothing to do -- probably want to display an error
	la $a0, emptyListStr
	li $v0, 4
	syscall
	sw $zero, dbCurrSize
	jr $ra
	
populateStack:
	### populate the stack with addresses of valid node locations. ###
	la $t0, nodeStack
	la $t1, list1
	li $t2, 1
	add $t3, $t0, -4 #stack pointer starts 'behind' the stack -- we will
	#increment it by one word before pushing first element.
	lw $t4, dbMaxSize #get the max size of the DB

stackLoop:
	bgt $t2, $t4, stackFull #replace 5 with n 
	addi $t3, $t3, 4 #increment stack pointer
	sw $t1, ($t3) #push to stack
	addi $t1, $t1, 8 #increment list address pointer
	addi $t2, $t2, 1
	j stackLoop
stackFull:
	#we're done, return.
	sw $t3, nodeStackPtr
	addi $t3, $t3, 4
	sw $t3, nodeStackEnd
	jr $ra

listDeletion:
	########################### linked list search/deletion ######################################
	#takes two parameters, the target value, expected to be in $t1, and the head, expected in $t0#
	#if we find the value, we modify the LRU structure by deleting the node and re-inserting it.##
	#if we do not find the node, we either insert it at the tail or replace the LRU (head)########
	##############################################################################################
	
	li $t4, 0 #assume length == 0
	beq $t0, $zero, emptyListDel #trivial case -- 'empty' list
	li $t4, 1 #turns out it is at least 1
	
deletionLoop:	
	beq $t0, $zero, delNodeNotFound #while head != null
	lw $t3, 4($t0) # t3 = head.next

delTrav:
	lw $s0, ($t0) #s0 = head.value
	beq $s0, $t1, delTarget
	move $t5, $t0 #store the head before traversing further
	move $t0, $t3 #head = head.next
	addi $t4, $t4, 1 #length += 1
	j deletionLoop

delTarget: #3 cases -- we are deleting the head, tail, or something in the middle
	#if head, simply need to update head pointer.
	#if tail, need to change the pointer of the *previous* node to null
	#if in the middle, simply need to copy the value and pointer of the next node
	
	#at the start of this label, $t5 contains the previous node's address.
	
	lw $t2, list1head
	beq $t0, $t2, delHead #target is the head
	lw $t2, 4($t0) #t2 = node.next
	beq $t2, $zero, delTail #the target is the tail
	
	#the node is in the middle if we get here
	
	#the node we will 'skip' over (the node to be deleted) will be empty.
	#push its address to the stack
	lw $t3, nodeStackPtr
	addi $t3, $t3, 4
	sw $t3, nodeStackPtr
	lw $t6, 4($t5)
	sw $t6, ($t3)
	
	lw $t3, 4($t0) #t3 = node.next
	#lw $t6, 4($t3) #t6 = node.next.next
	sw $t3, 4($t5) #previous_node.next = node.next
	
	la $a0, delNodeStr
	li $v0, 4
	syscall
	jr $ra
	
delTail:
	#set next pointer of previous node to null, push tail's address to the stack of empty
	#addresses.
	sw $zero, 4($t5) #previous.next = null
	lw $t3, nodeStackPtr
	addi $t3, $t3, 4
	sw $t3, nodeStackPtr
	sw $t0, ($t3)
	
	#lw $t6, 4($t5)
	#sw $t6, ($t3)
	la $a0, delNodeStr
	li $v0, 4
	syscall
	jr $ra
	

delHead:	
	#store head.next as new head. check if head.next == null!!
	#also, push head's address to the stack of empty addresses.

	#push the address of head to the stack of empty
	#addresses
	lw $t3, nodeStackPtr
	addi $t3, $t3, 4
	sw $t3, nodeStackPtr
	lw $t5, list1head
	sw $t5, ($t3)

	#head = head.next
	lw $t3, 4($t0) #t3 = head.next
	la $t5, list1head
	sw $t3, ($t5)
	
	la $a0, delNodeStr
	li $v0, 4
	syscall
	jr $ra
emptyListDel:
	### print some message ###
	la $a0, emptyListStr
	li $v0, 4
	syscall
	jr $ra
delNodeNotFound:
	### print some message ###
	la $a0, nodeNotFoundStr
	li $v0, 4
	syscall
	jr $ra
listInsertion:
	lw $t6, dbMaxSize #store max DB size in t6
	li $t4, 0 #assume length == 0
	beq $t0, 0, createList #trivial case -- 'empty' list when head == null. Create the list.
	li $t4, 1 #it turns out length is at least 1

	lw $t3, 4($t0) # t3 = head.next

	#here we basically steal the traversal function with some slight modifications
insertionLoop:
	beq $t4, $t6, replaceLRU 
	bne $t3, $zero, insTrav #while head.next != null
	#we didnt find the node -- insert it
	j addFromStack

insTrav:

	lw $s0, ($t0) #s0 = head.value
	beq $s0, $t1, foundTarget

	move $t0, $t3 #head = head.next
	lw $t3, 4($t0) #grab the next pointer of head
	addi $t4, $t4, 1 #length += 1
	j insertionLoop

insertAtAddr:
	sw $t1, ($t6)#node.value = target
	subi $t5, $t5, 4 #decrement stack pointer.
	sw $zero, 4($t6) #node.next = NULL
	sw $t5, nodeStackPtr
	la $a0, accInsertedStr
	li $v0, 4
	syscall
	jr $ra #return
addFromStack:
	lw $t5, nodeStackPtr
	lw $t6, ($t5) 
	sw $t6, 4($t0) #set previous node.next to point to our new node
	j insertAtAddr
createList:
	lw $t5, nodeStackPtr
	lw $t6, ($t5)
	sw $t6, list1head
	sw $t1, ($t6)
	subi $t5, $t5, 4
	sw $t5, nodeStackPtr
	sw $zero, 4($t6)
	la $a0, accInsertedStr
	li $v0, 4
	syscall
	jr $ra
	#sw $t1, ($t0) #(head.value = target)
	#sw $zero, 4($t0) #head.next = NULL
	#jr $ra

foundTarget:
	### modify LRU structure, output confirmation message ###
	#to reorder the LRU structure, we simply delete the node and
	#re-insert it.

	#print a message here#
	la $a0, foundAccStr
	li $v0, 4
	syscall

	#set t0 = head, t1 = target in preparation for deletion call
	lw $t0, list1head
	#push $ra and t1 into memory for preservation
	sw $ra, listRA_temp
	sw $t1, insertionT1Temp
	jal listDeletion
	
	#restore ra and t1
	lw $ra, listRA_temp
	lw $t1, insertionT1Temp
	#prepare t0 and t1 for insertion, store ra again
	sw $ra, listRA_temp
	la $t0, list1head
	lw $t0, ($t0)
	jal listInsertion

	#restore ra
	lw $ra, listRA_temp
	la $a0, accInsertedStr
	li $v0, 4
	syscall
	#return
	jr $ra
replaceLRU:
	#delete the head, append the target to the tail
	
	#first delete the head
	lw $t0, list1head
	#save ra and target
	sw $ra, listRA_temp
	sw $t1, insertionT1Temp
	
	lw $t1, ($t0) 
	jal listDeletion
	
	#restore target, insert the new account at tail
	lw $t1, insertionT1Temp
	lw $t0, list1head
	jal listInsertion
	
	#restore ra, return
	la $a0, replacedLRUStr
	li $v0, 4
	syscall
	lw $ra, listRA_temp
	jr $ra
