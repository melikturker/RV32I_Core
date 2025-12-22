# ============================================================
# GCD (Euclidean Algorithm) Benchmark - Performance Test
# ============================================================
# Measures: Software division (modulo), data-dependent loops
#
# PARAMETRIC CONFIGURATION:
# To change stress level, modify input values:
#
# GCD(12, 8) = 4           (~3 iterations, light)
# GCD(48, 18) = 6          (~4 iterations, light)
# GCD(1071, 462) = 21      (~9 iterations, medium)
# GCD(514229, 317811) = 1  (~30+ iterations, heavy) ← DEFAULT
# GCD(10000, 123) = 1      (~many iterations, heavy)
#
# Expected result: GCD(514229, 317811) = 1
# Note: Using Fibonacci(29) and Fibonacci(28) for worst-case GCD
# ============================================================

.eqv INPUT_A, 514229
.eqv INPUT_B, 317811

.data
.align 2
result: .word 0

.text
.globl _start

_start:
    # ============================================================
    # INITIALIZATION (not measured)
    # ============================================================
    lui sp, 0x10000
    
    # ============================================================
    # BENCHMARK START (measurement begins here)
    # ============================================================
benchmark_start:
    
    addi x20, x0, INPUT_A       # x20 = a
    addi x21, x0, INPUT_B       # x21 = b
    
gcd_loop:
    # While b != 0
    beq x21, x0, gcd_done
    
    # temp = a % b (software modulo)
    # We need to implement: temp = a - (a / b) * b
    # Division: a / b using shift-subtract
    
    # Save a and b
    addi x22, x20, 0            # x22 = a (dividend)
    addi x23, x21, 0            # x23 = b (divisor)
    
    # Software division: quotient = a / b
    addi x24, x0, 0             # x24 = quotient = 0
    
div_loop:
    # If dividend < divisor, division done
    blt x22, x23, div_done
    
    # dividend -= divisor
    sub x22, x22, x23
    
    # quotient++
    addi x24, x24, 1
    
    j div_loop
    
div_done:
    # x22 now contains remainder (a % b)
    # temp = remainder
    addi x25, x22, 0            # x25 = temp = a % b
    
    # a = b
    addi x20, x21, 0            # a = b
    
    # b = temp
    addi x21, x25, 0            # b = temp
    
    j gcd_loop
    
gcd_done:
    # Result is in x20 (a)
    
    # ============================================================
    # BENCHMARK END
    # ============================================================
    
    # Store result for validation
    lui x30, %hi(result)
    addi x30, x30, %lo(result)
    sw x20, 0(x30)              # Save GCD result
    
    # Exit
    ebreak
