# ============================================================
# Fibonacci (Recursive) Benchmark - Performance Test
# ============================================================
# Measures: JAL/JALR overhead, return address handling, stack operations
#
# PARAMETRIC CONFIGURATION:
# To change stress level, modify FIB_N:
#
# fib(10) = 55          (~177 calls, light)
# fib(15) = 610         (~1,973 calls, medium)
# fib(20) = 6,765       (~21,891 calls, heavy)
# fib(25) = 75,025      (~242,785 calls, extreme) ← DEFAULT
# fib(30) = 832,040     (~2,692,537 calls, very extreme)
#
# Expected result: fib(25) = 75,025
# ============================================================

.eqv FIB_N, 25

.data
.align 2
result: .word 0

.text
.globl _start

_start:
    # ============================================================
    # INITIALIZATION (not measured)
    # ============================================================
    lui sp, 0x10000         # Stack pointer at 0x10000000
    
    # ============================================================
    # BENCHMARK START (measurement begins here)
    # ============================================================
benchmark_start:
    
    addi a0, x0, FIB_N      # a0 = N
    jal ra, fibonacci       # result = fib(N)
    
    # ============================================================
    # BENCHMARK END
    # ============================================================
    
    # Store result for validation
    lui x30, %hi(result)
    addi x30, x30, %lo(result)
    sw a0, 0(x30)           # Save fib(N)
    
    # Exit
    ebreak

# ============================================================
# fibonacci(n) - Recursive implementation
# ============================================================
# Input:  a0 = n
# Output: a0 = fib(n)
# Uses:   a0, a1, ra, stack
# ============================================================
fibonacci:
    # Base case: if (n <= 1) return n
    addi t0, x0, 2
    blt a0, t0, fib_base_case    # if (n < 2) return n
    
    # Recursive case: fib(n-1) + fib(n-2)
    # Save n and return address on stack
    addi sp, sp, -12        # Allocate stack frame (3 words)
    sw ra, 8(sp)            # Save return address
    sw a0, 4(sp)            # Save n
    
    # Call fib(n-1)
    addi a0, a0, -1         # a0 = n - 1
    jal ra, fibonacci       # a0 = fib(n-1)
    sw a0, 0(sp)            # Save fib(n-1) on stack
    
    # Call fib(n-2)
    lw a0, 4(sp)            # Restore n
    addi a0, a0, -2         # a0 = n - 2
    jal ra, fibonacci       # a0 = fib(n-2)
    
    # Compute fib(n-1) + fib(n-2)
    lw a1, 0(sp)            # a1 = fib(n-1)
    add a0, a1, a0          # a0 = fib(n-1) + fib(n-2)
    
    # Restore stack and return
    lw ra, 8(sp)            # Restore return address
    addi sp, sp, 12         # Deallocate stack frame
    jalr x0, ra, 0          # Return
    
fib_base_case:
    # Return n (already in a0)
    jalr x0, ra, 0          # Return
