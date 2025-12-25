#!/usr/bin/env python3
"""
VCD Analyzer for RV32I Core
Comprehensive VCD analysis with multiple text-based trace outputs
"""

import sys
import os
import re
from pathlib import Path

# Import disassembler
from riscv_disasm import disassemble


class VCDAnalyzer:
    """
    Comprehensive VCD analysis tool for RV32I Core debugging
    
    Generates 4 types of analysis outputs:
    1. Execution Trace (PC + instruction flow)
    2. Pipeline Trace (stage-by-stage visualization)
    3. Events Trace (branch/hazard/system events)
    4. Final State (register file + memory dumps)
    """
    
    def __init__(self, vcd_path):
        self.vcd_path = vcd_path
        self.signals = {}
        self.signal_map = {}  # VCD identifier -> signal name
        self.timestamps = []
        self.cycles = []
        
        # Parse VCD on init
        self._parse_vcd()
    
    def _parse_vcd(self):
        """Parse VCD file and extract all required signals"""
        print(f"[VCD Analyzer] Parsing {self.vcd_path}...")
        
        # Define signals we want to extract
        required_signals = {
            'PC_IF', 'PC_ID', 'PC_EX', 'PC_MEM', 'PC_WB',
            'instr',
            'opcode_EX', 'opcode_MEM', 'opcode_WB',
            'flush', 'stall_FU', 'nop_EX',
            'Z', 'N', 'PC_sel'
        }
        
        with open(self.vcd_path, 'r') as f:
            lines = f.readlines()
        
        # Phase 1: Parse variable definitions
        in_definitions = True
        for line in lines:
            line = line.strip()
            
            if line.startswith('$var'):
                # Format: $var wire 32 ! PC_IF [31:0] $end
                parts = line.split()
                if len(parts) >= 5:
                    identifier = parts[3]
                    var_name = parts[4]
                    
                    # Check if this is a signal we want
                    for sig in required_signals:
                        if sig in var_name:
                            self.signal_map[identifier] = sig
                            self.signals[sig] = {}
                            break
            
            elif line.startswith('$enddefinitions'):
                in_definitions = False
                break
        
        print(f"[VCD Analyzer] Found {len(self.signal_map)} signals")
        
        # Phase 2: Parse value changes (after definitions)
        current_time = 0
        
        for line in lines:
            line = line.strip()
            
            # Skip definition section
            if in_definitions:
                if line.startswith('$enddefinitions'):
                    in_definitions = False
                continue
            
            # Parse value changes (after definitions)
            # Time stamp
            if line.startswith('#'):
                current_time = int(line[1:])
                if current_time not in self.timestamps:
                    self.timestamps.append(current_time)
            
            # Binary value: b10101010 !
            elif line.startswith('b'):
                match = re.match(r'b([01x]+)\s+(\S+)', line)
                if match:
                    binary_val = match.group(1)
                    identifier = match.group(2)
                    
                    if identifier in self.signal_map:
                        sig_name = self.signal_map[identifier]
                        try:
                            # Convert binary to int (replace x with 0)
                            val = int(binary_val.replace('x', '0'), 2)
                            self.signals[sig_name][current_time] = val
                        except ValueError:
                            pass
            
            # Single bit value: 0! or 1!
            elif len(line) >= 2 and line[0] in ['0', '1']:
                value = int(line[0])
                identifier = line[1:]
                if identifier in self.signal_map:
                    sig_name = self.signal_map[identifier]
                    self.signals[sig_name][current_time] = value
        
        # Extract cycle numbers (assuming 10 time units per cycle)
        self.cycles = [t // 10 for t in self.timestamps if t % 10 == 5]
        
        print(f"[VCD Analyzer] Parsed {len(self.timestamps)} timestamps")
        print(f"[VCD Analyzer] Cycles: {len(self.cycles)}")
    
    def _get_signal(self, sig_name, time):
        """Get signal value at specific time (with sample-and-hold)"""
        if sig_name not in self.signals:
            return None
        
        # Find most recent value
        sig_data = self.signals[sig_name]
        last_val = None
        
        for t in sorted(sig_data.keys()):
            if t > time:
                break
            last_val = sig_data[t]
        
        return last_val
    
    def generate_exec_trace(self, output_path):
        """
        Generate execution trace (IF stage)
        Format: Cycle | PC | Hex | Disassembly
        """
        print(f"[VCD Analyzer] Generating execution trace...")
        
        lines = []
        lines.append("=" * 100)
        lines.append("RV32I Core - Execution Trace (IF Stage)")
        lines.append("=" * 100)
        lines.append(f"Source: {Path(self.vcd_path).name}")
        lines.append("")
        lines.append(f"{'Cycle':<8} | {'PC':<10} | {'Hex':<10} | {'Disassembly':<50}")
        lines.append("-" * 100)
        
        for cycle in self.cycles:
            time = cycle * 10 + 5  # Posedge at +5
            
            pc = self._get_signal('PC_IF', time)
            instr = self._get_signal('instr', time)
            
            if pc is None or instr is None:
                continue
            
            # Disassemble
            disasm = disassemble(instr)
            
            lines.append(f"{cycle:<8} | 0x{pc:08x} | 0x{instr:08x} | {disasm:<50}")
        
        lines.append("-" * 100)
        lines.append(f"Total cycles: {len(self.cycles)}")
        
        # Write to file
        with open(output_path, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"[VCD Analyzer] ✓ Execution trace: {output_path}")
    
    def generate_pipeline_trace(self, output_path):
        """
        Generate pipeline trace (hybrid format)
        Format: Cycle | IF_PC ID_PC EX_PC MEM_PC WB_PC | Controls
        """
        print(f"[VCD Analyzer] Generating pipeline trace...")
        
        lines = []
        lines.append("=" * 120)
        lines.append("RV32I Core - Pipeline Trace (Hybrid Format)")
        lines.append("=" * 120)
        lines.append(f"Source: {Path(self.vcd_path).name}")
        lines.append("")
        lines.append(f"{'Cycle':<6} | {'IF_PC':<8} {'ID_PC':<8} {'EX_PC':<8} {'MEM_PC':<8} {'WB_PC':<8} | {'EX_op':<6} {'Flush':<5} {'Stall':<5} | {'Notes':<20}")
        lines.append("-" * 120)
        
        for cycle in self.cycles:
            time = cycle * 10 + 5
            
            # Get PC values for all stages
            pc_if = self._get_signal('PC_IF', time)
            pc_id = self._get_signal('PC_ID', time)
            pc_ex = self._get_signal('PC_EX', time)
            pc_mem = self._get_signal('PC_MEM', time)
            pc_wb = self._get_signal('PC_WB', time)
            
            # Get control signals
            opc_ex = self._get_signal('opcode_EX', time)
            flush = self._get_signal('flush', time)
            stall = self._get_signal('stall_FU', time)
            
            # Format values
            pc_if_str = f"{pc_if:08x}" if pc_if is not None else "--------"
            pc_id_str = f"{pc_id:08x}" if pc_id is not None else "--------"
            pc_ex_str = f"{pc_ex:08x}" if pc_ex is not None else "--------"
            pc_mem_str = f"{pc_mem:08x}" if pc_mem is not None else "--------"
            pc_wb_str = f"{pc_wb:08x}" if pc_wb is not None else "--------"
            
            opc_str = f"0x{opc_ex:02x}" if opc_ex is not None else "0x--"
            flush_str = str(flush) if flush is not None else "-"
            stall_str = str(stall) if stall is not None else "-"
            
            # Add notes for important events
            notes = ""
            if flush == 1:
                notes = "FLUSH!"
            elif stall == 1:
                notes = "STALL"
            elif opc_ex == 0x73:
                notes = "EBREAK in EX"
            
            lines.append(f"{cycle:<6} | {pc_if_str} {pc_id_str} {pc_ex_str} {pc_mem_str} {pc_wb_str} | {opc_str:<6} {flush_str:<5} {stall_str:<5} | {notes:<20}")
        
        lines.append("-" * 120)
        lines.append(f"Total cycles: {len(self.cycles)}")
        
        with open(output_path, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"[VCD Analyzer] ✓ Pipeline trace: {output_path}")
    
    def generate_events(self, output_path, event_filter=None):
        """
        Generate events trace (branch/hazard/system events)
        Format: Separate sections for each event type
        """
        print(f"[VCD Analyzer] Generating events trace...")
        
        lines = []
        lines.append("=" * 100)
        lines.append("RV32I Core - Events Trace")
        lines.append("=" * 100)
        lines.append(f"Source: {Path(self.vcd_path).name}")
        lines.append("")
        
        # Collect events
        branch_events = []
        system_events = []
        
        for cycle in self.cycles:
            time = cycle * 10 + 5
            
            # Branch events (opcode 0x63 = BRANCH)
            opc_ex = self._get_signal('opcode_EX', time)
            if opc_ex == 0x63:
                pc_ex = self._get_signal('PC_EX', time)
                flush = self._get_signal('flush', time)
                pc_sel = self._get_signal('PC_sel', time)
                
                # Determine if taken
                taken = "YES" if flush == 1 else "NO"
                target = "?" if pc_ex is None else f"0x{pc_ex:08x}"
                
                branch_events.append({
                    'cycle': cycle,
                    'pc': pc_ex,
                    'target': target,
                    'taken': taken,
                    'flush': flush
                })
            
            # System events (EBREAK/ECALL - opcode 0x73)
            opc_wb = self._get_signal('opcode_WB', time)
            if opc_wb == 0x73:
                pc_wb = self._get_signal('PC_WB', time)
                system_events.append({
                    'cycle': cycle,
                    'event': 'EBREAK/ECALL',
                    'pc': pc_wb,
                    'details': 'Program termination'
                })
        
        # Write branch events
        lines.append("=== BRANCH EVENTS ===")
        lines.append(f"{'Cycle':<6} | {'PC':<10} | {'Target':<10} | {'Taken':<5} | {'Flush':<5}")
        lines.append("-" * 50)
        
        if branch_events:
            for evt in branch_events:
                pc_str = f"0x{evt['pc']:08x}" if evt['pc'] is not None else "0x--------"
                lines.append(f"{evt['cycle']:<6} | {pc_str:<10} | {evt['target']:<10} | {evt['taken']:<5} | {evt['flush']:<5}")
        else:
            lines.append("  (No branch events)")
        
        lines.append("")
        
        # Write system events
        lines.append("=== SYSTEM EVENTS ===")
        lines.append(f"{'Cycle':<6} | {'Event':<15} | {'PC':<10} | {'Details':<30}")
        lines.append("-" * 70)
        
        if system_events:
            for evt in system_events:
                pc_str = f"0x{evt['pc']:08x}" if evt['pc'] is not None else "0x--------"
                lines.append(f"{evt['cycle']:<6} | {evt['event']:<15} | {pc_str:<10} | {evt['details']:<30}")
        else:
            lines.append("  (No system events)")
        
        lines.append("")
        lines.append("=" * 100)
        lines.append(f"Total branch events: {len(branch_events)}")
        lines.append(f"Total system events: {len(system_events)}")
        
        with open(output_path, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"[VCD Analyzer] ✓ Events trace: {output_path}")
    
    def generate_final_state(self, output_path):
        """
        Generate final state dump (regfile + memory at last cycle)
        Note: Requires VCD to have regfile/memory signals
        """
        print(f"[VCD Analyzer] Generating final state dump...")
        
        lines = []
        lines.append("=" * 100)
        lines.append("RV32I Core - Final State Dump")
        lines.append("=" * 100)
        lines.append(f"Source: {Path(self.vcd_path).name}")
        lines.append(f"Final Cycle: {self.cycles[-1] if self.cycles else 0}")
        lines.append("")
        
        # Note: Register file and memory dumps require additional VCD signals
        # For now, show what's available
        lines.append("=== AVAILABLE SIGNALS (Final Cycle) ===")
        
        if self.cycles:
            final_time = self.cycles[-1] * 10 + 5
            
            for sig_name in sorted(self.signals.keys()):
                val = self._get_signal(sig_name, final_time)
                if val is not None:
                    if isinstance(val, int) and val < 256:
                        lines.append(f"{sig_name:<20} = 0x{val:08x} ({val})")
                    else:
                        lines.append(f"{sig_name:<20} = 0x{val:08x}")
        
        lines.append("")
        lines.append("=" * 100)
        lines.append("Note: Full register file and memory dumps require additional VCD signals")
        lines.append("      Add rf[0]-rf[31] and Memory[0]-Memory[511] to VCD dump for complete state")
        
        with open(output_path, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"[VCD Analyzer] ✓ Final state dump: {output_path}")

    
    def generate(self, output_type, output_path):
        """Generate specific output type"""
        if output_type == 'exec':
            self.generate_exec_trace(output_path)
        elif output_type == 'pipeline':
            self.generate_pipeline_trace(output_path)
        elif output_type == 'events':
            self.generate_events(output_path)
        elif output_type == 'state':
            self.generate_final_state(output_path)
        else:
            print(f"[VCD Analyzer] Warning: Unknown output type '{output_type}'")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 vcd_analyzer.py <vcd_file> <output_dir>")
        print("Example: python3 vcd_analyzer.py test.vcd output/")
        sys.exit(1)
    
    vcd_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    if not os.path.exists(vcd_file):
        print(f"Error: VCD file not found: {vcd_file}")
        sys.exit(1)
    
    os.makedirs(output_dir, exist_ok=True)
    
    # Create analyzer
    analyzer = VCDAnalyzer(vcd_file)
    
    # Generate all analysis outputs
    print("\n" + "="*60)
    print("Generating analysis outputs...")
    print("="*60)
    
    analyzer.generate('exec', os.path.join(output_dir, 'exec_trace.txt'))
    analyzer.generate('pipeline', os.path.join(output_dir, 'pipeline_trace.txt'))
    analyzer.generate('events', os.path.join(output_dir, 'events.txt'))
    analyzer.generate('state', os.path.join(output_dir, 'final_state.txt'))
    
    print("\n✅ All analysis traces generated successfully!")
    print(f"📁 Output directory: {output_dir}")

