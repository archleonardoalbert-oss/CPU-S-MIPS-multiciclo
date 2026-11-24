# tests/memoria.asm - lectura y escritura en memoria
# Instrucciones: lw, sw, lb, lbu, sb (y la, addi, lui, ori, jal, jr, syscall).
# Casos de la tabla de la guia que cubre:
#   lw, sw     : desplazamiento positivo y desplazamiento negativo
#   lb, lbu    : byte con el bit 7 a 1 en al menos dos posiciones distintas de la palabra
#   sb         : en las cuatro posiciones de una misma palabra (d[1:0] = 0, 1, 2, 3),
#                comprobando despues con lw que los otros bytes no cambiaron
#   syscall    : servicios 11 y 10
# Salida (hexadecimal), en este orden:
#   linea 2: sw/lw(+8)  sw/lw(-4)  lw(-8) de .data
#   linea 3: lb(1) (bit 7 = 0)  lbu(2)  lb(2)  lb(3)
#   linea 4: lbu(3)  lb(0)  lbu(0)
#   (los bytes 0, 2 y 3 tienen el bit 7 a 1: f3, f1 y 80)
#   linea 5: 4 sb -> lw ; sb(2) -> lw ; sb(1) sobre aabbccdd -> lw
        .data
titulo: .asciiz "MEMORIA"
        .align 2
buf:    .word 0x11111111, 0x22222222, 0x33333333, 0x44444444
        .word 0x80F172F3, 0, 0xAABBCCDD, 0
        .text
main:   la   $a1, titulo
        jal  txt
        la   $s7, buf               # s7 = inicio del buffer
        addi $s6, $s7, 16           # s6 = buffer + 16
        lui  $t0, 0xCAFE
        ori  $t0, $t0, 0xBABE
        sw   $t0, 8($s7)            # desplazamiento positivo
        lw   $a1, 8($s7)            # cafebabe
        jal  hex
        lui  $t1, 0x0BAD
        ori  $t1, $t1, 0xF00D
        sw   $t1, -4($s6)           # desplazamiento negativo (= buf + 12)
        lw   $a1, -4($s6)           # 0badf00d
        jal  hex
        lw   $a1, -12($s6)          # buf + 4: 22222222
        jal  hex
        jal  nl
        lb   $a1, 1($s6)            # byte 1 de 80f172f3 = 72 (bit 7 = 0): lb -> 00000072
        jal  hex
        lbu  $a1, 2($s6)            # byte 2 = f1: lbu -> 000000f1
        jal  hex
        lb   $a1, 2($s6)            # byte 2 = f1: lb -> fffffff1
        jal  hex
        lb   $a1, 3($s6)            # byte 3 = 80: lb -> ffffff80
        jal  hex
        jal  nl
        lbu  $a1, 3($s6)            # byte 3 = 80: lbu -> 00000080
        jal  hex
        lb   $a1, 0($s6)            # byte 0 = f3: lb -> fffffff3
        jal  hex
        lbu  $a1, 0($s6)            # byte 0 = f3: lbu -> 000000f3
        jal  hex
        jal  nl
        addi $t2, $zero, 0x11
        sb   $t2, 4($s6)            # d[1:0] = 0
        addi $t2, $zero, 0x22
        sb   $t2, 5($s6)            # d[1:0] = 1
        addi $t2, $zero, 0x33
        sb   $t2, 6($s6)            # d[1:0] = 2
        addi $t2, $zero, 0x4C4
        sb   $t2, 7($s6)            # d[1:0] = 3, solo se guarda el byte bajo (c4)
        lw   $a1, 4($s6)            # c4332211
        jal  hex
        addi $t2, $zero, 0x99
        sb   $t2, 6($s6)
        lw   $a1, 4($s6)            # solo cambia el byte 2: c4992211
        jal  hex
        addi $t2, $zero, 0x55
        sb   $t2, 9($s6)            # sobre aabbccdd, byte 1
        lw   $a1, 8($s6)            # aabb55dd
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
