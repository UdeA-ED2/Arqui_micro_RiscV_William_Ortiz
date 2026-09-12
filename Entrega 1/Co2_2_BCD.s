.global _start

.data
# 1. Lista de números a probar
lista: 
    .word 12000000       # Prueba 1: Positivo normal
    .word -98765         # Prueba 2: Número negativo (Complemento a 2)
    .word 0              # Prueba 3: Cero absoluto

# 2. Arreglo de potencias de 10 (10^9 hasta 10^0)
po10:
    .word 1000000000
    .word 100000000
    .word 10000000
    .word 1000000
    .word 100000
    .word 10000
    .word 1000
    .word 100
    .word 10
    .word 1

# 3. Espacio en memoria para la salida BCD (40 bytes = 10 dígitos x 4 bytes)
bcd_out: 
    .zero 40

.text
_start:
main:
    # Preparación de punteros asumiendo que 'gp' apunta al inicio de .data
    # (Desplazamientos exactos basados en el tamaño de los datos declarados arriba)
	
    addi s0, zero, 0     # s0 = Índice del bucle de pruebas (i = 0)
    addi s1, zero, 3     # s1 = Cantidad de pruebas a realizar
    add s2, gp, zero     # s2 = Puntero de lectura (lista)
    addi s3, gp, 12      # s3 = Puntero a las potencias (12 bytes después del inicio)
    addi s4, gp, 52      # s4 = Puntero de escritura (52 bytes después: 12 de lista + 40 de po10)

test_loop:
    beq s0, s1, end_main # Si i == 3, terminar programa

    # Cargar argumentos para la función
    lw a0, 0(s2)         # a0 = Número actual de la lista
    add a1, s3, zero     # a1 = Puntero a po10
    add a2, s4, zero     # a2 = Puntero a bcd_out

    # Llamar a la función
    jal ra, ca2BCD

    # Avanzar punteros e índice para la siguiente prueba
    addi s2, s2, 4       # Siguiente número en la lista
    addi s0, s0, 1       # i++
    jal zero, test_loop  # Repetir

end_main:
    jal zero, end_main   # Bucle infinito para finalizar ejecución con seguridad



# Función ca2BCD
# Entradas: a0 (Número en Ca2), a1 (Puntero a po10), a2 (Puntero a bcd_out)

ca2BCD:
    
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s2, 12(sp)
    sw s3, 8(sp)
    sw s4, 4(sp)
    sw s5, 0(sp)

    
    add t6, a0, zero     # Trabajar con copia (t6)
    bge t6, zero, set    # Si es >= 0, iniciar
    sub t6, zero, t6     # Si es < 0, aplicar Ca2 (invertir signo)

set:
    add s3, a1, zero     # s3 = puntero de lectura de potencias
    add s5, a2, zero     # s5 = puntero de escritura de BCD
    addi s4, zero, 10    # s4 = 10 iteraciones (10^9 hasta 10^0)

set_loop:
    beq s4, zero, fin
    lw t0, 0(s3)         # Cargar potencia actual
    addi s3, s3, 4       # Avanzar puntero de potencias
    addi s4, s4, -1      # Decrementar contador
    addi t1, zero, 0     # Inicializar dígito actual en 0

sub_loop:
    blt t6, t0, saveD # Si (numero < potencia), terminar restas
    sub t6, t6, t0       # numero = numero - potencia
    addi t1, t1, 1       # digito++
    jal zero, sub_loop   

saveD:
    # Escribo el dígito calculado en memoria
    sw t1, 0(s5)
    addi s5, s5, 4       # Avanzar puntero de escritura en 1 word
    jal zero, set_loop   # Siguiente potencia

fin:
    
    lw s5, 0(sp)
    lw s4, 4(sp)
    lw s3, 8(sp)
    lw s2, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20

    jr ra # Retorno 
			
			
		 	
	
	
		
		
