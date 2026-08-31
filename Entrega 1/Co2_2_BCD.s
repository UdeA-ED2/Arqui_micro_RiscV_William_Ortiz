.global _start

.data

ejemplo: .word 1234
bcd: .word 0
po10:
	.word 100000000
	.word 10000000
	.word 1000000
	.word 100000
	.word 10000
	.word 1000
	.word 100
	.word 10
	.word 1
	
_start:
	
	lw s1, 0(gp) #guardo el número a convertir en un registro
	bge s1, zero, set # Si el número es mayor o igual a cero continuo con el proceso
	sub  s1, zero, s1 # Cambio el signo
	
	set:
		addi s2, zero, 0
		addi s3, gp, 12 #potencia de 10 mas grande
		addi s4, zero, 8 #contador de las potencias
	
	set_loop:
		beq  s4, zero, fin
		
		lw t0, 0(s4)
		addi s3, s3, 4 #variable para cambiar de dirección de memoria
		addi s4, s4, -1 #contador de las potencias
		addi t1, zero, 0 #contador del digito 
	
	sub_loop:
		
		blt s1, t0, veri #Si el numero es menor que la potencia, acaba la resta
		sub s1, s1, t1 #Le resto al numero la potencia
		addi t1, t1, 1 #Sumo 1 al contador de digito
		jal zero, sub_loop
		
		
