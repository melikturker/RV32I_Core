# Minimal JAL Test
# Expected: 1 unconditional jump, 1 flush

.text
.globl _start

_start:
    addi x1, x0, 100
    jal x2, target        # JAL - should flush next instruction
    addi x3, x0, 999      # This should be flushed
    
target:
    addi x4, x0, 42
    ebreak
