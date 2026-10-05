.data
    float_10:   .word 0x41200000   # 10.0
    float_0:    .word 0x00000000   # 0.0
    float_min_1: .word 0xBF800000 # -1.0 Para manejar negativos
   
    # Caso de prueba: Float -123.45 (probando signo negativo)
    test_float: .word 0xC2F69999   # -29.6875 en IEEE 754
    bcd_out:    .space 64          # Espacio para el resultado BCD
    bcd_in:     .word '-', '1', '2', '3', '.', '4', '5', '@' # Arreglo BCD de entrada con signo

.text
.globl main

main:
    # 1. Probar Float a BCD 
    la t0, test_float #Cargo dirección
    lw t0, 0(t0)      #Cargo la dirección del numero en float 
    fmv.w.x fa0, t0   #Paso el numero a formato float. Será una entrada de la función
    la a0, bcd_out    #Guardo la dirección de salida en BCD. Será otra entrada de la función
    jal ra, float_a_bcd

    # 2. Probar BCD a Float (['-1', '2', '3', '.', '4', '5', '@'] -> -123.45)
    la a0, bcd_in
    jal ra, bcd_a_float

end_main:
    jal zero, end_main


# ==============================================================================
# Función: float_a_bcd (Soporta enteros, decimales y signos negativos)
# ==============================================================================
float_a_bcd:
    la t0, float_10      # Guardo la dirección del 10
    lw t0, 0(t0)         # Guardo el 10 
    fmv.w.x f1, t0       # f1 = 10.0
    la t0, float_0       # Guardo la dirección del 0
    lw t0, 0(t0)         # Guardo el 0
    fmv.w.x f0, t0       # f0 = 0.0

    # Manejo del Signo 
    flt.s t0, fa0, f0    # t0 = (fa0 < 0.0) ? 1 : 0
    beq t0, zero, check_zero_val
    
    # Si es negativo, escribir '-' (ASCII 45) y volver el número positivo
    addi t1, zero, '-'   # Escribo el ASCCI del menos en un temp
    sb t1, 0(a0)         # Uso sb (store byte) para guardar caracteres
    addi a0, a0, 1       # Avanzo un byte 

    la t0, float_min_1   # Cargo la dirección del -1
    lw t0, 0(t0)         # Cargo el -1
    fmv.w.x f2, t0       # Lo hago float
    fmul.s fa0, fa0, f2  # fa0 = -fa0 (Vuelvo el numero de prueba positivo)

check_zero_val:

    # Separar parte entera y decimal
	
    fcvt.w.s t1, fa0,rtz # Extraigo la parte entera del float a un temp
    fcvt.s.w f2, t1      # Conservo una copia del float entero
    fsub.s f10, fa0, f2  # Le resto al float su parte entera para obtener la decimal

    
    add t2, zero, zero   # t2 = contador de dígitos enteros
    add t3, zero, t1     # t3 = copia de la parte entera

loop_int_extract:

    beq t3, zero, check_zero_int

    fcvt.s.w f3, t3      # Paso a float la parte entera 
    fdiv.s f4, f3, f1    # Divido la parte entera entre diez
    fcvt.w.s t4, f4, rtz # t4 = Cociente

    fcvt.s.w f5, t4      # Tomo la parte entera del cociente
    fmul.s f5, f5, f1    # La multiplico por 10
    fcvt.w.s t5, f5, rtz      # Paso el resultado a int
    sub t6, t3, t5       # Le resto al numero completo el procesado para obtener el ultimo digito

    # Guardo dígito en la pila para invertir el orden
	
    addi sp, sp, -4      # Me muevo una posición en la pila
    sw t6, 0(sp)         # Guardo el digito en esa posición
    addi t2, t2, 1       # contador++
    add t3, zero, t4     # Nuevo dividendo = cociente
	
    jal zero, loop_int_extract

check_zero_int:
    bne t2, zero, write_int_dig
	
    # Si la parte entera era 0, guardo 0 en la pila
    addi sp, sp, -4
    sw zero, 0(sp)
    addi t2, t2, 1

