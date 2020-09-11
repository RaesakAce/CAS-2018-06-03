#Marco Casaglia 5759711 marco.casaglia@stud.unifi.it

.data
fnf:	.ascii  "The file was not found: "
file1:	.asciiz	"pendenzaIN.txt"	
file2:	.asciiz	"sterzoIN.txt"	
file3:	.asciiz	"distanzaIN.txt"
out1:	.asciiz	"correttezzaPendenzaOUT.txt"	
out2:	.asciiz	"correttezzaSterzoOUT.txt"	
out3:	.asciiz	"correttezzaDistanzaOUT.txt"
outP1:	.asciiz	"correttezzaP1.txt"	
outP2:	.asciiz	"correttezzaP2.txt"	
outP3:	.asciiz	"correttezzaP3.txt"

buffer1_in: .space 1200		#max Int32 is 10 characters long,to that I add a possible "-" and necessary " "
				#which means the maximum buffer needed is 100 times the space needed for 12 characters.
buffer2_in: .space 400		#the maximum here is a 2 digit number , plus a " " , possibly preceeded by a "-" so 100 times 4
buffer3_in: .space 400		#same as before but here is a 2 digit number, preceeded by an uppercase character, plus a " " so 100 times 4
buffer1_out: .space 200		#the outputs are the character "1" or "0" followed by a " " so 100 times 2 character for all outputs.
buffer2_out: .space 200
buffer3_out: .space 200
bufferP1_out: .space 200
bufferP2_out: .space 200
bufferP3_out: .space 200
prev_steer: .space 4
prev_obs: .space 4
obs_flag: .space 4

.text
.globl main 

main:

addi $sp, $sp, -32		
	sw $ra, 0($sp)			
	sw $s0, 4($sp)			
	sw $s1, 8($sp)
	sw $s2, 12($sp)			
	sw $s3, 16($sp)			
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)


slope_check_init:			#reads input txt's files and makes $s0 the index 
	la $a0, file1			#the slope input buffer
	la $a1, buffer1_in
	li $a2, 1200
	jal read_file
	la $s0, buffer1_in
	
steer_check_init:			#reads the second input and makes $s1 the index
	la $a0, file2
	la $a1, buffer2_in
	li $a2, 400
	jal read_file
	la $s1, buffer2_in

obs_check_init:				#same as before, for the obstacle check $s2 is the
	la $a0, file3			#index of the buffer
	la $a1, buffer3_in
	li $a2, 400
	jal read_file
	la $s2, buffer3_in

init:						#s0 serves as a counter, $s1 to $s6 are used as
	move $t0,$s0
	move $t1,$s1
	move $t2,$s2
	
	li $s0,0				#indexes for the output buffers
	la $s1,buffer1_out
	la $s2,buffer2_out
	la $s3,buffer3_out
	la $s4,bufferP1_out
	la $s5,bufferP2_out
	la $s6,bufferP3_out	

