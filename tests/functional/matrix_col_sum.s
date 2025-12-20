// Matrix Column Sum Test
// 16x16 matrix, compute sum of each column
// Store column sums contiguously in memory

// Memory Layout:
// 0x000-0x3FF: Input matrix (16x16 = 256 words)
// 0x400-0x43F: Output column sums (16 words)

.text
.globl _start

_start:
    // Initialize matrix with i*2 + j pattern
    // M[i][j] = i*2 + j
    addi x10, x0, 0      // x10 = base address
    addi x11, x0, 0      // x11 = row index i
    
fill_matrix:
    addi x12, x0, 0      // x12 = col index j
fill_row:
    // Calculate i*2 + j
    slli x13, x11, 1     // i*2
    add x13, x13, x12    // i*2 + j
    
    // Address: (i * 16 + j) * 4
    slli x14, x11, 4
    add x14, x14, x12
    slli x14, x14, 2
    add x15, x10, x14
    
    sw x13, 0(x15)
    
    addi x12, x12, 1
    addi x14, x0, 16
    blt x12, x14, fill_row
    
    addi x11, x11, 1
    addi x14, x0, 16
    blt x11, x14, fill_matrix

// Compute column sums
    addi x10, x0, 0      // matrix base
    addi x16, x0, 0x400  // output base
    addi x12, x0, 0      // x12 = col index

compute_cols:
    addi x17, x0, 0      // x17 = column sum
    addi x11, x0, 0      // x11 = row index
    
sum_col:
    // Address: (i * 16 + j) * 4
    slli x14, x11, 4
    add x14, x14, x12
    slli x14, x14, 2
    add x15, x10, x14
    
    lw x18, 0(x15)
    add x17, x17, x18
    
    addi x11, x11, 1
    addi x14, x0, 16
    blt x11, x14, sum_col
    
    // Store column sum
    slli x14, x12, 2
    add x15, x16, x14
    sw x17, 0(x15)
    
    addi x12, x12, 1
    addi x14, x0, 16
    blt x12, x14, compute_cols

// Verification: Check col 0 sum
// Col 0: M[i][0] = i*2 + 0 = 0,2,4,...,30
// Sum = 2*(0+1+2+...+15) = 2*120 = 240
    lw x20, 0(x16)
    addi x21, x0, 240
    beq x20, x21, pass
    
fail:
    ebreak

pass:
    addi x1, x0, 0xBEEF
    ebreak
