# Performance Benchmarks

This directory contains 7 production benchmarks testing different performance characteristics of the RV32I core.

Baseline metrics are stored in `expected.json` for regression testing.

---

## Memory Benchmarks

### array_sum
**Tests:** Memory access patterns and ALU efficiency

**Algorithm:** Linear array summation with accumulation

**Characteristics:**
- Memory-intensive (sequential loads)
- Regular access pattern
- ALU-memory operation interleaving
- Tests load-to-use dependency handling

**Performance Profile:**
- Moderate IPC (memory-bound)
- Low stall rate (good forwarding)
- High load instruction percentage

**Source:** See `array_sum.s` for array size and implementation details

---

### memcpy
**Tests:** Memory copy efficiency

**Algorithm:** Byte-by-byte memory transfer

**Characteristics:**
- Load-store intensive
- Tests forwarding path between load/store units
- Minimal ALU operations
- Sequential access pattern

**Performance Profile:**
- Good IPC (efficient load-store interleaving)
- Low stall rate
- High memory operation percentage

**Source:** See `memcpy.s`

---

### matrix_transpose
**Tests:** Cache behavior and nested loop performance

**Algorithm:** In-place matrix transpose

**Characteristics:**
- Non-sequential memory access
- Nested loop structure
- Complex but regular access pattern
- Index calculation overhead

**Performance Profile:**
- High IPC (good pipeline utilization)
- Very low stall rate
- Loop-heavy with predictable branches

**Source:** See `matrix_transpose.s`

---

## Algorithm Benchmarks

### fibonacci
**Tests:** Function call overhead and recursion performance

**Algorithm:** Recursive Fibonacci calculation

**Characteristics:**
- Heavy function calls (JAL/JALR intensive)
- Stack manipulation on every call (push/pop x1, ra)
- Branch-heavy (base case checks)
- Minimal memory operations (register-based computation)

**Performance Profile:**
- Jump-intensive (high JAL/JALR rate)
- Low memory stalls
- Branch misprediction dominant
- Recursion overhead visible

**Source:** See `fibonacci.s` for recursion depth

---

### binary_search
**Tests:** Branch-heavy computation with minimal data dependencies

**Algorithm:** Binary search on sorted array

**Characteristics:**
- Logarithmic number of branches
- Conditional jumps dominant
- Minimal data dependencies
- Small working set

**Performance Profile:**
- Good IPC (minimal stalls)
- Low stall rate
- High branch rate
- Efficient despite many branches

**Source:** See `binary_search.s`

---

### bubble_sort
**Tests:** Nested loops and comparison-heavy workload

**Algorithm:** Classic bubble sort (quadratic complexity)

**Characteristics:**
- Nested loop structure
- Many comparisons and conditional swaps
- High branch count
- Dependent swap operations

**Performance Profile:**
- Lower IPC (many dependent operations)
- Higher stall rate
- Very high branch rate
- Swap operations stress forwarding path

**Source:** See `bubble_sort.s`

---

### gcd
**Tests:** Loop-intensive computation

**Algorithm:** Euclidean GCD algorithm

**Characteristics:**
- Iterative loop structure
- Division-free (subtraction-based)
- Branch-dominated control flow
- Variable iteration count

**Performance Profile:**
- Good IPC
- Low stall rate
- High branch rate
- Efficient despite control-heavy code

**Source:** See `gcd.s`

---

## Running Benchmarks

### Basic Usage

Run all performance benchmarks:
```bash
python3 runner.py test --performance
```

Show detailed per-benchmark reports:
```bash
python3 runner.py test --performance --verbose
```

Save summary to file:
```bash
python3 runner.py test --performance --save
python3 runner.py test --performance --save custom_report.txt
```

---

## Regression Testing

### Create Baseline

Save current performance as baseline:
```bash
python3 runner.py test --performance --save-baseline
```

This creates/updates `expected.json` with current metrics and tolerance thresholds.

### Check for Regressions

Compare current run against baseline:
```bash
python3 runner.py test --performance --check-regression
```

Reports show:
- **Abs Change:** Absolute metric difference
- **Rel %:** Relative percentage change
- **Status:** ✅ OK / ✅ IMPROVED / ⚠️ REGRESSED

**Color Coding:**
- Green: Performance improved or within tolerance
- Red: Performance regressed beyond tolerance

### Workflow

1. Make code changes to CPU core
2. Run `--check-regression` to verify no performance loss
3. If regressions appear, investigate cause
4. If changes are intentional, update baseline: `--save-baseline`

**Tolerance Levels:**
- IPC: ±2%
- Stall Rate: ±1 percentage point
- Pipeline Utilization: ±2%
- Cycles: ±5%

See `expected.json` for all thresholds.

---

## Understanding Results

### Summary Table Columns

- **IPC:** Instructions per cycle (higher = better)
- **Cycles:** Total clock cycles taken
- **Instr:** Total instructions retired
- **Util:** Pipeline utilization percentage
- **Stall:** Stall rate percentage
- **Branch:** Conditional branch rate
- **Jump:** Unconditional jump rate (JAL/JALR)

### Regression Report Columns

- **Benchmark:** Test name
- **Metric:** Performance metric being compared
- **Expected:** Baseline value from `expected.json`
- **Current:** Value from current run
- **Abs Change:** Absolute difference (e.g., +0.009 IPC or +3.5% stall)
- **Rel %:** Relative percentage change
- **Status:** OK / IMPROVED / REGRESSED

For detailed metric explanations, see [docs/METRICS.md](../../docs/METRICS.md).

---

## Baseline File: expected.json

**Structure:**
```json
{
  "benchmark_name": {
    "ipc": <value>,
    "cycles": <value>,
    "instructions": <value>,
    "pipeline_util": <value>,
    "stall_rate": <value>,
    "branch_rate": <value>,
    "jump_rate": <value>
  },
  "_tolerances": {
    "ipc": 0.02,
    "stall_rate": 0.01,
    ...
  }
}
```

**Note:** This file is automatically generated and should not be manually edited.

---

## For Developers

### Adding a New Benchmark

1. Create `.s` assembly file in `tests/performance/`
2. Add to benchmark list in `runner.py` (line ~306)
3. Add to appropriate group in `tools/performance_summary.py`
4. Document in this README (algorithm, characteristics, performance profile)
5. Run `--save-baseline` to update `expected.json`

### Benchmark Best Practices

- Add descriptive comments in assembly source
- Use `ebreak` instruction to terminate
- Keep benchmark deterministic (no random input)
- Document input parameters in source file
- Focus on one performance characteristic per benchmark
