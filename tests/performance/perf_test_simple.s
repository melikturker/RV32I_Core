# Performance Counter Test Program 1: Simple Linear Code
# Expected: 10 instructions, ~12 cycles (startup overhead), 0 branches, 0 flushes

.text
.globl _start

_start:
    # Linear code - no branches, no hazards
    addi x1, x0, 100      # 1 instruction
    addi x2, x0, 200      # 2
    add  x3, x1, x2       # 3
    addi x4, x0, 50       # 4
    sub  x5, x3, x4       # 5
    addi x6, x0, 10       # 6
    slli x7, x6, 2        # 7
    addi x8, x0, 0xFF     # 8
    andi x9, x8, 0x0F     # 9
    add  x10, x9, x7      # 10
    
    # Exit
    ebreak
