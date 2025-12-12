import ctypes

class RISCV_Model:
    def __init__(self):
        # 32 registers, initialized to 0
        self.regs = [0] * 32
        # Data memory (address: value), sparse map
        self.d_mem = {}  
        self.pc = 0
        self.trace = []

    def reset(self):
        self.regs = [0] * 32
        self.d_mem = {}
        self.pc = 0
        self.trace = []

    def to_signed(self, val):
        return ctypes.c_int32(val).value

    def to_unsigned(self, val):
        return ctypes.c_uint32(val).value

    def step(self, opcode, rd, rs1, rs2, funct3, funct7, imm, trace=False, inst=0):
        # Always enforce x0 = 0
        self.regs[0] = 0
        
        # Read source values (unsigned by default for logic)
        val1 = self.regs[rs1]
        val2 = self.regs[rs2]
        
        # Helper for signed arithmetic
        s_val1 = self.to_signed(val1)
        s_val2 = self.to_signed(val2)
        
        next_pc = self.pc + 4
        
        # Execute based on Opcode
        
        # R-Type
        if opcode == 0x33: 
            if funct3 == 0x0: # ADD / SUB
                if funct7 == 0x00: self.regs[rd] = self.to_unsigned(s_val1 + s_val2) # ADD
                elif funct7 == 0x20: self.regs[rd] = self.to_unsigned(s_val1 - s_val2) # SUB
            elif funct3 == 0x1: # SLL
                self.regs[rd] = (val1 << (val2 & 0x1F)) & 0xFFFFFFFF
            elif funct3 == 0x2: # SLT
                self.regs[rd] = 1 if s_val1 < s_val2 else 0
            elif funct3 == 0x3: # SLTU
                self.regs[rd] = 1 if val1 < val2 else 0
            elif funct3 == 0x4: # XOR
                self.regs[rd] = val1 ^ val2
            elif funct3 == 0x5: # SRL / SRA
                if funct7 == 0x00: self.regs[rd] = (val1 >> (val2 & 0x1F)) # SRL
                elif funct7 == 0x20: self.regs[rd] = self.to_unsigned(s_val1 >> (val2 & 0x1F)) # SRA
            elif funct3 == 0x6: # OR
                self.regs[rd] = val1 | val2
            elif funct3 == 0x7: # AND
                self.regs[rd] = val1 & val2

        # I-Type (Arithmetic)
        elif opcode == 0x13:
            s_imm = self.to_signed(imm)
            if funct3 == 0x0: # ADDI
                self.regs[rd] = self.to_unsigned(s_val1 + s_imm)
            elif funct3 == 0x2: # SLTI
                self.regs[rd] = 1 if s_val1 < s_imm else 0
            elif funct3 == 0x3: # SLTIU
                # For SLTIU, immediate is sign-extended first, then treated as unsigned comparison
                self.regs[rd] = 1 if val1 < self.to_unsigned(s_imm) else 0
            elif funct3 == 0x4: # XORI
                self.regs[rd] = val1 ^ s_imm # Logic ops use sign-extended imm but generally bitwise
            elif funct3 == 0x6: # ORI
                self.regs[rd] = val1 | s_imm
            elif funct3 == 0x7: # ANDI
                self.regs[rd] = val1 & s_imm
            elif funct3 == 0x1: # SLLI
                self.regs[rd] = (val1 << (imm & 0x1F)) & 0xFFFFFFFF
            elif funct3 == 0x5: # SRLI / SRAI
                shamt = imm & 0x1F
                if (imm & 0x400): # SRAI (check bit 10 of imm, or funct7 equivalent)
                     self.regs[rd] = self.to_unsigned(s_val1 >> shamt)
                else: # SRLI
                     self.regs[rd] = (val1 >> shamt)

        # U-Type
        elif opcode == 0x37: # LUI
            self.regs[rd] = (imm & 0xFFFFF000) 
        elif opcode == 0x17: # AUIPC
            self.regs[rd] = self.to_unsigned(self.pc + (imm & 0xFFFFF000))
            
        # J-Type (JAL)
        elif opcode == 0x6F: 
            self.regs[rd] = self.to_unsigned(self.pc + 4)
            next_pc = self.pc + imm
            
        # JALR
        elif opcode == 0x67:
            s_imm = self.to_signed(imm)
            self.regs[rd] = self.to_unsigned(self.pc + 4)
            next_pc = (self.regs[rs1] + s_imm) & 0xFFFFFFFE
            
        # B-Type (Branches)
        elif opcode == 0x63:
            s_imm = self.to_signed(imm) # Branch offset
            take_branch = False
            if funct3 == 0x0: # BEQ
                take_branch = (val1 == val2)
            elif funct3 == 0x1: # BNE
                take_branch = (val1 != val2)
            elif funct3 == 0x4: # BLT
                take_branch = (s_val1 < s_val2)
            elif funct3 == 0x5: # BGE
                take_branch = (s_val1 >= s_val2)
            elif funct3 == 0x6: # BLTU
                take_branch = (val1 < val2)
            elif funct3 == 0x7: # BGEU
                take_branch = (val1 >= val2)
            
            if take_branch:
                next_pc = self.pc + s_imm
                
        # Load
        elif opcode == 0x03:
            s_imm = self.to_signed(imm)
            addr = (self.regs[rs1] + s_imm) & 0xFFFFFFFF
            # Memory is byte-addressed but for simplification we can align or support byte access
            # Simple model: assume word aligned for now or handle naive byte/half
            # Since self.d_mem is a dictionary, we can key by address
            
            # Helper to read byte
            def read_byte(a): return self.d_mem.get(a, 0)
            
            data = 0
            if funct3 == 0x0: # LB
                val = read_byte(addr)
                if val & 0x80: data = val | 0xFFFFFF00 
                else: data = val
            elif funct3 == 0x1: # LH
                val = read_byte(addr) | (read_byte(addr+1) << 8)
                if val & 0x8000: data = val | 0xFFFF0000
                else: data = val
            elif funct3 == 0x2: # LW
                val = read_byte(addr) | (read_byte(addr+1) << 8) | (read_byte(addr+2) << 16) | (read_byte(addr+3) << 24)
                data = val
            elif funct3 == 0x4: # LBU
                data = read_byte(addr)
            elif funct3 == 0x5: # LHU
                data = read_byte(addr) | (read_byte(addr+1) << 8)
            
            self.regs[rd] = self.to_unsigned(data)
            
        # Store
        elif opcode == 0x23:
            s_imm = self.to_signed(imm) # Store offset is S-type imm
            addr = (self.regs[rs1] + s_imm) & 0xFFFFFFFF
            val = self.regs[rs2]
            
            if funct3 == 0x0: # SB
                self.d_mem[addr] = val & 0xFF
            elif funct3 == 0x1: # SH
                self.d_mem[addr] = val & 0xFF
                self.d_mem[addr+1] = (val >> 8) & 0xFF
            elif funct3 == 0x2: # SW
                self.d_mem[addr] = val & 0xFF
                self.d_mem[addr+1] = (val >> 8) & 0xFF
                self.d_mem[addr+2] = (val >> 16) & 0xFF
                self.d_mem[addr+3] = (val >> 24) & 0xFF
        
        # Enforce Register 0
        self.regs[0] = 0
        
        self.pc = next_pc
        
        if trace:
            # Simple trace entry
            entry = f"PC: {self.pc-4:08x} | Inst: {inst:08x} | Write: x{rd}={self.regs[rd]:x}"
            self.trace.append(entry)
            
        return self.regs

    def disassemble(self, inst):
        opcode = inst & 0x7F
        rd = (inst >> 7) & 0x1F
        funct3 = (inst >> 12) & 0x7
        rs1 = (inst >> 15) & 0x1F
        rs2 = (inst >> 20) & 0x1F
        funct7 = (inst >> 25) & 0x7F
        
        imm = 0
        s_imm = 0
        mnem = "UNK"
        asm = "UNKNOWN"
        
        regs = [f"x{i}" for i in range(32)]
        
        # R-Type
        if opcode == 0x33: 
            mnem = "UNK"
            if funct3 == 0x0: 
                if funct7 == 0x00: mnem = "ADD"
                elif funct7 == 0x20: mnem = "SUB"
            elif funct3 == 0x1: mnem = "SLL"
            elif funct3 == 0x2: mnem = "SLT"
            elif funct3 == 0x3: mnem = "SLTU"
            elif funct3 == 0x4: mnem = "XOR"
            elif funct3 == 0x5: 
                if funct7 == 0x00: mnem = "SRL"
                elif funct7 == 0x20: mnem = "SRA"
            elif funct3 == 0x6: mnem = "OR"
            elif funct3 == 0x7: mnem = "AND"
            asm = f"{mnem} {regs[rd]}, {regs[rs1]}, {regs[rs2]}"

        # I-Type
        elif opcode == 0x13 or opcode == 0x03 or opcode == 0x67: 
            imm = (inst >> 20) & 0xFFF
            if imm & 0x800: imm |= 0xFFFFF000
            s_imm = ctypes.c_int32(imm).value
            
            mnem = "UNK"
            if opcode == 0x03:
                if funct3 == 0x0: mnem = "LB"
                elif funct3 == 0x1: mnem = "LH"
                elif funct3 == 0x2: mnem = "LW"
                elif funct3 == 0x4: mnem = "LBU"
                elif funct3 == 0x5: mnem = "LHU"
                asm = f"{mnem} {regs[rd]}, {s_imm}({regs[rs1]})"
            elif opcode == 0x67:
                asm = f"JALR {regs[rd]}, {s_imm}({regs[rs1]})"
            elif opcode == 0x13:
                if funct3 == 0x0: mnem = "ADDI"
                elif funct3 == 0x2: mnem = "SLTI"
                elif funct3 == 0x3: mnem = "SLTIU"
                elif funct3 == 0x4: mnem = "XORI"
                elif funct3 == 0x6: mnem = "ORI"
                elif funct3 == 0x7: mnem = "ANDI"
                elif funct3 == 0x1: 
                    mnem = "SLLI"; s_imm = imm & 0x1F
                elif funct3 == 0x5: 
                    if imm & 0x400: mnem = "SRAI"
                    else: mnem = "SRLI"
                    s_imm = imm & 0x1F
                asm = f"{mnem} {regs[rd]}, {regs[rs1]}, {s_imm}"

        # S-Type
        elif opcode == 0x23: 
            imm = ((inst >> 25) & 0x7F) << 5 | ((inst >> 7) & 0x1F)
            if imm & 0x800: imm |= 0xFFFFF000
            s_imm = ctypes.c_int32(imm).value
            mnem = "UNK"
            if funct3 == 0x0: mnem = "SB"
            elif funct3 == 0x1: mnem = "SH"
            elif funct3 == 0x2: mnem = "SW"
            asm = f"{mnem} {regs[rs2]}, {s_imm}({regs[rs1]})"

        # B-Type
        elif opcode == 0x63: 
            imm = ((inst >> 31) & 0x1) << 12 | ((inst >> 7) & 0x1) << 11 | ((inst >> 25) & 0x3F) << 5 | ((inst >> 8) & 0xF) << 1
            if imm & 0x1000: imm |= 0xFFFFE000
            s_imm = ctypes.c_int32(imm).value
            mnem = "UNK"
            if funct3 == 0x0: mnem = "BEQ"
            elif funct3 == 0x1: mnem = "BNE"
            elif funct3 == 0x4: mnem = "BLT"
            elif funct3 == 0x5: mnem = "BGE"
            elif funct3 == 0x6: mnem = "BLTU"
            elif funct3 == 0x7: mnem = "BGEU"
            asm = f"{mnem} {regs[rs1]}, {regs[rs2]}, {s_imm}"

        # U-Type
        elif opcode == 0x37: # LUI
            imm = (inst >> 12) & 0xFFFFF
            asm = f"LUI {regs[rd]}, 0x{imm:x}"
        elif opcode == 0x17: # AUIPC
            imm = (inst >> 12) & 0xFFFFF
            asm = f"AUIPC {regs[rd]}, 0x{imm:x}"
            
        # J-Type
        elif opcode == 0x6F: 
            imm = ((inst >> 31) & 0x1) << 20 | ((inst >> 12) & 0xFF) << 12 | ((inst >> 20) & 0x1) << 11 | ((inst >> 21) & 0x3FF) << 1
            if imm & 0x100000: imm |= 0xFFE00000
            s_imm = ctypes.c_int32(imm).value
            asm = f"JAL {regs[rd]}, {s_imm}"
            
        return asm

    def step_hex(self, inst, trace=False):
        opcode = inst & 0x7F
        rd = (inst >> 7) & 0x1F
        funct3 = (inst >> 12) & 0x7
        rs1 = (inst >> 15) & 0x1F
        rs2 = (inst >> 20) & 0x1F
        funct7 = (inst >> 25) & 0x7F
        
        imm = 0
        
        # Decoding immediates
        if opcode == 0x33: # R-Type
            imm = 0
        elif opcode == 0x13 or opcode == 0x03 or opcode == 0x67: # I-Type (ALU, Load, JALR)
            imm = (inst >> 20) & 0xFFF
            if imm & 0x800: imm |= 0xFFFFF000 # Sign extend
        elif opcode == 0x23: # S-Type (Store)
            imm = ((inst >> 25) & 0x7F) << 5 | ((inst >> 7) & 0x1F)
            if imm & 0x800: imm |= 0xFFFFF000
        elif opcode == 0x63: # B-Type (Branch)
            imm = ((inst >> 31) & 0x1) << 12 | ((inst >> 7) & 0x1) << 11 | ((inst >> 25) & 0x3F) << 5 | ((inst >> 8) & 0xF) << 1
            if imm & 0x1000: imm |= 0xFFFFE000
        elif opcode == 0x37 or opcode == 0x17: # U-Type (LUI, AUIPC)
            imm = inst # step function expects full instruction for U-type or properly shifted value
        elif opcode == 0x6F: # J-Type (JAL)
            imm = ((inst >> 31) & 0x1) << 20 | ((inst >> 12) & 0xFF) << 12 | ((inst >> 20) & 0x1) << 11 | ((inst >> 21) & 0x3FF) << 1
            if imm & 0x100000: imm |= 0xFFE00000

        self.step(opcode, rd, rs1, rs2, funct3, funct7, imm, trace, inst)
        
        if trace:
             # Enhance trace with disassembly. 
             # Last entry was added by step(). Let's modify it or rely on step() to just add basics.
             # Wait, step() adds trace entry.
             # We want to use disassemble() there.
             # But step() doesn't have 'inst' unless passed. We passed it.
             # Let's override step()'s logging here if we want or modify step()
             # To keep it clean, let's just update the last trace entry?
             # Or better: Update step() to call disassemble if inst is provided? 
             # I can only edit 'step_hex' block here cleanly without large context.
             # Actually, step() adds: f"PC: ... | Inst: ... | Write: ..."
             # I can append Assembly to it.
             asm = self.disassemble(inst)
             self.trace[-1] = self.trace[-1] + f" | {asm}"
        
        return self.regs
