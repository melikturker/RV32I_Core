"""
Performance Metrics Report Generator

Parses Verilator simulation output and generates performance metrics table.
"""

import os

def parse_performance_metrics(sim_output):
    """Extract PERF_* lines from simulation output"""
    metrics = {}
    
    for line in sim_output.split('\n'):
        line = line.strip()
        if line.startswith('PERF_'):
            try:
                key, value = line.split('=')
                metric_name = key.replace('PERF_', '')
                metrics[metric_name] = int(value)
            except ValueError:
                continue
    
    return metrics

def calculate_derived_metrics(raw_metrics):
    """Calculate CPI, rates, etc. from raw counters"""
    
    if not raw_metrics:
        return None
    
    cycles = raw_metrics.get('CYCLES', 0)
    instructions = raw_metrics.get('INSTRUCTIONS', 0)
    stalls = raw_metrics.get('STALLS', 0)
    bubbles = raw_metrics.get('BUBBLES', 0)
    forwards = raw_metrics.get('FORWARDS', 0)
    raw_hazards = raw_metrics.get('RAW_HAZARDS', 0)
    cond_branches = raw_metrics.get('COND_BRANCHES', 0)
    uncond_branches = raw_metrics.get('UNCOND_BRANCHES', 0)
    cond_mispred = raw_metrics.get('COND_MISPRED', 0)
    
    # Avoid division by zero
    if instructions == 0:
        return None
    
    # Calculate metrics
    cpi = cycles / instructions
    stall_rate = (stalls / cycles * 100) if cycles > 0 else 0
    utilization = ((cycles - stalls - bubbles) / cycles * 100) if cycles > 0 else 0
    
    # Forward Success Rate
    forward_rate = (forwards / raw_hazards * 100) if raw_hazards > 0 else 100.0
    
    # Branch metrics
    total_branches = cond_branches + uncond_branches
    
    # Conditional branch accuracy (only meaningful for conditional)
    cond_accuracy = ((cond_branches - cond_mispred) / cond_branches * 100) if cond_branches > 0 else 100.0
    
    # Overall branch penalty: 
    # - All unconditional have 2 cycle penalty (always "mispredicted")
    # - Conditional mispredictions have 2 cycle penalty
    total_penalties = uncond_branches + cond_mispred
    avg_branch_penalty = (total_penalties * 2) / total_branches if total_branches > 0 else 0
    
    return {
        'Clock Cycles': cycles,
        'Instructions Retired': instructions,
        'CPI': f"{cpi:.3f}",
        'Stall Rate': f"{stall_rate:.1f}%",
        'Pipeline Utilization': f"{utilization:.1f}%",
        'Forward Rate': f"{forward_rate:.1f}%",
        'Conditional Branches': cond_branches,
        'Conditional Prediction Accuracy': f"{cond_accuracy:.1f}%",
        'Unconditional Jumps (JAL/JALR)': uncond_branches,
        'Avg Branch Penalty': f"{avg_branch_penalty:.2f} cycles"
    }

def print_metrics_table(metrics, test_name="Performance Test"):
    """Print metrics in a clean table format"""
    
    if not metrics:
        print("\n⚠️  No performance metrics available")
        return
    
    print("\n" + "="*60)
    print(f"📊 PERFORMANCE METRICS: {test_name}")
    print("="*60)
    
    for key, value in metrics.items():
        print(f"  {key:<30} {str(value):>25}")
    
    print("="*60 + "\n")

def save_metrics_to_log(metrics, test_name, log_path):
    """Save metrics to log file"""
    
    if not metrics:
        return
    
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    with open(log_path, 'w') as f:
        f.write(f"Performance Metrics Report\n")
        f.write(f"Test: {test_name}\n")
        f.write(f"Timestamp: {timestamp}\n")
        f.write(f"\n{'='*60}\n")
        
        for key, value in metrics.items():
            f.write(f"{key:<30} {str(value):>25}\n")
        
        f.write(f"{'='*60}\n")

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

def generate_report(sim_output=None, test_name="Performance Test", log_file=None, perf_file=None):
    """Main entry point for generating performance report"""
    
    # Try file first, then stdout
    if perf_file and os.path.exists(perf_file):
        raw = parse_from_file(perf_file)
    elif sim_output:
        raw = parse_performance_metrics(sim_output)
    else:
        print(f"\n⚠️  No performance data source for {test_name}")
        return
    
    # Calculate derived metrics
    metrics = calculate_derived_metrics(raw)
    
    if not metrics:
        print(f"\n⚠️  No performance metrics found for {test_name}")
        return
    
    # Print to terminal
    print_metrics_table(metrics, test_name)
    
    # Save to file if requested
    if log_file:
        save_metrics_to_log(metrics, test_name, log_file)
        print(f"📝 Performance log saved: {log_file}\n")

if __name__ == "__main__":
    # Test with sample data
    sample_output = """
Some simulation output
PERF_CYCLES=1000
PERF_INSTRUCTIONS=850
PERF_STALLS=100
PERF_BUBBLES=50
PERF_FORWARDS=80
PERF_RAW_HAZARDS=100
PERF_BRANCHES=150
PERF_BRANCH_TAKEN=90
PERF_BRANCH_MISPRED=30
    """
    
    generate_report(sample_output, "Sample Benchmark")
