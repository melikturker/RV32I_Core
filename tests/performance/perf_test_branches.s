# Performance Counter Test Program 3: Conditional Branches
# Expected:
#   - Instructions: ~10
#   - Conditional branches: 3 (1 not taken, 2 taken)
#   - Flushes: 2 (only taken branches cause flush)

.text
.globl _start

_start:
    addi x1, x0, 100      # 1
    addi x2, x0, 50       # 2
    
    # Branch 1: NOT TAKEN (no flush)
    blt x1, x2, skip1     # 3 - NOT TAKEN (100 < 50? NO)
    addi x3, x0, 1        # 4 - executed
    
skip1:
    # Branch 2: TAKEN (flush occurs)
    addi x4, x0, 10       # 5
    addi x5, x0, 20       # 6
    blt x4, x5, skip2     # 7 - TAKEN (10 < 20? YES) -> FLUSH
    addi x6, x0, 999      # Should be flushed
    
skip2:
    # Branch 3: TAKEN (flush occurs)
    addi x7, x0, 30       # 8
    beq x7, x7, skip3     # 9 - TAKEN (30 == 30? YES) -> FLUSH
    addi x8, x0, 888      # Should be flushed
    
skip3:
    addi x9, x0, 42       # 10
    
    # Exit
    ebreak