cycle_scheduler:			#this cycle makes sure that every operation gets done						
	addi $sp, $sp, -12		#at the same time (t=$s0+1)
	sw $t0, 0($sp)			#since there are many procedure calls, saving 
	sw $t1, 4($sp)			#registers in the stack is needed
	sw $t2, 8($sp)
	
	addi $sp, $sp, -12
	move $a0,$t0
	jal slope_cycle_in		#calls the slope check procedure
	sw $v0,0($sp)			#and saves the value for the correctness
	sw $v1,12($sp)			#also every time I have to modify the saved index for the buffer
	lw $a0,16($sp)
	move $a1,$s0
	jal steer_cycle_in		#calls the steer check procedure
	sw $v0,4($sp)			#and saves the value for the correctness as well
	sw $v1,16($sp)
	lw $a0,20($sp)
	jal obs_cycle_in		#same goes for the obstacle sensor check
	sw $v0,8($sp)
	sw $v1,20($sp)
	
	lw $a0, 0($sp)			#now the saved registers are needed for filling the
	lw $a1, 4($sp)			#output buffers and evaluating the correctness of
	lw $a2, 8($sp)			#system for the different politics of aggregation
	addi $sp, $sp, 12		#and loaded as arguments
					
	move $a3,$s1
					#I have 6 outputs buffers, so 
					#the stack is needed for the other arguments
	
	addi $sp, $sp, -20		
	sw $s2, 0($sp)			
	sw $s3, 4($sp)			
	sw $s4, 8($sp)
	sw $s5, 12($sp)
	sw $s6, 16($sp)
	
	jal buffer_fill			
			
	move $s1,$v0
	move $s2,$v1
			
	lw $s3, 0($sp)			
	lw $s4, 4($sp)
	lw $s5, 8($sp)
	lw $s6, 12($sp)
	
	addi $sp, $sp, 16
	
	addi $s0,$s0,1
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	li $t7,100				 #after 100 cycles, all sensors data was read
	beq $t7,$s0,write_to_txt		 #so the procedure for printing on text is called.
	j cycle_scheduler

write_to_txt:				#prints every buffer to the right output .txt file, 
	la $a0,	out1
	la $a1, buffer1_out
	jal write_file

	la $a0,	out2
	la $a1, buffer2_out
	jal write_file

	la $a0,	out3
	la $a1, buffer3_out
	jal write_file

	la $a0, outP1
	la $a1, bufferP1_out
	jal write_file

	la $a0,	outP2
	la $a1, bufferP2_out
	jal write_file

	la $a0, outP3
	la $a1, bufferP3_out
	jal write_file

	j end					#then the program gets closed

slope_cycle_in:			
	move $t0,$a0				#first step of the slope check procedure, since
	lb $t1,($t0)				#we only care about the absoulte value of the
	li $t2, 0					#sensor value, it skips '-' if it finds one.
	bne $t1, '-', slope_cycle
	addi $t0, $t0, 1

slope_cycle:					#this cycle reads the buffer one byte by one
	lb $t1,($t0)				#until it finds a space or the end of the string
	beq $t1,' ',slope_check		
	beq $t1,$zero,slope_check
	addi $t1, $t1, -48			#and translates it from ASCII value to an integer
	mul $t2, $t2, 10			#considering it's supposed to read a base 10 number
	add $t2, $t2, $t1			#the final value will end up in $t2
	addi $t0, $t0, 1
	j slope_cycle
	
slope_check:					#now that we have an integer in $t2, we check
	li $v0,1					#if the value of the integer is less than 60,
	li $t3,60					#if it is, the sensor works correctly so C(t)=$v0=1
	blt $t2,$t3,slope_end
	li $v0,0					#otherwise $v0=0

slope_end:						#before returning to the main cycle, it skips the
	addi $t0, $t0, 1			#' ' that interrupted the cycle.
	move $v1,$t0
	jr $ra

steer_cycle_in:	
	move $t0,$a0				#sets up the registers for the conversion and loads
	li $t2, 0					#the value of the sensor at t-1
	la $t3, prev_steer
	move $t7, $a1
	beq $t7,$zero,steer_cycle	#if it's the very first cycle, there will not be any
	lw $t5,($t3)				# value in $t3
		
steer_cycle:					#this cycle is exactly the same as the slope one,
	lb $t1,($t0)				#converts the characters from ASCII to integers assuming
	beq $t1,' ',steer_check		#a decimal value, values separated with spaces, and null
	beq $t1,$zero,steer_check   #terminated string
	addi $t1, $t1, -48
	mul $t2, $t2, 10
	add $t2, $t2, $t1
	addi $t0, $t0, 1
	j steer_cycle

steer_check:					#checks the integer value obtained, finds the absolute
	subu $t4,$t5,$t2			#value of the difference between the value at t and
	abs $t4,$t4					#the value at t-1
	sw $t2,0($t3)				#saves the current value, because it will be the previous
	li $v0,1					#value in the next cycle
	blt $t4,11,steer_end		#if the difference is 10 or less the sensor works correctly
	beq $t7,$zero,steer_end		#if t=0, then there's no meaning in the difference and we
	li $v0,0					#assume the sensor is working correctly

