// Store-Load Forwarding Test
// Tests memory dependency detection and forwarding
// Pattern: SW followed by LW to same/nearby address

.text
.globl _start

_start:
    // === Test 1: Store then load same address ===
    addi x1, x0, 123
    sw x1, 0(x0)                // M[0] = 123
    lw x2, 0(x0)                // Load from M[0]
    
    // Verify x2 = 123
    addi x3, x0, 123
    bne x2, x3, fail
    
    // === Test 2: Store then load different address (no dependency) ===
    addi x4, x0, 456
    sw x4, 4(x0)                // M[4] = 456
    lw x5, 8(x0)                // Load from M[8] (different)
    
    // x5 should be 0 (uninitialized)
    bne x5, x0, fail
    
    // === Test 3: Multiple stores then loads ===
    addi x6, x0, 10
    addi x7, x0, 20
    addi x8, x0, 30
    
    sw x6, 0(x0)                // M[0] = 10
    sw x7, 4(x0)                // M[4] = 20
    sw x8, 8(x0)                // M[8] = 30
    
    lw x9, 0(x0)                // Load 10
    lw x10, 4(x0)               // Load 20
    lw x11, 8(x0)               // Load 30
    
    // Sum should be 60
    add x12, x9, x10
    add x12, x12, x11
    
    addi x13, x0, 60
    bne x12, x13, fail
    
    // === Test 4: Store-load with offset calculation ===
    addi x14, x0, 12            // Base offset
    sw x14, 0(x14)              // M[12] = 12
    lw x15, 0(x14)              // Load from M[12]
    
    // Verify x15 = 12
    bne x14, x15, fail
    
    // === Test 5: Overlapping word access ===
    addi x16, x0, 0x7CD         // Use 12-bit safe value
    sw x16, 16(x0)              // M[16] = 0x7CD
    lw x17, 16(x0)              // Immediate load-back
    
    // Verify exact match
    bne x16, x17, fail
    
pass:
    addi x31, x0, 0xAA   # Signature: PASS
    ebreak

fail:
    addi x31, x0, 0xFF   # Signature: FAIL
    ebreak
