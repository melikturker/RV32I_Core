# ============================================================
# Bubble Sort Benchmark - Performance Test (TINY VERSION)
# ============================================================
# Measures: Nested loops, data-dependent branches, memory swaps
#
# PARAMETRIC CONFIGURATION:
# ARRAY_SIZE: 32 elements (optimized for fast simulation)
#
# 32 elements:   ~500 comparisons, O(n²) ← TINY (fast)
# 64 elements:   ~2K comparisons, O(n²)
# 128 elements:  ~8K comparisons, O(n²)
# 256 elements:  ~32K comparisons, O(n²) (original)
#
# Worst case: Reverse sorted array
# Expected result: Sorted in ascending order
# ============================================================

.eqv ARRAY_SIZE, 32

.data
.align 2
array:
    .fill 32, 4, 0          # Array to be sorted

result: .word 0              # 1=sorted correctly, 0=failed

.text
.globl _start

_start:
    # ============================================================
    # INITIALIZATION (not measured)
    # ============================================================
    lui sp, 0x10000
    
    # Initialize array with REVERSE sorted values (worst case)
    # array[i] = N - 1 - i
    lui x10, %hi(array)
    addi x10, x10, %lo(array)   # x10 = array base address
    
    addi x11, x0, 0                # x11 = counter
    addi x12, x0, ARRAY_SIZE       # x12 = N
    addi x13, x12, -1              # x13 = N - 1
    
init_loop:
    sub x14, x13, x11              # x14 = (N-1) - counter
    slli x15, x11, 2               # x15 = offset = counter * 4
    add x16, x10, x15              # x16 = &array[counter]
    sw x14, 0(x16)                 # array[counter] = N-1-counter
    
    addi x11, x11, 1               # counter++
    blt x11, x12, init_loop
    
    # ============================================================
    # BENCHMARK START (measurement begins here)
    # ============================================================
benchmark_start:
    
    # Bubble Sort: for (i = 0; i < n-1; i++)
    #                 for (j = 0; j < n-i-1; j++)
    #                     if (arr[j] > arr[j+1]) swap
    
    addi x20, x0, 0                # x20 = i = 0
    addi x21, x0, ARRAY_SIZE       # x21 = N
    addi x21, x21, -1              # x21 = N - 1
    
outer_loop:
    # Check if i >= N-1
    blt x20, x21, outer_continue
    j sort_done
    
outer_continue:
    # Inner loop: j = 0
    addi x22, x0, 0                # x22 = j = 0
    
    # Calculate inner loop limit: N - i - 1
    sub x23, x21, x20              # x23 = (N-1) - i = N - i - 1
    
inner_loop:
    # Check if j >= N-i-1
    blt x22, x23, inner_continue
    
    # End of inner loop, increment i
    addi x20, x20, 1               # i++
    j outer_loop
    
inner_continue:
    # Load arr[j]
    slli x24, x22, 2               # x24 = j * 4
    add x25, x10, x24              # x25 = &arr[j]
    lw x26, 0(x25)                 # x26 = arr[j]
    
    # Load arr[j+1]
    lw x27, 4(x25)                 # x27 = arr[j+1]
    
    # Compare: if (arr[j] > arr[j+1]) swap
    blt x27, x26, do_swap          # if (arr[j+1] < arr[j]) swap
    j skip_swap
    
do_swap:
    # Swap arr[j] and arr[j+1]
    sw x27, 0(x25)                 # arr[j] = arr[j+1]
    sw x26, 4(x25)                 # arr[j+1] = arr[j]
    
skip_swap:
    # j++
    addi x22, x22, 1
    j inner_loop
    
sort_done:
    # ============================================================
    # BENCHMARK END
    # ============================================================
    
    # Validation: Check if array is sorted
    addi x28, x0, 0                # x28 = i = 0
    addi x29, x0, ARRAY_SIZE       # x29 = N
    addi x29, x29, -1              # x29 = N - 1
    addi x30, x0, 1                # x30 = result = 1 (assume sorted)
    
verify_loop:
    # Check if i >= N-1
    blt x28, x29, verify_continue
    j verify_done
    
verify_continue:
    # Load arr[i]
    slli x24, x28, 2
    add x25, x10, x24
    lw x26, 0(x25)                 # x26 = arr[i]
    
    # Load arr[i+1]
    lw x27, 4(x25)                 # x27 = arr[i+1]
    
    # Check if arr[i] <= arr[i+1]
    blt x27, x26, verify_fail      # if (arr[i+1] < arr[i]) fail!
    
    addi x28, x28, 1               # i++
    j verify_loop
    
verify_fail:
    addi x30, x0, 0                # result = 0 (not sorted)
    
verify_done:
    # Store result
    lui x31, %hi(result)
    addi x31, x31, %lo(result)
    sw x30, 0(x31)
    
    # Set signature based on result
    beq x30, x0, fail       # if (result == 0) fail
    
pass:
    addi x31, x0, 0xAA   # Signature: PASS
    ebreak

fail:
    addi x31, x0, 0xFF   # Signature: FAIL
    ebreak
