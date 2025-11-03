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
DATA_DIR = data
TOOLS_DIR = tools
ASSETS_DIR = assets
BUILD_DIR = build
DOCS_DIR = docs

# Source Files
ASM_SOURCES = $(wildcard $(ASM_DIR)/*.s)
MAIN_ASM = $(ASM_DIR)/main.s

# Build Targets
.PHONY: all clean rom extract-assets extract-graphics extract-text extract-music \
        convert-graphics install-deps build-tools docs test test-rom test-setup \
        test-launch test-debug extract-bank06 extract-all verify-bank06 verify-all \
        generate-asm pipeline graphics-extract graphics-rebuild graphics-full \
        graphics-validate graphics-asm graphics-pipeline rom-with-graphics \
        text-extract text-rebuild text-pipeline \
        maps-extract maps-rebuild maps-pipeline \
        overworld-extract effects-extract \
        extract-all-phase3 rebuild-all-phase3 full-pipeline \
        extract-data convert-data data-pipeline

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
	@echo ""
	@echo "Data Extraction Pipeline:"
	@echo "  extract-bank06         - Extract Bank $$06 data (metatiles, collision)"
	@echo "  extract-all            - Extract data from all supported banks"
	@echo "  verify-bank06          - Verify Bank $$06 round-trip integrity"
	@echo "  generate-asm           - Generate ASM files from JSON data"
	@echo "  pipeline               - Full workflow: extract -> generate -> verify"
	@echo ""
	@echo "Asset Extraction:"
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

# ==============================================================================
# Data Extraction and Build Pipeline
# ==============================================================================

# Extract Bank $06 data from ROM
extract-bank06:
	@echo "Extracting Bank $$06 metatile and collision data..."
	$(PYTHON) $(TOOLS_DIR)/extract_bank06_data.py "$(BASE_ROM)"
	@echo "Done! Data saved to $(DATA_DIR)/map_tilemaps.json"

# Extract all banks (Bank $06 currently supported)
extract-all: extract-bank06
	@echo "Note: Only Bank $$06 fully supported"
	@echo "Bank $$08 text extraction needs text compression algorithm"

# Verify Bank $06 round-trip (ROM -> JSON -> Binary)
verify-bank06:
	@echo "Verifying Bank $$06 round-trip integrity..."
	$(PYTHON) $(TOOLS_DIR)/verify_roundtrip.py "$(BASE_ROM)"

# Verify all extracted data
verify-all: verify-bank06
	@echo "All verifications complete"

# Generate ASM files from JSON data
generate-asm:
	@echo "Generating Bank $$06 metatile ASM..."
	$(PYTHON) $(TOOLS_DIR)/generate_bank06_metatiles.py > $(TOOLS_DIR)/bank06_metatiles_generated.asm
	@echo "Generating Bank $$06 data ASM..."
	$(PYTHON) $(TOOLS_DIR)/build_asm_from_json.py $(DATA_DIR)/map_tilemaps.json $(ASM_DIR)/bank_06_data_generated.asm
	@echo "Done! Generated ASM in $(ASM_DIR)/"

# Full data pipeline: extract -> generate -> verify
pipeline: extract-bank06 generate-asm verify-bank06
	@echo ""
	@echo "=========================================="
	@echo "Data pipeline complete!"
	@echo "=========================================="

# ============================================
# Battle Data Extraction & Conversion Pipeline
# ============================================

# Extract all battle data from ROM to JSON
extract-data:
	@echo "Extracting battle data from ROM..."
	$(PYTHON) $(TOOLS_DIR)/extraction/extract_enemies.py
	@echo "Enemy data extracted!"
	@echo "Note: Attack data and attack links already extracted"

# Convert all JSON data to ASM
convert-data:
	@echo "Converting JSON data to ASM..."
	$(PYTHON) $(TOOLS_DIR)/conversion/convert_all.py

# Full data pipeline: extract -> convert
data-pipeline: extract-data convert-data
	@echo ""
	@echo "=========================================="
	@echo "Battle data pipeline complete!"
	@echo "=========================================="
	@echo "Generated ASM files:"
	@echo "  - data/converted/enemies/enemies_stats.asm"
	@echo "  - data/converted/enemies/enemies_level.asm"
	@echo "  - data/converted/attacks/attacks_data.asm"
	@echo "  - data/converted/attacks/enemy_attack_links.asm"

# ============================================
# Graphics Build Integration Pipeline
# ============================================

# Extract all graphics from ROM to PNG
graphics-extract:
	@echo "Extracting graphics from ROM..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --extract

# Rebuild modified graphics (incremental)
graphics-rebuild:
	@echo "Rebuilding modified graphics..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --rebuild

# Full graphics rebuild (extract + rebuild)
graphics-full:
	@echo "Full graphics rebuild..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --full

# Validate all graphics
graphics-validate:
	@echo "Validating graphics..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --validate

# Generate ASM includes for graphics
graphics-asm:
	@echo "Generating graphics ASM includes..."
	$(PYTHON) $(TOOLS_DIR)/generate_graphics_asm.py

# Complete graphics workflow
graphics-pipeline: graphics-rebuild graphics-asm
	@echo ""
	@echo "=========================================="
	@echo "Graphics pipeline complete!"
	@echo "=========================================="

# Build ROM with graphics integration
rom-with-graphics: graphics-rebuild rom
	@echo "ROM built with integrated graphics!"

# ============================================
# Phase 3: Text Editing Pipeline
# ============================================

# Extract all text to JSON/CSV
text-extract:
	@echo "Extracting text from ROM..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --extract-text

# Rebuild text from edited JSON/CSV
text-rebuild:
	@echo "Rebuilding text data..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --rebuild-text

# Complete text workflow
text-pipeline: text-extract text-rebuild
	@echo ""
	@echo "=========================================="
	@echo "Text pipeline complete!"
	@echo "Edit data/extracted/text/text_complete.json"
	@echo "Then run 'make text-rebuild' to update ROM"
	@echo "=========================================="

# ============================================
# Phase 3: Map Editing Pipeline
# ============================================

# Extract all maps to TMX (Tiled format)
maps-extract:
	@echo "Extracting maps to TMX format..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --extract-maps

# Rebuild maps from edited TMX files
maps-rebuild:
	@echo "Rebuilding maps from TMX..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --rebuild-maps

# Complete maps workflow
maps-pipeline: maps-extract maps-rebuild
	@echo ""
	@echo "=========================================="
	@echo "Maps pipeline complete!"
	@echo "Edit TMX files in Tiled Map Editor"
	@echo "Then run 'make maps-rebuild' to update ROM"
	@echo "=========================================="

# ============================================
# Phase 3: Overworld Graphics Pipeline
# ============================================

# Extract overworld graphics (tilesets, sprites, objects, NPCs)
overworld-extract:
	@echo "Extracting overworld graphics..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --extract-overworld

# ============================================
# Phase 3: Effects Graphics Pipeline
# ============================================

# Extract effect graphics (spells, attacks, status, particles)
effects-extract:
	@echo "Extracting effect graphics..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --extract-effects

# ============================================
# Phase 3: Combined Operations
# ============================================

# Extract everything (Phase 2 + Phase 3)
extract-all-phase3: graphics-extract text-extract maps-extract overworld-extract effects-extract
	@echo ""
	@echo "=========================================="
	@echo "All Phase 3 extraction complete!"
	@echo "=========================================="
	@echo "Extracted:"
	@echo "  - Battle graphics (sprites)"
	@echo "  - Text data (dialogue, items, spells, enemies)"
	@echo "  - Maps (TMX for Tiled editor)"
	@echo "  - Overworld graphics (tilesets, walking sprites)"
	@echo "  - Effect graphics (spells, attacks, particles)"
	@echo ""
	@echo "Edit files in data/extracted/"
	@echo "Then run 'make rebuild-all-phase3'"
	@echo "=========================================="

# Rebuild everything that changed
rebuild-all-phase3: graphics-rebuild text-rebuild maps-rebuild
	@echo ""
	@echo "=========================================="
	@echo "All Phase 3 rebuild complete!"
	@echo "=========================================="

# Full pipeline: extract all + rebuild all
full-pipeline:
	@echo "Running complete FFMQ modding pipeline..."
	$(PYTHON) $(TOOLS_DIR)/build_integration.py --pipeline

# Build complete ROM with all modifications
rom-full: rebuild-all-phase3 rom
	@echo ""
	@echo "=========================================="
	@echo "Complete ROM built with all modifications!"
	@echo "=========================================="
	@echo "Output: $(OUTPUT_ROM)"
	@echo ""

