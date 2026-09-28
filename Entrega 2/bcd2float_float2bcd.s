.data
    float_10:   .word 0x41200000   # 10.0
    float_0:    .word 0x00000000   # 0.0
   
    # Caso de prueba: Float 123.45
    test_float: .word 0x42F6E666   # ~123.45 
    bcd_out:    .space 64          # Espacio para el resultado BCD
    bcd_in:     .word 1, 2, 3, '.', 4, 5, '@' # Arreglo BCD de entrada

.text
.globl main

main:

    # Probar Float a BCD (123.45 -> [1, 2, 3, '.', 4, 5, '@'])
    la t0, test_float 	# guardo el addres del numero a probar
    lw t0, 0(t0)	# guardo el numero 
    fmv.w.x fa0, t0	# guardo el numero en un registro flotante
    la a0, bcd_out	# arreglo de BCD
    jal ra, float_a_bcd

    # Probar BCD a Float ([1, 2, 3, '.', 4, 5, '@'] -> 123.45)
    la a0, bcd_in
    jal ra, bcd_a_float

end_main:
    jal zero, end_main


# ==============================================================================
# Entrada: fa0 = float, a0 = dirección BCD
# ==============================================================================
float_a_bcd:

    la t0, float_10	     #guardo address 10 para las multiplicaciones sucesivas 
    lw t0, 0(t0)		 #guardo el 10 en registro temporal
    fmv.w.x f1, t0       #Lo paso a un registro de punto flotante 

    # Separar parte entera y decimal
    fcvt.w.s t1, fa0     # parte entera 
    fcvt.s.w f2, t1      # Una vez conozco la parte entera la paso otra vez a float para obtener la porción decimal
    fsub.s f10, fa0, f2  # parte decimal (fa0 - f2)

    # Extraer dígitos enteros al stack
    add t2, zero, zero   # t2 = contador de dígitos enteros
    add t3, zero, t1     # t3 = copia de la parte entera

    int_extrac:
    beq t3, zero, check_zero

    # División flotante para obtener cociente y residuo
    fcvt.s.w f3, t3      # paso el dividendo a un registro flotante
    fdiv.s f4, f3, f1    # divido el numero entre 10
    fcvt.w.s t4, f4      # Tomo la parte entera de la division 

    fcvt.s.w f5, t4      # convierto la parte decimal a float 
    fmul.s f5, f5, f1    # multiplico por la potencia de 10
    fcvt.w.s t5, f5		 # convierto el float a entero 
    sub t6, t3, t5       # t6 = Residuo (Dígito BCD)

    # Guardar dígito en la pila para invertir el orden
    addi sp, sp, -4
    sw t6, 0(sp)         # guardo el numero en el stack 
    addi t2, t2, 1       # contador++
    add t3, zero, t4     # Nuevo dividendo = cociente
    jal zero,int_extrac
sus_module:
		fsub.s f10, f3, f10 # Resto el modulo en caso que el programa aproxime y me quede una resta negativa

check_zero:
    bne t2, zero, write_int_digits
    # Si la parte entera era 0, guardo 0 en la pila
    addi sp, sp, -4
    sw zero, 0(sp)
    addi t2, t2, 1

write_int_digits:

    # Escribo los dígitos enteros en orden correcto a la memoria BCD
	
    lw t6, 0(sp) 	# tomo la dirección del primer numero en el stack
    addi sp, sp, 4 	# avanzo en el stack
    sw t6, 0(a0) 	# guardo el numero en memoria 
    addi a0, a0, 4 	# avanzo en la memoria
    addi t2, t2, -1 # reduzco el contador 
    bne t2, zero, write_int_digits

    #Procesar Parte Decimal 
    la t0, float_0 # cargo el address del float cero 
    lw t0, 0(t0)   # cargo el cero en un registro temporal 
    fmv.w.x f0, t0 # paso el cero de un registro entero a uno float
   
    #¿Hay parte decimal?
    fmv.x.w t0, f10
    beq t0, zero, fin_bcd # Si la parte decimal es 0.0, terminar

    # Escribir punto decimal '.' (ASCII 46)
    addi t0, zero, '.'
    sw t0, 0(a0)
    addi a0, a0, 4

    add t1, zero, zero   # Contador de decimales (límite máximo de 4 cifras)
    addi t6, zero, 4
	
loop_dec_extract:
    
	
    bge t1, t6, fin_bcd # Límite de precision decimal
    fmul.s f10, f10, f1  # multiplico el decimal x 10
    fcvt.w.s t2, f10     # tomo la parte entera del decimal 
    sw t2, 0(a0)         # Escribir dígito decimal
    addi a0, a0, 4       # avanzo en la memoria 

    fcvt.s.w f3, t2
	bge f3, f10, sus_module
    fsub.s f10, f10, f3  # Restar parte entera extraída	
	sus_module:	
		fsub.s f10, f3, f10 # Resto el modulo en caso que el programa aproxime y me quede una resta negativa
		j done	
	done:
    addi t1, t1, 1

    # Verificar si el residuo decimal ya es prácticamente 0
    fmv.x.w t0, f10
    beq t0, zero, fin_bcd
    jal zero, loop_dec_extract
	
fin_bcd:
    # Escribir carácter centinela final '@'
    addi t0, zero, '@'
    sw t0, 0(a0)
    jalr zero, ra, 0


# ==============================================================================
# Entrada: a0 = dirección arreglo BCD
# Salida:  fa0 = número float
# ==============================================================================

bcd_a_float:

    la t0, float_10
    lw t0, 0(t0)
    fmv.w.x f1, t0       # f1 = 10.0

    la t0, float_0
    lw t0, 0(t0)
    fmv.w.x fa0, t0      # fa0 = 0.0 (Acumulador)
    #                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            fmv.w.x f10, f1      # f10 = divisor decimal (10.0, 100.0, ...)

    addi t3, zero, '@'   # signo de parada
    addi t4, zero, '.'   # Punto decimal
    add t5, zero, zero   # Modo: 0 = Entero, 1 = Decimal

loop_b2f:
    lw t2, 0(a0)
    beq t2, t3, end_b2f  # Si es '@', terminar

    beq t2, t4, set_decimal_mode # Si es '.', cambiar a modo decimal

    fcvt.s.w f2, t2      # f2 = (float) dígito

    bne t5, zero, process_decimal_digit

    # Modo Entero: fa0 = (fa0 * 10.0) + dígito
    fmul.s fa0, fa0, f1
    fadd.s fa0, fa0, f2
    jal zero, next_bcd_char

set_decimal_mode:
    addi t5, zero, 1     # Activar modo decimal
    jal zero, next_bcd_char

process_decimal_digit:
    # Modo Decimal: fa0 = fa0 + (dígito / divisor)
    fdiv.s f3, f2, f10   # f3 = dígito / divisor
    fadd.s fa0, fa0, f3
    fmul.s f10, f10, f1  # Incrementar divisor (* 10.0)

next_bcd_char:
    addi a0, a0, 4
    jal zero, loop_b2f

end_b2f:
    jalr zero, ra, 0
	
