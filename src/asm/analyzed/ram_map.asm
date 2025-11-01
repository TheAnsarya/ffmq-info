; ============================================================================
; FFMQ Complete RAM Variable Map
; ============================================================================
; Comprehensive mapping of RAM variables used throughout FFMQ
; Based on analysis of code patterns across all banks
;
; RAM Layout:
; $0000-$00ff: Zero Page (Direct Page) - Fast access variables
; $0100-$01ff: Stack Page - Also used for variables
; $0200-$1fff: Low RAM - General purpose variables
; $7e0000-$7fffff: Work RAM Bank $7e - Main game data
; $7f0000-$7fffff: Work RAM Bank $7f - Additional data/buffers
; $700000-$7fffff: SRAM - Save game data
; ============================================================================

; ============================================================================
; Zero Page Variables ($0000-$00ff)
; ============================================================================
; These are in direct page for fast access (no bank byte needed)

; --- Temporary/Scratch Variables ---
	$15 = .word                         ; Temporary result/return value
	$17 = .word                         ; Pointer/address (low/mid bytes)
	$19 = .byte                         ; Pointer bank byte
	$53 = .word                         ; Temporary pointer
	$58 = .word                         ; Callback routine address
	$5a = .byte                         ; Callback routine bank
	$64 = .word                         ; Temporary calculation/index

; --- PPU/Display Control ---
	$00aa = .byte                       ; Screen brightness (0-15, $0f=full)
	$00b2 = .byte                       ; Equipment stat bonus 2
	$00b3 = .byte                       ; Equipment stat bonus 4
	$00b4 = .byte                       ; Equipment stat bonus 3
	$00b5 = .byte                       ; Equipment stat bonus 1

; --- System Flags (Critical!) ---
	$00d2 = .byte                       ; DMA/System flags byte 1
; Bit 0: Unknown
; Bit 1: Unknown
; Bit 2: Unknown
; Bit 3: Menu DMA active
; Bit 4: VRAM transfer mode
; Bit 5: Tile transfer pending
; Bit 6: Unknown
; Bit 7: Palette DMA requested

	$00d4 = .byte                       ; DMA/System flags byte 2
; Bit 0: General transfer flag
; Bit 1: Tile transfer flag
; Bit 2: Unknown
; Bit 3: Unknown
; Bit 4: Unknown
; Bit 5: Unknown
; Bit 6: Unknown
; Bit 7: Tile DMA requested

	$00d6 = .byte                       ; Display update flags
; Bit 0-5: Unknown
; Bit 6: Display update pending
; Bit 7: Unknown

	$00d8 = .byte                       ; VBlank/transfer flags
; Bit 0: Unknown
; Bit 1: Palette mode flag
; Bit 2: Unknown
; Bit 3: Unknown
; Bit 4: Unknown
; Bit 5: Unknown
; Bit 6: VBlank occurred (set by NMI, cleared by WaitForVBlank)
; Bit 7: Special transfer mode

	$00d9 = .byte                       ; Additional system flags
	$00da = .word                       ; Hardware configuration flags
	$00dd = .byte                       ; VRAM transfer flags
; Bit 6: Transfer pending

	$00de = .byte                       ; General flags byte 1
; Bit 7: Used in boot sequence

; --- Callback/Interrupt Control ---
	$00e2 = .byte                       ; Callback flags
; Bit 6: Callback pending (execute $0058-$005a routine)

	$00ef = .byte                       ; Current equipment slot (0-4)
	$00f0 = .word                       ; Transfer mask word

; ============================================================================
; Page 1 Variables ($0100-$01ff)
; ============================================================================

	$0110 = .byte                       ; Menu state/mode
	$0111 = .byte                       ; General menu flags
	$0112 = .byte                       ; Saved interrupt enable flags (for $4200)
	$015f = .byte                       ; Current equipment ID

; --- DMA Parameter Storage ---
	$01eb = .word                       ; Palette data size
	$01ed = .word                       ; Palette source address (low/mid)
	$01ef = .byte                       ; Palette source bank
	$01f0 = .word                       ; Unknown parameter
	$01f2 = .word                       ; Unknown parameter
	$01f4 = .word                       ; General transfer size
	$01f6 = .word                       ; General source address
	$01f8 = .word                       ; General VRAM destination
	$0048 = .word                       ; VRAM destination address
	$0062 = .word                       ; Transfer mode type
	$0064 = .word                       ; Tile data index

; ============================================================================
; Low RAM Variables ($0200-$1fff)
; ============================================================================

; --- Menu/Equipment Display ---
	$0e08 = .word                       ; Menu window data
	$0e0a = .word                       ; Menu window data
	$0e0c = .word                       ; Menu window data
	$0e88 = .byte                       ; Equipment parameter 1
	$0e89 = .word                       ; Equipment parameter 2
	$0e92 = .byte                       ; Equipment parameter 3
	$0e9c = .word                       ; Unknown data

