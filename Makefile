# Makefile for RV32I Core - Centralized Build System

# --- Tools ---
VERILATOR = verilator
CXX = g++
SDL_CFLAGS = $(shell sdl2-config --cflags)
SDL_LDFLAGS = $(shell sdl2-config --libs)
PWD = $(shell pwd)

# --- Directories ---
SRC_DIR = src
CORE_DIR = src/core
MEM_DIR = src/memory
PERIPH_DIR = src/peripherals
SIM_DIR = sim
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj_dir

# --- Files ---
VERILOG_SRCS = $(SRC_DIR)/SoC.v \
               $(CORE_DIR)/*.v \
               $(MEM_DIR)/*.v \
               $(PERIPH_DIR)/*.v

# Default App path updated to new location
APP ?= src/memory/instructions/instr.txt
ARGS ?=

# --- Flags ---
# Common Verilator Flags
V_FLAGS = -cc --exe -j 4 -Wall -Wno-fatal -Wno-CASEINCOMPLETE -Wno-WIDTHTRUNC \
          -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-EOFNEWLINE -Wno-DECLFILENAME -Wno-WIDTHEXPAND \
          -I$(SRC_DIR) -I$(CORE_DIR) -I$(MEM_DIR) -I$(PERIPH_DIR) \
          -Mdir $(OBJ_DIR) --trace

# Optimization Flags (O3 for speed in both modes)
OPT_FLAGS = -O3

# --- Targets ---
.PHONY: all headless gui clean directories

all: headless gui

directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(OBJ_DIR)

# --- 1. Headless Target (Performance / Verification) ---
# Output: build/sim_headless
HEADLESS_EXE = $(BUILD_DIR)/sim_headless

# We copy the C++ wrapper to build dir to keep source clean
$(BUILD_DIR)/sim_headless.cpp: $(SIM_DIR)/sim_headless.cpp directories
	@cp $(SIM_DIR)/sim_headless.cpp $(BUILD_DIR)/
	@cp $(SIM_DIR)/sim_vram_dpi.cpp $(BUILD_DIR)/

headless_verilate: $(VERILOG_SRCS) $(BUILD_DIR)/sim_headless.cpp
	@echo "[Makefile] Building Headless Simulation..."
	@$(VERILATOR) $(V_FLAGS) $(OPT_FLAGS) \
		$(VERILOG_SRCS) $(PWD)/$(BUILD_DIR)/sim_headless.cpp \
		$(PWD)/$(BUILD_DIR)/sim_vram_dpi.cpp \
		-LDFLAGS "-pthread -lrt" \
		-CFLAGS "-I$(PWD)/$(SIM_DIR) $(OPT_FLAGS)" \
		-o ../sim_headless
	@make -s -C $(OBJ_DIR) -f VSoC.mk

headless: headless_verilate

# --- 1b. Headless Trace Target (With VCD Waveform) ---
# Output: build/sim_headless_trace
HEADLESS_TRACE_EXE = $(BUILD_DIR)/sim_headless_trace

headless_trace_verilate: $(VERILOG_SRCS) $(BUILD_DIR)/sim_headless.cpp
	@echo "[Makefile] Building Headless Simulation with Trace..."
	@$(VERILATOR) $(V_FLAGS) $(OPT_FLAGS) \\\t\t--trace --trace-depth 99 --trace-structs \\\t\t$(VERILOG_SRCS) $(PWD)/$(BUILD_DIR)/sim_headless.cpp \
		$(PWD)/$(BUILD_DIR)/sim_vram_dpi.cpp \
		-LDFLAGS "-pthread -lrt" \
		-CFLAGS "-I$(PWD)/$(SIM_DIR) $(OPT_FLAGS)" \
		-o ../sim_headless_trace
	@make -s -C $(OBJ_DIR) -f VSoC.mk

headless_trace: headless_trace_verilate

# --- 2. GUI Target (SDL2 Visualization) ---
# Output: build/sim_gui
GUI_EXE = $(BUILD_DIR)/sim_gui

$(BUILD_DIR)/sim_soc.cpp: $(SIM_DIR)/sim_soc.cpp directories
	@cp $(SIM_DIR)/sim_soc.cpp $(BUILD_DIR)/
	@cp $(SIM_DIR)/sim_vram_dpi.cpp $(BUILD_DIR)/

gui_verilate: $(VERILOG_SRCS) $(BUILD_DIR)/sim_soc.cpp
	@echo "[Makefile] Building GUI Simulation..."
	@$(VERILATOR) $(V_FLAGS) \
		$(VERILOG_SRCS) $(PWD)/$(BUILD_DIR)/sim_soc.cpp $(PWD)/$(BUILD_DIR)/sim_vram_dpi.cpp \
		-LDFLAGS "$(SDL_LDFLAGS)" \
		-CFLAGS "$(SDL_CFLAGS) -I$(PWD)/$(SIM_DIR)" \
		-o ../sim_gui
	@make -s -C $(OBJ_DIR) -f VSoC.mk

gui: gui_verilate

# --- 3. Coverage Target ---
# Output: build/sim_cov
COV_EXE = $(BUILD_DIR)/sim_cov

cov_verilate: $(VERILOG_SRCS) $(BUILD_DIR)/sim_headless.cpp
	@echo "[Makefile] Building Coverage Simulation..."
	@$(VERILATOR) $(V_FLAGS) --coverage $(OPT_FLAGS) \
		$(VERILOG_SRCS) $(PWD)/$(BUILD_DIR)/sim_headless.cpp $(PWD)/$(BUILD_DIR)/sim_vram_dpi.cpp \
		-LDFLAGS "-pthread -lrt" \
		-CFLAGS "-I$(PWD)/$(SIM_DIR) $(OPT_FLAGS)" \
		-o ../sim_cov
	@make -s -C $(OBJ_DIR) -f VSoC.mk

coverage: cov_verilate

# --- Cleanup ---
clean:
	rm -rf $(BUILD_DIR)
