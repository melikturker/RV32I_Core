# ============================================================
# Array Sum Benchmark - Performance Test (TINY + SIGNATURE)
# ============================================================
# Measures: Load-use hazards, ALU forwarding, memory throughput
# Size: 64 elements (optimized for fast simulation)
# Validation: Signature-based (0xFACECAFE at 0x400)
# ============================================================

.text
.globl _start

_start:
    # Build array at address 0x2000 (safe area in D_mem)
    addi t0, x0, 1
    slli t0, t0, 13         # t0 = 0x2000 (8KB offset)
    
    # Initialize 64 elements with sequential values (0..63)
    addi t1, x0, 0          # counter
    addi t2, x0, 64         # limit
    
init_loop:
    sw   t1, 0(t0)          # array[i] = i
    addi t0, t0, 4
    addi t1, t1, 1
    blt  t1, t2, init_loop
    
    # Reset pointer to array start
    addi t0, x0, 1
    slli t0, t0, 13         # t0 = 0x2000
    
    # Sum array (0+1+2+...+63 = 2016)
    addi t3, x0, 0          # sum = 0
    addi t1, x0, 0          # index = 0
    addi t2, x0, 64         # limit
    
sum_loop:
    lw   t4, 0(t0)          # Load array[i]
    add  t3, t3, t4         # sum += array[i]
    addi t0, t0, 4
    addi t1, t1, 1
    blt  t1, t2, sum_loop
    
    # Verify sum = 2016 (0x7E0)
    addi t5, x0, 0x7E0
    bne  t3, t5, fail
    
pass:
    addi x31, x0, 0xAA   # Signature: PASS
    ebreak

fail:
    addi x31, x0, 0xFF   # Signature: FAIL
    ebreak
