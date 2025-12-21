// RV32I - Chaotic Palette Wave (Independent Drift + Alpha Chaos)
// R = Drift(X+T)
// G = Drift(Y-T)
// B = Turbulence((X^Y) + T)
// A = Breathing((X+Y) & Range)
// 2x2 Block Rendering for Performance.

.eqv VRAM_BASE,   0x00008000
.eqv REFRESH_REG, 0x00054000
.eqv SCREEN_W,    320
.eqv SCREEN_H,    240

.text
.globl _start

_start:
    lui sp, 0x10000

    lui x9, %hi(VRAM_BASE)
    addi x9, x9, %lo(VRAM_BASE)

    lui x30, %hi(REFRESH_REG)
    addi x30, x30, %lo(REFRESH_REG)

    addi x11, x0, 0          // t = 0

frame_loop:
    // Use shift for pseudo-slow time.
    srli x2, x11, 2          // slow_t = t >> 2

    // Initialize pointers
    add x25, x0, x9          // Top Ptr
    addi x28, x0, 240        // y limit

    addi x13, x0, 0          // y = 0

y_loop:
    // We update 2x2 blocks.
    // Row 1 Ptr = x25
    // Row 2 Ptr = x25 + 1280
    add x26, x25, x0
    addi x20, x0, 1280 // Constant fit in 12-bit? No (320*4). Need to construct.
    addi x20, x0, 1
    slli x20, x20, 10  // 1024
    addi x21, x0, 1
    slli x21, x21, 8   // 256
    add  x20, x20, x21 // 1280
    add  x26, x26, x20 // Bottom Ptr

    addi x12, x0, 0          // x = 0
    addi x29, x0, 320        // x limit

x_loop:
    // --- SMOOTH PLASMA ALGORITHM (No XOR) ---
    // Triangle Wave Function: T(v) = (v & 1FF) > 255 ? 511 - (v&1FF) : (v&1FF)
    
    // R = Triangle(x + t)
    add x4, x12, x11
    andi x4, x4, 0x1FF       // mod 512
    addi x22, x0, 256
    blt  x4, x22, calc_r_done
    addi x22, x0, 511
    sub  x4, x22, x4
calc_r_done:
    slli x4, x4, 16          // R Pos

    // G = Triangle(y + t*2)
    slli x22, x11, 1         // t*2
    add x5, x13, x22
    andi x5, x5, 0x1FF
    addi x22, x0, 256
    blt  x5, x22, calc_g_done
    addi x22, x0, 511
    sub  x5, x22, x5
calc_g_done:
    slli x5, x5, 8           // G Pos

    // B = Triangle(x + y - t)
    add x6, x12, x13
    sub x6, x6, x11
    andi x6, x6, 0x1FF
    addi x22, x0, 256
    blt  x6, x22, calc_b_done
    addi x22, x0, 511
    sub  x6, x22, x6
calc_b_done:
    // B is in low bits, no shift needed
    
    // A = Triangle(x - y + t) -> Breathing
    sub x7, x12, x13
    add x7, x7, x11
    andi x7, x7, 0x1FF
    addi x22, x0, 256
    blt  x7, x22, calc_a_done
    addi x22, x0, 511
    sub  x7, x22, x7
calc_a_done:
    // Compress A to 128..255 range? 
    // Currently 0..255. Let's make it 128 + (v>>1)
    srli x7, x7, 1
    addi x7, x7, 128
    slli x7, x7, 24          // A Pos

    // Combine
    or x8, x4, x5            // R | G
    or x8, x8, x6            // R | G | B
    or x8, x8, x7            // A | R | G | B

    // Store to 2x2 Block
    sw x8, 0(x25)            // Top Left
    sw x8, 4(x25)            // Top Right
    sw x8, 0(x26)            // Bot Left
    sw x8, 4(x26)            // Bot Right
    
    // Increment Ptrs (2 pixels = 8 bytes)
    addi x25, x25, 8
    addi x26, x26, 8
    
    // Increment X (2 steps)
    addi x12, x12, 2
    blt  x12, x29, x_loop

    // Next Y Row (2 steps)
    // Ptr already advanced by width.
    // Wait, x25 processed one row. But we did 2 rows.
    // So next x25 should be x26 + width? No.
    // current x25 finished row 1. x26 finished row 2.
    // Next x25 should be start of row 3.
    // Start of Row 3 = Start of Row 1 + 2 * 1280.
    // Actually simpler:
    // Ptrs advanced by Width * 4 already?
    // In x_loop, we added 8 * (320/2) = 1280.
    // So x25 is at start of Row 2.
    // We want it at Row 3.
    // So add 1280 to x25.
    // Add 1280 to x26.
    // But x_loop logic incremented x25/x26 continuously.
    // They are at end of their respective rows.
    // Just need to skip the row x26 just did (Row 2) for x25?
    // No, x25 ended at end of Row 1.
    // We want x25 to go to start of Row 3.
    // Row 1 End + Row 2 (1280) = Row 3 Start.
    
    // Re-calc Ptr Base is safer.
    // But let's just add 1280 to x25.
    add x25, x25, x20        // x25 += 1280 (Skip Row 2)
    
    addi x13, x13, 2
    blt  x13, x28, y_loop

    // Refresh & Time
    sw x0, 0(x30)
    addi x11, x11, 2         // Speed 2x
    j frame_loop
