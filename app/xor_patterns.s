// RV32I - XOR Patterns v4 (Independent Channels)
// R = (X + T) & 0xFF
// G = (Y + T + 85) & 0xFF
// B = ((X ^ Y) + 170) & 0xFF
// Alpha = 0xFF
// Interlaced Rendering (4x speed)

.eqv VRAM_BASE,   0x00008000
.eqv REFRESH_REG, 0x00054000
.eqv SCREEN_W,    320
.eqv SCREEN_H,    240

.text
.globl _start

_start:
    lui sp, 0x10000

    lui x30, %hi(REFRESH_REG)
    addi x30, x30, %lo(REFRESH_REG)

    addi x11, x0, 0          // t = 0

    // VRAM Base Constant
    lui x9, %hi(VRAM_BASE)
    addi x9, x9, %lo(VRAM_BASE)

frame_loop:
    // Interlaced Y-Start: (t & 3)
    andi x2, x11, 3          // y

    addi x28, x0, SCREEN_H   // y_limit
    addi x29, x0, SCREEN_W   // x_limit
    
y_loop:
    // --- ROW ADDRESS ---
    // Offset = y * 1280
    slli x20, x2, 10
    slli x21, x2, 8
    add  x20, x20, x21      // Offset
    add  x25, x9, x20       // Ptr = Base + Offset

    // --- PRE-CALCULATE GREEN (depends on Y, T) ---
    // G = (y + t + 85) & 0xFF
    add  x6, x2, x11
    addi x6, x6, 85
    andi x6, x6, 0xFF
    slli x6, x6, 8          // Position G (0000GG00)

    addi x3, x0, 0          // x = 0

x_loop:
    // --- RED (depends on X, T) ---
    // R = (x + t) & 0xFF
    add  x4, x3, x11
    andi x4, x4, 0xFF
    slli x4, x4, 16         // Position R (00RR0000)

    // --- BLUE (depends on X, Y) ---
    // B = ((x ^ y) + 170) & 0xFF
    xor  x5, x3, x2
    addi x5, x5, 170
    andi x5, x5, 0xFF       // Position B (000000BB)

    // --- COMBINE ---
    // R | G | B
    or   x8, x4, x6
    or   x8, x8, x5
    
    // Alpha (0xFF)
    lui  x4, 0xFF000
    or   x8, x8, x4

    // Store
    sw   x8, 0(x25)

    // Next Pixel
    addi x25, x25, 4
    addi x3, x3, 1
    blt  x3, x29, x_loop

    // Next Row (Interlaced +4)
    addi x2, x2, 4
    blt  x2, x28, y_loop

    // Refresh & Time
    sw x0, 0(x30)
    addi x11, x11, 1
    j frame_loop
