.global _start

.data

ejemplo: .word 12000000 #0
bcd: .word 0 #4

po10:
	.word 100000000 #8
	.word 10000000  #12
	.word 1000000   #16
	.word 100000    #20
	.word 10000     #24
	.word 1000      #28  
	.word 100       #32
	.word 10        #36
	.word 1         #40
	
	
_start:

main:
	
	addi a0, zero, 2
	addi a1, zero, zero
	
	jal ca2BCD
	
	ca2BCD:
	
		lw a1, 0(gp)  #gado el número a convertir en un registro
	    bge a1, zero, set # Si el número es mayor o igual a cero continuo con el proceso
	    addi t3, t3, 7 # Constante para iterar la cantidad de sumas de desplazamiento 
	
	    set:
			addi s2, zero, 0
			addi s3, gp, 8 #potencia de 10 mas grande
			addi s4, zero, 8 #contador de las potencias
	
	    set_loop:
			beq  s4, zero, fin
			lw t0, 0(s3)
			addi s3, s3, 4 #variable para cambiar de dirección de memoria
			addi s4, s4, -1 #contador de las potencias
			addi t1, zero, 0 #contador del digito 
	
		sub_loop:
		
			blt a1, t0, veri #Si el numero es menor que la potencia, acaba la resta
			sub a1, a1, t0 #Le resto al numero la potencia
			addi t1, t1, 1 #Sumo 1 al contador de digito
			j sub_loop
		
		veri:
			add t2, t2, t1 # guardo el numero de veces que está la potencia de 10 en otro registro para organizar el número 
			addi t4, t4, 28 # Contador de las sumas de desplazamiento 
			beq s4, t3, sumad # If para decidir la cantidad de sumas 
		
			suma28:
				beq t4, zero, set_loop
				add t2, t2, t2
				add s5, s5, t2
				addi t4, t4, -1
				j suma28
			
			
			
		 	
	fin:
	
		
		
