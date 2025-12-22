# ============================================================
# Matrix Transpose Benchmark - Performance Test
# ============================================================
# Measures: Non-sequential memory access, cache behavior (stride)
#
# PARAMETRIC CONFIGURATION:
# To change matrix size, modify ALL sections below:
#
# 64×64   (4096):    MATRIX_DIM=64,  TOTAL_ELEMENTS=4096,  lui x12/x22/x28=1
# 128×128 (16384):   MATRIX_DIM=128, TOTAL_ELEMENTS=16384, lui x12/x22/x28=4
# 256×256 (65536):   MATRIX_DIM=256, TOTAL_ELEMENTS=65536, lui x12/x22/x28=16
#
# Transpose: dest[j][i] = src[i][j]
# Expected result: Transpose verified (result=1)
# ============================================================

.eqv MATRIX_DIM, 128
.eqv TOTAL_ELEMENTS, 16384   # MATRIX_DIM * MATRIX_DIM

.data
.align 2
source_matrix:
    .fill 16384, 4, 0        # Must match TOTAL_ELEMENTS

transposed_matrix:
    .fill 16384, 4, 0        # Must match TOTAL_ELEMENTS

.text
.globl _start

_start:
    # ============================================================
    # INITIALIZATION (not measured)
    # ============================================================
    lui sp, 0x10000
    
    # Initialize source matrix with value = row * DIM + col
    lui x10, %hi(source_matrix)
    addi x10, x10, %lo(source_matrix)   # x10 = source base address
    
    addi x11, x0, 0                      # x11 = row
    addi x12, x0, MATRIX_DIM             # x12 = MATRIX_DIM constant
    
init_row_loop:
    addi x13, x0, 0                      # x13 = col
    
init_col_loop:
    # Calculate value = row * DIM + col
    # row * 128 = row << 7 (since 128 = 2^7)
    slli x14, x11, 7                     # x14 = row * 128
    add x14, x14, x13                    # x14 = row * 128 + col
    
    # Calculate offset = (row * DIM + col) * 4
    slli x15, x11, 7                     # x15 = row * 128
    add x15, x15, x13                    # x15 = row * 128 + col
    slli x15, x15, 2                     # x15 = offset in bytes
    
    add x16, x10, x15                    # x16 = &source[row][col]
    sw x14, 0(x16)                       # source[row][col] = value
    
    addi x13, x13, 1                     # col++
    blt x13, x12, init_col_loop
    
    addi x11, x11, 1                     # row++
    blt x11, x12, init_row_loop
    
    # Get destination address
    lui x17, %hi(transposed_matrix)
    addi x17, x17, %lo(transposed_matrix)  # x17 = destination base address
    
    # ============================================================
    # BENCHMARK START (measurement begins here)
    # ============================================================
benchmark_start:
    
    addi x20, x0, 0                      # x20 = row
    addi x22, x0, MATRIX_DIM             # x22 = MATRIX_DIM constant
    
transpose_row_loop:
    addi x21, x0, 0                      # x21 = col
    
transpose_col_loop:
    # Read source[row][col]
    # row * 128 = row << 7
    slli x23, x20, 7                     # x23 = row * 128
    add x23, x23, x21                    # x23 = row * 128 + col
    slli x23, x23, 2                     # x23 = offset in bytes
    add x24, x10, x23                    # x24 = &source[row][col]
    lw x25, 0(x24)                       # x25 = source[row][col] ← Load
    
    # Write dest[col][row] (transpose)
    # col * 128 = col << 7
    slli x26, x21, 7                     # x26 = col * 128
    add x26, x26, x20                    # x26 = col * 128 + row
    slli x26, x26, 2                     # x26 = offset in bytes
    add x27, x17, x26                    # x27 = &dest[col][row]
    sw x25, 0(x27)                       # dest[col][row] = x25 ← Store
    
    addi x21, x21, 1                     # col++
    blt x21, x22, transpose_col_loop
    
    addi x20, x20, 1                     # row++
    blt x20, x22, transpose_row_loop
    
    # ============================================================
    # BENCHMARK END
    # ============================================================
    
    # Verification: Sample check - verify first row and first column
    # Check dest[0][i] == source[i][0] for all i
    addi x28, x0, 0                      # x28 = verify_index
    addi x29, x0, MATRIX_DIM             # x29 = MATRIX_DIM
    addi x30, x0, 1                      # x30 = result = 1 (success)
    
verify_loop:
    # Check dest[0][i] == source[i][0]
    # dest[0][i] offset = (0 * DIM + i) * 4 = i * 4
    slli x23, x28, 2                     # x23 = i * 4
    add x24, x17, x23                    # x24 = &dest[0][i]
    lw x25, 0(x24)                       # x25 = dest[0][i]
    
    # source[i][0] offset = (i * DIM + 0) * 4 = i * 128 * 4
    # i * 128 = i << 7
    slli x23, x28, 7                     # x23 = i * 128
    slli x23, x23, 2                     # x23 = i * 128 * 4
    add x24, x10, x23                    # x24 = &source[i][0]
    lw x26, 0(x24)                       # x26 = source[i][0]
    
    bne x25, x26, verify_fail            # If mismatch, fail
    
    addi x28, x28, 1                     # verify_index++
    blt x28, x29, verify_loop
    
    j verify_done
    
verify_fail:
    addi x30, x0, 0                      # result = 0 (fail)
    
verify_done:
    # Store result for validation
    lui x31, %hi(result)
    addi x31, x31, %lo(result)
    sw x30, 0(x31)
    
    # Exit
    ebreak

.data
result: .word 0
