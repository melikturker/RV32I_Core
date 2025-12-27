// x0 Register Corner Case Test
// Verifies x0 is always hardwired to zero
// Any writes to x0 should be ignored

.text
.globl _start

_start:
    // === Test 1: Read x0 (should be 0) ===
    addi x1, x0, 0
    bne x1, x0, fail
    
    // === Test 2: Write to x0 (should be ignored) ===
    addi x0, x0, 100            // Try to set x0 = 100
    addi x2, x0, 0              // Read x0
    bne x2, x0, fail            // Should still be 0
    
    // === Test 3: Use x0 as both source ops ===
    add x3, x0, x0              // 0 + 0 = 0
    bne x3, x0, fail
    
    // === Test 4: Store and load via x0 base ===
    addi x4, x0, 42
    sw x4, 0(x0)                // M[0] = 42
    lw x5, 0(x0)                // Load from M[0]
    
    addi x6, x0, 42
    bne x5, x6, fail
    
    // === Test 5: Arithmetic with x0 ===
    addi x7, x0, 99
    add x8, x7, x0              // 99 + 0 = 99
    sub x9, x7, x0              // 99 - 0 = 99
    
    addi x10, x0, 99
    bne x8, x10, fail
    bne x9, x10, fail
    
    // === Test 6: Logical ops with x0 ===
    ori x11, x0, 0xFF           // 0 | 0xFF = 0xFF
    andi x12, x0, 0xFF          // 0 & 0xFF = 0
    
    addi x13, x0, 0xFF
    bne x11, x13, fail
    bne x12, x0, fail
    
pass:
    addi x1, x0, 0x0000
    ebreak

fail:
    ebreak
