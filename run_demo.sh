#!/bin/bash

APP=$1
if [ -z "$APP" ]; then
    echo "Usage: ./run_demo.sh <assembly_file>"
    exit 1
fi

# 1. Assemble
echo "[Demo] Assembling $APP..."
cd example
python3 simple_assembler.py $APP app.hex
if [ $? -ne 0 ]; then
    echo "Assembly failed!"
    exit 1
fi
cd ..

# 2. Start Virtual Screen (Display Client)
echo "[Demo] Launching Virtual Screen..."
./sim/display/virtual_screen &
DISPLAY_PID=$!

# Give it a moment to initialize SDL
sleep 1

# 3. Start Simulator (Core + Shared Memory Writer)
echo "[Demo] Starting Simulation (Ctrl+C to stop)..."
./tests/sim_headless +TESTFILE=example/app.hex +INTERACTIVE

# 4. Cleanup
echo "[Demo] Simulation finished. Closing display..."
kill $DISPLAY_PID 2>/dev/null
