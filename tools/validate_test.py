#!/usr/bin/env python3
"""
Simplified Test Validator - x31 Signature Only
Checks x31 register for pass/fail signature.
"""

import sys
import os

def parse_regfile_dump(dump_file):
    """
    Parse Verilog $writememh output for register file.
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
                    continue
    
    return registers


def validate_x31_signature(regfile_dump):
    """
    Validate based solely on x31 signature register.
    Returns: (passed, message)
    """
    registers = parse_regfile_dump(regfile_dump)
    
    if registers is None or 'x31' not in registers:
        return False, "⚠️  No register dump or x31 not found"
    
    x31 = registers['x31']
    
    if x31 == 0xAA:
        return True, "✅ x31 Signature: PASS (0xAA)"
    elif x31 == 0xFF:
        return False, "❌ x31 Signature: FAIL (0xFF) - Test assertion failed"
    elif x31 == 0x00:
        return False, "⚠️  x31 Signature: UNDEFINED (0x00) - Test didn't complete"
    else:
        return False, f"⚠️  x31 = 0x{x31:08x} (non-standard signature)"


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_test.py <regfile_dump>")
        sys.exit(2)
    
    regfile_dump = sys.argv[1]
    passed, message = validate_x31_signature(regfile_dump)
    
    if passed:
        print("=== TEST PASSED ===")
        print(f"  {message}")
        sys.exit(0)
    else:
        print("=== TEST FAILED ===")
        print(f"  {message}")
        sys.exit(1)


if __name__ == "__main__":
    main()
