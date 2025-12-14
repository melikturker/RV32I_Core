// RISC-V Audio Bars - Exact ARM Symbol Pattern
// Verified bitmap: 40 rows x 30 columns

.eqv VRAM_BASE, 0x00008000
.eqv REFRESH_REG, 0x00054000

.text
.globl _start

_start:
    lui sp, 0x10000
    lui x9, %hi(VRAM_BASE)
    addi x9, x9, %lo(VRAM_BASE)
    
    lui x7, 0xC3A26
    addi x7, x7, 0x4B5
    lui x1, 0xFF21E
    addi x1, x1, 0x635
    addi x11, x0, 0

frame_loop:
    addi x29, x0, 300
    slli x29, x29, 8
    add x28, x0, x9
clear:
    sw x0, 0(x28)
    addi x28, x28, 4
    addi x29, x29, -1
    bnez x29, clear
    
    addi x4, x0, 0
bar_loop:
    slli x20, x7, 13
    xor x7, x7, x20
    srli x20, x7, 17
    xor x7, x7, x20
    slli x20, x7, 5
    xor x7, x7, x20
    
    andi x5, x7, 0x7F
    addi x5, x5, 20
    addi x6, x0, 240
    sub x6, x6, x5
    srli x1, x7, 8
    slli x1, x1, 8
    lui x20, 0xFF000
    or x1, x1, x20
    
    addi x2, x0, 239
rect_row:
    add x28, x0, x4
    addi x27, x4, 10
rect_col:
    slli x20, x2, 8
    slli x21, x2, 6
    add x20, x20, x21
    add x20, x20, x28
    slli x20, x20, 2
    add x20, x20, x9
    sw x1, 0(x20)
    addi x28, x28, 1
    blt x28, x27, rect_col
    addi x2, x2, -1
    blt x6, x2, rect_row
    
    addi x4, x4, 10
    addi x20, x0, 320
    blt x4, x20, bar_loop
    
    // === EXACT ARM SYMBOL ===
    lui x26, 0xFFFFF
    addi x2, x0, 30
    
    // Helper macro: draw horizontal segment
    // Rows 30-33: col 9-18 (9 pixels)
b1:
    addi x3, x11, 9
    addi x21, x11, 18
b1_col:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b1_col
    addi x2, x2, 1
    addi x20, x0, 34
    blt x2, x20, b1
    
    // Rows 34-37: col 9-21 (12 pixels)
b2:
    addi x3, x11, 9
    addi x21, x11, 21
b2_col:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b2_col
    addi x2, x2, 1
    addi x20, x0, 38
    blt x2, x20, b2
    
    // Rows 38-41: col 9-12, 15-27
b3:
    addi x3, x11, 9
    addi x21, x11, 12
b3_1:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b3_1
    addi x3, x11, 15
    addi x21, x11, 24
b3_2:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b3_2
    addi x2, x2, 1
    addi x20, x0, 42
    blt x2, x20, b3
    
    // Rows 42-45: col 9-12, 18-30
b4:
    addi x3, x11, 9
    addi x21, x11, 12
b4_1:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b4_1
    addi x3, x11, 18
    addi x21, x11, 27
b4_2:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b4_2
    addi x2, x2, 1
    addi x20, x0, 46
    blt x2, x20, b4
    
    // Rows 46-49: col 9-12, 18-27
b5:
    addi x3, x11, 9
    addi x21, x11, 12
b5_1:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b5_1
    addi x3, x11, 18
    addi x21, x11, 24
b5_2:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b5_2
    addi x2, x2, 1
    addi x20, x0, 50
    blt x2, x20, b5
    
    // Rows 50-53: col 9-12, 15-21
b6:
    addi x3, x11, 9
    addi x21, x11, 12
b6_1:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b6_1
    addi x3, x11, 15
    addi x21, x11, 18
b6_2:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b6_2
    addi x2, x2, 1
    addi x20, x0, 54
    blt x2, x20, b6
    
    // Rows 54-57: col 3-12
b7:
    addi x3, x11, 3
    addi x21, x11, 12
b7_col:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b7_col
    addi x2, x2, 1
    addi x20, x0, 58
    blt x2, x20, b7
    
    // Rows 58-65: col 0-12
b8:
    add x3, x0, x11
    addi x21, x11, 12
b8_col:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b8_col
    addi x2, x2, 1
    addi x20, x0, 66
    blt x2, x20, b8
    
    // Rows 66-69: col 3-9
b10:
    addi x3, x11, 3
    addi x21, x11, 9
b10_col:
    slli x22, x2, 8
    slli x23, x2, 6
    add x22, x22, x23
    add x22, x22, x3
    slli x22, x22, 2
    add x22, x22, x9
    sw x26, 0(x22)
    addi x3, x3, 1
    blt x3, x21, b10_col
    addi x2, x2, 1
    addi x20, x0, 70
    blt x2, x20, b10
    
    lui x30, %hi(REFRESH_REG)
    sw x0, %lo(REFRESH_REG)(x30)
    
    addi x11, x11, 2
    addi x20, x0, 296
    blt x11, x20, frame_loop
    addi x11, x0, 0
    j frame_loop
