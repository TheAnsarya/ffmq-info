; Final Fantasy Mystic Quest (SNES) - Complete Disassembly
; Integrated from multiple sources:
; - Diztinguish full disassembly (banks 00-0F)
; - Original reverse engineering work (macros, text, graphics)
; - Modern SNES development structure
;
; Assembler: asar (for now - will convert to ca65 later)
; Format: LoROM
; Processor: 65816 (SNES CPU)

; ============================================================================
; Memory Map Configuration
; ============================================================================

lorom						; LoROM mapping mode
arch 65816					; 65816 processor

; ============================================================================
; Include Files - Definitions and Macros
; ============================================================================

; SNES Hardware Register Definitions
; These are standard SNES registers used throughout the game
incsrc "../include/snes_registers.inc"

; Original FFMQ Macros
; Convenience macros for register size switching, databank management, etc.
incsrc "../include/ffmq_macros_original.inc"

; RAM Variables
; All RAM address definitions and variable names
incsrc "../include/ffmq_ram_variables.inc"

; Diztinguish Labels
; Global labels and constants from the Diztinguish disassembly
incsrc "banks/labels.asm"

; ============================================================================
; Bank Organization
; ============================================================================
; The game is organized into 16 banks ($00-$0F) in LoROM format
; Each bank contains $8000 bytes of code/data starting at $8000

; Bank $00: Main initialization, core engine
incsrc "banks/bank_00.asm"

; Bank $01: Additional engine code
incsrc "banks/bank_01.asm"

; Bank $02: Engine routines
incsrc "banks/bank_02.asm"

; Bank $03: Game logic
incsrc "banks/bank_03.asm"

; Bank $04: Graphics data and routines
incsrc "banks/bank_04.asm"

; Bank $05: More graphics and tile data
incsrc "banks/bank_05.asm"

; Bank $06: Data and routines
incsrc "banks/bank_06.asm"

; Bank $07: Graphics palettes and data
incsrc "banks/bank_07.asm"

; Bank $08: Game data
incsrc "banks/bank_08.asm"

; Bank $09: Battle system
incsrc "banks/bank_09.asm"

; Bank $0A: Additional game logic
incsrc "banks/bank_0A.asm"

; Bank $0B: More game logic
incsrc "banks/bank_0B.asm"

; Bank $0C: Menu system and UI
incsrc "banks/bank_0C.asm"

; Bank $0D: More menu and UI
incsrc "banks/bank_0D.asm"

; Bank $0E: Additional systems
incsrc "banks/bank_0E.asm"

; Bank $0F: Final bank - additional code
incsrc "banks/bank_0F.asm"

; ============================================================================
; Additional Game Engines
; ============================================================================
; These were reverse-engineered separately and provide detailed comments

; Text Engine
; Character rendering, text boxes, dialogue system
; Contains detailed analysis of text loading and display routines
pushpc
incsrc "text_engine.asm"
pullpc

; Graphics Engine
; Tile loading, palette management, DMA transfers
; Contains detailed analysis of graphics loading routines
pushpc
incsrc "graphics_engine.asm"
pullpc

; ============================================================================
; Game Data
; ============================================================================

; Text Data
pushpc
org pctosnes($060000)		; Text data region

; Item and equipment names
incsrc "../data/text/weapon-names.asm"
incsrc "../data/text/armor-names.asm"
incsrc "../data/text/helmet-names.asm"
incsrc "../data/text/shield-names.asm"
incsrc "../data/text/accessory-names.asm"
incsrc "../data/text/item-names.asm"

; Spell and attack names
incsrc "../data/text/spell-names.asm"
incsrc "../data/text/attack-descriptions.asm"

; Location and monster names
incsrc "../data/text/location-names.asm"
incsrc "../data/text/monster-names.asm"

pullpc

; Character Starting Stats
pushpc
incsrc "../data/character-start-stats.asm"
pullpc

; ============================================================================
; Graphics Data
; ============================================================================

pushpc
org pctosnes($028C80)

; Main Background Tiles ($05:8C80)
; 34 banks of tiles, $100 tiles per bank
; Format: 4BPP (16 colors per tile)
DataTiles:
	; This will be generated/extracted from ROM
	; Each tile is $30 bytes (expanded format in RAM becomes $20 bytes)
	; incbin "../graphics/tiles.bin"		; Placeholder

; pc should equal $05F280
pullpc

pushpc
org pctosnes($020000)

; Additional Tiles ($04:8000)
; $100 tiles of additional graphics
; Format: 4BPP
DataTiles048000:
	; incbin "../graphics/048000-tiles.bin"		; Placeholder

; pc should equal $048000 + $1800 = $049800
pullpc

pushpc
org $07B013		; pctosnes($03b013)

; Sprite Graphics Data ($07:B013)
; Character sprites, enemy sprites, effects
; Format: 4BPP
Data07b013:
	; incbin "../graphics/data07b013.bin"		; Placeholder

; pc should equal $07DBFC
pullpc

; ============================================================================
; Helper Macros for PC/SNES Address Conversion
; ============================================================================

; pctosnes() - Convert PC (file) address to SNES address
; This is defined elsewhere but documented here for reference
; Example: pctosnes($028C80) = $058C80

; snestoph() - Convert SNES address to PC address  
; Example: snestoph($058C80) = $028C80

; ============================================================================
; Build Information
; ============================================================================

; This disassembly combines:
; 1. Complete Diztinguish disassembly - full code coverage
; 2. Original reverse engineering - detailed commented routines
; 3. Modern development structure - organized and buildable
;
; The goal is a 100% matching disassembly that can be:
; - Built to create identical ROM to original
; - Modified for ROM hacking
; - Studied for game reverse engineering
;
; Directory Structure:
;   src/asm/banks/     - Diztinguish bank files (bank_00.asm through bank_0F.asm)
;   src/asm/           - Main engines (text_engine.asm, graphics_engine.asm)
;   src/include/       - Headers, macros, constants
;   src/data/          - Game data (text, stats, etc.)
;   src/graphics/      - Graphics data (tiles, palettes)
;
; Build Command:
;   asar main.asm output.sfc
;
; TODO: Convert to ca65 syntax for modern open-source toolchain
