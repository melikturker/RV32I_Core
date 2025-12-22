# Performance Metrics Reference

This document explains all performance metrics reported by the RV32I core.

For benchmark-specific information, see [tests/performance/README.md](../tests/performance/README.md).

---

## Core Execution Metrics

### IPC (Instructions Per Cycle)

**Definition:** Number of instructions retired per clock cycle.

**Formula:** `instructions / cycles`

**Range:** 0.0 to 1.0 (theoretical max for single-issue pipeline)

**Interpretation:**
- Higher is better
- Close to 1.0: Efficient pipeline with minimal stalls/flushes
- Below 0.5: Significant performance issues

**Affected by:** Pipeline stalls, flushes, bubbles

---

### CPI (Cycles Per Instruction)

**Definition:** Average clock cycles needed per instruction.

**Formula:** `cycles / instructions` (inverse of IPC)

**Interpretation:**
- Lower is better
- Minimum value: 1.0 (ideal pipeline)
- Values >2.0 indicate poor performance

---

### Pipeline Utilization

**Definition:** Percentage of cycles spent doing useful work.

**Formula:** `(cycles - stalls - flushes) / cycles × 100%`

**Interpretation:**
- Higher is better
- 100%: No wasted cycles (rarely achievable)
- Below 70%: Significant pipeline inefficiency

**Note:** Complements stall rate and flush rate.

---

## Stall & Hazard Metrics

### RAW Hazards

**Definition:** Read-After-Write data dependencies detected in the pipeline.

**Interpretation:**
- Count of potentially hazardous instruction pairs
- Not all cause stalls (forwarding resolves many)
- High count is normal for data-intensive code
- Compare with Forward Rate to assess forwarding effectiveness

---

### Stall Rate

**Definition:** Percentage of cycles the CPU is stalled.

**Causes:** Load-use hazards that cannot be resolved by forwarding

**Formula:** `stalls / cycles × 100%`

**Interpretation:**
- Lower is better
- 0%: No load-use hazards or perfect instruction scheduling
- Above 5%: Memory-heavy code with poor scheduling

---

### Forward Rate

**Definition:** Percentage of RAW hazards resolved by data forwarding.

**Formula:** `forwards / raw_hazards × 100%`

**Interpretation:**
- Higher is better
- 100%: All hazards forwarded (no stalls from hazards)
- Below 80%: Load-use hazards present

**Note:** Shows forwarding path effectiveness.

---

### Bubble Rate

**Definition:** Percentage of cycles with pipeline bubbles.

**Note:** Implementation-dependent; may overlap with stalls/flushes.

---

## Control Flow Metrics

### Branch Rate

**Definition:** Percentage of instructions that are conditional branches.

**Formula:** `conditional_branches / instructions × 100%`

**Interpretation:**
- Algorithm characteristic (not inherently good or bad)
- Above 20%: Control-flow intensive (many loops/conditions)
- Below 5%: Straight-line or memory-bound code

---

### Jump Rate

**Definition:** Percentage of instructions that are jumps (JAL/JALR).

**Formula:** `jumps / instructions × 100%`

**Interpretation:**
- High (above 10%): Function-call heavy code
- Low (below 1%): Long basic blocks, minimal function calls

---

### Flush Rate

**Definition:** Percentage of cycles wasted due to pipeline flushes.

**Causes:** Branch mispredictions (core uses static "not taken" predictor)

**Formula:** `flushes / cycles × 100%`

**Interpretation:**
- Lower is better
- Backward branches (loops) always mispredict when taken
- Above 10%: Branch-heavy code with many mispredictions

**Note:** Cannot be optimized (static predictor limitation).

---

### Flush Count

**Definition:** Total number of pipeline flushes.

**Interpretation:**
- Each flush typically wastes 2 cycles
- Compare with branch count to assess prediction accuracy

---

### Avg Control-Flow Penalty

**Definition:** Average cycles lost per branch/jump instruction.

**Formula:** `(flushes × 2) / (branches + jumps)`

**Typical Range:** 1-2 cycles for mispredicted branches

**Interpretation:**
- Lower is better
- High value: Poor branch prediction accuracy

---

## Instruction Mix

Breakdown of retired instructions by type. Shows workload characteristics.

### ALU R-type
Register-register operations: `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`

### ALU I-type
Immediate operations: `addi`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai`, `slti`, `sltiu`

### Load
Memory read operations: `lw`, `lh`, `lb`, `lhu`, `lbu`

### Store
Memory write operations: `sw`, `sh`, `sb`

### Branch
Conditional branches: `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`

### Jump
Unconditional jumps: `jal`, `jalr`

### System
System calls: `ecall`, `ebreak`, `fence`

### Other
Less common instructions: `lui`, `auipc`

**Usage:** Understand workload balance and identify bottlenecks.

---

## Interpreting Metrics for Optimization

### High Stall Rate?

**Possible Causes:**
- Many load-use dependencies
- Poor instruction scheduling

**Optimization:**
- Reorder instructions to avoid load-use patterns
- Insert independent instructions between load and use
- Reduce memory access frequency

---

### High Flush Rate?

**Possible Causes:**
- Many backward branches (loops)
- Branch-heavy algorithms

**Notes:**
- Often unavoidable (static predictor)
- Backward branches (loops) always taken → always mispredicted
- Algorithm characteristic, not necessarily a problem

---

### Low IPC with Low Stalls?

**Likely Cause:** High flush rate (branch mispredictions)

**Analysis:**
- Check flush rate and branch rate
- May be algorithm characteristic (loop-heavy code)

---

### High Jump Rate?

**Cause:** Function call overhead

**Optimization:**
- Consider function inlining for hot paths
- Reduce call depth if possible

**Note:** Some algorithms inherently require many calls (recursion).

---

### Low Pipeline Utilization?

**Causes:** Combination of stalls and flushes

**Analysis:**
- Check individual stall rate and flush rate
- Identify dominant bottleneck
- Apply targeted optimizations

---

## Baseline Comparison

Baseline metrics are stored in `tests/performance/expected.json`.

Use regression testing to compare current performance:
```bash
python3 runner.py test --performance --check-regression
```

**Tolerance Thresholds:**
- IPC: ±2%
- Stall Rate: ±1 percentage point
- Pipeline Utilization: ±2%
- Cycles: ±5%
- Instructions: ±1% (should be very stable)

See `expected.json` file for complete tolerance configuration.

---

## Related Documentation

- **Benchmarks:** [tests/performance/README.md](../tests/performance/README.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Main README:** [../README.md](../README.md)