; --- Character Stats (per character) ---
; Each character has a stat block, likely ~32-64 bytes
; Includes: HP, MP, ATK, DEF, level, experience, etc.

	$0c84 = .word                       ; Character data pointer 1
	$0c88 = .word                       ; Character data pointer 2
	$0c8c = .word                       ; Character data pointer 3
	$0c90 = .word                       ; Character data pointer 4
	$0cc0 = .word                       ; Character extended data 1
	$0cc4 = .word                       ; Character extended data 2
	$0cc8 = .word                       ; Character extended data 3
	$0ccc = .word                       ; Character extended data 4

; ============================================================================
; Work RAM Bank $7e ($7e0000-$7e7fff)
; ============================================================================

; --- Boot/Save Flags ---
	$7e3659 = .byte                     ; Unknown flag
	$7e365a = .word                     ; Unknown data
	$7e365c = .word                     ; Unknown data
	$7e365e = .byte                     ; Unknown flag
	$7e365f = .word                     ; Unknown data
	$7e3661 = .word                     ; Unknown data
	$7e3663 = .byte                     ; Unknown flag
	$7e3665 = .byte                     ; Save data present / Menu initialized flag
; $00 = no save, $01 = save exists/menu ready
	$7e3667 = .byte                     ; Boot flag 1
; Incremented on each boot
	$7e3668 = .byte                     ; Boot flag 2
; Incremented on each restart
	$7e3367 = .word                     ; Magic number $3369 (checksum/validity?)

; --- Game State Data ---
; $7e3000-$7e3fff likely contains:
; - Party member data
; - Inventory
; - Equipment
; - Flags for events/progression
; - Current location/map

; --- Graphics Buffers ---
; $7f0000-$7fffff used for:
; - DMA source buffers
; - Decompressed graphics
; - Tilemap staging area

	$7f075a = .word                     ; Graphics buffer (used in DMA)

; ============================================================================
; SRAM ($700000-$7fffff)
; ============================================================================
; Battery-backed save RAM for persistent game data

; --- Save Slots ---
	$700000 = .block 140                ; Save slot 1 data
; Offset $000-$038b (907 bytes)
	$70038c = .block 140                ; Save slot 2 data
; Offset $38c-$717 (907 bytes)
	$700718 = .block 140                ; Save slot 3 data
; Offset $718-$aa3 (907 bytes)

; Save data format (per slot, ~900 bytes):
; - Character stats (HP, MP, level, exp)
; - Equipment (weapon, armor, helmet, shield, accessory per character)
; - Inventory (items, quantities)
; - Magic spells learned
; - Game progress flags
; - Play time
; - Gold/currency
; - Current location
; - Party formation

; ============================================================================
; Flag Byte Usage Patterns
; ============================================================================

; The game extensively uses bit flags for state management:
;
; Common operations:
; - TSB (Test and Set Bits): Set specific bits to 1
; - TRB (Test and Reset Bits): Clear specific bits to 0
; - AND: Test if bits are set
; - BEQ/BNE: Branch based on result
;
; Example VBlank synchronization:
;   LDA #$40        ; Bit 6
;   TRB $00d8       ; Clear VBlank flag
; .loop:
;   AND $00d8       ; Test VBlank flag
;   BEQ .loop       ; Loop until set
;
; This pattern appears hundreds of times throughout the code

; ============================================================================
; Critical RAM Addresses Summary
; ============================================================================
; Most frequently accessed:
; 1. $00d8 - VBlank flag (used in every frame update)
; 2. $00d2 - DMA flags (used in all graphics operations)
; 3. $00d4 - Transfer flags (used in VRAM updates)
; 4. $00aa - Brightness (screen fade in/out)
; 5. $7e3665 - Save/init flag (checked often)
; 6. $00da - Hardware config (checked for features)
; 7. $01f4-$01f8 - DMA parameters (every graphics transfer)

; ============================================================================
; Memory Map Confidence Levels
; ============================================================================
; ✅ High Confidence (verified through multiple code paths):
;    $00aa, $00d2, $00d4, $00d6, $00d8, $00e2, $7e3665, $7e3667, $7e3668
;
; ⚠️ Medium Confidence (inferred from patterns):
;    $00b2-$00b5, $00ef, $015f, $01eb-$01f8, SRAM layout
;
; ❓ Low Confidence (needs more analysis):
;    Character stat block exact layout, inventory structure details
;
; 🔍 Needs Investigation:
;    $7e3000-$7e3600 range (likely game state/progression)
;    $0200-$0800 range (various game systems)
;    $1000-$1fff range (additional buffers)
; ============================================================================

; ============================================================================
; Next Steps for Complete RAM Map
; ============================================================================
; 1. Analyze save/load routines to understand SRAM structure
; 2. Trace character stat access patterns
; 3. Map inventory system RAM usage
; 4. Document battle system RAM (enemy data, damage calc)
; 5. Map event/script system flags
; 6. Document sound/music RAM usage
; ============================================================================
