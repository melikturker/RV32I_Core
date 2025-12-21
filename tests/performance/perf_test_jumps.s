# Performance Counter Test Program 2: Unconditional Jumps
# Expected:
#   - Instructions: 7 (excluding ebreak)
#   - Unconditional jumps: 2 (JAL + JALR)
#   - Flushes: 2 (each jump causes flush)
#   - Flush cycles: 2 flushes

.text
.globl _start

_start:
    addi x1, x0, 100      # 1
    jal x2, target1       # 2 - UNCONDITIONAL JUMP (causes flush)
    addi x3, x0, 999      # Should be flushed
    
target1:
    addi x4, x0, 200      # 3
    addi x5, x1, x4       # 4
    auipc x6, 0           # 5 - Load PC into x6
    addi x6, x6, 12       # 6 - Add offset to target2
    jalr x7, x6, 0        # 7 - UNCONDITIONAL JUMP (causes flush)
    addi x8, x0, 888      # Should be flushed
    
target2:
    addi x9, x0, 42       # 8
    
    # Exit
    ebreak
