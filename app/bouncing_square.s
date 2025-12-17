// RV32I - Bouncing Color Square (Ghosting)
// Physics:
// - Position: x12 (px), x13 (py)
// - Velocity: x14 (vx), x15 (vy) 
// - Bounding Box: SQ_SIZE x SQ_SIZE pixels.
// - Max X: 320 - SQ_SIZE
// - Max Y: 240 - SQ_SIZE

.eqv VRAM_BASE,   0x00008000
.eqv REFRESH_REG, 0x00054000
.eqv SQ_SIZE,     25  // Change this to resize the square!

.text
.globl _start

_start:
    lui sp, 0x10000

    lui x9, %hi(VRAM_BASE)
    addi x9, x9, %lo(VRAM_BASE)

    lui x30, %hi(REFRESH_REG)
    addi x30, x30, %lo(REFRESH_REG)

    // RNG Seed Init
    lui x7, 0xC3A26
    addi x7, x7, 0x4B5
    
    // Initial State
    addi x12, x0, 10     // px
    addi x13, x0, 20     // py
    addi x14, x0, 1      // vx (+1)
    addi x15, x0, 1      // vy (+1)
    
    // Initial Color (Light Blue: 0xFF33AAFF)
    lui x8, 0xFF33B
    addi x8, x8, 0xAFF
    
frame_loop:
    // --- 1. PHYSICS UPDATE ---
    add x12, x12, x14         // px += vx
    add x13, x13, x15         // py += vy

    // --- 2. BOUNCE CHECKS ---
    // Min X Check (< 1)
    addi x20, x0, 1
    blt x12, x20, bounce_x_min
    
    // Max X Check (>= 320 - SQ_SIZE)
    addi x20, x0, 320-SQ_SIZE
    bge x12, x20, bounce_x_max
    j check_y

bounce_x_min:
    addi x12, x0, 0           // Clamp X=0
    bge x14, x0, check_y      // If vx >= 0, skip
    sub x14, x0, x14          // vx = -vx
    jal ra, change_color
    j check_y

bounce_x_max:
    addi x12, x0, 320-SQ_SIZE // Clamp X Max
    blt x14, x0, check_y      // If vx < 0, skip
    sub x14, x0, x14          // vx = -vx
    jal ra, change_color
    j check_y

check_y:
    // Min Y Check (< 1)
    addi x20, x0, 1
    blt x13, x20, bounce_y_min
    
    // Max Y Check (>= 240 - SQ_SIZE)
    addi x20, x0, 240-SQ_SIZE
    bge x13, x20, bounce_y_max
    j draw_square

bounce_y_min:
    addi x13, x0, 0           // Clamp Y=0
    bge x15, x0, draw_square  // If vy >= 0, skip
    sub x15, x0, x15          // vy = -vy
    jal ra, change_color
    j draw_square

bounce_y_max:
    addi x13, x0, 240-SQ_SIZE // Clamp Y Max
    blt x15, x0, draw_square  // If vy < 0, skip
    sub x15, x0, x15          // vy = -vy
    jal ra, change_color
    j draw_square

    // --- 3. DRAW SQUARE (SQ_SIZE) ---
draw_square:
    addi x16, x0, 0           // sy
    addi x28, x0, SQ_SIZE
    
sq_y:
    addi x17, x0, 0           // sx

sq_x:
    // USE SAFE REGISTERS: x22, x23
    add  x22, x13, x16        // y = py + sy
    add  x23, x12, x17        // x = px + sx

    // addr = base + 4*((y<<8)+(y<<6)+x)
    slli x20, x22, 8
    slli x21, x22, 6
    add  x20, x20, x21
    add  x20, x20, x23
    slli x20, x20, 2
    add  x20, x20, x9
    sw   x8, 0(x20)

    addi x17, x17, 1
    blt  x17, x28, sq_x

    addi x16, x16, 1
    blt  x16, x28, sq_y

    // --- 4. REFRESH & DELAY ---
    sw x0, 0(x30)
    
    // Delay Loop
    lui x29, 0x1
delay:
    addi x29, x29, -1
    bnez x29, delay

    j frame_loop

// --- Subroutine: Change Color ---
change_color:
    // XOR Shift
    slli x20, x7, 13
    xor x7, x7, x20
    srli x20, x7, 17
    xor x7, x7, x20
    slli x20, x7, 5
    xor x7, x7, x20
    
    add x8, x0, x7
    lui x21, 0xFF000
    or x8, x8, x21
    
    ret
