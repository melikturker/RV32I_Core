#!/usr/bin/env python3
"""
Test Result Validator
Reads register/memory dumps from simulation and compares with golden reference.
Used by runner.py to validate test correctness.
"""

import json
import sys
import os

def parse_regfile_dump(dump_file):
    """
    Parse Verilog $writememh output for register file.
    Each line is one 32-bit register value in hex.
    Returns dict: {'x0': value, 'x1': value, ...}
    """
    registers = {}
    
    if not os.path.exists(dump_file):
        return None
        
    with open(dump_file, 'r') as f:
        for i, line in enumerate(f):
            line = line.strip()
            if line and not line.startswith('@') and not line.startswith('//'):
                try:
                    value = int(line, 16)
                    registers[f'x{i}'] = value
                except ValueError:
                    continue  # Skip invalid lines
    
    return registers


def parse_dmem_dump(dump_file):
    """
    Parse Verilog $writememh output for data memory.
    Returns dict: {address: value}
    Address is index*4 (word-aligned)
    """
    memory = {}
    
    if not os.path.exists(dump_file):
        return None
    
    with open(dump_file, 'r') as f:
        for i, line in enumerate(f):
            line = line.strip()
            if line and not line.startswith('@') and not line.startswith('//'):
                try:
                    value = int(line, 16)
                    address = i * 4  # Word-aligned
                    memory[address] = value
                except ValueError:
                    continue
    
    return memory


def load_golden(golden_file):
    """Load golden reference JSON"""
    if not os.path.exists(golden_file):
        return None
        
    with open(golden_file, 'r') as f:
        return json.load(f)


def validate(regfile_dump, dmem_dump, golden_file):
    """
    Compare dumps against golden reference.
    Returns: (passed, errors, warnings)
    """
    # Load actual values
    actual_regs = parse_regfile_dump(regfile_dump)
    actual_mem = parse_dmem_dump(dmem_dump)
    
    if actual_regs is None and actual_mem is None:
        return False, ["Dump files not found"], []
    
    # Load expected values
    expected = load_golden(golden_file)
    
    if expected is None:
        return False, [f"Golden reference not found: {golden_file}"], []
    
    errors = []
    warnings = []
    
    # ===== Register Validation =====
    if 'registers' in expected and actual_regs is not None:
        for reg, exp_val in expected['registers'].items():
            # Convert hex string to int if needed
            if isinstance(exp_val, str):
                exp_val = int(exp_val, 16) if exp_val.startswith('0x') else int(exp_val)
            
            # Get actual value
            act_val = actual_regs.get(reg, 0)
            
            if act_val != exp_val:
                errors.append(
                    f"Register {reg}: expected 0x{exp_val:08x}, got 0x{act_val:08x}"
                )
    
    # ===== Memory Validation =====
    if 'memory' in expected and actual_mem is not None:
        for mem_check in expected['memory']:
            addr = mem_check['address']
            exp_val = mem_check['value']
            
            # Convert address if string
            if isinstance(addr, str):
                addr = int(addr, 16) if addr.startswith('0x') else int(addr)
            
            # Convert value if string
            if isinstance(exp_val, str):
                exp_val = int(exp_val, 16) if exp_val.startswith('0x') else int(exp_val)
            
            act_val = actual_mem.get(addr, 0)
            
            if act_val != exp_val:
                errors.append(
                    f"Memory[0x{addr:04x}]: expected 0x{exp_val:08x}, got 0x{act_val:08x}"
                )
    
    # Add memory range warning
    if 'memory' in expected:
        warnings.append("Note: Only first 1024 words (4KB) of memory validated")
    
    passed = len(errors) == 0
    return passed, errors, warnings


def main():
    if len(sys.argv) != 4:
        print("Usage: validate_test.py <regfile_dump> <dmem_dump> <golden_json>")
        sys.exit(2)
    
    regfile_dump = sys.argv[1]
    dmem_dump = sys.argv[2]
    golden_file = sys.argv[3]
    
    passed, errors, warnings = validate(regfile_dump, dmem_dump, golden_file)
    
    if passed:
        print("=== TEST PASSED ===")
        for warning in warnings:
            print(f"  ℹ️  {warning}")
        sys.exit(0)
    else:
        print("=== TEST FAILED ===")
        for error in errors:
            print(f"  ❌ {error}")
        for warning in warnings:
            print(f"  ℹ️  {warning}")
        sys.exit(1)


if __name__ == "__main__":
    main()
