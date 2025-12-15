// RISC-V Assembly: Colors Demo
// Adapted from ARM implementation for RV32I Core
// Maps direct framebuffer writes instead of register-based controller.

// Constants
.eqv VRAM_BASE, 0x00008000
.eqv WIDTH, 32
.eqv HEIGHT, 32
.eqv MAX_PIXELS, 1024  // 32*32

.text
.globl _start

_start:
    // x10 = VRAM Base Address (0x8000)
    // 0x8000 is 32768. 32768 >> 12 = 8.
    lui x10, 8
    
// 320x240 Colors Demo (Bulk Transfer Mode)
    .eqv WIDTH 320
    .eqv HEIGHT 240
    // MAX_PIXELS = 320*240 = 76800
    .eqv VRAM_BASE 0x00008000
    .eqv REFRESH_REG 0x00054000

    // x1 = Color accumulator (Start with RED RGB 0x00FF0000)
    lui x1, 0x00FF0
    
// Main infinite loop
frame_loop:
    // x2 = Pixel Counter
    addi x2, x0, 0
    
    // x3 = Current Address
    lui x3, %hi(VRAM_BASE)
    addi x3, x3, %lo(VRAM_BASE)

    // x4 = Max Pixels (76800)
    // 300 * 256
    addi x4, x0, 300
    slli x4, x4, 8
    // 76800 correct.

pixel_loop:
    // Combine RGB (x1) with Alpha (0xFF000000)
    lui x5, 0xFF000
    add x6, x1, x5
    sw x6, 0(x3)
    
    addi x3, x3, 4
    addi x2, x2, 1
    blt x2, x4, pixel_loop
    
    // --- Screen Painted (76800 Writes Done) ---
    // Now trigger bulk dump to Python
    
    // Trigger Refresh (Write to REFRESH_REG)
    lui x6, %hi(REFRESH_REG)
    sw x0, %lo(REFRESH_REG)(x6)
    
    // Change Color for next frame
    // Target: 0x00030507 (R+=3, G+=5, B+=7)
    lui x5, 48 
    addi x5, x5, 1287
    add x1, x1, x5
    
    // Clear top 8 bits to prevent overflow into Alpha during add
    slli x1, x1, 8
    srli x1, x1, 8
    
    j frame_loop

// End of execution
    ebreak
