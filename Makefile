# Makefile for RV32I Core

# Tools
VERILATOR = verilator
CXX = g++
SDL_CFLAGS = $(shell sdl2-config --cflags)
SDL_LDFLAGS = $(shell sdl2-config --libs)

# Directories
SRC_DIR = src
CORE_DIR = src/core
MEM_DIR = src/memory
PERIPH_DIR = src/peripherals
SIM_DIR = sim
OBJ_DIR = obj_dir

# Files
VERILOG_SRCS = $(SRC_DIR)/SoC.v \
               $(CORE_DIR)/*.v \
               $(MEM_DIR)/*.v \
               $(PERIPH_DIR)/*.v

# Default App (can be overridden: make sim APP=instructions/instr.txt)
APP ?= instructions/instr.txt
ARGS ?=

# Flags
VERILATOR_FLAGS = -cc --exe -j 4 -Wall -Wno-fatal --trace \
                  -I$(SRC_DIR) -I$(CORE_DIR) -I$(MEM_DIR) -I$(PERIPH_DIR)

# Targets
.PHONY: all sim headless clean

all: sim

# 2. Headless Simulation (Core Only / Verify)
# 2. Headless Simulation (Core Only / Verify)
# Build only
verilate_headless: $(VERILOG_SRCS) $(SIM_DIR)/sim_headless.cpp
	@echo "Building Headless Simulation Binary..."
	rm -rf $(OBJ_DIR)
	mkdir -p $(OBJ_DIR)
	cp $(SIM_DIR)/sim_headless.cpp $(OBJ_DIR)/sim_headless.cpp
	cp $(SIM_DIR)/sim_vram_dpi.cpp $(OBJ_DIR)/sim_vram_dpi.cpp
	$(VERILATOR) -cc --exe -j 4 -Wall -Wno-fatal -O3 -Isrc -Isrc/core -Isrc/memory -Isrc/peripherals src/SoC.v src/core/*.v src/memory/*.v src/peripherals/*.v $(OBJ_DIR)/sim_headless.cpp $(OBJ_DIR)/sim_vram_dpi.cpp \
		-LDFLAGS "-pthread -lrt" -CFLAGS "-I../sim -O3" -Mdir $(OBJ_DIR) -o ../tests/sim_headless
	make -C $(OBJ_DIR) -f VSoC.mk

# Build and Run
headless: verilate_headless
	./tests/sim_headless $(ARGS)

# Alias for headless (used by run_vis.sh)
run: headless

# 1. Graphical Simulation (SoC + SDL)
sim: $(VERILOG_SRCS) $(SIM_DIR)/sim_soc.cpp
	@echo "Building Graphical Simulation..."
	# Creating hex file for I_mem if it's an assembly file
	@if [[ "$(APP)" == *.s ]]; then \
		echo "Assembling $(APP)..."; \
		riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o app.o $(APP); \
        riscv64-unknown-elf-objcopy -O verilog app.o app.hex; \
        rm -f app.o; \
        APP_PATH="app.hex"; \
    else \
        APP_PATH="$(APP)"; \
    fi; \
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILOG_SRCS) $(PWD)/$(SIM_DIR)/sim_soc.cpp \
		-LDFLAGS "$(SDL_LDFLAGS)" -CFLAGS "$(SDL_CFLAGS) -I$(PWD)/$(SIM_DIR)" -Mdir $(OBJ_DIR) -o ../sim_soc; \
	make -C $(OBJ_DIR) -f VSoC.mk; \
	./sim_soc +TESTFILE=$$APP_PATH

clean:
	rm -rf $(OBJ_DIR) sim_soc sim_headless app.hex
