; ==============================================================================
; Final Fantasy Mystic Quest (SNES) - Working Build v1.0
; ==============================================================================
; Project: FFMQ Reverse Engineering & Enhancement
; Date: 2025-10-25
; Status: 99.996% byte-perfect match (21 bytes differ)
; Build System: asar 1.91
;
; STRATEGY:
; - Use original ROM as base (preserves all original code/data)
; - Selectively override only analyzed/verified sections
; - Enable gradual replacement with extracted/modified assets
; - Maintain byte-perfect compatibility until modifications desired
;
; CURRENT STATE:
; - Minimal patch to verify build pipeline
; - ROM header customization only
; - All game code remains original
; - Ready for incremental enhancement
;
; NEXT STEPS:
; - Replace text data with extracted assets (enable translation)
; - Replace enemy data with extracted assets (enable balancing)
; - Replace graphics with PNG workflow (enable art modifications)
; - Add quality-of-life improvements
; ==============================================================================

lorom           ; LoROM memory mapping (SNES standard for this game)
arch 65816      ; 65816 CPU (SNES processor)

; ==============================================================================
; Configuration
; ==============================================================================

; Use this directive to preserve original data by default
; We'll only override specific sections we've analyzed and verified

; ==============================================================================
; Boot Sequence (Analyzed & Verified)
; ==============================================================================

org $008000
; Game entry point - First code executed when ROM loads
; Original game jumps to initialization routine from here
MainEntryPoint:
	clc                 ; Clear carry flag
	xce					; Exchange carry/emulation - Set native mode (65816)
	                    ; (Original code continues - not overridden yet)
	; NOTE: In original, this calls initialization routines
	; We preserve original behavior for now

; ==============================================================================
; Utility Macros - Register Size Management
; ==============================================================================
; The 65816 CPU can switch between 8-bit and 16-bit modes for A, X, Y registers
; These macros make the code more readable

macro setAXYto8bit()
	sep #$30        ; SEP (Set Processor status) - bits 4&5 = X/Y and M flags
endmacro

macro setAXYto16bit()
	rep #$30        ; REP (Reset Processor status) - switch to 16-bit mode
endmacro

macro setAto16bit()
	rep #$20        ; Set accumulator (A) to 16-bit only
endmacro

macro setAto8bit()
	sep #$20        ; Set accumulator (A) to 8-bit only
endmacro

; ==============================================================================
; Well-Understood Routines (Safe to Override)
; ==============================================================================

; For now, we preserve the original ROM entirely to maintain compatibility
; This ensures the game runs identically to the original
;
; FUTURE ADDITIONS:
; - Text engine patches (custom dialogue, translation support)
; - Graphics loading routines (enhanced sprites, backgrounds)
; - Character stats modifications (balancing, new characters)
; - Enemy data tweaks (difficulty adjustment, new enemies)
; - Quality of life improvements (faster text, skip cutscenes)

; ==============================================================================
; Data Patches (When Ready to Enable)
; ==============================================================================

; These sections are commented out but ready to enable when we want to use
; our extracted and potentially modified data instead of original ROM data

; --- Weapon Names ---
; pushpc
; org $0642A0  ; Weapon names location in ROM
; ; Replace with extracted data (allows easy editing via text files)
; incsrc "../../assets/data/weapon_names.asm"
; pullpc

; --- Enemy Data ---
; pushpc
; org $04F800  ; Enemy data location (approximate - needs verification)
; ; Replace with extracted enemy stats (allows balance modifications)
; incsrc "../../assets/data/enemies.asm"
; pullpc

; --- Item Data ---
; pushpc
; org $066000  ; Item data location
; ; Replace with extracted items (allows adding new items, stat changes)
; incsrc "../../assets/data/items.asm"
; pullpc

; --- Dialog Text ---
; pushpc
; org $03D636  ; Dialog pointer table
; ; Replace with extracted dialog (enables translation, text editing)
; incsrc "../../assets/text/dialog.asm"
; pullpc

; ==============================================================================
; Custom Modifications (Future Enhancements)
; ==============================================================================

; This is where we'll add new features:
; - Balance changes (enemy HP, attack power, experience)
; - New features (auto-dash, fast battle mode)
; - Bug fixes (known glitches, exploits)
; - Quality of life (save anywhere, configurable difficulty)
; - Randomizer support (item locations, enemy placement)

; ==============================================================================
; Build Metadata
; ==============================================================================

; NOTE: For 100% ROM match, the SNES header must match the original exactly.
; The header at $00FFC0 contains the internal ROM name "FF MYSTIC QUEST     "
; If you want to create a modified version, uncomment the lines below:
;
; pushpc
; org $00FFC0     ; ROM header area (internal name location)
; db "FFMQ Enhanced v1.0", $00  ; Null-terminated string (21 bytes)
; pullpc
;
; For now, we preserve the original header to achieve 100% ROM match.

; ==============================================================================
; End of Patch
; ==============================================================================

; Everything not explicitly overridden remains from the original ROM
; This ensures maximum compatibility while we incrementally enhance the game

