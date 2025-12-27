# ============================================================
# JAL/JALR Chain Test - Micro Benchmark
# ============================================================
# Purpose: Test return address (x1) forwarding
# Pattern: Chain of 6 JAL/JALR calls
# Validates: Link register dependency handling
# ============================================================

.text
.globl _start

_start:
    addi x10, x0, 0     # x10 = accumulator
    
    # Call chain: func1 -> func2 -> func3 -> func4 -> func5 -> func6
    jal  x1, func1
    
    # Verify accumulator = 6
    addi x2, x0, 6
    bne  x10, x2, fail
    j pass

func1:
    addi x10, x10, 1
    jal  x1, func2
    jalr x0, x1, 0      # Return

func2:
    addi x10, x10, 1
    jal  x1, func3
    jalr x0, x1, 0

func3:
    addi x10, x10, 1
    jal  x1, func4
    jalr x0, x1, 0

func4:
    addi x10, x10, 1
    jal  x1, func5
    jalr x0, x1, 0

func5:
    addi x10, x10, 1
    jal  x1, func6
    jalr x0, x1, 0

func6:
    addi x10, x10, 1
    jalr x0, x1, 0      # Return to func5

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
