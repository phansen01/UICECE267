# Part 1:

.text
li $t0, 0
m1:
li $a0, '#'
li $v0, 11
syscall
beq, $t0, 7, m2
li $a0, ' '
syscall
addi, $t0, $t0, 1
bne $t0, 7, m1

m2: #part 2

li $t1, 0
li $t2, 100
m3:
li $v0, 1
move $a0, $t2
syscall
li $a0, '\n'
li $v0, 11
syscall
addi, $t1, $t1, 1
addi, $t2, $t2, 1
bne $t1, 41, m3

m4:

#part 3: read int from user, display x ... x-5

li $t5, 0
li $v0, 5
li $t7, '\n'
syscall
move $a0, $v0
m5:
addi $t5, $t5, 1
li $v0, 1
syscall 
addi $a0, $a0, -1 #decrement a0
move $t4, $a0 #stash a0 in t4
li $a0, '\n' #linebreak
li $v0, 11
syscall
move $a0, $t4 #get a0 back
bne $t5, 6, m5

m6:

#part 4: display 3 lines of 6 *'s 

li $v0, 11
li $a0, '\n'
li $t2, 0
syscall
syscall
m7: li $t1, 0
m8:
li $a0, '*'
syscall
li $a0, ' '
syscall
addi $t1, $t1, 1
bne $t1, 6, m8
li $a0, '\n'
syscall
addi $t2, $t2, 1
bne $t2, 4, m7

