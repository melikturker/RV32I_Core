# Backward BLT Test (Like audio_bars loops)
# Expected: 100 branches, ~99 flushes (all backward taken)

.text
.globl _start

_start:
    addi x1, x0, 0        # Counter
    addi x2, x0, 100      # Limit
    
backward_loop:
    addi x1, x1, 1        # counter++
    addi x3, x1, 5        # Some work
    blt x1, x2, backward_loop  # BACKWARD BRANCH (should flush when taken)
    
    addi x4, x0, 42
    ebreak
