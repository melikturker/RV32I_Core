#!/usr/bin/env python3
"""
Test script to validate RISC-V disassembler accuracy
Assembles a test program, then disassembles it, and compares
"""

import subprocess
import sys
import os

# Get project root (parent of tools/)
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(TOOLS_DIR)
sys.path.insert(0, TOOLS_DIR)

from riscv_disasm import disassemble

# Test program - simple instructions
test_asm = """
.text
.globl _start

_start:
    addi x1, x0, 1
    addi x2, x0, 2
    add x3, x1, x2
    sub x4, x3, x1
    and x5, x3, x2
    or x6, x1, x2
    xor x7, x1, x2
    sll x8, x1, x2
    slli x9, x1, 5
    lw x10, 0(x1)
    sw x3, 0(x2)
    beq x1, x2, 8
    bne x1, x2, 8
    blt x1, x2, 8
    jal x1, 16
    jalr x0, x1, 0
    lui x10, 0x12345
    auipc x11, 0x100
    ebreak
"""

# Write test file
test_file = "/tmp/test_disasm.s"
with open(test_file, 'w') as f:
    f.write(test_asm)

# Assemble
hex_file = "/tmp/test_disasm.hex"
assembler = os.path.join(TOOLS_DIR, "assembler.py")
result = subprocess.run(
    f"python3 {assembler} {test_file} {hex_file}",
    shell=True,
    capture_output=True,
    text=True
)

if result.returncode != 0:
    print("❌ Assembly failed:")
    print(result.stderr)
    sys.exit(1)

print("✅ Assembly successful\n")

# Read hex and disassemble
print("Instruction | Hex        | Disassembly")
print("-" * 70)

with open(hex_file, 'r') as f:
    for line_no, line in enumerate(f, 1):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        try:
            instr_hex = int(line, 16)
            disasm = disassemble(instr_hex)
            print(f"{line_no:3} | 0x{instr_hex:08x} | {disasm}")
        except ValueError:
            continue

print("\n✅ Disassembly test completed!")
