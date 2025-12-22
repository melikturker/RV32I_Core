#!/usr/bin/env python3
"""
Performance Summary Table Generator
Generates comparative performance tables for benchmark suite
"""

import os
import sys
from datetime import datetime

# ANSI color codes
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    RESET = '\033[0m'
    
    @staticmethod
    def disable():
        """Disable colors for file output"""
        Colors.GREEN = ''
        Colors.RED = ''
        Colors.YELLOW = ''
        Colors.BLUE = ''
        Colors.CYAN = ''
        Colors.BOLD = ''
        Colors.RESET = ''

def format_number(value, suffix=True):
    """Format large numbers with K/M suffix"""
    if not suffix or value < 1000:
        return str(int(value))
    elif value < 1_000_000:
        return f"{value/1000:.0f}K"
    else:
        return f"{value/1_000_000:.2f}M"

def format_percentage(value):
    """Format percentage with 2 decimals"""
    return f"{value*100:.2f}%"

def format_ipc(value):
    """Format IPC with 3 decimals"""
    return f"{value:.3f}"

def parse_perf_file(perf_file):
    """Parse performance counter file and extract metrics"""
    metrics = {}
    
    try:
        with open(perf_file, 'r') as f:
            for line in f:
                line = line.strip()
                if '=' in line:
                    key, value = line.split('=')
                    try:
                        metrics[key.strip()] = int(value.strip())
                    except ValueError:
                        pass
    except FileNotFoundError:
        return None
    
    # Calculate derived metrics
    if 'cycles' in metrics and 'instructions' in metrics and metrics['instructions'] > 0:
        metrics['ipc'] = metrics['instructions'] / metrics['cycles']
        metrics['cpi'] = metrics['cycles'] / metrics['instructions']
        
        total_cycles = metrics['cycles']
        bubble = metrics.get('bubbles', 0)
        stall = metrics.get('stalls', 0)
        flush = metrics.get('flushes', 0)
        useful = total_cycles - bubble - stall - flush
        
        metrics['pipeline_util'] = useful / total_cycles if total_cycles > 0 else 0
        metrics['bubble_rate'] = bubble / total_cycles if total_cycles > 0 else 0
        metrics['stall_rate'] = stall / total_cycles if total_cycles > 0 else 0
        metrics['flush_rate'] = flush / total_cycles if total_cycles > 0 else 0
        
        # Note: perf_counters.txt uses 'branch' and 'jump' keys
        metrics['branch_rate'] = metrics.get('branch', 0) / metrics['instructions'] if metrics['instructions'] > 0 else 0
        metrics['jump_rate'] = metrics.get('jump', 0) / metrics['instructions'] if metrics['instructions'] > 0 else 0
    
    return metrics

def generate_summary_table(benchmark_results, use_color=True):
    """
    Generate summary comparison table
    benchmark_results: dict of {benchmark_name: (status, metrics_dict)}
    """
    if not use_color:
        Colors.disable()
    
    # Group benchmarks
    memory_benchmarks = ['array_sum', 'memcpy', 'matrix_transpose']
    algorithm_benchmarks = ['fibonacci', 'binary_search', 'bubble_sort', 'gcd']
    
    output = []
    
    def render_group(group_name, benchmark_list):
        group_output = []
        group_output.append(f"\n{Colors.BOLD}📊 {group_name}{Colors.RESET}")
        
        # Calculate actual table width
        table_width = 18 + 3 + 7 + 3 + 8 + 3 + 8 + 3 + 7 + 3 + 7 + 3 + 8 + 3 + 7  # columns + separators
        
        group_output.append("=" * table_width)
        
        # Header
        header = f"{'Benchmark':<18} | {'IPC':>7} | {'Cycles':>8} | {'Instr':>8} | {'Util':>7} | {'Stall':>7} | {'Branch':>8} | {'Jump':>7}"
        group_output.append(header)
        group_output.append("-" * table_width)
        
        # Rows
        for bench_name in benchmark_list:
            if bench_name not in benchmark_results:
                continue
            
            status, metrics = benchmark_results[bench_name]
            
            if status == 'FAIL' or not metrics:
                # FAIL row - red name
                bench_display = f"{Colors.RED}{bench_name:<18}{Colors.RESET}"
                row = f"{bench_display} | {'FAIL':>7} | {'-':>8} | {'-':>8} | {'-':>7} | {'-':>7} | {'-':>8} | {'-':>7}"
                group_output.append(row)
                continue
            
            # Format values (no coloring on values)
            ipc_str = format_ipc(metrics['ipc'])
            cycles_str = format_number(metrics['cycles'])
            instr_str = format_number(metrics['instructions'])
            util_str = format_percentage(metrics['pipeline_util'])
            stall_str = format_percentage(metrics['stall_rate'])
            branch_str = format_percentage(metrics['branch_rate'])
            jump_str = format_percentage(metrics['jump_rate'])
            
            # Benchmark name: green for PASS (pad BEFORE coloring!)
            bench_display = f"{Colors.GREEN}{bench_name:<18}{Colors.RESET}"
            
            # Build row
            row = f"{bench_display} | {ipc_str:>7} | {cycles_str:>8} | {instr_str:>8} | {util_str:>7} | {stall_str:>7} | {branch_str:>8} | {jump_str:>7}"
            group_output.append(row)
        
        group_output.append("=" * table_width)
        return group_output
    
    # Render both groups
    output.extend(render_group("MEMORY BENCHMARKS", memory_benchmarks))
    output.extend(render_group("ALGORITHM BENCHMARKS", algorithm_benchmarks))
    
    return "\n".join(output)

def save_report(content, save_path=None, verbose_content=None):
    """
    Save report to file
    save_path: None (auto), path string, or filename
    verbose_content: Additional detailed content to append
    """
    import re
    
    # Strip ANSI color codes from content for file output
    ansi_escape = re.compile(r'\x1b\[[0-9;]*m')
    clean_content = ansi_escape.sub('', content)
    if verbose_content:
        verbose_content = ansi_escape.sub('', verbose_content)
    
    # Determine save path
    if save_path is None:
        # Auto-generate filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.makedirs("logs", exist_ok=True)
        save_path = f"logs/perf_summary_{timestamp}.txt"
    elif not save_path.startswith('/') and '/' not in save_path and not save_path.startswith('logs/'):
        # Just filename, prepend logs/
        os.makedirs("logs", exist_ok=True)
        save_path = f"logs/{save_path}"
    elif '/' in save_path:
        # Path with directory, create directory if needed
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    # Write to file (use cleaned content without ANSI codes)
    with open(save_path, 'w') as f:
        f.write("=" * 110 + "\n")
        f.write(f"Performance Summary Report - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 110 + "\n\n")
        f.write(clean_content)
        
        if verbose_content:
            f.write("\n\n" + "=" * 110 + "\n")
            f.write("DETAILED REPORTS\n")
            f.write("=" * 110 + "\n\n")
            f.write(verbose_content)
    
    return save_path

if __name__ == "__main__":
    # Test
    test_results = {
        'array_sum': ('PASS', {
            'cycles': 262153, 'instructions': 180236, 'ipc': 0.688,
            'pipeline_util': 0.813, 'stall_rate': 0.062, 'branch_rate': 0.182, 'jump_rate': 0.0
        }),
        'fibonacci': ('PASS', {
            'cycles': 999988, 'instructions': 741031, 'ipc': 0.741,
            'pipeline_util': 0.869, 'stall_rate': 0.008, 'branch_rate': 0.14, 'jump_rate': 0.156
        }),
    }
    
    print(generate_summary_table(test_results, use_color=True))
