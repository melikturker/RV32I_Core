# Backward Branch Loop Test
# Expected:
#   - Conditional branches: 10 (loop runs 10 times)
#   - Flushes: 10 (every backward branch is TAKEN, causes flush)

.text
.globl _start

_start:
    addi x1, x0, 0        # Counter = 0
    addi x2, x0, 10       # Limit = 10
    
loop:
    addi x1, x1, 1        # counter++
    addi x3, x1, 100      # Some work
    addi x4, x3, 200      # More work
    blt x1, x2, loop      # BACKWARD BRANCH - should ALWAYS flush when taken
    
    # Exit
    addi x5, x0, 42       # Final instruction
    ebreak