write_int_dig:

    add s1, zero, sp
	slli t0, t2, 2
    # Escribo los dígitos enteros en orden correcto a la memoria BCD convertidos a ASCII ('0' + dígito)
    
    lw t6, 0(s1)         # Guardo el primer digito en un temp
    addi s1, s1, 4       # Avanzo en una posiciónes del stack
    addi t6, t6, '0'     # Convierto el valor numérico a carácter ASCII 
    sb t6, 0(a0)         # sb en lugar de sw para guardar un byte por carácter
    addi a0, a0, 1       # Avanzo una posición en memoria
    addi t2, t2, -1      # Le resto al contador 1
    bne t2, zero, write_int_dig
    add sp, sp, t0
	
    #Procesar Parte Decimal
	
    fmv.x.w t0, f10          #Paso la parte decimal a un temp
    beq t0, zero, finish_bcd # Si la parte decimal es 0.0, terminar

    # Escribir punto decimal '.' (ASCII 46)
	
    addi t0, zero, '.'      # Escribo un punto para comenzar la parte decimal
    sb t0, 0(a0)            # Lo guardo en memoria
    addi a0, a0, 1          # Avanzo en memoria
    add t1, zero, zero      # Contador de decimales (límite máximo de 4 cifras)

loop_dec_extract:

    li t4, 4
    bge t1, t4, finish_bcd   # Compara el registro t1 con el registro t4
    fmul.s f10, f10, f1      # Multiplico la parte decimal x10
    fcvt.w.s t2, f10, rtz    # Lo convierto en entero para quedarme sin la parte decimal
    addi t3, t2, '0'         # Convertir dígito decimal a ASCII
    sb t3, 0(a0)             # Guardo el digito 
    addi a0, a0, 1           # Avanzo en memoria 

    fcvt.s.w f3, t2          # Convierto el numero operado a float
    fsub.s f10, f10, f3      # Restar parte entera extraída para tener

    addi t1, t1, 1

    # Verificar si el residuo decimal ya es prácticamente 0
    fmv.x.w t0, f10
    beq t0, zero, finish_bcd
    jal zero, loop_dec_extract

finish_bcd:
    # Escribir carácter centinela final '@'
    addi t0, zero, '@'
    sb t0, 0(a0)
    jalr zero, ra, 0


# ==============================================================================
# Función: bcd_a_float (Soporta enteros, punto decimal '.' y signo negativo '-')
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
    fmv.s f10, f1
    addi t3, zero, '@'   # Centinela
    addi t4, zero, '.'   # Punto decimal
    addi t6, zero, '-'   # Signo negativo
    
    add t5, zero, zero   # Modo: 0 = Entero, 1 = Decimal
    add sp, sp, -4
    li t0, 1
    sw t0, 0(sp)         # Guardar signo positivo por defecto en la pila (+1)

loop_b2f:
    lbu t2, 0(a0)        # Usar lbu (load byte unsigned) para leer caracteres individuales
    beq t2, t3, end_b2f  # Si es '@', terminar

    beq t2, t4, set_decimal_mode # Si es '.', cambiar a modo decimal
    beq t2, t6, set_negative_sign # Si es '-', marcar signo negativo

    # Convertir carácter ASCII ('0' a '9') a su valor numérico entero (0 a 9)
    addi t2, t2, -48

    fcvt.s.w f2, t2      # f2 = (float) dígito

    bne t5, zero, process_decimal_digit_b2f

    # Modo Entero: fa0 = (fa0 * 10.0) + dígito
    fmul.s fa0, fa0, f1
    fadd.s fa0, fa0, f2
    jal zero, next_bcd_char_b2f

set_decimal_mode:
    add t5, zero, 1      # Activar modo decimal
    jal zero, next_bcd_char_b2f

set_negative_sign:
    li t0, -1
    sw t0, 0(sp)         # Actualizar signo a -1 en la pila
    jal zero, next_bcd_char_b2f

process_decimal_digit_b2f:
    # Modo Decimal: fa0 = fa0 + (dígito / divisor)
    fdiv.s f3, f2, f10   # f3 = dígito / divisor
    fadd.s fa0, fa0, f3
    fmul.s f10, f10, f1  # Incrementar divisor (* 10.0)

next_bcd_char_b2f:
    addi a0, a0, 1       # Incrementar de a 1 byte (ya que usamos sb/lbu)
    jal zero, loop_b2f

end_b2f:
    # Aplicar el signo almacenado al acumulador final
    lw t0, 0(sp)
    addi sp, sp, 4
    li t1, -1
    bne t0, t1, finish_b2f

    la t0, float_min_1
    lw t0, 0(t0)
    fmv.w.x f2, t0
    fmul.s fa0, fa0, f2  # fa0 = -fa0

finish_b2f:
    jalr zero, ra, 0
	

end_b2f:
    jalr zero, ra, 0
	
