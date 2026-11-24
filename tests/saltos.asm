# tests/saltos.asm - saltos condicionales, j, procedimientos y pila
# Instrucciones: beq, bne, j, jal, jr, syscall (y addi, add, sw, lw, slti, srl, andi, lbu).
# Casos de la tabla de la guia que cubre:
#   beq, bne   : cada uno tomado y no tomado; al menos un salto hacia atras
#   j          : al menos una vez
#   jal, jr    : un procedimiento que llama a otro (no hoja), guardando $ra en la pila
#                y retornando correctamente (factorial recursivo que llama a mult)
#   syscall    : servicios 11 y 10
# Salida (hexadecimal), en este orden:
#   linea 2: marcas de beq/bne (cada salto tomado o no tomado suma un valor distinto)
#   linea 3: suma 1+2+...+10 con salto hacia atras ; resultado de j
#   linea 4: factorial(6) recursivo ; $sp antes ; $sp despues (deben ser iguales)
        .data
titulo: .asciiz "SALTOS Y PROCEDIMIENTOS"
        .text
main:   la   $a1, titulo
        jal  txt
        addi $t0, $zero, 5
        addi $t1, $zero, 5
        addi $t2, $zero, 7
        add  $s0, $zero, $zero      # s0 acumula marcas
        beq  $t0, $t1, b1           # beq TOMADO
        addi $s0, $s0, 0x1000       # no debe ejecutarse
b1:     addi $s0, $s0, 1
        beq  $t0, $t2, b2           # beq NO tomado
        addi $s0, $s0, 0x10         # si se ejecuta
b2:     bne  $t0, $t2, b3           # bne TOMADO
        addi $s0, $s0, 0x2000       # no debe ejecutarse
b3:     addi $s0, $s0, 0x100
        bne  $t0, $t1, b4           # bne NO tomado
        addi $s0, $s0, 0x10000      # si se ejecuta
b4:     move $a1, $s0               # esperado 00010111
        jal  hex
        jal  nl
        add  $s1, $zero, $zero      # suma 1..10
        addi $t3, $zero, 10
atras:  add  $s1, $s1, $t3
        addi $t3, $t3, -1
        bne  $t3, $zero, atras      # salto hacia atras
        move $a1, $s1               # 55 = 00000037
        jal  hex
        addi $s2, $zero, 1
        j    salta                  # j
        addi $s2, $zero, 99         # no debe ejecutarse
salta:  addi $s2, $s2, 2
        move $a1, $s2               # 00000003
        jal  hex
        jal  nl
        move $s3, $sp               # $sp antes de llamar
        addi $a1, $zero, 6
        jal  fact                   # factorial(6) = 720 = 000002d0
        jal  hex
        move $a1, $s3
        jal  hex
        move $a1, $sp               # $sp despues: igual que antes
        jal  hex
        jal  nl
        addi $v0, $zero, 10
        syscall
# fact(a1) -> a1. Recursivo y no hoja: guarda $ra y el argumento en la pila.
fact:   addi $sp, $sp, -8
        sw   $ra, 4($sp)
        sw   $a1, 0($sp)
        slti $k0, $a1, 2
        beq  $k0, $zero, rec
        addi $a1, $zero, 1          # caso base: fact(0) = fact(1) = 1
        j    ffin
rec:    addi $a1, $a1, -1
        jal  fact                   # a1 = fact(n - 1)
        lw   $a2, 0($sp)            # a2 = n
        jal  mult                   # a1 = a1 * a2
ffin:   lw   $ra, 4($sp)
        addi $sp, $sp, 8
        jr   $ra
# mult(a1, a2) -> a1 = a1 * a2 por sumas repetidas (a2 > 0). Hoja.
mult:   add  $a3, $zero, $zero
mloop:  add  $a3, $a3, $a1
        addi $a2, $a2, -1
        bne  $a2, $zero, mloop
        move $a1, $a3
        jr   $ra
# ------------------------------------------------------------------
# Procedimientos de impresion (solo syscall 11)
# hex: imprime $a1 como 8 cifras hexadecimales y un espacio.
#      No es hoja (llama a nib): guarda $ra en la pila.
hex:    addi $sp, $sp, -4
        sw   $ra, 0($sp)
        srl  $a3, $a1, 28
        jal  nib
        srl  $a3, $a1, 24
        jal  nib
        srl  $a3, $a1, 20
        jal  nib
        srl  $a3, $a1, 16
        jal  nib
        srl  $a3, $a1, 12
        jal  nib
        srl  $a3, $a1, 8
        jal  nib
        srl  $a3, $a1, 4
        jal  nib
        srl  $a3, $a1, 0
        jal  nib
        addi $a0, $zero, 32         # espacio
        addi $v0, $zero, 11
        syscall
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
# nib: imprime la cifra hexadecimal de los 4 bits bajos de $a3
nib:    andi $a3, $a3, 15
        slti $k0, $a3, 10
        bne  $k0, $zero, cifra
        addi $a3, $a3, 87           # 10..15 -> 'a'..'f'
        j    sale
cifra:  addi $a3, $a3, 48           # 0..9 -> '0'..'9'
sale:   add  $a0, $a3, $zero
        addi $v0, $zero, 11
        syscall
        jr   $ra
# nl: salto de linea
nl:     addi $a0, $zero, 10
        addi $v0, $zero, 11
        syscall
        jr   $ra
# txt: imprime la cadena terminada en 0 que empieza en $a1, y un salto de linea
txt:    lbu  $a0, 0($a1)
        beq  $a0, $zero, txtfin
        addi $v0, $zero, 11
        syscall
        addi $a1, $a1, 1
        j    txt
txtfin: addi $a0, $zero, 10
        addi $v0, $zero, 11
        syscall
        jr   $ra
