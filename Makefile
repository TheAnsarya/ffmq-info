# Final Fantasy Mystic Quest (SNES) Disassembly & ROM Hack Project
# Modern SNES Development Environment
# Requires: ca65 (cc65 suite), python 3.x, asar

# Project Configuration
PROJECT_NAME = ffmq
ROM_NAME = Final Fantasy - Mystic Quest (U) (V1.1)
BASE_ROM = ~roms/$(ROM_NAME).sfc
OUTPUT_ROM = build/$(PROJECT_NAME)-modified.sfc

# Tools
ASM = ca65
LINK = ld65
ASAR = asar
PYTHON = python

# Directories
SRC_DIR = src
ASM_DIR = $(SRC_DIR)/asm
INCLUDE_DIR = $(SRC_DIR)/include
DATA_DIR = $(SRC_DIR)/data
ASSETS_DIR = assets
TOOLS_DIR = tools
BUILD_DIR = build
DOCS_DIR = docs

# Source Files
ASM_SOURCES = $(wildcard $(ASM_DIR)/*.s)
MAIN_ASM = $(ASM_DIR)/main.s

# Build Targets
.PHONY: all clean rom extract-assets extract-graphics extract-text extract-music \
        convert-graphics install-deps build-tools docs test test-rom test-setup \
        test-launch test-debug

# Default target
all: rom

# Build the ROM
rom: $(OUTPUT_ROM)

$(OUTPUT_ROM): $(ASM_SOURCES) $(BASE_ROM) | $(BUILD_DIR)
	@echo "Building Final Fantasy Mystic Quest ROM..."
	cp "$(BASE_ROM)" "$(OUTPUT_ROM)"
	$(ASAR) "$(MAIN_ASM)" "$(OUTPUT_ROM)"
	@echo "ROM built successfully: $(OUTPUT_ROM)"

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Extract assets from original ROM
extract-assets: extract-graphics extract-text extract-music
	@echo "All assets extracted successfully!"

# Extract graphics only
extract-graphics: $(BASE_ROM) | $(ASSETS_DIR)
	@echo "Extracting graphics from ROM..."
	$(PYTHON) $(TOOLS_DIR)/extract_graphics_v2.py "$(BASE_ROM)" "$(ASSETS_DIR)/graphics/" --docs
	@echo "Graphics extraction complete"

# Extract text only
extract-text: $(BASE_ROM) | $(ASSETS_DIR)
	@echo "Extracting text from ROM..."
	$(PYTHON) $(TOOLS_DIR)/extract_text.py "$(BASE_ROM)" "$(ASSETS_DIR)/text/"
	@echo "Text extraction complete"

# Extract music only
extract-music: $(BASE_ROM) | $(ASSETS_DIR)
	@echo "Extracting music from ROM..."
	$(PYTHON) $(TOOLS_DIR)/extract_music.py "$(BASE_ROM)" "$(ASSETS_DIR)/music/"
	@echo "Music extraction complete"

# Convert graphics between formats
convert-graphics:
	@echo "Graphics Conversion Utility"
	@echo "Usage: make convert-graphics-to-png INPUT=file.bin OUTPUT=file.png"
	@echo "   or: make convert-graphics-to-snes INPUT=file.png OUTPUT=file.bin"

# Helper target: Convert SNES to PNG
convert-graphics-to-png:
	@if [ -z "$(INPUT)" ] || [ -z "$(OUTPUT)" ]; then \
		echo "Error: INPUT and OUTPUT required"; \
		echo "Example: make convert-graphics-to-png INPUT=tiles.bin OUTPUT=tiles.png BPP=4"; \
		exit 1; \
	fi
	$(PYTHON) $(TOOLS_DIR)/convert_graphics.py to-png "$(INPUT)" "$(OUTPUT)" \
		$(if $(PALETTE),--palette $(PALETTE)) \
		$(if $(BPP),--bpp $(BPP)) \
		$(if $(TILES_PER_ROW),--tiles-per-row $(TILES_PER_ROW)) \
		$(if $(INDEXED),--indexed)

# Helper target: Convert PNG to SNES
convert-graphics-to-snes:
	@if [ -z "$(INPUT)" ] || [ -z "$(OUTPUT)" ]; then \
		echo "Error: INPUT and OUTPUT required"; \
		echo "Example: make convert-graphics-to-snes INPUT=tiles.png OUTPUT=tiles.bin BPP=4"; \
		exit 1; \
	fi
	$(PYTHON) $(TOOLS_DIR)/convert_graphics.py to-snes "$(INPUT)" "$(OUTPUT)" \
		$(if $(PALETTE),--palette $(PALETTE)) \
		$(if $(BPP),--bpp $(BPP))

# Install Python dependencies
install-deps:
	@echo "Installing Python dependencies..."
	$(PYTHON) -m pip install -r requirements.txt
	@echo "Dependencies installed!"

# Build development tools
build-tools:
	@echo "Building development tools..."
	$(MAKE) -C $(TOOLS_DIR)
	@echo "Tools built successfully"

# Generate documentation
docs:
	@echo "Generating documentation..."
	$(PYTHON) $(TOOLS_DIR)/generate_docs.py "$(SRC_DIR)" "$(DOCS_DIR)"
	@echo "Documentation generated"

# Test the ROM
test: $(OUTPUT_ROM)
	@echo "Testing ROM with automated tests..."
	$(PYTHON) $(TOOLS_DIR)/rom_tester.py "$(OUTPUT_ROM)"
	@echo "Launching ROM in MesenS..."
	$(PYTHON) $(TOOLS_DIR)/mesen_integration.py launch "$(OUTPUT_ROM)"

# Run ROM validation tests only
test-rom: $(OUTPUT_ROM)
	@echo "Running ROM validation tests..."
	$(PYTHON) $(TOOLS_DIR)/rom_tester.py "$(OUTPUT_ROM)"

# Setup testing environment
test-setup:
	@echo "Setting up testing environment..."
	$(PYTHON) $(TOOLS_DIR)/mesen_integration.py setup

# Launch ROM in MesenS
test-launch: $(OUTPUT_ROM)
	@echo "Launching ROM in MesenS..."
	$(PYTHON) $(TOOLS_DIR)/mesen_integration.py launch "$(OUTPUT_ROM)"

# Launch ROM with debugging
test-debug: $(OUTPUT_ROM)
	@echo "Launching ROM with debugging in MesenS..."
	$(PYTHON) $(TOOLS_DIR)/mesen_integration.py debug "$(OUTPUT_ROM)"

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.o *.lst
	@echo "Clean complete"

# Development helpers
setup-env:
	@echo "Setting up development environment..."
	@echo "Checking for required tools..."
	@command -v $(ASM) >/dev/null 2>&1 || { echo "ca65 not found. Please install cc65."; exit 1; }
	@command -v $(ASAR) >/dev/null 2>&1 || { echo "asar not found. Please install asar."; exit 1; }
	@command -v $(PYTHON) >/dev/null 2>&1 || { echo "Python not found. Please install Python 3.x."; exit 1; }
	@echo "Development environment ready!"

# Install tools (Windows)
install-tools:
	@echo "Installing SNES development tools..."
	@echo "Please manually install:"
	@echo "1. cc65: https://cc65.github.io/"
	@echo "2. asar: https://github.com/RPGHacker/asar"
	@echo "3. MesenS: https://github.com/SourMesen/Mesen-S"
	@echo "4. Python 3.x: https://python.org/"

# Show help
help:
	@echo "Final Fantasy Mystic Quest SNES Development"
	@echo "==========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all                    - Build everything (default)"
	@echo "  rom                    - Build the modified ROM"
	@echo "  extract-assets         - Extract all assets (graphics, text, music)"
	@echo "  extract-graphics       - Extract graphics only with PNG output"
	@echo "  extract-text           - Extract text only"
	@echo "  extract-music          - Extract music only"
	@echo "  convert-graphics       - Show graphics conversion help"
	@echo "  install-deps           - Install Python dependencies (Pillow, etc.)"
	@echo "  build-tools            - Build development tools"
	@echo "  docs                   - Generate documentation"
	@echo "  test                   - Run ROM tests and launch in MesenS emulator"
	@echo "  test-rom               - Run ROM validation tests only"
	@echo "  test-setup             - Setup testing environment with MesenS"
	@echo "  test-launch            - Launch ROM in MesenS emulator"
	@echo "  test-debug             - Launch ROM with debugging enabled"
	@echo "  setup-env              - Check development environment"
	@echo "  install-tools          - Show installation instructions for tools"
	@echo "  clean                  - Clean build artifacts"
	@echo "  help                   - Show this help"
	@echo ""
	@echo "Graphics Conversion Examples:"
	@echo "  make convert-graphics-to-png INPUT=tiles.bin OUTPUT=tiles.png BPP=4"
	@echo "  make convert-graphics-to-snes INPUT=tiles.png OUTPUT=tiles.bin BPP=4"
	@echo ""
	@echo "Requirements:"
	@echo "  - ca65/cc65 assembler suite"
	@echo "  - asar assembler"
	@echo "  - Python 3.x + Pillow (for graphics tools)"
	@echo "  - MesenS emulator (for testing)"