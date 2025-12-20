# RV32I Core Test Suite

This directory contains automated tests for verifying the RV32I Core implementation.

## Test Organization

Tests are organized into two main categories:

### 1. **Functionality Tests** (`functional/`)
Tests that verify correctness of core functionality:

- **Random Corner Case Test**: Dynamically generated random instruction sequences (default: 100 instructions)
  - Tests unexpected instruction combinations
  - Validates core robustness
  - Catches edge cases not covered by deterministic tests

- **ISA Coverage**:
  - `isa_full_coverage.s` - Comprehensive test covering all 38 RV32I base instructions with signature verification

- **Hazard Handling**:
  - `hazard_raw_basic.s` - Read-After-Write hazards with ALU forwarding (EX->EX, MEM->EX, chains, dual-source)
  - `hazard_load_use.s` - Load-use stalls with memory dependencies (basic, ALU, address calc, back-to-back loads)
  - `hazard_branch.s` - Control hazards with branch/jump handling (taken/not-taken, loops, JAL/JALR, dependencies)
  - `hazard_store_load.s` - Store-load forwarding and memory dependencies (same addr, different addr, overlapping)

- **Corner Cases**:
  - `corner_x0_register.s` - x0 hardwired-zero behavior (read, write-ignore, arithmetic, logical ops)

- **Matrix Operations**:
  - `matrix_row_sum.s` - Computes sum of each row in 16x16 matrix
  - `matrix_col_sum.s` - Computes sum of each column in 16x16 matrix
  - `matrix_add.s` - Element-wise addition of two 16x16 matrices

**Total: 10 functional tests** covering 100% ISA, pipeline hazards, corner cases, and real workloads.

### 2. **Performance Tests** (`performance/`)
Tests focused on benchmarking and performance validation.

*(Currently empty - future: benchmark tests, throughput measurements, cache performance tests)*

## Running Tests

Use the `runner.py` CLI to execute tests:

```bash
# Run all tests
./runner.py test

# Run only functional correctness tests (fast, deterministic)
./runner.py test --functionality

# Run only performance benchmarks (currently empty)
./runner.py test --performance

# Customize random test size
./runner.py test --functionality --count 500 --seed 42
```

## Test Failure Logging

When a test fails, detailed logs are automatically saved to `logs/` directory:

**Failure logs** (`logs/test_fail_<name>_<timestamp>.log`):
- Full simulation output
- Exit code and error analysis
- Suspected causes (timeout, segfault, etc.)
- Last 20 lines for quick debugging

**Timeout logs** (`logs/test_timeout_<name>_<timestamp>.log`):
- Timeout duration
- Likely causes (infinite loop, deadlock, etc.)
- Troubleshooting suggestions

## Test Organization Strategy

**Functionality Tests (10 tests):**
- Purpose: Verify correctness and robustness
- Characteristics: Mix of deterministic and random, fast (~5 seconds total)
- Coverage: 100% ISA coverage + critical pipeline scenarios + corner cases

**Performance Tests (0 tests):**
- Purpose: Benchmarking and performance validation
- Characteristics: Throughput, latency, cache hit rates
- Coverage: Performance metrics (future work)

## Test Details

### Hazard Tests
Each hazard test is designed to stress a specific pipeline scenario:

**RAW (Read-After-Write)**: Tests data forwarding paths
- EX->EX forwarding (1-cycle dependency)
- MEM->EX forwarding (2-cycle dependency)  
- Dependency chains (multi-hop forwarding)
- Dual-source operand forwarding

**Load-Use**: Tests pipeline stalls
- Basic load followed by immediate use
- Load with shift/ALU operations
- Load result used as memory address
- Back-to-back dependent loads

**Branch/Control**: Tests control flow handling
- Taken vs. not-taken branches
- Backward branches (loops)
- JAL/JALR unconditional jumps
- Branches with register dependencies

**Store-Load**: Tests memory dependencies
- Store-load to same address
- Store-load to different addresses
- Multiple stores with subsequent loads
- Address offset calculations

### Matrix Operation Tests
Each matrix test follows this pattern:
1. Initialize 16x16 input matrix with predictable pattern
2. Perform computation (row sum / column sum / addition)
3. Store results in contiguous memory
4. Verify correctness with known expected values

**Memory Layout Example (matrix_row_sum)**:
- `0x000-0x3FF`: Input matrix (256 words)
- `0x400-0x43F`: Output row sums (16 words)

Pattern: `M[i][j] = i + j`  
Expected row 0 sum: `0+1+2+...+15 = 120`

## Adding New Tests

### Functionality Test
1. Create `.s` assembly file in `tests/functional/`
2. Use `ebreak` for success (optionally set x1 to magic value)
3. Test will be auto-assembled and run by runner

### Performance Test
1. Create test in `tests/performance/`
2. Design for measurable metrics (cycles, cache hits, etc.)
3. Document expected performance characteristics

## Test Generators

Located in `tools/` directory:

**ISA Coverage Generator** (`tools/isa_full_coverage_gen.py`):
- Generates comprehensive test covering all RV32I instructions
- Output: `tests/functional/isa_full_coverage.s`
- Usage: Run manually when ISA changes (rarely needed)
  ```bash
  python3 tools/isa_full_coverage_gen.py --output tests/functional/isa_full_coverage.s
  ```

**Random Test Generator** (`tools/random_instruction_test_gen.py`):
- Generates random instruction sequences
- Configurable count and seed for reproducibility
- Auto-run during test execution
- Usage:
  ```bash
  python3 tools/random_instruction_test_gen.py --count 100 --seed 42 --out test.hex
  ```