steer_end:						#exactly the same as the slope procedure end
	addi $t0, $t0, 1
	move $v1,$t0
	jr $ra
	
obs_cycle_in:	
	move $t0,$a0				#Some registers get loaded with service variables
	lb $t1,($t0)				#we check the first character, which might be 'A' or 'B'
	la $t6, prev_obs			#distance of the previous moving obstacle
	la $t3, obs_flag			#flag that tells if we already found 2 obstcles at the same
	li $t4, 1					#distance.
	li $t2, 0					#$t4 is a local 'A' or 'B' flag, $t2 will contain the value
	li $t7, 0					#$t7 now just contains 0, to reset the obs_flag, will be 
	li $t8, 58					#useful later. 
	beq $t1, 'B', obs_cycle				#This checks if it starts with 'A' or 'B'
	li $t4, 0					#in case of 'A', resets the flags.
	sw $t7,0($t3)

obs_cycle:						#almost the same as the previous 2 values, but now
	addi $t0, $t0, 1			#it assumes a base 16 value so it's changed accordingly
	lb $t1,($t0)
	beq $t1,' ',obs_check
	beq $t1,$zero,obs_check
	blt $t1,$t8,ASCII_correct
	addi $t1,$t1,-7
ASCII_correct:
	addi $t1, $t1, -48
	mul $t2, $t2, 16
	add $t2, $t2, $t1
	j obs_cycle
	
obs_check:						#Checks are done pace by pace
	li $t5,50					#loads the value 50 to check if the sensor is past
	li $v0,0					#maximum distance or equal to zero, in that case 
	beq $t2,$zero,obs_end		#the procedure ends with $v0=0
	blt $t5,$t2,obs_end
	li $v0,1					#now the sensor works correctly
	beq $t4,0,obs_end			#as long as it is a static obstacle, otherwise
	lw $t7,0($t6)				#the previous obstacle distance gets loaded
	sw $t2,0($t6)				#and the current one gets saved
	bne $t2,$t7,reset_flag		#in case they are not the same, the flag gets reset
	lw $t5,($t3)				#otherwise it gets loaded
	li $v0,0					#and if it's positive, $v0=0 and the procedure ends
	beq $t5,1,obs_end			#otherwise, we set the flag to 1, which means 2 
	li $t5,1					#consecutive same distance moving obstacles found
	li $v0,1					#and the sensor is working correctly
	sw $t5,($t3)				#the value of the flag gets saved in memory
	j obs_end
	
reset_flag:						#makes the flag equal zero
	li $t5,0
	sw $t5,($t3)

obs_end:						
	addi $t0, $t0, 1
	move $v1,$t0
	jr $ra

