# Performance Counter Test Program 4: Load-Use Hazard (Stalls)
# Expected:
#   - Stalls: 2 (load-use hazards)
#   - RAW Hazards: should be detected
#   - Forwards: some forwarding should occur

.text
.globl _start

_start:
    addi x1, x0, 0x100    # 1 - Initialize address
    
    # Store some data
    addi x2, x0, 42       # 2
    sw   x2, 0(x1)        # 3 - Store 42 to memory
    
    # Load-use hazard 1
    lw   x3, 0(x1)        # 4 - Load from memory (takes time)
    addi x4, x3, 10       # 5 - Use x3 immediately -> STALL
    
    # No hazard (gap)
    addi x5, x0, 100      # 6
    addi x6, x0, 200      # 7
    
    # Store another value
    addi x7, x0, 99       # 8
    sw   x7, 4(x1)        # 9
    
    # Load-use hazard 2
    lw   x8, 4(x1)        # 10 - Load
    add  x9, x8, x5       # 11 - Use immediately -> STALL
    
    # Some forwarding (no stall)
    addi x10, x0, 1       # 12
    addi x11, x10, 2      # 13 - x10 forwarded from EX
    addi x12, x11, 3      # 14 - x11 forwarded from MEM
    
    # Exit
    ebreak
