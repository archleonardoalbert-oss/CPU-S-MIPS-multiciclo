# tests/desplazamientos.asm - desplazamientos e inmediatos sin signo
# Instrucciones: sll, srl, andi, ori, lui (y addi, add, slti, bne, beq, j, jal, jr, lw, sw, lbu, syscall).
# Casos de la tabla de la guia que cubre:
#   sll, srl   : shamt = 0 y shamt distinto de 0; srl sobre un valor negativo (entran ceros)
#   andi, ori  : inmediato con el bit 15 a 1 (se extiende con ceros)
#   lui        : inmediato con el bit 15 a 1
#   syscall    : servicios 11 y 10
# Salida (hexadecimal), en este orden:
#   linea 2: sll0  sll4  sll31 srl0
#   linea 3: srl4(neg) srl31(neg) srl8
#   linea 4: andi  ori   ori(altos) andi(mezcla)
#   linea 5: lui   lui+ori
        .data
titulo: .asciiz "DESPLAZAMIENTOS E INMEDIATOS"
        .text
main:   la   $a1, titulo
        jal  txt
        lui  $t0, 0x1234            # t0 = 12348765
        ori  $t0, $t0, 0x8765
        li   $t1, -16               # t1 = fffffff0 (negativo)
        sll  $a1, $t0, 0            # shamt 0: no cambia
        jal  hex
        sll  $a1, $t0, 4            # 23487650
        jal  hex
        sll  $a1, $t0, 31           # 80000000
        jal  hex
        srl  $a1, $t1, 0            # shamt 0: fffffff0
        jal  hex
        jal  nl
        srl  $a1, $t1, 4            # negativo: entran ceros -> 0fffffff
        jal  hex
        srl  $a1, $t1, 31           # 00000001
        jal  hex
        srl  $a1, $t0, 8            # 00123487
        jal  hex
        jal  nl
        li   $t2, -1
        andi $a1, $t2, 0x8001       # bit 15 = 1: arriba ceros -> 00008001
        jal  hex
        ori  $a1, $zero, 0x8001     # 00008001 (no ffff8001)
        jal  hex
        lui  $t3, 0xFFFF
        ori  $a1, $t3, 0x8001       # los 16 altos se conservan: ffff8001
        jal  hex
        andi $a1, $t0, 0xF0F0       # 00008060
        jal  hex
        jal  nl
        lui  $a1, 0x8001            # bit 15 = 1: 80010000
        jal  hex
        lui  $t4, 0xABCD
        ori  $a1, $t4, 0xEF01       # abcdef01
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
