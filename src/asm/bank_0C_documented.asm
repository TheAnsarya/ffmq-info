; ==============================================================================
; Bank $0C - Display and Graphics Management
; ==============================================================================
; This bank contains executable code for screen management, graphics transfers,
; PPU (Picture Processing Unit) control, and visual effects.
;
; Memory Range: $0C8000-$0CFFFF (32 KB)
;
; Major Sections:
; - VBLANK synchronization routines
; - DMA transfer management
; - Screen mode setup
; - Palette loading
; - Background layer management
; - HDMA (Horizontal DMA) effects
;
; Key Routines:
; - CODE_0C8000: VBLANK wait routine
; - CODE_0C8013: Character/monster stat display
; - CODE_0C8080: Screen initialization
;
; Related Files:
; - Bank $0B: Battle graphics routines
; - Bank $09/$0A: Graphics data
; ==============================================================================

				ORG $0C8000

; ==============================================================================
; VBLANK Wait Routine
; ==============================================================================
; Waits for VBLANK (vertical blanking interval) before proceeding.
; Critical for safe PPU access - prevents screen tearing.
; See: https://wiki.superfamicom.org/vblank-and-nmi
; ==============================================================================

CODE_0C8000:
				PHP										;0C8000	; Save processor status
				SEP #$20								;0C8001	; 8-bit accumulator
				PHA										;0C8003	; Save accumulator
				LDA.B #$40								;0C8004	; VBLANK flag bit
				TRB.W $00D8								;0C8006	; Test and reset VBLANK flag

CODE_0C8009:
				LDA.B #$40								;0C8009	; VBLANK flag bit
				AND.W $00D8								;0C800B	; Test VBLANK flag
				BEQ CODE_0C8009							;0C800E	; Loop until VBLANK starts
				PLA										;0C8010	; Restore accumulator
				PLP										;0C8011	; Restore processor status
				RTL										;0C8012	; Return

; ==============================================================================
; Character/Monster Stat Display Routine
; ==============================================================================
; Displays character or monster statistics on screen.
; Input: Accumulator = Character/monster index
; Uses stat lookup tables at $07EE84+
; ==============================================================================

CODE_0C8013:
				PHP										;0C8013	; Save processor status
				PHD										;0C8014	; Save direct page
				PEA.W $0000								;0C8015	; Push $0000
				PLD										;0C8018	; Pull to direct page (set DP=$0000)
				REP #$30								;0C8019	; 16-bit mode
				PHX										;0C801B	; Save X
				AND.W #$00FF							;0C801C	; Mask to byte
				STA.B $64								;0C801F	; Store character index
				ASL A									;0C8021	; Multiply by 5
				ASL A									;0C8022	; (shift left)
				ADC.B $64								;0C8023	; Add original (×5 total)
				TAX										;0C8025	; Transfer to X
				SEP #$20								;0C8026	; 8-bit accumulator
				LDA.B $64								;0C8028	; Load character index
				STA.W $00EF								;0C802A	; Store to temp variable
				LDA.L DATA8_07EE84,X					;0C802D	; Load stat byte 0
				STA.W $015F								;0C8031	; Store to display buffer
				LDA.L DATA8_07EE85,X					;0C8034	; Load stat byte 1
				JSR.W CODE_0C8071						;0C8038	; Process stat value
				STA.W $00B5								;0C803B	; Store processed value
				LDA.L DATA8_07EE86,X					;0C803E	; Load stat byte 2
				JSR.W CODE_0C8071						;0C8042	; Process stat value
				STA.W $00B2								;0C8045	; Store processed value
				LDA.L DATA8_07EE87,X					;0C8048	; Load stat byte 3
				JSR.W CODE_0C8071						;0C804C	; Process stat value
				STA.W $00B4								;0C804F	; Store processed value
				LDA.L DATA8_07EE88,X					;0C8052	; Load stat byte 4
				JSR.W CODE_0C8071						;0C8056	; Process stat value
				STA.W $00B3								;0C8059	; Store processed value
				LDX.W #$A433							;0C805C	; Load display routine address
				STX.B $17								;0C805F	; Store to jump pointer
				LDA.B #$03								;0C8061	; Bank $03
				STA.B $19								;0C8063	; Store bank to jump pointer
				JSL.L CODE_009D6B						;0C8065	; Call display routine
				REP #$30								;0C8069	; 16-bit mode
				LDA.B $15								;0C806B	; Load return value
				PLX										;0C806D	; Restore X
				PLD										;0C806E	; Restore direct page
				PLP										;0C806F	; Restore processor status
				RTL										;0C8070	; Return

