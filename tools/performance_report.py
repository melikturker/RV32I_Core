"""
Performance Metrics Report Generator

Parses performance counters and generates clean performance analysis report.
No branch predictor is assumed - flush events indicate control-flow penalties.
"""

import os

def parse_from_file(file_path):
    """Parse performance metrics from file"""
    try:
        with open(file_path, 'r') as f:
            metrics = {}
            for line in f:
                line = line.strip()
                if '=' in line:
                    key, value = line.split('=')
                    metrics[key.upper()] = int(value)
            return metrics
    except FileNotFoundError:
        return None
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
        return None

def calculate_metrics(raw):
    """Calculate all derived metrics from raw counters"""
    
    if not raw:
        return None
    
    # Raw counters
    cycles = raw.get('CYCLES', 0)
    instructions = raw.get('INSTRUCTIONS', 0)
    stalls = raw.get('STALLS', 0)
    bubbles = raw.get('BUBBLES', 0)
    flushes = raw.get('FLUSHES', 0)
    forwards = raw.get('FORWARDS', 0)
    raw_hazards = raw.get('RAW_HAZARDS', 0)
    cond_branches = raw.get('COND_BRANCHES', 0)
    uncond_branches = raw.get('UNCOND_BRANCHES', 0)
    
    # Avoid division by zero
    if instructions == 0 or cycles == 0:
        return None
    
    # === Core Execution Metrics ===
    cpi = cycles / instructions
    ipc = instructions / cycles
    
    # === Cycle Breakdown ===
    # Note: Bubbles are overlapping with stalls/flushes in some cases
    # Useful cycles = cycles spent doing real work
    useful_cycles = cycles - (stalls + flushes)
    
    # === Rates ===
    bubble_rate = (bubbles / cycles * 100) if cycles > 0 else 0
    stall_rate = (stalls / cycles * 100) if cycles > 0 else 0
    flush_rate = (flushes / cycles * 100) if cycles > 0 else 0
    utilization = (useful_cycles / cycles * 100) if cycles > 0 else 0
    
    # === Hazard & Forwarding ===
    forward_rate = (forwards / raw_hazards * 100) if raw_hazards > 0 else 100.0
    
    # === Control-Flow ===
    total_control_flow = cond_branches + uncond_branches
    branch_rate = (cond_branches / instructions * 100) if instructions > 0 else 0
    jump_rate = (uncond_branches / instructions * 100) if instructions > 0 else 0
    
    # Average control-flow penalty (in cycles)
    # Each flush typically costs 2 cycles (2 instructions flushed from pipeline)
    avg_cf_penalty = (flushes * 2) / total_control_flow if total_control_flow > 0 else 0
    
    return {
        # === Core Execution Metrics ===
        'Clock Cycles': cycles,
        'Instructions Retired': instructions,
        'CPI (Cycles Per Instruction)': f"{cpi:.3f}",
        'IPC (Instructions Per Cycle)': f"{ipc:.3f}",
        
        # === Cycle Breakdown ===
        'Bubble Cycles': bubbles,
        'Stall Cycles': stalls,
        'Flush Cycles': flushes,
        'Useful Cycles': useful_cycles,
        
        # === Control-Flow ===
        'Conditional Branches': cond_branches,
        'Unconditional Jumps (JAL/JALR)': uncond_branches,
        'Flush Count': flushes,
        'Avg Control-Flow Penalty': f"{avg_cf_penalty:.2f} cycles",
        
        # === Hazard & Forwarding ===
        'RAW Hazards': raw_hazards,
        'Forwards Used': forwards,
        
        # === Rates ===
        'Bubble Rate': f"{bubble_rate:.1f}%",
        'Stall Rate': f"{stall_rate:.1f}%",
        'Flush Rate': f"{flush_rate:.1f}%",
        'Pipeline Utilization': f"{utilization:.1f}%",
        'Forward Success Rate': f"{forward_rate:.1f}%",
        'Branch Rate': f"{branch_rate:.1f}%",
        'Jump Rate': f"{jump_rate:.1f}%",
    }

