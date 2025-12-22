// Matrix Addition Test
// Add two 16x16 matrices: C = A + B
// Verify correctness of result

// Memory Layout:
// 0x000-0x3FF: Matrix A (16x16 = 256 words)
// 0x400-0x7FF: Matrix B (16x16 = 256 words)
// 0x800-0xBFF: Matrix C (Result)

.text
.globl _start

_start:
    // Initialize Matrix A: A[i][j] = i
    addi x10, x0, 0      // base A
    addi x11, x0, 0      // row i
    
fill_A:
    addi x12, x0, 0      // col j
fill_A_row:
    // Value = i
    add x13, x0, x11
    
    // Address
    slli x14, x11, 4
    add x14, x14, x12
    slli x14, x14, 2
    add x15, x10, x14
    sw x13, 0(x15)
    
    addi x12, x12, 1
    addi x14, x0, 16
    blt x12, x14, fill_A_row
    
    addi x11, x11, 1
    addi x14, x0, 16
    blt x11, x14, fill_A

// Initialize Matrix B: B[i][j] = j
    addi x10, x0, 0x400  // base B
    addi x11, x0, 0
    
fill_B:
    addi x12, x0, 0
fill_B_row:
    // Value = j
    add x13, x0, x12
    
    slli x14, x11, 4
    add x14, x14, x12
    slli x14, x14, 2
    add x15, x10, x14
    sw x13, 0(x15)
    
    addi x12, x12, 1
    addi x14, x0, 16
    blt x12, x14, fill_B_row
    
    addi x11, x11, 1
    addi x14, x0, 16
    blt x11, x14, fill_B

// Compute C = A + B
    addi x10, x0, 0      // base A
    addi x20, x0, 0x400  // base B
    addi x21, x0, 0x800  // base C
    addi x11, x0, 0      // row
    
add_matrices:
    addi x12, x0, 0      // col
add_row:
    // Calculate offset
    slli x14, x11, 4
    add x14, x14, x12
    slli x14, x14, 2
    
    // Load A[i][j]
    add x15, x10, x14
    lw x16, 0(x15)
    
    // Load B[i][j]
    add x15, x20, x14
    lw x17, 0(x15)
    
    // C[i][j] = A[i][j] + B[i][j]
    add x18, x16, x17
    
    // Store C[i][j]
    add x15, x21, x14
    sw x18, 0(x15)
    
    addi x12, x12, 1
    addi x14, x0, 16
    blt x12, x14, add_row
    
    addi x11, x11, 1
    addi x14, x0, 16
    blt x11, x14, add_matrices

// Verification: C[5][7] should be 5 + 7 = 12
    addi x22, x0, 0x800
    addi x23, x0, 5
    slli x23, x23, 4
    addi x24, x0, 7
    add x23, x23, x24
    slli x23, x23, 2
    add x23, x22, x23
    lw x25, 0(x23)
    
    addi x26, x0, 12
    beq x25, x26, pass
    
fail:
    ebreak

pass:
    addi x1, x0, 0xFACE
    ebreak
