# Makefile for RV32I Core

# Compiler and Simulator
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Files
SRC = src/*.v
TB = tb/tb.v
OUT = a.out
VCD = tb.vcd

# Default target
all: run

# Compile
$(OUT): $(SRC) $(TB)
	$(IVERILOG) -o $(OUT) $(SRC) $(TB)

# Run simulation
run: $(OUT)
	$(VVP) $(OUT) $(ARGS)

# View waveforms
wave: $(VCD)
	$(GTKWAVE) $(VCD) &

# Clean
clean:
	rm -f $(OUT) $(VCD)

.PHONY: all run wave clean
