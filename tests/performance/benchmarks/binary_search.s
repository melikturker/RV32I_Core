# ============================================================
# Binary Search Benchmark - Performance Test
# ============================================================
# Measures: Complex branching patterns (3-way), logarithmic access
#
# PARAMETRIC CONFIGURATION:
# To change stress level, modify ARRAY_SIZE:
#
# 256 elements:   ~8 iterations per search
# 512 elements:   ~9 iterations per search
# 1024 elements:  ~10 iterations per search ← DEFAULT
# 2048 elements:  ~11 iterations per search
#
# Expected result: Found index (varies by target)
# ============================================================

.eqv ARRAY_SIZE, 1024
.eqv SEARCH_TARGET, 777

.data
.align 2
array:
    .fill 1024, 4, 0         # Sorted array (0, 1, 2, ..., 1023)

result: .word 0              # Found index or -1

.text
.globl _start

_start:
    # ============================================================
    # INITIALIZATION (not measured)
    # ============================================================
    lui sp, 0x10000
    
    # Initialize array with sorted values (0..N-1)
    lui x10, %hi(array)
    addi x10, x10, %lo(array)   # x10 = array base address
    
    addi x11, x0, 0             # x11 = counter (0..N-1)
    addi x12, x0, ARRAY_SIZE    # x12 = N
    
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
    
    # Binary search for SEARCH_TARGET
    addi x20, x0, 0             # x20 = low = 0
    addi x21, x0, ARRAY_SIZE    # x21 = high = N - 1
    addi x21, x21, -1
    addi x22, x0, SEARCH_TARGET # x22 = target
    addi x23, x0, -1            # x23 = result = -1 (not found)
    
search_loop:
    # Check if low > high (search failed)
    blt x21, x20, search_done
    
    # Calculate mid = (low + high) / 2
    add x24, x20, x21           # x24 = low + high
    srli x24, x24, 1            # x24 = mid = (low + high) >> 1
    
    # Load array[mid]
    slli x25, x24, 2            # x25 = mid * 4 (offset)
    add x26, x10, x25           # x26 = &array[mid]
    lw x27, 0(x26)              # x27 = array[mid]
    
    # Compare array[mid] with target
    beq x27, x22, found         # if (array[mid] == target) found!
    blt x27, x22, go_right      # if (array[mid] < target) go right
    
    # Go left: high = mid - 1
    addi x21, x24, -1
    j search_loop
    
go_right:
    # Go right: low = mid + 1
    addi x20, x24, 1
    j search_loop
    
found:
    # Found! Save index
    addi x23, x24, 0            # result = mid
    
search_done:
    # ============================================================
    # BENCHMARK END
    # ============================================================
    
    # Store result for validation
    lui x30, %hi(result)
    addi x30, x30, %lo(result)
    sw x23, 0(x30)              # Save found index (or -1)
    
    # Exit
    ebreak
