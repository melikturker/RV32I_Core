// RAW (Read-After-Write) Hazard Test
// Tests data forwarding for back-to-back ALU operations
// Pattern: Write x1, then immediately use x1 as source

.text
.globl _start

_start:
    // === Test 1: EX->EX forwarding (1 cycle apart) ===
    addi x1, x0, 10      // x1 = 10
    addi x2, x1, 5       // x2 = x1 + 5 = 15 (needs forwarding from EX)
    
    // Verify x2 = 15
    addi x3, x0, 15
    bne x2, x3, fail
    
    // === Test 2: MEM->EX forwarding (2 cycles apart) ===
    addi x4, x0, 20      // x4 = 20
    addi x5, x0, 3       // x5 = 3 (1 cycle gap)
    add x6, x4, x5       // x6 = x4 + x5 = 23 (forward from MEM)
    
    // Verify x6 = 23
    addi x7, x0, 23
    bne x6, x7, fail
    
    // === Test 3: Chain dependency ===
    addi x8, x0, 1       // x8 = 1
    slli x9, x8, 2       // x9 = x8 << 2 = 4
    add x10, x9, x8      // x10 = x9 + x8 = 5
    slli x11, x10, 1     // x11 = x10 << 1 = 10
    
    // Verify x11 = 10
    addi x12, x0, 10
    bne x11, x12, fail
    
    // === Test 4: Multiple source operands ===
    addi x13, x0, 7      // x13 = 7
    add x14, x13, x13    // x14 = x13 + x13 = 14 (both ops need forwarding)
    
    // Verify x14 = 14
    addi x15, x0, 14
    bne x14, x15, fail
    
pass:
    addi x1, x0, 0xFACE
    ebreak

fail:
    ebreak
