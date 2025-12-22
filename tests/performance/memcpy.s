# ============================================================
# Memcpy Benchmark - Performance Test
# ============================================================
# Measures: Sequential memory bandwidth, load-store forwarding
#
# PARAMETRIC CONFIGURATION:
# To change array size, modify BOTH sections below:
#
# 4K elements  (16KB):   ARRAY_SIZE=4096,  lui x12/x22=1
# 16K elements (64KB):   ARRAY_SIZE=16384, lui x12/x22=4
# 64K elements (256KB):  ARRAY_SIZE=65536, lui x12/x22=16
#
# Expected result: All elements copied correctly (result=1)
# ============================================================

.eqv ARRAY_SIZE, 16384

.data
.align 2
source_array:
    .fill 16384, 4, 0      # Must match ARRAY_SIZE

destination_array:
    .fill 16384, 4, 0      # Must match ARRAY_SIZE

.text
.globl _start

_start:
    # ============================================================
    # INITIALIZATION (not measured)
    # ============================================================
    lui sp, 0x10000
    
    # Initialize source array with sequential values (0..N-1)
    lui x10, %hi(source_array)
    addi x10, x10, %lo(source_array)   # x10 = source base address
    
    addi x11, x0, 0                     # x11 = counter (0..N-1)
    lui x12, 4                         # ⚠️ SIZE-DEPENDENT: 1=4K, 4=16K, 16=64K
    
init_loop:
    slli x13, x11, 2                    # x13 = offset = counter * 4
    add x14, x10, x13                   # x14 = &source[counter]
    sw x11, 0(x14)                      # source[counter] = counter
    
    addi x11, x11, 1                    # counter++
    blt x11, x12, init_loop
    
    # Get destination address
    lui x15, %hi(destination_array)
    addi x15, x15, %lo(destination_array)  # x15 = destination base address
    
    # ============================================================
    # BENCHMARK START (measurement begins here)
    # ============================================================
benchmark_start:
    
    addi x20, x0, 0                     # x20 = index = 0
    lui x22, 4                         # ⚠️ SIZE-DEPENDENT: 1=4K, 4=16K, 16=64K
    
copy_loop:
    slli x23, x20, 2                    # x23 = offset = index * 4
    add x24, x10, x23                   # x24 = &source[index]
    lw x25, 0(x24)                      # x25 = source[index] ← Load
    
    add x26, x15, x23                   # x26 = &destination[index]
    sw x25, 0(x26)                      # destination[index] = x25 ← Store
    
    addi x20, x20, 1                    # index++
    blt x20, x22, copy_loop
    
    # ============================================================
    # BENCHMARK END
    # ============================================================
    
    # Verification: Check if destination matches source
    addi x27, x0, 0                     # x27 = verify_index = 0
    lui x28, 4                         # ⚠️ SIZE-DEPENDENT: 1=4K, 4=16K, 16=64K
    addi x29, x0, 1                     # x29 = result = 1 (success)
    
verify_loop:
    slli x23, x27, 2                    # x23 = offset
    add x24, x10, x23                   # x24 = &source[index]
    lw x25, 0(x24)                      # x25 = source[index]
    
    add x26, x15, x23                   # x26 = &destination[index]
    lw x30, 0(x26)                      # x30 = destination[index]
    
    bne x25, x30, verify_fail           # If mismatch, fail
    
    addi x27, x27, 1                    # verify_index++
    blt x27, x28, verify_loop
    
    j verify_done
    
verify_fail:
    addi x29, x0, 0                     # result = 0 (fail)
    
verify_done:
    # Store result for validation
    lui x31, %hi(result)
    addi x31, x31, %lo(result)
    sw x29, 0(x31)
    
    # Exit
    ebreak

.data
result: .word 0
