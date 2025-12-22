# ============================================================
# Array Sum Benchmark - Performance Test
# ============================================================
# Measures: Load-use hazards, ALU forwarding, memory throughput
#
# PARAMETRIC CONFIGURATION:
# To change array size, modify BOTH sections below:
#
# 64×64   (4096):    ARRAY_SIZE=64,  TOTAL_ELEMENTS=4096,  lui x12/x22=1
# 128×128 (16384):   ARRAY_SIZE=128, TOTAL_ELEMENTS=16384, lui x12/x22=4
# 256×256 (65536):   ARRAY_SIZE=256, TOTAL_ELEMENTS=65536, lui x12/x22=16
#
# Expected sum formulas:
# 64×64:   sum = 8,386,560    (0x7FF800)
# 128×128: sum = 134,209,536  (0x7FFE000)
# 256×256: sum = 2,147,450,880 (0x7FFFE000)
# ============================================================

.eqv ARRAY_SIZE, 128
.eqv TOTAL_ELEMENTS, 16384   # ARRAY_SIZE * ARRAY_SIZE

.data
.align 2
array: 
    .fill 16384, 4, 0        # Must match TOTAL_ELEMENTS

.text
.globl _start

_start:
    # ============================================================
    # INITIALIZATION (not measured)
    # ============================================================
    lui sp, 0x10000
    
    # Initialize array with sequential values (0..4095)
    lui x10, %hi(array)
    addi x10, x10, %lo(array)   # x10 = array base address
    
    addi x11, x0, 0             # x11 = counter (0..N-1)
    lui x12, 4                 # ⚠️ SIZE-DEPENDENT: 1=4K, 4=16K, 16=64K
    
init_loop:
    slli x13, x11, 2            # x13 = offset = counter * 4
    add x14, x10, x13           # x14 = &array[counter]
    sw x11, 0(x14)              # array[counter] = counter
    
    addi x11, x11, 1            # counter++
    blt x11, x12, init_loop
    
    # ============================================================
    # BENCHMARK START (measurement begins here)
    # ============================================================
benchmark_start:
    
    addi x20, x0, 0             # x20 = sum = 0
    addi x21, x0, 0             # x21 = index = 0
    lui x22, 4                 # ⚠️ SIZE-DEPENDENT: 1=4K, 4=16K, 16=64K
    
sum_loop:
    slli x23, x21, 2            # x23 = offset = index * 4
    add x24, x10, x23           # x24 = &array[index]
    lw x25, 0(x24)              # x25 = array[index] ← Load-use hazard!
    add x20, x20, x25           # sum += array[index] ← ALU forwarding test
    
    addi x21, x21, 1            # index++
    blt x21, x22, sum_loop
    
    # ============================================================
    # BENCHMARK END
    # ============================================================
    
    # Result validation
    # Expected: 8,386,560 (0x7FE000)
    # Result is in x20
    
    # Store result for validation
    lui x30, %hi(result)
    addi x30, x30, %lo(result)
    sw x20, 0(x30)
    
    # Exit
    ebreak

.data
result: .word 0