buffer_fill:					#saves in the buffer the results from the sensor checks first
	move $t1,$a3
	lw $t2, 0($sp)			
	lw $t3, 4($sp)			
	lw $t4, 8($sp)
	lw $t5, 12($sp)
	lw $t6, 16($sp)
	addi $sp, $sp, 20

	addi $t7,$a0,48				#converted to ASCII values
	sb $t7,($t1)
	addi $t1,$t1,1
	li $t7,' '					#and separated with ' '
	sb $t7,($t1)
	addi $t1,$t1,1
	addi $t7,$a1,48
	sb $t7,($t2)
	addi $t2,$t2,1
	li $t7,' '
	sb $t7,($t2)
	addi $t2,$t2,1
	addi $t7,$a2,48
	sb $t7,($t3)
	addi $t3,$t3,1
	li $t7,' '
	sb $t7,($t3)
	addi $t3,$t3,1

	add $t7,$a0,$a1				#then sums the values, obtaining how many sensors are working
	add $t7,$t7,$a2				#correctly in $t7.

	beq $t7,$zero,end_buffer_fill_0	#if $t7 equals zero, no sensor is working, all politics buffer
	li $t8,'1'						#get a '0', otherwise, the P3 buffer gets a '1' and a ' '
	sb $t8,($t6)
	addi $t6,$t6,1
	li $t9,' '
	sb $t9,($t6)
	addi $t6,$t6,1

	beq $t7,1,end_buffer_fill_P1	#if $t7 equals 1, the remaning buffers will get a '0',
	sb $t8,($t5)					#otherwise at least 2 sensors are working so P2 gets the 
	addi $t5,$t5,1					#correctness value as well
	sb $t9,($t5)
	addi $t5,$t5,1

	beq $t7,2,end_buffer_fill_P2	#if $t7 equals 2, only 2 sensor works at the current time so
	sb $t8,($t4)					#P1 gets a 0, otherwise all sensors are working and all the buffers
	addi $t4,$t4,1					#get a '1'
	sb $t9,($t4)
	addi $t4,$t4,1

	j end_buffer_fill

end_buffer_fill_0:				#these procedures fill the appropriate buffers with '0' and ' '
	li $t8,'0'					#following the previous procedures.
	sb $t8,($t6)
	addi $t6,$t6,1
	li $t9,' '
	sb $t9,($t6)
	addi $t6,$t6,1

end_buffer_fill_P1:
	li $t8,'0'
	sb $t8,($t5)
	addi $t5,$t5,1
	sb $t9,($t5)
	addi $t5,$t5,1

end_buffer_fill_P2:
	li $t8,'0'
	sb $t8,($t4)
	addi $t4,$t4,1
	sb $t9,($t4)
	addi $t4,$t4,1

end_buffer_fill:				#in case the buffer_fill procedure never branched, now it only needs 
	move $v0,$t1
	move $v1,$t2
	
	addi $sp, $sp, -16
	sw $t3, 0($sp)			
	sw $t4, 4($sp)
	sw $t5, 8($sp)
	sw $t6, 12($sp)
	
	jr $ra						#return to the main cycle

read_file:						#open and read file with specified name in $a0 and buffer address in $a1
	move $t0,$a2
	move	$t7,$a1
	li	$v0, 13					# Open File Syscall
	li	$a1, 0					# Read-only Flag
	li	$a2, 0					# (ignored)
	syscall
	move	$t8, $v0			# Save File Descriptor
	blt	$v0, 0, err				#Error message in case the file isn't found

	li	$v0, 14					# Read File Syscall
	move	$a0, $t8			# Load File Descriptor
	move	$a1, $t7			# Load Buffer Address
	move	$a2, $t0				# Buffer Size 
	syscall
	j close						# close file

write_file:						#open or create file end write on it with specified name in $a0 and buffer address in $a1
	move	$t7,$a1
	li	$v0, 13					# Open File Syscall
	li	$a1, 1					# write and create Flag
	li	$a2, 0					# (ignored)
	syscall
	move	$t8, $v0			# Save File Descriptor
	blt	$v0, 0, err				# Goto Error

	li	$v0, 15					# Write File Syscall
	move	$a0, $t8			# Load File Descriptor
	move	$a1, $t7			# Load Buffer Address
	li	$a2, 200	#			 Buffer Size 
	syscall
	j close						# close file

close:
	li	$v0, 16					# Close File Syscall
	move	$a0, $t8			# Load File Descriptor
	syscall
	jr	$ra						# return
 
err:
	li	$v0, 4					# Print String Syscall
	la	$a0, fnf				# Load Error String
	syscall

end:							#end of the program, gets called when all other procedures are finished
			
	lw $ra, 0($sp)			
	lw $s0, 4($sp)			
	lw $s1, 8($sp)
	lw $s2, 12($sp)			
	lw $s3, 16($sp)			
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	addi $sp, $sp, 32

	li	$v0, 10					#quit program Syscall
	syscall
