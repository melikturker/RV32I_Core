# ============================================================
# Branch Stress Test - Micro Benchmark
# ============================================================
# Purpose: Test branch prediction and flush mechanism
# Pattern: 20 consecutive branches (mix of taken/not-taken)
# Validates: Pipeline flush handling under stress
# ============================================================

.text
.globl _start

_start:
    # Initialize counter
    addi x1, x0, 0      # x1 = counter
    
    # Branch 1: taken
    addi x2, x0, 5
    blt  x1, x2, br1_taken
    j fail
br1_taken:
    addi x1, x1, 1
    
    # Branch 2: not taken
    addi x2, x0, 0
    blt  x2, x1, br2_skip
    j fail
br2_skip:
    addi x1, x1, 1
    
    # Branch 3: taken
    addi x2, x0, 10
    blt  x1, x2, br3_taken
    j fail
br3_taken:
    addi x1, x1, 1
    
    # Branch 4: not taken
    addi x2, x0, 1
    blt  x2, x1, br4_skip
    j fail
br4_skip:
    addi x1, x1, 1
    
    # Branch 5-10: rapid sequence
    addi x2, x0, 20
    blt  x1, x2, br5
    j fail
br5:
    addi x1, x1, 1
    blt  x1, x2, br6
    j fail
br6:
    addi x1, x1, 1
    blt  x1, x2, br7
    j fail
br7:
    addi x1, x1, 1
    blt  x1, x2, br8
    j fail
br8:
    addi x1, x1, 1
    blt  x1, x2, br9
    j fail
br9:
    addi x1, x1, 1
    blt  x1, x2, br10
    j fail
br10:
    addi x1, x1, 1
    
    # Verify counter = 10
    addi x2, x0, 10
    bne  x1, x2, fail
    
pass:
    # Write signature
    addi t0, x0, 1
    slli t0, t0, 10
    
    addi t1, x0, 0xFA
    slli t1, t1, 8
    addi t1, t1, 0xCE
    slli t1, t1, 8
    addi t1, t1, 0xCA
    slli t1, t1, 8
    addi t1, t1, 0xFE
    
    sw   t1, 0(t0)
    ebreak

fail:
    ebreak
