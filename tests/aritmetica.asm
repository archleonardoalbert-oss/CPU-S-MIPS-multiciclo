# tests/aritmetica.asm - instrucciones aritmeticas y logicas
# Instrucciones: add, sub, and, or, slt, slti, addi, addiu (li), addu (move),
#   y tambien lui, ori, srl, andi, bne, beq, j, jal, jr, lw, sw, lbu, syscall (impresion).
# Casos de la tabla de la guia que cubre:
#   add, sub   : operandos positivos y con al menos un operando negativo
#   and, or    : operandos con unos en los 16 bits altos
#   slt, slti  : resultado 1 y resultado 0; con un negativo donde con signo y sin signo difieren
#   addi       : inmediato negativo
#   addiu, addu: mediante li (constante entre -32768 y 32767) y move
#   $zero      : una instruccion escribe en $zero y despues se comprueba que vale 0
#   syscall    : servicios 11 (imprimir) y 10 (terminar)
# Salida (hexadecimal), en este orden:
#   linea 2: add+  add-  sub+  sub-
#   linea 3: and   or    slt=1 slt=0
#   linea 4: slti=1 slti=0 addi-  move  li
#   linea 5: $zero
        .data
titulo: .asciiz "ARITMETICA"
        .text
main:   la   $a1, titulo
        jal  txt
        li   $t0, 1234              # addiu
        li   $t1, 4321
        li   $t2, -5000             # addiu con negativo
        add  $a1, $t0, $t1          # positivos: 1234 + 4321 = 5555
        jal  hex
        add  $a1, $t0, $t2          # con negativo: 1234 + (-5000) = -3766
        jal  hex
        sub  $a1, $t1, $t0          # positivos: 4321 - 1234 = 3087
        jal  hex
        sub  $a1, $t2, $t1          # con negativo: -5000 - 4321 = -9321
        jal  hex
        jal  nl
        lui  $t3, 0xF0F0            # t3 = f0f000ff
        ori  $t3, $t3, 0x00FF
        lui  $t4, 0xFF00            # t4 = ff000f0f
        ori  $t4, $t4, 0x0F0F
        and  $a1, $t3, $t4          # f000000f
        jal  hex
        or   $a1, $t3, $t4          # fff00fff
        jal  hex
        li   $t5, -1
        slt  $a1, $t5, $t0          # -1 < 1234 con signo: 1 (sin signo seria 0)
        jal  hex
        slt  $a1, $t0, $t5          # 1234 < -1: 0
        jal  hex
        jal  nl
        slti $a1, $t5, 1            # -1 < 1: 1
        jal  hex
        slti $a1, $t0, -3           # 1234 < -3: 0
        jal  hex
        addi $a1, $t0, -2000        # inmediato negativo: -766
        jal  hex
        move $t9, $t2               # addu
        move $a1, $t9
        jal  hex
        li   $a1, -32768            # addiu con el menor inmediato
        jal  hex
        jal  nl
        addi $zero, $t1, 77         # escribir en $zero no tiene efecto
        add  $zero, $t0, $t1
        move $a1, $zero
        jal  hex
        jal  nl
        addi $v0, $zero, 10
        syscall
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
