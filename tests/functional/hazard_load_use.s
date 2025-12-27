// Load-Use Hazard Test
// Tests pipeline stall when load result is immediately used
// Pattern: LW followed by instruction using loaded value

.text
.globl _start

_start:
    // Setup: Store test values to memory
    addi x1, x0, 42
    sw x1, 0(x0)         // M[0] = 42
    
    addi x2, x0, 100
    sw x2, 4(x0)         // M[4] = 100
    
    addi x3, x0, 77
    sw x3, 8(x0)         // M[8] = 77
    
    // === Test 1: Basic load-use stall ===
    lw x4, 0(x0)         // Load x4 from M[0] = 42
    addi x5, x4, 8       // Use x4 immediately (MUST stall 1 cycle)
    
    // Verify x5 = 50
    addi x6, x0, 50
    bne x5, x6, fail
    
    // === Test 2: Load-use with ALU op ===
    lw x7, 4(x0)         // Load x7 = 100
    slli x8, x7, 1       // x8 = x7 << 1 = 200 (stall required)
    
    // Verify x8 = 200
    addi x9, x0, 200
    bne x8, x9, fail
    
    // === Test 3: Load followed by store (use as address) ===
    addi x10, x0, 4      // x10 = 4
    sw x10, 12(x0)       // M[12] = 4
    lw x11, 12(x0)       // x11 = 4
    sw x3, 0(x11)        // M[x11] = M[4] = 77 (use loaded value as addr)
    
    // Verify M[4] = 77
    lw x12, 4(x0)
    addi x13, x0, 77
    bne x12, x13, fail
    
    // === Test 4: Back-to-back loads with dependency ===
    lw x14, 0(x0)        // x14 = M[0] = 42
    lw x15, 8(x0)        // x15 = M[8] = 77
    add x16, x14, x15    // x16 = 42 + 77 = 119 (both may need stall)
    
    // Verify x16 = 119
    addi x17, x0, 119
    bne x16, x17, fail
    
pass:
    addi x31, x0, 0xAA   # Signature: PASS
    ebreak

fail:
    addi x31, x0, 0xFF   # Signature: FAIL
    ebreak
