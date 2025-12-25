#!/usr/bin/env python3
"""
Simple RISC-V RV32I Disassembler
Converts 32-bit instruction hex to assembly mnemonic
"""

def disassemble(instr_hex):
    """
    Disassemble a single 32-bit RISC-V instruction
    
    Args:
        instr_hex: int or str - 32-bit instruction value
    
    Returns:
        str - Assembly mnemonic (e.g., "addi x1, x0, 5")
    """
    if isinstance(instr_hex, str):
        instr = int(instr_hex, 16)
    else:
        instr = instr_hex
    
    # Handle NOP/invalid
    if instr == 0:
        return "nop (illegal)"
    
    # Extract fields
    opcode = instr & 0x7F
    rd = (instr >> 7) & 0x1F
    funct3 = (instr >> 12) & 0x7
    rs1 = (instr >> 15) & 0x1F
    rs2 = (instr >> 20) & 0x1F
    funct7 = (instr >> 25) & 0x7F

    # I-type immediate (sign-extended)
    imm_i = (instr >> 20) & 0xFFF
    if imm_i & 0x800:  # Sign extend
        imm_i |= 0xFFFFF000
    imm_i = imm_i & 0xFFFFFFFF  # Keep as 32-bit

    # S-type immediate
    imm_s = ((instr >> 7) & 0x1F) | ((instr >> 25) << 5)
    if imm_s & 0x800:
        imm_s |= 0xFFFFF000
    imm_s = imm_s & 0xFFFFFFFF

    # B-type immediate
    imm_b = (((instr >> 8) & 0xF) << 1) | (((instr >> 25) & 0x3F) << 5) | \
            (((instr >> 7) & 0x1) << 11) | (((instr >> 31) & 0x1) << 12)
    if imm_b & 0x1000:
        imm_b |= 0xFFFFE000
    imm_b = imm_b & 0xFFFFFFFF

    # U-type immediate
    imm_u = instr & 0xFFFFF000

    # J-type immediate
    imm_j = (((instr >> 21) & 0x3FF) << 1) | (((instr >> 20) & 0x1) << 11) | \
            (((instr >> 12) & 0xFF) << 12) | (((instr >> 31) & 0x1) << 20)
    if imm_j & 0x100000:
        imm_j |= 0xFFE00000
    imm_j = imm_j & 0xFFFFFFFF

    # Register names
    reg = lambda r: f"x{r}" if r != 0 else "x0"
    
    # Convert to signed for display
    def to_signed(val, bits=32):
        if val & (1 << (bits - 1)):
            return val - (1 << bits)
        return val
    
    # Decode by opcode
    try:
        # R-type ALU
        if opcode == 0b0110011:
            if funct3 == 0b000 and funct7 == 0b0000000:
                return f"add {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b000 and funct7 == 0b0100000:
                return f"sub {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b111:
                return f"and {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b110:
                return f"or {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b100:
                return f"xor {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b001:
                return f"sll {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b101 and funct7 == 0b0000000:
                return f"srl {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b101 and funct7 == 0b0100000:
                return f"sra {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b010:
                return f"slt {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
            elif funct3 == 0b011:
                return f"sltu {reg(rd)}, {reg(rs1)}, {reg(rs2)}"
        
        # I-type ALU
        elif opcode == 0b0010011:
            imm_signed = to_signed(imm_i, 12)
            if funct3 == 0b000:
                return f"addi {reg(rd)}, {reg(rs1)}, {imm_signed}"
            elif funct3 == 0b111:
                return f"andi {reg(rd)}, {reg(rs1)}, {imm_signed}"
            elif funct3 == 0b110:
                return f"ori {reg(rd)}, {reg(rs1)}, {imm_signed}"
            elif funct3 == 0b100:
                return f"xori {reg(rd)}, {reg(rs1)}, {imm_signed}"
            elif funct3 == 0b001:
                shamt = rs2
                return f"slli {reg(rd)}, {reg(rs1)}, {shamt}"
            elif funct3 == 0b101 and funct7 == 0b0000000:
                shamt = rs2
                return f"srli {reg(rd)}, {reg(rs1)}, {shamt}"
            elif funct3 == 0b101 and funct7 == 0b0100000:
                shamt = rs2
                return f"srai {reg(rd)}, {reg(rs1)}, {shamt}"
            elif funct3 == 0b010:
                return f"slti {reg(rd)}, {reg(rs1)}, {imm_signed}"
            elif funct3 == 0b011:
                return f"sltiu {reg(rd)}, {reg(rs1)}, {imm_signed}"
        
        # Load
        elif opcode == 0b0000011:
            imm_signed = to_signed(imm_i, 12)
            if funct3 == 0b010:
                return f"lw {reg(rd)}, {imm_signed}({reg(rs1)})"
            elif funct3 == 0b000:
                return f"lb {reg(rd)}, {imm_signed}({reg(rs1)})"
            elif funct3 == 0b001:
                return f"lh {reg(rd)}, {imm_signed}({reg(rs1)})"
            elif funct3 == 0b100:
                return f"lbu {reg(rd)}, {imm_signed}({reg(rs1)})"
            elif funct3 == 0b101:
                return f"lhu {reg(rd)}, {imm_signed}({reg(rs1)})"
        
        # Store
        elif opcode == 0b0100011:
            imm_signed = to_signed(imm_s, 12)
            if funct3 == 0b010:
                return f"sw {reg(rs2)}, {imm_signed}({reg(rs1)})"
            elif funct3 == 0b000:
                return f"sb {reg(rs2)}, {imm_signed}({reg(rs1)})"
            elif funct3 == 0b001:
                return f"sh {reg(rs2)}, {imm_signed}({reg(rs1)})"
        
        # Branch
        elif opcode == 0b1100011:
            imm_signed = to_signed(imm_b, 13)
            if funct3 == 0b000:
                return f"beq {reg(rs1)}, {reg(rs2)}, {imm_signed}"
            elif funct3 == 0b001:
                return f"bne {reg(rs1)}, {reg(rs2)}, {imm_signed}"
            elif funct3 == 0b100:
                return f"blt {reg(rs1)}, {reg(rs2)}, {imm_signed}"
            elif funct3 == 0b101:
                return f"bge {reg(rs1)}, {reg(rs2)}, {imm_signed}"
            elif funct3 == 0b110:
                return f"bltu {reg(rs1)}, {reg(rs2)}, {imm_signed}"
            elif funct3 == 0b111:
                return f"bgeu {reg(rs1)}, {reg(rs2)}, {imm_signed}"
        
        # JAL
        elif opcode == 0b1101111:
            imm_signed = to_signed(imm_j, 21)
            if rd == 0:
                return f"j {imm_signed}"
            return f"jal {reg(rd)}, {imm_signed}"
        
        # JALR
        elif opcode == 0b1100111:
            imm_signed = to_signed(imm_i, 12)
            if rd == 0 and rs1 == 1 and imm_i == 0:
                return "ret"
            return f"jalr {reg(rd)}, {reg(rs1)}, {imm_signed}"
        
        # LUI
        elif opcode == 0b0110111:
            return f"lui {reg(rd)}, 0x{imm_u >> 12:x}"
        
        # AUIPC
        elif opcode == 0b0010111:
            return f"auipc {reg(rd)}, 0x{imm_u >> 12:x}"
        
        # SYSTEM
        elif opcode == 0b1110011:
            if instr == 0x00000073:
                return "ecall"
            elif instr == 0x00100073:
                return "ebreak"
            elif funct3 == 0b000:
                return f"system 0x{instr:08x}"
        
        # FENCE
        elif opcode == 0b0001111:
            return "fence"
        
        return f"unknown 0x{instr:08x}"
    
    except:
        return f"invalid 0x{instr:08x}"


if __name__ == "__main__":
    # Test cases
    test_cases = [
        (0x00100093, "addi x1, x0, 1"),
        (0x002081b3, "add x3, x1, x2"),
        (0x00100073, "ebreak"),
        (0xfe209ee3, "bne x1, x2, -4"),
    ]
    
    print("RISC-V Disassembler Test:")
    for instr_hex, expected in test_cases:
        result = disassemble(instr_hex)
        status = "✓" if expected in result else "✗"
        print(f"{status} 0x{instr_hex:08x} -> {result}")
