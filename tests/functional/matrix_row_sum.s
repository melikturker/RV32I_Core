// Matrix Row Sum Test
// 16x16 matrix, compute sum of each row
// Store row sums contiguously in memory

// Memory Layout:
// 0x000-0x3FF: Input matrix (16x16 = 256 words)
// 0x400-0x43F: Output row sums (16 words)

.text
.globl _start

_start:
    // Initialize matrix with i+j pattern
    // M[i][j] = i + j
    addi x10, x0, 0      // x10 = base address (0x000)
    addi x11, x0, 0      // x11 = row index i
    
fill_matrix:
    addi x12, x0, 0      // x12 = col index j
fill_row:
    // Calculate i + j
    add x13, x11, x12
    
    // Calculate address offset: (i * 16 + j) * 4
    slli x14, x11, 4     // i * 16
    add x14, x14, x12    // i * 16 + j
    slli x14, x14, 2     // * 4 (bytes)
    add x15, x10, x14    // final address
    
    // Store value
    sw x13, 0(x15)
    
    // Increment j
    addi x12, x12, 1
    addi x14, x0, 16
    blt x12, x14, fill_row
    
    // Increment i
    addi x11, x11, 1
    addi x14, x0, 16
    blt x11, x14, fill_matrix

// Compute row sums
    addi x10, x0, 0      // x10 = matrix base
    addi x16, x0, 0x400  // x16 = output base
    addi x11, x0, 0      // x11 = row index

compute_rows:
    addi x17, x0, 0      // x17 = row sum accumulator
    addi x12, x0, 0      // x12 = col index
    
sum_row:
    // Address: (i * 16 + j) * 4
    slli x14, x11, 4
    add x14, x14, x12
    slli x14, x14, 2
    add x15, x10, x14
    
    lw x18, 0(x15)
    add x17, x17, x18    // accumulate
    
    addi x12, x12, 1
    addi x14, x0, 16
    blt x12, x14, sum_row
    
    // Store row sum
    slli x14, x11, 2     // i * 4
    add x15, x16, x14
    sw x17, 0(x15)
    
    addi x11, x11, 1
    addi x14, x0, 16
    blt x11, x14, compute_rows

// Verification: Check row 0 sum (should be 0+1+2+...+15 = 120)
    lw x20, 0(x16)
    addi x21, x0, 120
    beq x20, x21, pass
    
fail:
    ebreak

pass:
    // Success marker
    addi x1, x0, 0xCAFE
    ebreak
