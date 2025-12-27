# ============================================================
# Memcpy Benchmark - Performance Test (TINY + SIGNATURE)
# ============================================================
# Measures: Sequential memory bandwidth, load-store forwarding
# Size: 64 elements (optimized for fast simulation)
# Validation: Signature-based (0xFACECAFE at 0x400)
# ============================================================

.text
.globl _start

_start:
    # Source array at 0x2000, Dest at 0x2100
    addi t0, x0, 1
    slli t0, t0, 13         # t0 = 0x2000 (source)
    
    addi t1, x0, 1
    slli t1, t1, 13
    addi t1, t1, 0x100      # t1 = 0x2100 (dest)
    
    # Initialize source with values 0..63
    addi t2, x0, 0          # counter
    addi t3, x0, 64         # limit
    add  t4, t0, x0         # temp pointer
    
init_loop:
    sw   t2, 0(t4)
    addi t4, t4, 4
    addi t2, t2, 1
    blt  t2, t3, init_loop
    
    # Memcpy: copy 64 words from source to dest
    addi t2, x0, 0          # index
    addi t3, x0, 64         # limit
    
copy_loop:
    lw   t4, 0(t0)          # Load from source
    sw   t4, 0(t1)          # Store to dest
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, 1
    blt  t2, t3, copy_loop
    
    # Verify: check first and last elements
    addi t0, x0, 1
    slli t0, t0, 13
    addi t0, t0, 0x100      # dest start
    
    lw   t2, 0(t0)          # dest[0] should be 0
    bne  t2, x0, fail
    
    addi t0, t0, 252        # dest[63]
    lw   t2, 0(t0)
    addi t3, x0, 63
    bne  t2, t3, fail
    
pass:
    # Write signature
    addi t0, x0, 1
    slli t0, t0, 10         # 0x400
    
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
