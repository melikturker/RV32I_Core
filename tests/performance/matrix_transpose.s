# ============================================================
# Matrix Transpose Benchmark - Performance Test (TINY + SIGNATURE)
# ============================================================
# Measures: Non-sequential memory access, cache behavior
# Size: 8x8 matrix (optimized for fast simulation)
# Validation: Signature-based (0xFACECAFE at 0x400)
# ============================================================

.text
.globl _start

_start:
    # Source matrix at 0x2000, Dest at 0x2100
    addi s0, x0, 1
    slli s0, s0, 13         # s0 = 0x2000 (source)
    
    addi s1, x0, 1
    slli s1, s1, 13
    addi s1, s1, 0x100      # s1 = 0x2100 (dest)
    
    # Initialize 8x8 matrix: M[i][j] = i*8 + j
    addi t0, x0, 0          # row
    addi t6, x0, 8          # DIM
    
init_row:
    addi t1, x0, 0          # col
init_col:
    slli t2, t0, 3          # row * 8
    add  t2, t2, t1         # row*8 + col
    
    slli t3, t0, 3
    add  t3, t3, t1
    slli t3, t3, 2          # offset in bytes
    add  t4, s0, t3
    sw   t2, 0(t4)          # source[row][col] = value
    
    addi t1, t1, 1
    blt  t1, t6, init_col
    
    addi t0, t0, 1
    blt  t0, t6, init_row
    
    # Transpose: dest[j][i] = source[i][j]
    addi t0, x0, 0          # row
transpose_row:
    addi t1, x0, 0          # col
transpose_col:
    # Read source[row][col]
    slli t2, t0, 3
    add  t2, t2, t1
    slli t2, t2, 2
    add  t3, s0, t2
    lw   t4, 0(t3)
    
    # Write dest[col][row]
    slli t2, t1, 3
    add  t2, t2, t0
    slli t2, t2, 2
    add  t3, s1, t2
    sw   t4, 0(t3)
    
    addi t1, t1, 1
    blt  t1, t6, transpose_col
    
    addi t0, t0, 1
    blt  t0, t6, transpose_row
    
    # Verify: dest[0][1] should equal source[1][0] = 8
    lw   t0, 4(s1)          # dest[0][1]
    addi t1, x0, 8
    bne  t0, t1, fail
    
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
