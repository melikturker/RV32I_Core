import sys
import re

# Minimal RISC-V Assembler for the Visualization Demo
# Supports: lui, addi, add, sub, slli, sw, lw, li (pseudo), bne, blt, j, jal, ret, xor, andi, srli, ebreak
# Supports: .eqv CONST VAL
# Supports: %hi(VAL), %lo(VAL)
# Supports: Arithmetic expressions in immediates (via eval)

def parse_reg(r):
    r = r.lower().replace(',', '')
    if r.startswith('x'): 
        try:
            return int(r[1:])
        except:
            return 0
    
    abi_map = {
        'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
        't0': 5, 't1': 6, 't2': 7, 
        's0': 8, 'fp': 8, 's1': 9, 
        'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
        's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
        't3': 28, 't4': 29, 't5': 30, 't6': 31
    }
    return abi_map.get(r, 0)

def parse_imm(s):
    s = s.strip()
    # Handle %hi(...)
    hi_match = re.match(r'%hi\((.*)\)', s)
    if hi_match:
        try:
            val = int(eval(hi_match.group(1)))
            return (val >> 12) & 0xFFFFF
        except Exception as e:
            print(f"Error evaluating %hi: {s} -> {e}")
            return 0
            
    # Handle %lo(...)
    lo_match = re.match(r'%lo\((.*)\)', s)
    if lo_match:
        try:
            val = int(eval(lo_match.group(1)))
            # Sign extend 12-bit
            # But usually we just want the bits for the field
            return val & 0xFFF
        except Exception as e:
            print(f"Error evaluating %lo: {s} -> {e}")
            return 0
    
    # Handle normal expressions
    try:
        # Hex strings need to be handled by eval? eval("0x10") works.
        return int(eval(s))
    except Exception as e:
        print(f"Error evaluating immediate: {s} -> {e}")
        return 0

def to_hex(val, bits):
    return val & ((1 << bits) - 1)

