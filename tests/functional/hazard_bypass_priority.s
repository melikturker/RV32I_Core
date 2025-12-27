# ============================================================
# Bypass Priority Test - Micro Benchmark
# ============================================================
# Purpose: Test forwarding priority (EX vs MEM stage)
# Pattern: Create scenario where both EX and MEM have same register
# Validates: Correct bypass path selection (EX should have priority)
# ============================================================

.text
.globl _start

_start:
    # Setup: Create a scenario where x3 is in both EX and MEM stages
    
    # Test 1: EX-to-EX forwarding (most recent should win)
    addi x3, x0, 10     # x3 = 10 (will be in MEM stage)
    addi x3, x0, 20     # x3 = 20 (will be in EX stage)
    add  x4, x3, x0     # Should use 20, not 10
    
    addi x5, x0, 20
    bne  x4, x5, fail
    
    # Test 2: Load-use with intervening instruction
    addi x6, x0, 0x100
    sw   x0, 0(x6)      # Memory[0x100] = 0
    addi x7, x0, 30
    sw   x7, 0(x6)      # Memory[0x100] = 30
    lw   x8, 0(x6)      # x8 = 30 (load)
    addi x8, x0, 40     # x8 = 40 (overwrite immediately)
    add  x9, x8, x0     # Should use 40
    
    addi x10, x0, 40
    bne  x9, x10, fail
    
    # Test 3: Chain with multiple dependencies
    addi x11, x0, 1
    addi x11, x11, 2    # x11 = 3
    addi x11, x11, 3    # x11 = 6
    addi x11, x11, 4    # x11 = 10
    add  x12, x11, x0   # x12 = 10
    
    addi x13, x0, 10
    bne  x12, x13, fail
    
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
