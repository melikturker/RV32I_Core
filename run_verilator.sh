#!/bin/bash

# Usage: ./run_verilator.sh <assembly_file.s>
# Example: ./run_verilator.sh example/audio_bars_riscv.s

if [ -z "$1" ]; then
    echo "Usage: $0 <assembly_file.s>"
    exit 1
fi

TEST_FILE="$1"
HEX_FILE="$(pwd)/app.hex"
WIDTH=320
HEIGHT=240

echo "=== RV32I Verilator Launcher ==="
echo "Target: $TEST_FILE"

# 1. Assemble
EXT="${TEST_FILE##*.}"
if [ "$EXT" == "s" ]; then
    echo "[1/2] Assembling..."
    # Copy to temp to replace constants if needed (borrowed from run_vis.sh)
    TEMP_ASM="temp_verilator.s"
    cp "$TEST_FILE" "$TEMP_ASM"
    
    # Simple replacement if files use .eqv (optional but safe)
    sed -i "s/.eqv WIDTH.*/.eqv WIDTH $WIDTH/g" "$TEMP_ASM"
    sed -i "s/.eqv HEIGHT.*/.eqv HEIGHT $HEIGHT/g" "$TEMP_ASM"
    
    python3 example/simple_assembler.py "$TEMP_ASM" "$HEX_FILE"
    rm "$TEMP_ASM"
    
    if [ ! -f "$HEX_FILE" ]; then
        echo "Assembly failed."
        exit 1
    fi
else
    cp "$TEST_FILE" "$HEX_FILE"
fi

# 2. Run Verilator Model
echo "[2/2] Launching High-Performance Simulation..."
# +TESTFILE=app.hex tells the model where to load memory from
./obj_dir/VCore +TESTFILE="$HEX_FILE"
