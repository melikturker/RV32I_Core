#!/usr/bin/env python3
"""
VCD Trace Parser for RV32I Core
Extracts PC, Instruction signals from VCD waveform and generates execution trace
"""

import sys
import re
from pathlib import Path

def parse_vcd_signals(vcd_file, signals_to_extract):
    """
    Parse VCD file and extract specified signals
    
    Args:
        vcd_file: Path to VCD file
        signals_to_extract: dict of signal names to extract
            e.g., {"PC_IF": None, "instr": None}
    
    Returns:
        dict: {signal_name: {time: value, ...}}
    """
    signal_map = {}  # identifier -> signal_name
    signal_values = {sig: {} for sig in signals_to_extract}  # signal_name -> {time: value}
    current_time = 0
    
    with open(vcd_file, 'r') as f:
        in_definitions = True
        
        for line in f:
            line = line.strip()
            
            # Parse variable definitions
            if in_definitions:
                if line.startswith('$var'):
                    # $var wire 32 ! PC_IF [31:0] $end
                    parts = line.split()
                    if len(parts) >= 5:
                        var_type = parts[1]
                        bit_width = parts[2]
                        identifier = parts[3]
                        var_name = parts[4]
                        
                        # Check if this is a signal we want
                        for sig in signals_to_extract:
                            if sig in var_name:
                                signal_map[identifier] = sig
                                break
                
                elif line.startswith('$enddefinitions'):
                    in_definitions = False
                    continue
            
            # Parse value changes
            else:
                # Time stamp: #12345
                if line.startswith('#'):
                    current_time = int(line[1:])
                
                # Binary value: b10101010 !
                elif line.startswith('b'):
                    match = re.match(r'b([01x]+)\s+(\S+)', line)
                    if match:
                        binary_val = match.group(1)
                        identifier = match.group(2)
                        
                        if identifier in signal_map:
                            sig_name = signal_map[identifier]
                            # Convert binary to hex
                            try:
                                val = int(binary_val.replace('x', '0'), 2)
                                signal_values[sig_name][current_time] = val
                            except ValueError:
                                pass  # Skip invalid values
    
    return signal_values


def generate_exec_trace(vcd_file, output_file, max_cycles=None):
    """
    Generate execution trace from VCD file
    
    Args:
        vcd_file: Path to VCD waveform file
        output_file: Path to output trace file
        max_cycles: Optional max cycles to parse
    """
    from riscv_disasm import disassemble
    
    print(f"[Trace] Parsing VCD: {vcd_file}")
    
    # Extract signals: PC and instruction from IF stage
    signals = parse_vcd_signals(vcd_file, {"PC_IF": None, "instr": None})
    
    pc_values = signals.get("PC_IF", {})
    instr_values = signals.get("instr", {})
    
    if not pc_values or not instr_values:
        print(f"[Trace] Error: Could not find PC_IF or instr signals in VCD")
        print(f"[Trace] Found signals: {list(signals.keys())}")
        return
    
    # Get all unique timestamps
    all_times = sorted(set(list(pc_values.keys()) + list(instr_values.keys())))
    
    # Apply max_cycles filter
    if max_cycles:
        # Each cycle has 2 edges (rising + falling), so time = cycle * 2
        max_time = max_cycles * 10  # Conservative estimate
        all_times = [t for t in all_times if t <= max_time]
    
    # Track last values (for sample-and-hold)
    last_pc = 0
    last_instr = 0
    
    trace_lines = []
    trace_lines.append("=" * 100)
    trace_lines.append("RV32I Core Execution Trace (IF Stage)")
    trace_lines.append("=" * 100)
    trace_lines.append(f"Source: {Path(vcd_file).name}")
    trace_lines.append("")
    trace_lines.append(f"{'Cycle':<8} | {'PC':<10} | {'Instruction':<12} | {'Disassembly':<50}")
    trace_lines.append("-" * 100)
    
    cycle = 0
    for time_val in all_times:
        # Update signals if changed
        if time_val in pc_values:
            last_pc = pc_values[time_val]
        if time_val in instr_values:
            last_instr = instr_values[time_val]
        
        # Only log on rising edge (assume clk toggles every unit time)
        # Time 0, 2, 4, 6, ... are rising edges
        if time_val % 10 == 0 and time_val > 0:  # Rising edge
            cycle += 1
            
            # Disassemble instruction
            disasm = disassemble(last_instr)
            
            trace_lines.append(
                f"{cycle:<8} | 0x{last_pc:08x} | 0x{last_instr:08x}   | {disasm:<50}"
            )
    
    # Write to file
    with open(output_file, 'w') as f:
        f.write('\n'.join(trace_lines))
    
    print(f"[Trace] Generated execution trace: {output_file}")
    print(f"[Trace] Total cycles logged: {cycle}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 vcd_trace_parser.py <vcd_file> [output_file] [max_cycles]")
        sys.exit(1)
    
    vcd_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "exec_trace.txt"
    max_cycles = int(sys.argv[3]) if len(sys.argv) > 3 else None
    
    generate_exec_trace(vcd_file, output_file, max_cycles)
