.text
.globl _start

_start:
    # Setup memory
    addi x1, x0, 10
    sw x1, 0(x0)      # M[0] = 10
    addi x2, x0, 20
    sw x2, 4(x0)      # M[4] = 20
    
    # The Critical Pattern: Back-to-back Loads
    lw x3, 0(x0)      # x3 = 10
    lw x4, 4(x0)      # x4 = 20
    
    # Check Result (Stall should happen here due to x4 usage)
    add x5, x3, x4    # x5 = 30
    
    # Verification
    addi x6, x0, 30
    bne x5, x6, fail
    
pass:
    addi x31, x0, 0xAA   # Signature: PASS
    ebreak

fail:
    addi x31, x0, 0xFF   # Signature: FAIL
    ebreak
