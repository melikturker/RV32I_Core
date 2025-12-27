// Signature-Based Test - Minimal Example
// Writes 0xFACECAFE to address 0x400

.text
.globl _start

_start:
    // Quick test: 10 + 20 = 30
    addi x1, x0, 10
    addi x2, x0, 20
    add  x3, x1, x2
    addi x4, x0, 30
    bne  x3, x4, fail
    
pass:
    // Build address 0x400 = 1024
    addi t0, x0, 1       // t0 = 1
    slli t0, t0, 10      // t0 = 1 << 10 = 1024 = 0x400
    
    // Build signature 0xFACECAFE byte by byte
    addi t1, x0, 0xFA    // t1 = 0xFA
    slli t1, t1, 8       // t1 = 0xFA00
    addi t1, t1, 0xCE    // t1 = 0xFACE
    slli t1, t1, 8       // t1 = 0xFACE00
    addi t1, t1, 0xCA    // t1 = 0xFACECA
    slli t1, t1, 8       // t1 = 0xFACECA00
    addi t1, t1, 0xFE    // t1 = 0xFACECAFE
    
    sw   t1, 0(t0)       // Write to 0x400
    ebreak

fail:
    addi t0, x0, 1
    slli t0, t0, 10      // 0x400
    addi t1, x0, 0xEF    // Wrong signature
    sw   t1, 0(t0)
    ebreak
