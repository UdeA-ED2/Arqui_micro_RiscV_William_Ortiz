.global _start

.data

pruebas:

	.word 2
	.word 4
	.word 6
	.word 9
	.word 42 #el 42 representa el asterisco en ASCCI, será la bandera que avise cuando el numero acabó 
	
.text
_start:
	add t3, zero, zero
	add t1, zero, zero
	set:
		add t3, t1, t3	
		addi s0, zero, 42
		la gp, pruebas
		beq t0, s0, fin
	
	save_num:
		lw t0, 0(gp)
		addi gp, gp, 4
		add t1, zero, t0
		addi t2, zero, 10
		
		
	sucev_sum:
		beq t2, zero, set
		addi t2, t2, -1
		addi t1, t1, 10
		j sucev_sum
		
	fin:
	
	