def print_metrics_table(metrics, test_name="Performance Test"):
    """Print metrics in organized sections"""
    
    if not metrics:
        print("\n⚠️  No performance metrics available")
        return
    
    print("\n" + "="*70)
    print(f"📊 PERFORMANCE REPORT: {test_name}")
    print("="*70)
    
    # Core Execution Metrics
    print("\n🔹 CORE EXECUTION METRICS")
    print("-" * 70)
    for key in ['Clock Cycles', 'Instructions Retired', 'CPI (Cycles Per Instruction)', 
                'IPC (Instructions Per Cycle)']:
        if key in metrics:
            print(f"  {key:<35} {str(metrics[key]):>30}")
    
    # Cycle Breakdown
    print("\n🔹 CYCLE BREAKDOWN")
    print("-" * 70)
    for key in ['Bubble Cycles', 'Stall Cycles', 'Flush Cycles', 'Useful Cycles']:
        if key in metrics:
            print(f"  {key:<35} {str(metrics[key]):>30}")
    
    # Control-Flow
    print("\n🔹 CONTROL-FLOW CHARACTERISTICS")
    print("-" * 70)
    for key in ['Conditional Branches', 'Unconditional Jumps (JAL/JALR)', 
                'Flush Count', 'Avg Control-Flow Penalty']:
        if key in metrics:
            print(f"  {key:<35} {str(metrics[key]):>30}")
    
    # Hazard & Forwarding
    print("\n🔹 HAZARD & FORWARDING")
    print("-" * 70)
    for key in ['RAW Hazards', 'Forwards Used']:
        if key in metrics:
            print(f"  {key:<35} {str(metrics[key]):>30}")
    
    # Rates
    print("\n🔹 PERFORMANCE RATES")
    print("-" * 70)
    for key in ['Bubble Rate', 'Stall Rate', 'Flush Rate', 'Pipeline Utilization',
                'Forward Success Rate', 'Branch Rate', 'Jump Rate']:
        if key in metrics:
            print(f"  {key:<35} {str(metrics[key]):>30}")
    
    print("="*70 + "\n")

def generate_report(sim_output=None, test_name="Performance Test", log_file=None, perf_file=None):
    """Main entry point for generating performance report"""
    
    # Try file first
    if perf_file and os.path.exists(perf_file):
        raw = parse_from_file(perf_file)
    else:
        print(f"\n⚠️  No performance data source for {test_name}")
        return
    
    # Calculate derived metrics
    metrics = calculate_metrics(raw)
    
    if not metrics:
        print(f"\n⚠️  No performance metrics found for {test_name}")
        return
    
    # Print to terminal
    print_metrics_table(metrics, test_name)
    
    # Save to file if requested
    if log_file:
        import datetime
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        with open(log_file, 'w') as f:
            f.write(f"Performance Metrics Report\n")
            f.write(f"Test: {test_name}\n")
            f.write(f"Timestamp: {timestamp}\n")
            f.write(f"\n{'='*70}\n")
            
            for key, value in metrics.items():
                f.write(f"{key:<35} {str(value):>30}\n")
            
            f.write(f"{'='*70}\n")
        
        print(f"📝 Performance log saved: {log_file}\n")

if __name__ == "__main__":
    # Test with sample data
    print("Testing performance report generator...")
    
    # Create a sample perf file for testing
    sample_data = """cycles=150
instructions=100
stalls=10
bubbles=15
flushes=8
forwards=25
raw_hazards=30
cond_branches=20
uncond_branches=5
"""
    
    with open('/tmp/test_perf.txt', 'w') as f:
        f.write(sample_data)
    
    generate_report(perf_file='/tmp/test_perf.txt', test_name="Sample Test")
