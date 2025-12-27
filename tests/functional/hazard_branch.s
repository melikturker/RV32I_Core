// Branch/Control Hazard Test
// Tests branch prediction and pipeline flushing
// Verifies correct handling of taken/not-taken branches

.text
.globl _start

_start:
    // === Test 1: Simple taken branch ===
    addi x1, x0, 10
    addi x2, x0, 5
    blt x2, x1, branch1_taken   // 5 < 10, should take branch
    
    // Should NOT execute (misfetch)
    addi x3, x0, 999
    j fail
    
branch1_taken:
    // Verify we got here
    addi x3, x0, 1
    
    // === Test 2: Not-taken branch ===
    addi x4, x0, 20
    addi x5, x0, 30
    blt x5, x4, fail            // 30 < 20? NO, fall through
    
    // Should execute
    addi x6, x0, 2
    
    // === Test 3: Backward branch (loop) ===
    addi x7, x0, 0              // counter
    addi x8, x0, 5              // limit
    
loop:
    addi x7, x7, 1
    blt x7, x8, loop            // count to 5
    
    // Verify x7 = 5
    addi x9, x0, 5
    bne x7, x9, fail
    
    // === Test 4: JAL (unconditional jump) ===
    jal x10, jump_target
    
    // Should skip this
    addi x11, x0, 999
    j fail
    
jump_target:
    // Verify return address in x10
    // Should be PC+4 of jal instruction
    addi x11, x0, 42
    
    // === Test 5: JALR (indirect jump) ===
    lui x12, %hi(jalr_target)
    addi x12, x12, %lo(jalr_target)
    jalr x13, 0(x12)
    
    // Should skip
    j fail
    
jalr_target:
    addi x14, x0, 55
    
    // === Test 6: Branch with dependency ===
    addi x15, x0, 100
    addi x16, x15, 50           // x16 = 150
    blt x15, x16, pass          // 100 < 150, jump to pass
    
fail:
    addi x31, x0, 0xFF   # Signature: FAIL
    ebreak

pass:
    addi x31, x0, 0xAA   # Signature: PASS
    ebreak