def assemble(input_file, output_file):
    lines = []
    with open(input_file, 'r') as f:
        lines = f.readlines()

    labels = {}
    constants = {}
    clean_lines = []
    
    # Pass 1: Find Labels, Constants, and Clean
    pc = 0
    for line in lines:
        # Remove both // and # comments
        line = line.split('//')[0].split('#')[0].strip()
        if not line: continue
        
        # Handle .eqv constants
        # Format: .eqv NAME VALUE
        if line.startswith('.eqv'):
            parts = line.split()
            if len(parts) >= 3:
                name = parts[1].replace(',', '')
                val = " ".join(parts[2:]) # Take rest of line as value
                constants[name] = val
            continue

        # Substitute constants (naive string replace)
        for name, val in constants.items():
            # word boundary check would be better, but simple replace suffices for now
            if name in line:
                 line = line.replace(name, val)

        if line.startswith('.'): continue # Ignore other directives
        
        if ':' in line:
            label, rest = line.split(':')
            labels[label.strip()] = pc
            line = rest.strip()
        
        if line:
            clean_lines.append((pc, line))
            pc += 4  # 4 bytes per instruction

    # Pass 2: Assemble
    hex_output = []
    
    for pc, line in clean_lines:
        parts = line.replace(',', ' ').split()
        if not parts: continue
        op = parts[0]
        mach_code = 0
        
        try:
            if op == 'li': 
                pass 
                
            if op == 'addi': 
                # addi rd, rs1, imm
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                imm = parse_imm(parts[3])
                mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x13
                
            elif op == 'add':
                # add rd, rs1, rs2
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x33

            elif op == 'sw':
                # sw rs2, imm(rs1) OR sw rs2, offset(rs1)
                rs2 = parse_reg(parts[1])
                offset_str = parts[2]
                
                # Regex for offset(base)
                match = re.match(r'(.+)\((.+)\)', offset_str)

                if match:
                    imm = parse_imm(match.group(1))
                    rs1 = parse_reg(match.group(2))
                    imm11_5 = (imm >> 5) & 0x7F
                    imm4_0 = imm & 0x1F
                    mach_code = (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | (imm4_0 << 7) | 0x23

            elif op == 'lw':
                rd = parse_reg(parts[1])
                offset_str = parts[2]
                match = re.match(r'(.+)\((.+)\)', offset_str)
                if match:
                    imm = parse_imm(match.group(1))
                    rs1 = parse_reg(match.group(2))
                    mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x03

            elif op == 'slli':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                shamt = parse_imm(parts[3])
                mach_code = (0 << 25) | (shamt << 20) | (rs1 << 15) | (1 << 12) | (rd << 7) | 0x13
            
            elif op == 'srli':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                shamt = parse_imm(parts[3])
                mach_code = (0 << 25) | (shamt << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x13
            
            elif op == 'sub':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0x20 << 25) | (rs2 << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x33

            elif op == 'beq':
                # beq rs1, rs2, label
                rs1 = parse_reg(parts[1])
                rs2 = parse_reg(parts[2])
                label = parts[3]
                if label in labels:
                    target = labels[label]
                    offset = target - pc
                    imm12 = (offset >> 12) & 1
                    imm10_5 = (offset >> 5) & 0x3F
                    imm4_1 = (offset >> 1) & 0xF
                    imm11 = (offset >> 11) & 1
                    mach_code = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (0 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63
                else:
                    print(f"Error: Label '{label}' not found for beq at PC={pc}")

            elif op == 'bne':
                # bne rs1, rs2, label
                rs1 = parse_reg(parts[1])
                rs2 = parse_reg(parts[2])
                label = parts[3]
                if label in labels:
                    target = labels[label]
                    offset = target - pc
                    imm12 = (offset >> 12) & 1
                    imm10_5 = (offset >> 5) & 0x3F
                    imm4_1 = (offset >> 1) & 0xF
                    imm11 = (offset >> 11) & 1
                    mach_code = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (1 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63
                else:
                    print(f"Error: Label '{label}' not found for bne at PC={pc}")

            elif op == 'bnez':
                # bnez rs1, label -> bne rs1, x0, label
                rs1 = parse_reg(parts[1])
                label = parts[2]
                if label in labels:
                    target = labels[label]
                    offset = target - pc
                    imm12 = (offset >> 12) & 1
                    imm10_5 = (offset >> 5) & 0x3F
                    imm4_1 = (offset >> 1) & 0xF
                    imm11 = (offset >> 11) & 1
                    mach_code = (imm12 << 31) | (imm10_5 << 25) | (0 << 20) | (rs1 << 15) | (1 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63
                else:
                    print(f"Warning: Label {label} not found")

            elif op == 'blt':
                rs1 = parse_reg(parts[1])
                rs2 = parse_reg(parts[2])
                label = parts[3]
                if label in labels:
                    target = labels[label]
                    offset = target - pc
                    imm12 = (offset >> 12) & 1
                    imm10_5 = (offset >> 5) & 0x3F
                    imm4_1 = (offset >> 1) & 0xF
                    imm11 = (offset >> 11) & 1
                    mach_code = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (4 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

            elif op == 'bge':
                rs1 = parse_reg(parts[1])
                rs2 = parse_reg(parts[2])
                label = parts[3]
                if label in labels:
                    target = labels[label]
                    offset = target - pc
                    imm12 = (offset >> 12) & 1
                    imm10_5 = (offset >> 5) & 0x3F
                    imm4_1 = (offset >> 1) & 0xF
                    imm11 = (offset >> 11) & 1
                    mach_code = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (5 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

            elif op == 'j':
                label = parts[1]
                if label in labels:
                    target = labels[label]
                    offset = target - pc
                    imm20 = (offset >> 20) & 1
                    imm10_1 = (offset >> 1) & 0x3FF
                    imm11 = (offset >> 11) & 1
                    imm19_12 = (offset >> 12) & 0xFF
                    mach_code = (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | (0 << 7) | 0x6F

            elif op == 'jal':
                rd = parse_reg(parts[1])
                label = parts[2]
                if label in labels:
                    target = labels[label]
                    offset = target - pc
                    imm20 = (offset >> 20) & 1
                    imm10_1 = (offset >> 1) & 0x3FF
                    imm11 = (offset >> 11) & 1
                    imm19_12 = (offset >> 12) & 0xFF
                    mach_code = (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | (rd << 7) | 0x6F
                
            elif op == 'ret':
                mach_code = 0x00008067
                
            elif op == 'xor':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (4 << 12) | (rd << 7) | 0x33

            elif op == 'andi':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                imm = parse_imm(parts[3])
                mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (7 << 12) | (rd << 7) | 0x13

            elif op == 'ori':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                imm = parse_imm(parts[3])
                mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (6 << 12) | (rd << 7) | 0x13

            elif op == 'or':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (6 << 12) | (rd << 7) | 0x33
            
            elif op == 'lui':
                rd = parse_reg(parts[1])
                imm_val = parse_imm(parts[2])
                mach_code = (to_hex(imm_val, 20) << 12) | (rd << 7) | 0x37

            elif op == 'jalr':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                imm = parse_imm(parts[3])
                mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x67

            elif op == 'auipc':
                rd = parse_reg(parts[1])
                imm_val = parse_imm(parts[2])
                mach_code = (to_hex(imm_val, 20) << 12) | (rd << 7) | 0x17
            
            elif op == 'fence':
                # Simplified FENCE (pred=succ=PIPO)
                mach_code = 0x0FF0000F
            
            elif op == 'ecall':
                mach_code = 0x00000073

            elif op == 'ebreak':
                mach_code = 0x00100073

            elif op == 'csrrw':
                rd = parse_reg(parts[1])
                csr = parse_imm(parts[2])
                rs1 = parse_reg(parts[3])
                mach_code = (csr << 20) | (rs1 << 15) | (1 << 12) | (rd << 7) | 0x73

            elif op == 'csrrs':
                rd = parse_reg(parts[1])
                csr = parse_imm(parts[2])
                rs1 = parse_reg(parts[3])
                mach_code = (csr << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x73
            
            # --- LOGIC & SHIFTS (R-Type) ---
            elif op == 'and':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (7 << 12) | (rd << 7) | 0x33

            elif op == 'sll':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (1 << 12) | (rd << 7) | 0x33

            elif op == 'srl':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x33

            elif op == 'sra':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0x20 << 25) | (rs2 << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x33
            
            # --- COMPARE (R-Type) ---
            elif op == 'slt':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x33

            elif op == 'sltu':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                rs2 = parse_reg(parts[3])
                mach_code = (0 << 25) | (rs2 << 20) | (rs1 << 15) | (3 << 12) | (rd << 7) | 0x33

            # --- LOGIC & SHIFTS (I-Type) ---
            elif op == 'xori':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                imm = parse_imm(parts[3])
                mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (4 << 12) | (rd << 7) | 0x13
            
            elif op == 'slti':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                imm = parse_imm(parts[3])
                mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x13

            elif op == 'sltiu':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                imm = parse_imm(parts[3])
                mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (3 << 12) | (rd << 7) | 0x13
            
            elif op == 'srai':
                rd = parse_reg(parts[1])
                rs1 = parse_reg(parts[2])
                shamt = parse_imm(parts[3])
                mach_code = (0x20 << 25) | (shamt << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x13

            # --- LOADS (I-Type) ---
            elif op in ['lb', 'lh', 'lbu', 'lhu']:
                rd = parse_reg(parts[1])
                match = re.match(r'(.+)\((.+)\)', parts[2])
                if match:
                    imm = parse_imm(match.group(1))
                    rs1 = parse_reg(match.group(2))
                    # funct3 mapping
                    f3 = 0
                    if op == 'lh': f3 = 1
                    if op == 'lbu': f3 = 4
                    if op == 'lhu': f3 = 5
                    if op == 'lb': f3 = 0
                    mach_code = (to_hex(imm, 12) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x03

            # --- STORES (S-Type) ---
            elif op in ['sb', 'sh']:
                rs2 = parse_reg(parts[1])
                match = re.match(r'(.+)\((.+)\)', parts[2])
                if match:
                    imm = parse_imm(match.group(1))
                    rs1 = parse_reg(match.group(2))
                    f3 = 0
                    if op == 'sh': f3 = 1
                    if op == 'sb': f3 = 0
                    imm11_5 = (imm >> 5) & 0x7F
                    imm4_0 = imm & 0x1F
                    mach_code = (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (imm4_0 << 7) | 0x23

            
            elif op == '.word':
                val = parse_imm(parts[1])
                mach_code = val & 0xFFFFFFFF
            
            else:
                # Unrecognized instruction!
                print(f"ERROR: Unrecognized instruction '{op}' at PC={pc}: {line}")
                print(f"       This instruction is not supported by the assembler.")
                raise ValueError(f"Unsupported instruction: {op}")

        except Exception as e:
            print(f"Error assembling line at PC={pc}: {line}")
            print(f"  Exception: {e}")
            raise  # Re-raise to stop assembly
            
        hex_output.append(f"{mach_code:08x}")

    with open(output_file, 'w') as f:
        for h in hex_output:
            f.write(h + '\n')
    print(f"Assembled {len(hex_output)} instructions to {output_file}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 simple_assembler.py input.s output.hex")
    else:
        assemble(sys.argv[1], sys.argv[2])