; ==============================================================================
; Stat Value Processing Subroutine
; ==============================================================================
; Processes stat values for display (checks flags, conditions).
; Input: Accumulator = Raw stat value
; Output: Accumulator = Processed value
; ==============================================================================

CODE_0C8071:
				BEQ CODE_0C807F							;0C8071	; Branch if zero
				JSL.L CODE_009776						;0C8073	; Check stat condition
				BEQ CODE_0C807D							;0C8077	; Branch if normal
				LDA.B #$02								;0C8079	; Stat modified flag
				BRA CODE_0C807F							;0C807B	; Continue

CODE_0C807D:
				LDA.B #$01								;0C807D	; Normal stat flag

CODE_0C807F:
				RTS										;0C807F	; Return

; ==============================================================================
; Screen Initialization Routine
; ==============================================================================
; Initializes PPU registers for screen display.
; Sets up background modes, object selection, and layer priorities.
; See: https://wiki.superfamicom.org/snes-initialization
; ==============================================================================

CODE_0C8080:
				JSL.L CODE_00825C						;0C8080	; Call initialization helper
				LDA.W #$0000							;0C8084	; Clear value
				STA.L $7E3665							;0C8087	; Clear WRAM variable
				LDA.W #$2100							;0C808B	; PPU register base address
				TCD										;0C808E	; Transfer to direct page
				SEP #$20								;0C808F	; 8-bit accumulator
				STZ.W $0111								;0C8091	; Clear NMI flag
				STZ.W $00D2								;0C8094	; Clear screen mode flag
				STZ.W $00D4								;0C8097	; Clear layer enable flag
				LDA.B #$08								;0C809A	; Mode 7 enable bit
				TSB.W $00D2								;0C809C	; Set mode 7 flag
				LDA.B #$40								;0C809F	; VBLANK enable bit
				TSB.W $00D6								;0C80A1	; Enable VBLANK NMI
				LDA.B #$62								;0C80A4	; Object config value
				STA.B SNES_OBJSEL-$2100					;0C80A6	; Set object selection ($2101)
				LDA.B #$07								;0C80A8	; Background mode 7
				STA.B SNES_BGMODE-$2100					;0C80AA	; Set BG mode ($2105)
				LDA.B #$80								;0C80AC	; Mode 7 settings
				STA.B SNES_M7SEL-$2100					;0C80AE	; Set Mode 7 select ($211A)
				LDA.B #$11								;0C80B0	; Layer enable mask
				STA.B SNES_TM-$2100						;0C80B2	; Set main screen layers ($212C)

; ==============================================================================
; [Additional Display Management Routines]
; ==============================================================================
; The remaining code includes:
; - Palette loading and fading
; - Background layer scrolling
; - DMA transfer setup and execution
; - HDMA effect configuration
; - Mode 7 matrix calculations
; - Window/masking effects
;
; Complete code available in original bank_0C.asm
; Total bank size: ~4,200 lines of display management code
; ==============================================================================

; [Remaining display code continues to $0CFFFF]
; See original bank_0C.asm for complete implementation

; ==============================================================================
; End of Bank $0C
; ==============================================================================
; Total size: 32 KB (complete bank)
; Primary content: Display/PPU management code
; Related banks: $0B (battle graphics), $09/$0A (graphics data)
;
; Key functions documented:
; - VBLANK synchronization
; - Character/monster stat display
; - Screen initialization
; - PPU register management
;
; Remaining work:
; - Complete disassembly of DMA routines
; - Document HDMA effects
; - Map all Mode 7 calculations
; - Document palette management
; ==============================================================================
