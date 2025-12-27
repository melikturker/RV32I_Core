# ============================================================
# Shift Chain Test - Micro Benchmark
# ============================================================
# Purpose: Test shift unit with dependencies
# Pattern: Maximum shifts (31 bits) with immediate use
# Validates: Shift-then-use hazard handling
# ============================================================

.text
.globl _start

_start:
    # Test 1: Maximum left shift
    addi x1, x0, 1
    slli x2, x1, 31     # x2 = 0x80000000
    srli x3, x2, 31     # x3 = 1 (shift back)
    
    addi x4, x0, 1
    bne  x3, x4, fail
    
    # Test 2: Shift chain with dependency
    addi x5, x0, 0xFF
    slli x6, x5, 8      # x6 = 0xFF00
    slli x7, x6, 8      # x7 = 0xFF0000 (use x6 immediately)
    slli x8, x7, 8      # x8 = 0xFF000000 (use x7 immediately)
    
    # Verify x8 = 0xFF000000
    lui  x9, 0xFF000
    bne  x8, x9, fail
    
    # Test 3: Arithmetic right shift with sign extension
    addi x10, x0, -1    # x10 = 0xFFFFFFFF
    srai x11, x10, 1    # x11 = 0xFFFFFFFF (sign extended)
    srai x12, x11, 15   # x12 = 0xFFFFFFFF
    
    addi x13, x0, -1
    bne  x12, x13, fail
    
    # Test 4: Shift-then-add dependency
    addi x14, x0, 5
    slli x15, x14, 2    # x15 = 20
    add  x16, x15, x14  # x16 = 25 (use x15 immediately)
    
    addi x17, x0, 25
    bne  x16, x17, fail
    
    # Test 5: Variable shift (using register)
    addi x18, x0, 0x100
    addi x19, x0, 4
    sll  x20, x18, x19  # x20 = 0x1000
    
    addi x21, x0, 1
    slli x21, x21, 12   # x21 = 0x1000
    bne  x20, x21, fail
    
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
