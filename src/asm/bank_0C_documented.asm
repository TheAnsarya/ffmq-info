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
; ==============================================================================
; BANK $0C CYCLE 1 - Screen Initialization & Graphics Management (Lines 100-500)
; ==============================================================================
; Continuation from address $0C80B2
; Major systems: Screen mode setup, VRAM initialization, palette DMA, window effects
; ==============================================================================

; [Continued from documented section ending at $0C80B2]

	STA.B SNES_TM-$2100						;0C80B2	; Set main screen layers ($212C) = $11 (BG1+Obj)
	JSR.W CODE_0C8D7B						;0C80B4	; Call graphics setup routine
	LDA.W $0112								;0C80B7	; Load NMI enable flags
	STA.W $4200								;0C80BA	; Set NMI/IRQ/Auto-Joypad ($4200)
	CLI										;0C80BD	; Enable interrupts
	LDA.B #$0F								;0C80BE	; Brightness = 15 (full)
	STA.W $00AA								;0C80C0	; Store brightness value
	STZ.W $0110								;0C80C3	; Clear screen state flag
	JSL.L CODE_00C795						;0C80C6	; Call main game loop handler
	JSR.W CODE_0C8BAD						;0C80CA	; Graphics state update
	JSR.W CODE_0C896F						;0C80CD	; Background layer setup
	JSL.L CODE_0C8000						;0C80D0	; Wait for VBLANK
	LDA.B #$01								;0C80D4	; BG mode 1
	STA.B SNES_BGMODE-$2100					;0C80D6	; Set background mode ($2105)
	LDA.B #$62								;0C80D8	; BG1 tilemap config
	STA.B SNES_BG1SC-$2100					;0C80DA	; BG1 screen config ($2107)
	LDA.B #$69								;0C80DC	; BG2 tilemap config
	STA.B SNES_BG2SC-$2100					;0C80DE	; BG2 screen config ($2108)
	LDA.B #$44								;0C80E0	; Character address config
	STA.B SNES_BG12NBA-$2100				;0C80E2	; BG1/BG2 char address ($210B)
	LDA.B #$13								;0C80E4	; Layer enable mask
	STA.B SNES_TM-$2100						;0C80E6	; Set main screen layers ($212C)
	JSR.W CODE_0C9037						;0C80E8	; Additional graphics setup
	JSR.W CODE_0C8103						;0C80EB	; Call main screen init
	REP #$30								;0C80EE	; 16-bit A/X/Y
	LDA.W #$0001							;0C80F0	; Screen initialized flag
	STA.L $7E3665							;0C80F3	; Set screen ready flag (WRAM)
	JSL.L CODE_00C7B8						;0C80F7	; Game state handler
	SEI										;0C80FB	; Disable interrupts
	LDA.W #$0008							;0C80FC	; VBLANK processing flag
	TRB.W $00D2								;0C80FF	; Reset VBLANK flag
	RTL										;0C8102	; Return

; ==============================================================================
; CODE_0C8103 - Main Screen Initialization Routine
; ==============================================================================
; Sets up Mode 7 screen, loads palettes, initializes display registers.
; Called during screen transitions and battle entry.
; ==============================================================================

CODE_0C8103:
	LDA.B #$0C								;0C8103	; Bank $0C
	STA.W $005A								;0C8105	; Set data bank
	LDX.W #$90D7							;0C8108	; Address of palette DMA code
	STX.W $0058								;0C810B	; Set DMA routine pointer
	LDA.B #$40								;0C810E	; VBLANK DMA flag
	TSB.W $00E2								;0C8110	; Set DMA pending flag
	JSL.L CODE_0C8000						;0C8113	; Wait for VBLANK
	LDA.B #$07								;0C8117	; Background mode 7
	STA.B SNES_BGMODE-$2100					;0C8119	; Set BG mode ($2105)
	JSR.W CODE_0C87ED						;0C811B	; Mode 7 matrix setup
	JSR.W CODE_0C81DA						;0C811E	; Palette load setup
	JSR.W CODE_0C88BE						;0C8121	; Additional graphics init
	JSR.W CODE_0C8872						;0C8124	; Background scrolling setup
	JSR.W CODE_0C87E9						;0C8127	; Finalize graphics state
	LDA.B #$40								;0C812A	; VBLANK flag
	TRB.W $00D6								;0C812C	; Clear VBLANK pending
	JSL.L CODE_0C8000						;0C812F	; Wait for VBLANK
	LDA.B #$01								;0C8133	; BG mode 1
	STA.B SNES_BGMODE-$2100					;0C8135	; Set BG mode ($2105)
	STZ.B SNES_BG1VOFS-$2100				;0C8137	; BG1 V-scroll = 0 ($210E)
	STZ.B SNES_BG1VOFS-$2100				;0C8139	; Write high byte
	JSR.W CODE_0C8767						;0C813B	; Graphics state finalize
	JSR.W CODE_0C8241						;0C813E	; Sprite/OAM setup
	RTS										;0C8141	; Return

; ==============================================================================
; CODE_0C8142 - Window Effect Configuration
; ==============================================================================
; Sets up color window registers for screen effects (fades, transitions).
; Configures SNES window masking system.
; ==============================================================================

CODE_0C8142:
	LDX.W #$4156							;0C8142	; Window config value 1
	STX.W $0E08								;0C8145	; Store window settings
	LDX.W #$5555							;0C8148	; Window config value 2
	STX.W $0E0A								;0C814B	; Additional window data
	LDX.W #$5500							;0C814E	; Window config value 3
	STX.W $0E0C								;0C8151	; Final window settings
	JMP.W CODE_0C8910						;0C8154	; Jump to window apply routine

; ==============================================================================
; CODE_0C8157 - VRAM Address Calculation Routine
; ==============================================================================
; Calculates VRAM addresses for tile placement.
; Adds offset $0804 to base addresses for proper tile positioning.
; ==============================================================================

CODE_0C8157:
	CLC										;0C8157	; Clear carry
	REP #$30								;0C8158	; 16-bit A/X/Y
	LDA.W $0C84								;0C815A	; Load VRAM base address 1
	ADC.W #$0804							;0C815D	; Add tile offset
	STA.W $0CC0								;0C8160	; Store calculated address
	LDA.W $0C88								;0C8163	; Load VRAM base address 2
	ADC.W #$0804							;0C8166	; Add tile offset
	STA.W $0CC4								;0C8169	; Store calculated address
	LDA.W $0C8C								;0C816C	; Load VRAM base address 3
	ADC.W #$0804							;0C816F	; Add tile offset
	STA.W $0CC8								;0C8172	; Store calculated address
	LDA.W $0C90								;0C8175	; Load VRAM base address 4
	ADC.W #$0C90							;0C8178	; Add tile offset
	STA.W $0CCC								;0C817B	; Store calculated address
	SEP #$20								;0C817E	; 8-bit accumulator
	LDA.B #$80								;0C8180	; VRAM increment mode (increment on $2119 write)
	JSL.L CODE_0C8000						;0C8182	; Wait for VBLANK
	STA.B SNES_VMAINC-$2100					;0C8186	; Set VRAM increment ($2115)
	LDA.B #$08								;0C8188	; Tile pattern value
	LDX.W #$6225							;0C818A	; VRAM address $6225
	JSR.W CODE_0C81A5						;0C818D	; Call VRAM fill routine
	LDA.B #$0C								;0C8190	; Tile pattern value
	LDX.W #$622A							;0C8192	; VRAM address $622A
	JSR.W CODE_0C81A5						;0C8195	; Call VRAM fill routine
	LDA.B #$14								;0C8198	; Tile pattern value
	LDX.W #$6234							;0C819A	; VRAM address $6234
	JSR.W CODE_0C81A5						;0C819D	; Call VRAM fill routine
	LDA.B #$10								;0C81A0	; Tile pattern value
	LDX.W #$6239							;0C81A2	; VRAM address $6239

; ==============================================================================
; CODE_0C81A5 - VRAM Pattern Fill Routine
; ==============================================================================
; Fills VRAM with sequential tile numbers for background patterns.
; Creates animated tile sequences (water, fire, etc.).
; Input: A = pattern start value, X = VRAM address
; ==============================================================================

CODE_0C81A5:
	XBA										;0C81A5	; Swap A/B registers
	LDA.B #$00								;0C81A6	; Clear low byte
	REP #$30								;0C81A8	; 16-bit A/X/Y

CODE_0C81AA:									; Loop: Fill VRAM pattern
	STX.B SNES_VMADDL-$2100					;0C81AA	; Set VRAM address ($2116)
	STA.B SNES_VMDATAL-$2100				;0C81AC	; Write tile number ($2118)
	INC A									;0C81AE	; Next tile
	STA.B SNES_VMDATAL-$2100				;0C81AF	; Write tile number
	INC A									;0C81B1	; Next tile
	STA.B SNES_VMDATAL-$2100				;0C81B2	; Write tile number
	TAY										;0C81B4	; Save tile counter to Y
	TXA										;0C81B5	; Load VRAM address
	ADC.W #$0020							;0C81B6	; Move to next row (+32 tiles)
	TAX										;0C81B9	; Update VRAM address
	TYA										;0C81BA	; Restore tile counter
	ADC.W #$000E							;0C81BB	; Advance tile pattern
	BIT.W #$0040							;0C81BE	; Test completion bit
	BEQ CODE_0C81AA							;0C81C1	; Loop if not done
	SEP #$20								;0C81C3	; 8-bit accumulator
	RTS										;0C81C5	; Return

; ==============================================================================
; CODE_0C81C6 - Color Math Disable Routine
; ==============================================================================
; Disables color addition/subtraction effects.
; Resets window and color math registers.
; ==============================================================================

CODE_0C81C6:
	STZ.B SNES_CGSWSEL-$2100				;0C81C6	; Clear color window select ($2130)
	STZ.B SNES_CGADSUB-$2100				;0C81C8	; Clear color math ($2131)
	RTS										;0C81CA	; Return

; ==============================================================================
; CODE_0C81CB - Color Addition Effect Setup
; ==============================================================================
; Enables color addition for screen brightness/darkness effects.
; Used for battle transitions, lightning, darkness, etc.
; ==============================================================================

CODE_0C81CB:
	LDX.W #$7002							;0C81CB	; Color window config
	STX.B SNES_CGSWSEL-$2100				;0C81CE	; Set color window ($2130-$2131)
	LDA.B #$E0								;0C81D0	; Fixed color data (brightness)
	STA.B SNES_COLDATA-$2100				;0C81D2	; Set fixed color value ($2132)
	LDX.W #$0110							;0C81D4	; Layer enable mask
	STX.B SNES_TM-$2100						;0C81D7	; Set main/sub screen layers ($212C-$212D)
	RTS										;0C81D9	; Return

; ==============================================================================
; CODE_0C81DA - Palette DMA Setup Routine
; ==============================================================================
; Prepares palette data for DMA transfer during VBLANK.
; Sets up indirect DMA from Bank $0C address $81EF.
; ==============================================================================

CODE_0C81DA:
	LDA.B #$0C								;0C81DA	; Bank $0C
	STA.W $005A								;0C81DC	; Set DMA source bank
	LDX.W #$81EF							;0C81DF	; Palette DMA routine address
	STX.W $0058								;0C81E2	; Set DMA routine pointer
	LDA.B #$40								;0C81E5	; VBLANK DMA flag
	TSB.W $00E2								;0C81E7	; Set DMA pending flag
	JSL.L CODE_0C8000						;0C81EA	; Wait for VBLANK
	RTS										;0C81EE	; Return

; ==============================================================================
; Palette DMA Transfer Code (Embedded at $0C81EF)
; ==============================================================================
; Direct palette load routine executed during VBLANK.
; Transfers 16-byte palette chunks from Bank $07 to CGRAM.
; ==============================================================================

; [Palette DMA routine starts here]
	LDX.W #$2200							;0C81EF	; DMA params: A→B, increment
	STX.B SNES_DMA0PARAM-$4300				;0C81F2	; DMA0 params ($4300)
	LDA.B #$07								;0C81F4	; Source bank = Bank $07 (palette data)
	STA.B SNES_DMA0ADDRH-$4300				;0C81F6	; DMA0 source bank ($4304)
	LDA.B #$10								;0C81F8	; Starting palette index = $10
	LDY.W #$D974							;0C81FA	; Source address $07:D974
	JSR.W CODE_0C8224						;0C81FD	; DMA 16 bytes to CGRAM
	LDY.W #$D934							;0C8200	; Source address $07:D934
	JSR.W CODE_0C8224						;0C8203	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C8206	; DMA 16 bytes (auto-increment)
	JSR.W CODE_0C8224						;0C8209	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C820C	; DMA 16 bytes
	LDA.B #$B0								;0C820F	; Palette index = $B0
	JSR.W CODE_0C8224						;0C8211	; DMA 16 bytes
	LDY.W #$D934							;0C8214	; Reset source to $07:D934
	JSR.W CODE_0C8224						;0C8217	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C821A	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C821D	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C8220	; DMA 16 bytes
	RTL										;0C8223	; Return from palette DMA

; ==============================================================================
; CODE_0C8224 - Single Palette DMA Transfer (16 bytes)
; ==============================================================================
; Transfers 16 bytes of palette data to CGRAM via DMA.
; Input: A = CGRAM address, Y = source address (Bank $07)
; Output: A += $10, Y += $10 (auto-incremented for next call)
; ==============================================================================

CODE_0C8224:
	PHA										;0C8224	; Save CGRAM address
	STA.W SNES_CGADD						;0C8225	; Set CGRAM address ($2121)
	STY.B SNES_DMA0ADDRL-$4300				;0C8228	; DMA0 source address ($4302)
	LDX.W #$0010							;0C822A	; Transfer size = 16 bytes
	STX.B SNES_DMA0CNTL-$4300				;0C822D	; DMA0 byte count ($4305)
	LDA.B #$01								;0C822F	; Enable DMA channel 0
	STA.W SNES_MDMAEN						;0C8231	; Start DMA ($420B)
	REP #$30								;0C8234	; 16-bit A/X/Y
	TYA										;0C8236	; Load source address
	ADC.W #$0010							;0C8237	; Advance +16 bytes
	TAY										;0C823A	; Update source address
	SEP #$20								;0C823B	; 8-bit accumulator
	PLA										;0C823D	; Restore CGRAM address
	ADC.B #$10								;0C823E	; Advance +16 colors
	RTS										;0C8240	; Return

; ==============================================================================
; CODE_0C8241 - OAM/Sprite Initialization Routine
; ==============================================================================
; Copies sprite configuration data to OAM buffer.
; Uses MVN (block move) for fast 9-byte transfer.
; ==============================================================================

CODE_0C8241:
	REP #$30								;0C8241	; 16-bit A/X/Y
	LDX.W #$8667							;0C8243	; Source address $0C:8667
	LDY.W #$0202							;0C8246	; Destination address $00:0202
	LDA.W #$0009							;0C8249	; Transfer 10 bytes (9+1 for MVN)
	MVN $0C,$0C								;0C824C	; Block move within bank $0C
	SEP #$20								;0C824F	; 8-bit accumulator
	STZ.W $0160								;0C8251	; Clear sprite state flag
	STZ.W $0201								;0C8254	; Clear OAM control byte
	LDX.W #$8671							;0C8257	; Effect script address

; ==============================================================================
; CODE_0C825A - Visual Effect Script Interpreter
; ==============================================================================
; Interprets bytecode commands for screen effects (fades, flashes, transitions).
; Commands: 00=wait, 01=fade step, 02=color cycle, 03=palette load, etc.
; ==============================================================================

CODE_0C825A:
	LDA.W $0000,X							;0C825A	; Load effect command byte
	INX										;0C825D	; Advance script pointer
	CMP.B #$01								;0C825E	; Command < 01?
	BCC CODE_0C8297							;0C8260	; Branch to wait routine
	BEQ CODE_0C8292							;0C8262	; Command = 01: Single frame delay
	CMP.B #$03								;0C8264	; Command < 03?
	BCC CODE_0C8288							;0C8266	; Branch to color cycle
	BEQ CODE_0C82A0							;0C8268	; Command = 03: Palette operation
	CMP.B #$05								;0C826A	; Command = 05?
	BEQ CODE_0C82A3							;0C826C	; Branch to special effect
	BCS CODE_0C82A6							;0C826E	; Command >= 06: Complex operations
	LDY.W #$0004							;0C8270	; Loop count = 4

; Color flash effect loop (command 04)
CODE_0C8273:
	PHY										;0C8273	; Save loop counter
	LDA.B #$3F								;0C8274	; Fixed color = white ($3F)
	STA.B SNES_COLDATA-$2100				;0C8276	; Set color addition ($2132)
	JSR.W CODE_0C85DB						;0C8278	; Wait one frame
	LDA.B #$E0								;0C827B	; Fixed color = dark ($E0)
	STA.B SNES_COLDATA-$2100				;0C827D	; Set color subtraction
	JSR.W CODE_0C85DB						;0C827F	; Wait one frame
	PLY										;0C8282	; Restore loop counter
	DEY										;0C8283	; Decrement
	BNE CODE_0C8273							;0C8284	; Loop 4 times (4 flashes)
	BRA CODE_0C825A							;0C8286	; Continue script

; Color cycle effect (command 02)
CODE_0C8288:
	LDA.B #$3B								;0C8288	; Cycle duration = 59 frames

CODE_0C828A:
	PHA										;0C828A	; Save counter
	JSR.W CODE_0C85DB						;0C828B	; Wait one frame
	PLA										;0C828E	; Restore counter
	DEC A									;0C828F	; Decrement
	BNE CODE_0C828A							;0C8290	; Loop until counter = 0

; Single frame delay (command 01)
CODE_0C8292:
	JSR.W CODE_0C85DB						;0C8292	; Wait one frame
	BRA CODE_0C825A							;0C8295	; Continue script

; Wait until condition met (command 00)
CODE_0C8297:
	JSR.W CODE_0C85DB						;0C8297	; Wait one frame
	LDA.W $0C82								;0C829A	; Load condition flag
	BNE CODE_0C8297							;0C829D	; Loop until flag clears
	RTS										;0C829F	; Return from effect script

; Palette load command (command 03)
CODE_0C82A0:
	JMP.W CODE_0C8460						;0C82A0	; Jump to palette loader

; Special effect command (command 05)
CODE_0C82A3:
	JMP.W CODE_0C8421						;0C82A3	; Jump to special effect handler

; ==============================================================================
; Complex Command Handler (Commands $06-$FF)
; ==============================================================================
; Decodes complex commands with parameters.
; Format: [CMD:5bits][PARAM:3bits] for advanced visual effects.
; ==============================================================================

CODE_0C82A6:
	PHA										;0C82A6	; Save command byte
	AND.B #$07								;0C82A7	; Extract parameter (bits 0-2)
	STA.W $015F								;0C82A9	; Store parameter
	PLA										;0C82AC	; Restore command byte
	AND.B #$F8								;0C82AD	; Extract command (bits 3-7)
	CMP.B #$40								;0C82AF	; Command < $40?
	BCC CODE_0C8302							;0C82B1	; Branch to low-range handler
	CMP.B #$80								;0C82B3	; Command < $80?
	BCC CODE_0C82F7							;0C82B5	; Branch to mid-range handler
	CMP.B #$C0								;0C82B7	; Command < $C0?
	BCC CODE_0C82CF							;0C82B9	; Branch to high-range handler
	SBC.B #$40								;0C82BB	; Normalize command ($C0+ → $80+)
	STA.W $0161								;0C82BD	; Store normalized command
	REP #$30								;0C82C0	; 16-bit A/X/Y
	LDA.W $015F								;0C82C2	; Load parameter
	ASL A									;0C82C5	; *2
	ASL A									;0C82C6	; *4 (table offset)
	ADC.W #$0CBC							;0C82C7	; Add table base address
	JSR.W CODE_0C83CB						;0C82CA	; Execute table entry
	BRA CODE_0C825A							;0C82CD	; Continue script

; High-range command handler ($80-$BF)
CODE_0C82CF:
	STA.W $0161								;0C82CF	; Store command
	REP #$30								;0C82D2	; 16-bit A/X/Y
	LDA.W $015F								;0C82D4	; Load parameter
	ASL A									;0C82D7	; *2
	ASL A									;0C82D8	; *4
	PHA										;0C82D9	; Save offset
	ADC.W #$0C80							;0C82DA	; Add table base 1
	JSR.W CODE_0C83CB						;0C82DD	; Execute table entry 1
	REP #$30								;0C82E0	; 16-bit A/X/Y
	PLA										;0C82E2	; Restore offset
	ASL A									;0C82E3	; *2 again (*8 total)
	ADC.W #$0C94							;0C82E4	; Add table base 2
	JSR.W CODE_0C83CB						;0C82E7	; Execute table entry 2
	REP #$30								;0C82EA	; 16-bit A/X/Y
	TYA										;0C82EC	; Load Y (result from previous call)
	CLC										;0C82ED	; Clear carry
	ADC.W #$0004							;0C82EE	; Add 4
	JSR.W CODE_0C83CB						;0C82F1	; Execute table entry 3
	JMP.W CODE_0C825A						;0C82F4	; Continue script

; Mid-range command handler ($40-$7F)
CODE_0C82F7:
	SBC.B #$30								;0C82F7	; Normalize command ($40+ → $10+)
	LSR A									;0C82F9	; /2
	LSR A									;0C82FA	; /4
	LSR A									;0C82FB	; /8
	STA.W $0200								;0C82FC	; Store effect type
	JMP.W CODE_0C825A						;0C82FF	; Continue script

; Low-range command handler ($08-$3F)
CODE_0C8302:
	CMP.B #$08								;0C8302	; Command = $08?
	BNE CODE_0C837D							;0C8304	; Branch if not $08
	LDA.W $015F								;0C8306	; Load parameter
	BNE CODE_0C831E							;0C8309	; Branch if parameter != 0
	REP #$30								;0C830B	; 16-bit A/X/Y
	LDA.W #$3C03							;0C830D	; Bit mask
	TRB.W $0E08								;0C8310	; Clear bits in window config
	LDA.W #$0002							;0C8313	; New value
	TSB.W $0E08								;0C8316	; Set bits in window config
	SEP #$20								;0C8319	; 8-bit accumulator
	JMP.W CODE_0C825A						;0C831B	; Continue script

; Parameter-based table lookup
CODE_0C831E:
	REP #$30								;0C831E	; 16-bit A/X/Y
	LDA.W $015F								;0C8320	; Load parameter
	ASL A									;0C8323	; *2
	ASL A									;0C8324	; *4
	PHA										;0C8325	; Save offset
	ADC.W #$0C80							;0C8326	; Add table base 1
	TAY										;0C8329	; Use as index
	LDA.W $0C80								;0C832A	; Load value from table
	STA.W $0000,Y							;0C832D	; Store to destination
	PLA										;0C8330	; Restore offset
	ASL A									;0C8331	; *2 (*8 total)
	ADC.W #$0C94							;0C8332	; Add table base 2
	TAY										;0C8335	; Use as index
	LDA.W $0C94								;0C8336	; Load first value
	STA.W $0000,Y							;0C8339	; Store to destination
	LDA.W $0C98								;0C833C	; Load second value
	STA.W $0004,Y							;0C833F	; Store to destination+4
	LDY.W $015F								;0C8342	; Load parameter
	LDA.W #$0003							;0C8345	; Bit shift value = 3

; Bit shift loop
CODE_0C8348:
	ASL A									;0C8348	; Shift left *2
	ASL A									;0C8349	; Shift left *2 (total *4)
	DEY										;0C834A	; Decrement parameter
	BNE CODE_0C8348							;0C834B	; Loop until parameter = 0
	PHA										;0C834D	; Save shifted value
	TRB.W $0E08								;0C834E	; Clear bits in window config
	AND.W #$AAAA							;0C8351	; Mask pattern ($AAAA)
	TSB.W $0E08								;0C8354	; Set masked bits
	PLA										;0C8357	; Restore shifted value
	LDY.W $015F								;0C8358	; Reload parameter
	LSR A									;0C835B	; Shift right /2
	LSR A									;0C835C	; Shift right /2 (total /4)

; Second bit shift loop
CODE_0C835D:
	ASL A									;0C835D	; Shift left *2
	ASL A									;0C835E	; Shift left *2 (total *4)
	DEY										;0C835F	; Decrement parameter
	BNE CODE_0C835D							;0C8360	; Loop until parameter = 0
	LSR A									;0C8362	; Shift right /2
	LSR A									;0C8363	; Shift right /2 (total /4)
	PHA										;0C8364	; Save value
	LSR A									;0C8365	; Shift right /2
	LSR A									;0C8366	; Shift right /2
	ORA.B $01,S								;0C8367	; OR with stack value
	TRB.W $0E0A								;0C8369	; Clear bits in second window config
	CMP.W #$0003							;0C836C	; Compare to 3
	BNE CODE_0C8377							;0C836F	; Branch if not equal
	LDA.W #$C000							;0C8371	; Top bits mask
	TRB.W $0E08								;0C8374	; Clear top bits in first window config

CODE_0C8377:
	PLA										;0C8377	; Clean up stack
	SEP #$20								;0C8378	; 8-bit accumulator
	JMP.W CODE_0C825A						;0C837A	; Continue script

; ==============================================================================
; Complex Screen Effect Setup (Command $08+)
; ==============================================================================
; Initializes multi-stage screen effects combining VRAM updates,
; palette fades, and color window operations.
; ==============================================================================

CODE_0C837D:
	PHX										;0C837D	; Save script pointer
	JSR.W CODE_0C8157						;0C837E	; Calculate VRAM addresses
	JSR.W CODE_0C8142						;0C8381	; Setup window effects
	JSR.W CODE_0C83B1						;0C8384	; Execute effect stage 1
	JSR.W CODE_0C83B1						;0C8387	; Execute effect stage 2
	JSR.W CODE_0C83B1						;0C838A	; Execute effect stage 3
	LDA.B #$10								;0C838D	; Loop counter = 16 frames

CODE_0C838F:
	PHA										;0C838F	; Save counter
	JSR.W CODE_0C81CB						;0C8390	; Enable color addition
	JSR.W CODE_0C85DB						;0C8393	; Wait one frame
	JSR.W CODE_0C85DB						;0C8396	; Wait one frame

; [Additional effect code continues...]

; ==============================================================================
; End of Bank $0C Cycle 1
; ==============================================================================
; Lines documented: 400 source lines (100-500)
; Address range: $0C80B2-$0C8399 (partial)
; Major systems: Screen init, VRAM management, palette DMA, effect scripts
; ==============================================================================
; ==============================================================================
; BANK $0C CYCLE 2 - Graphics Effects & Screen Transitions (Lines 500-900)
; ==============================================================================
; Address range: $0C8396-$0C8813
; Systems: Screen effects, window animations, visual transitions, Mode 7 setup
; ==============================================================================

; [Continued from Cycle 1 ending at $0C8399]

	JSR.W CODE_0C85DB						;0C8396	; Wait one frame (VBLANK sync)
	LDA.B #$11								;0C8399	; Layer enable mask
	STA.B SNES_TM-$2100						;0C839B	; Set main screen layers ($212C)
	JSR.W CODE_0C81C6						;0C839D	; Disable color math
	JSR.W CODE_0C85DB						;0C83A0	; Wait one frame
	JSR.W CODE_0C85DB						;0C83A3	; Wait one frame
	PLA										;0C83A6	; Restore loop counter
	DEC A									;0C83A7	; Decrement
	BNE CODE_0C838F							;0C83A8	; Loop if not done (16 frames total)
	JSR.W CODE_0C81CB						;0C83AA	; Re-enable color addition
	PLX										;0C83AD	; Restore script pointer
	JMP.W CODE_0C825A						;0C83AE	; Continue effect script

; ==============================================================================
; CODE_0C83B1 - Flash Effect Subroutine
; ==============================================================================
; Creates white flash effect (bright → normal → bright sequence).
; Used for lightning, magic spells, critical hits.
; ==============================================================================

CODE_0C83B1:
	JSR.W CODE_0C81CB						;0C83B1	; Enable color addition
	LDA.B #$11								;0C83B4	; Layer enable mask
	STA.B SNES_TM-$2100						;0C83B6	; Set layers ($212C)
	LDA.B #$3F								;0C83B8	; Fixed color = white ($3F)
	STA.B SNES_COLDATA-$2100				;0C83BA	; Set color addition ($2132)
	JSR.W CODE_0C85DB						;0C83BC	; Wait one frame (flash)
	JSR.W CODE_0C81C6						;0C83BF	; Disable color math
	JSR.W CODE_0C85DB						;0C83C2	; Wait one frame
	JSR.W CODE_0C85DB						;0C83C5	; Wait one frame
	JMP.W CODE_0C85DB						;0C83C8	; Wait one frame and return

; ==============================================================================
; CODE_0C83CB - Table-Based Effect Executor
; ==============================================================================
; Executes visual effects from data tables.
; Modifies screen position/color values based on command and parameter.
; Input: A = table offset, $0161 = command type, $0200 = adjustment value
; ==============================================================================

CODE_0C83CB:
	PHX										;0C83CB	; Save X register
	TAX										;0C83CC	; Use A as table index
	SEP #$20								;0C83CD	; 8-bit accumulator
	LDY.W $0161								;0C83CF	; Load command type
	CPY.W #$00B8							;0C83D2	; Command = $B8 (specific effect)?
	BEQ CODE_0C83DD							;0C83D5	; Branch if match
	CPY.W #$0089							;0C83D7	; Command >= $89?
	BCS UNREACH_0C83E8						;0C83DA	; Branch if high range
	SEC										;0C83DC	; Set carry for subtraction

CODE_0C83DD:
	LDA.W $0001,X							;0C83DD	; Load table value
	SBC.W $0200								;0C83E0	; Subtract adjustment
	STA.W $0001,X							;0C83E3	; Store result
	BRA CODE_0C83FB							;0C83E6	; Continue

UNREACH_0C83E8:
	db $C0,$98,$00,$90,$0E,$C0,$A9,$00,$B0,$09,$BD,$01,$00,$6D,$00,$02 ; Additional effect logic
	db $9D,$01,$00

CODE_0C83FB:
	CPY.W #$0088							;0C83FB	; Command < $88?
	BCC CODE_0C8410							;0C83FE	; Branch if low range
	db $C0,$99,$00,$B0,$0B,$BD,$00,$00,$6D,$00,$02,$9D,$00,$00,$80,$0E ; Effect processing

CODE_0C8410:
	CPY.W #$00A8							;0C8410	; Command < $A8?
	BCC CODE_0C841E							;0C8413	; Branch if not A8+
	db $BD,$00,$00,$ED,$00,$02,$9D,$00,$00 ; Additional effect

CODE_0C841E:
	TXY										;0C841E	; Transfer result to Y
	PLX										;0C841F	; Restore X
	RTS										;0C8420	; Return

; ==============================================================================
; CODE_0C8421 - Screen Scroll Effect
; ==============================================================================
; Animated scrolling effect for screen transitions.
; Scrolls window positions over 32 frames, then holds for 60 frames.
; ==============================================================================

CODE_0C8421:
	LDA.B #$20								;0C8421	; Loop counter = 32 frames

CODE_0C8423:
	PHA										;0C8423	; Save counter
	SEC										;0C8424	; Set carry for subtraction
	LDA.W $0CC1								;0C8425	; Load window position 1
	SBC.B #$04								;0C8428	; Scroll -4 pixels
	STA.W $0CC1								;0C842A	; Update position 1
	STA.W $0CC5								;0C842D	; Update position 2
	STA.W $0CC9								;0C8430	; Update position 3
	STA.W $0CCD								;0C8433	; Update position 4
	LDA.W $0CCC								;0C8436	; Load position 5
	SBC.B #$04								;0C8439	; Scroll -4 pixels
	STA.W $0CCC								;0C843B	; Update position 5
	LDA.W $0CC0								;0C843E	; Load position 6
	ADC.B #$03								;0C8441	; Scroll +3 pixels
	STA.W $0CC0								;0C8443	; Update position 6
	JSR.W CODE_0C85DB						;0C8446	; Wait one frame
	PLA										;0C8449	; Restore counter
	DEC A									;0C844A	; Decrement
	BNE CODE_0C8423							;0C844B	; Loop 32 times
	LDA.B #$3C								;0C844D	; Hold duration = 60 frames

CODE_0C844F:
	PHA										;0C844F	; Save counter
	JSR.W CODE_0C85DB						;0C8450	; Wait one frame
	PLA										;0C8453	; Restore counter
	DEC A									;0C8454	; Decrement
	BNE CODE_0C844F							;0C8455	; Loop 60 times
	STZ.W $0E0D								;0C8457	; Clear window state 1
	STZ.W $0E0E								;0C845A	; Clear window state 2
	JMP.W CODE_0C825A						;0C845D	; Continue script

; ==============================================================================
; CODE_0C8460 - Complex Palette Fade Sequence
; ==============================================================================
; Multi-stage palette fading effect using indirect function calls.
; Cycles through color transformations with precise timing.
; ==============================================================================

CODE_0C8460:
	PHX										;0C8460	; Save script pointer
	LDY.W #$8575							;0C8461	; Function pointer 1
	STY.W $0212								;0C8464	; Store function address
	LDX.W #$0000							;0C8467	; Clear X (parameter)
	LDY.W #$84CB							;0C846A	; Fade table address
	JSR.W CODE_0C849E						;0C846D	; Execute fade stage 1
	LDY.W #$84CB							;0C8470	; Fade table address
	JSR.W CODE_0C849E						;0C8473	; Execute fade stage 2
	LDY.W #$8520							;0C8476	; Different fade table
	JSR.W CODE_0C849E						;0C8479	; Execute fade stage 3
	LDY.W #$84CC							;0C847C	; Fade table address
	JSR.W CODE_0C849E						;0C847F	; Execute fade stage 4
	LDY.W #$84F6							;0C8482	; Fade table address
	JSR.W CODE_0C849E						;0C8485	; Execute fade stage 5
	STZ.W $0214								;0C8488	; Clear fade state
	LDY.W #$854A							;0C848B	; Function pointer 2
	STY.W $0212								;0C848E	; Update function address
	LDY.W #$84CB							;0C8491	; Final fade table
	JSR.W CODE_0C849E						;0C8494	; Execute final stage
	JSR.W CODE_0C85DB						;0C8497	; Wait one frame
	PLX										;0C849A	; Restore script pointer
	JMP.W CODE_0C825A						;0C849B	; Continue script

; ==============================================================================
; CODE_0C849E - Fade Stage Executor
; ==============================================================================
; Executes one stage of palette fade using function table.
; Input: Y = fade curve table address
; Uses indirect JSR through $0210 and $0212 function pointers.
; ==============================================================================

CODE_0C849E:
	STY.W $0210								;0C849E	; Store table address
	LDY.W #$85B3							;0C84A1	; Fade curve start

CODE_0C84A4:									; Loop through fade curve
	JSR.W ($0210,X)							;0C84A4	; Call effect function (indirect)
	SEC										;0C84A7	; Set carry
	LDA.W $0C81								;0C84A8	; Load base color value
	SBC.W $0000,Y							;0C84AB	; Subtract curve value
	JSR.W ($0212,X)							;0C84AE	; Call adjustment function (indirect)
	INY										;0C84B1	; Next curve entry
	CPY.W #$85DB							;0C84B2	; End of curve?
	BNE CODE_0C84A4							;0C84B5	; Loop if not done
	DEY										;0C84B7	; Back up one entry

CODE_0C84B8:									; Reverse fade loop
	DEY										;0C84B8	; Previous curve entry
	JSR.W ($0210,X)							;0C84B9	; Call effect function
	CLC										;0C84BC	; Clear carry
	LDA.W $0C81								;0C84BD	; Load base color
	ADC.W $0000,Y							;0C84C0	; Add curve value
	JSR.W ($0212,X)							;0C84C3	; Call adjustment function
	CPY.W #$85B2							;0C84C6	; Back at start?
	BNE CODE_0C84B8							;0C84C9	; Loop if not done
	RTS										;0C84CB	; Return

; [Fade function - adjusts window positions alternately]
	TYA										;0C84CC	; Transfer Y to A
	BIT.B #$01								;0C84CD	; Test bit 0 (odd/even)
	BEQ CODE_0C84F5							;0C84CF	; Skip if even frame
	DEC.W $0C88								;0C84D1	; Adjust position 1
	DEC.W $0CA4								;0C84D4	; Adjust position 2
	DEC.W $0CA8								;0C84D7	; Adjust position 3
	INC.W $0C90								;0C84DA	; Adjust position 4
	INC.W $0CB4								;0C84DD	; Adjust position 5
	INC.W $0CB8								;0C84E0	; Adjust position 6
	INC.W $0C84								;0C84E3	; Adjust position 7
	INC.W $0C9C								;0C84E6	; Adjust position 8
	INC.W $0CA0								;0C84E9	; Adjust position 9
	DEC.W $0C8C								;0C84EC	; Adjust position 10
	DEC.W $0CAC								;0C84EF	; Adjust position 11
	DEC.W $0CB0								;0C84F2	; Adjust position 12

CODE_0C84F5:
	RTS										;0C84F5	; Return

; [Fade function 2 - reverse direction adjustments]
	TYA										;0C84F6	; Transfer Y to A
	BIT.B #$01								;0C84F7	; Test bit 0
	BEQ CODE_0C851F							;0C84F9	; Skip if even
	INC.W $0C88								;0C84FB	; Adjust opposite direction
	INC.W $0CA4								;0C84FE	; Adjust position
	INC.W $0CA8								;0C8501	; Adjust position
	DEC.W $0C90								;0C8504	; Adjust position
	DEC.W $0CB4								;0C8507	; Adjust position
	DEC.W $0CB8								;0C850A	; Adjust position
	DEC.W $0C84								;0C850D	; Adjust position
	DEC.W $0C9C								;0C8510	; Adjust position
	DEC.W $0CA0								;0C8513	; Adjust position
	INC.W $0C8C								;0C8516	; Adjust position
	INC.W $0CAC								;0C8519	; Adjust position
	INC.W $0CB0								;0C851C	; Adjust position

CODE_0C851F:
	RTS										;0C851F	; Return

; [Fade function 3 - partial position adjustments]
	TYA										;0C8520	; Transfer Y
	BIT.B #$01								;0C8521	; Test bit 0
	BEQ CODE_0C8537							;0C8523	; Skip if even
	DEC.W $0C88								;0C8525	; Adjust subset of positions
	DEC.W $0CA4								;0C8528	; Adjust position
	DEC.W $0CA8								;0C852B	; Adjust position
	INC.W $0C90								;0C852E	; Adjust position
	INC.W $0CB4								;0C8531	; Adjust position
	INC.W $0CB8								;0C8534	; Adjust position

CODE_0C8537:
	DEC.W $0C84								;0C8537	; Adjust remaining positions
	DEC.W $0C9C								;0C853A	; Adjust position
	DEC.W $0CA0								;0C853D	; Adjust position
	INC.W $0C8C								;0C8540	; Adjust position
	INC.W $0CAC								;0C8543	; Adjust position
	INC.W $0CB0								;0C8546	; Adjust position
	RTS										;0C8549	; Return

; [Fade function 4 - complex bidirectional fade]
	LDA.W $0C81								;0C854A	; Load base value
	PHA										;0C854D	; Save to stack
	LDA.W $0214								;0C854E	; Load fade direction flag
	BCS CODE_0C8559							;0C8551	; Branch if carry set
	SEC										;0C8553	; Set carry
	SBC.W $0000,Y							;0C8554	; Subtract curve value
	BRA CODE_0C855D							;0C8557	; Continue

CODE_0C8559:
	CLC										;0C8559	; Clear carry
	ADC.W $0000,Y							;0C855A	; Add curve value

CODE_0C855D:
	STA.W $0214								;0C855D	; Store new fade value
	LSR A									;0C8560	; Divide by 2
	PHA										;0C8561	; Save to stack
	LDA.B $02,S								;0C8562	; Load original value
	SEC										;0C8564	; Set carry
	SBC.B $01,S								;0C8565	; Subtract half-fade value
	JSR.W CODE_0C8575						;0C8567	; Apply to screen
	PLA										;0C856A	; Clean up stack
	PLA										;0C856B	; Clean up stack
	PHY										;0C856C	; Save Y
	LDY.W #$0000							;0C856D	; Clear Y
	JSR.W CODE_0C8575						;0C8570	; Apply secondary effect
	PLY										;0C8573	; Restore Y
	RTS										;0C8574	; Return

; ==============================================================================
; CODE_0C8575 - Screen Color Value Updater
; ==============================================================================
; Updates multiple screen color/position registers with same value.
; Spreads value across 5 primary + 5 secondary position registers.
; Input: A = value to write
; ==============================================================================

CODE_0C8575:
	SEC										;0C8575	; Set carry
	STA.W $0C81								;0C8576	; Store to register 1
	STA.W $0C85								;0C8579	; Store to register 2
	STA.W $0C89								;0C857C	; Store to register 3
	STA.W $0C8D								;0C857F	; Store to register 4
	STA.W $0C91								;0C8582	; Store to register 5
	SBC.B #$10								;0C8585	; Subtract offset
	STA.W $0C95								;0C8587	; Store to secondary register 1
	STA.W $0C9D								;0C858A	; Store to secondary register 2
	STA.W $0CA5								;0C858D	; Store to secondary register 3
	STA.W $0CAD								;0C8590	; Store to secondary register 4
	STA.W $0CB5								;0C8593	; Store to secondary register 5
	ADC.B #$2F								;0C8596	; Add different offset
	STA.W $0C99								;0C8598	; Store to tertiary register 1
	STA.W $0CA1								;0C859B	; Store to tertiary register 2
	STA.W $0CA9								;0C859E	; Store to tertiary register 3
	STA.W $0CB1								;0C85A1	; Store to tertiary register 4
	STA.W $0CB9								;0C85A4	; Store to tertiary register 5
	TYA										;0C85A7	; Transfer Y to A
	BIT.B #$01								;0C85A8	; Test bit 0
	BEQ CODE_0C85B1							;0C85AA	; Skip if even
	PHY										;0C85AC	; Save Y
	JSR.W CODE_0C85DB						;0C85AD	; Wait one frame
	PLY										;0C85B0	; Restore Y

CODE_0C85B1:
	RTS										;0C85B1	; Return

; Fade curve data table (40 bytes)
	db $00,$04,$02,$01,$02,$01,$01,$01,$01,$00,$01,$01,$00,$01,$00,$01 ; Smooth fade curve
	db $01,$00,$01,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00 ; values (0-4 range)
	db $00,$00,$00,$01,$00,$00,$00,$00,$00 ; End of curve

; ==============================================================================
; CODE_0C85DB - Frame Wait & Sprite Animation Update
; ==============================================================================
; Primary VBLANK synchronization + sprite animation handler.
; Called hundreds of times per second - performance critical!
; Updates animated sprite tiles every 4 frames.
; ==============================================================================

CODE_0C85DB:
	PHK										;0C85DB	; Push data bank
	PLB										;0C85DC	; Set data bank = current bank
	PHX										;0C85DD	; Save X register
	LDA.W $0E97								;0C85DE	; Load animation timer
	AND.B #$04								;0C85E1	; Test bit 2 (every 4 frames)
	LSR A									;0C85E3	; Shift to bit 1
	ADC.B #$4C								;0C85E4	; Base tile number = $4C or $4E
	STA.W $0CC2								;0C85E6	; Update sprite tile 1
	STA.W $0CCA								;0C85E9	; Update sprite tile 2
	EOR.B #$02								;0C85EC	; Toggle between tiles ($4C↔$4E)
	STA.W $0CC6								;0C85EE	; Update sprite tile 3
	STA.W $0CCE								;0C85F1	; Update sprite tile 4
	REP #$30								;0C85F4	; 16-bit A/X/Y
	LDA.W #$0005							;0C85F6	; Loop counter = 5 sprites
	STA.W $020C								;0C85F9	; Store counter
	STZ.W $020E								;0C85FC	; Clear sprite index

CODE_0C85FF:									; Loop: Update each sprite
	LDA.W $020E								;0C85FF	; Load sprite index
	ASL A									;0C8602	; *2 (word offset)
	ADC.W #$0C80							;0C8603	; Add base address
	TAY										;0C8606	; Use as pointer
	LDX.W $020E								;0C8607	; Load sprite index
	LDA.W $0202,X							;0C860A	; Load animation frame
	INC A									;0C860D	; Next frame
	CMP.W #$000E							;0C860E	; Frame >= 14?
	BNE CODE_0C8616							;0C8611	; Branch if not
	LDA.W #$0000							;0C8613	; Wrap to frame 0

CODE_0C8616:
	STA.W $0202,X							;0C8616	; Store new frame number
	TAX										;0C8619	; Use frame as index
	SEP #$20								;0C861A	; 8-bit accumulator
	LDA.W DATA8_0C8659,X					;0C861C	; Load tile number from table
	STA.W $0002,Y							;0C861F	; Update sprite tile
	CMP.B #$44								;0C8622	; Tile = $44?
	PHP										;0C8624	; Save comparison result
	REP #$30								;0C8625	; 16-bit A/X/Y
	LDA.W $020E								;0C8627	; Load sprite index
	ASL A									;0C862A	; *2
	ASL A									;0C862B	; *4 (dword offset)
	ADC.W #$0C94							;0C862C	; Add base address
	TAY										;0C862F	; Use as pointer
	PLP										;0C8630	; Restore comparison
	BEQ CODE_0C863D							;0C8631	; Branch if tile was $44
	LDA.B #$48								;0C8633	; Tile pattern = $48
	STA.W $0002,Y							;0C8635	; Update pattern 1
	STA.W $0006,Y							;0C8638	; Update pattern 2
	BRA CODE_0C8647							;0C863B	; Continue

CODE_0C863D:
	LDA.B #$6C								;0C863D	; Tile pattern = $6C
	STA.W $0002,Y							;0C863F	; Update pattern 1
	LDA.B #$6E								;0C8642	; Tile pattern = $6E
	STA.W $0006,Y							;0C8644	; Update pattern 2

CODE_0C8647:
	REP #$30								;0C8647	; 16-bit A/X/Y
	INC.W $020E								;0C8649	; Next sprite
	INC.W $020E								;0C864C	; Increment by 2 (word addressing)
	DEC.W $020C								;0C864F	; Decrement counter
	BNE CODE_0C85FF							;0C8652	; Loop for all 5 sprites
	JSR.W CODE_0C8910						;0C8654	; Update PPU registers
	PLX										;0C8657	; Restore X
	RTS										;0C8658	; Return

; ==============================================================================
; Animation Frame Table (14 frames of sprite tile numbers)
; ==============================================================================

DATA8_0C8659:
	db $00,$04,$04,$00,$00,$08,$08,$08,$0C,$40,$40,$44,$44,$00,$00,$00 ; Sprite animation sequence

; [Additional sprite configuration data continues...]
	db $06,$00,$02,$00,$08,$00,$04,$00,$02,$08,$01,$68,$80,$01,$80,$01
	db $80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01
	db $80,$01,$80,$01,$09,$0A,$0B,$0C,$03,$02,$02,$02,$10,$40,$02,$02
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $02,$04,$01,$01,$05,$02,$02,$02,$02,$02,$02,$02,$02,$00

; ==============================================================================
; CODE_0C8767 - Sprite OAM Data Copy
; ==============================================================================
; Block copies sprite configuration to OAM buffer.
; 112 bytes ($70) transferred via MVN instruction.
; ==============================================================================

CODE_0C8767:
	REP #$30								;0C8767	; 16-bit A/X/Y
	LDX.W #$8779							;0C8769	; Source address
	LDY.W #$0C80							;0C876C	; Destination address (OAM buffer)
	LDA.W #$006F							;0C876F	; Transfer size = 112 bytes
	MVN $00,$0C								;0C8772	; Block move (Bank $0C → Bank $00)
	JSR.W CODE_0C8910						;0C8775	; Update PPU registers
	RTS										;0C8778	; Return

; OAM sprite configuration data (112 bytes)
	db $74,$CF,$00,$36,$74,$CF,$00,$38,$74,$CF,$00,$3A,$74,$CF,$00,$3C
	db $74,$CF,$00,$3E,$7C,$BF,$00,$36,$7C,$EF,$00,$36,$7C,$BF,$00,$38
	db $7C,$EF,$00,$38,$7C,$BF,$00,$3A,$7C,$EF,$00,$3A,$7C,$BF,$00,$3C
	db $7C,$EF,$00,$3C,$7C,$BF,$00,$3E,$7C,$EF,$00,$3E,$78,$8F,$4C,$06
	db $78,$8F,$4C,$08,$78,$8F,$4C,$0A,$78,$8F,$4C,$0C,$78,$8F,$4C,$0E
	db $40,$6F,$C0,$00,$50,$6F,$C2,$00,$60,$6F,$C4,$00,$70,$6F,$C6,$00
	db $80,$6F,$C8,$00,$90,$6F,$CA,$00,$A0,$6F,$CC,$00,$B0,$6F,$CE,$00

; ==============================================================================
; CODE_0C87E9 - Clear NMI Flag
; ==============================================================================
; Disables NMI interrupts by clearing flag.
; Called before major PPU updates.
; ==============================================================================

CODE_0C87E9:
	STZ.W $0111								;0C87E9	; Clear NMI enable flag
	RTS										;0C87EC	; Return

; ==============================================================================
; CODE_0C87ED - Mode 7 Tilemap Setup
; ==============================================================================
; Initializes Mode 7 tilemap with block fill.
; Fills 30 rows ($1E) × 128 columns with pattern $C0.
; ==============================================================================

CODE_0C87ED:
	REP #$30								;0C87ED	; 16-bit A/X/Y
	PEA.W $0C7F								;0C87EF	; Push bank $0C
	PLB										;0C87F2	; Pull to data bank register
	LDX.W #$4000							;0C87F3	; VRAM start address
	LDY.W #$001E							;0C87F6	; Row count = 30
	LDA.W #$00C0							;0C87F9	; Fill pattern = $C0
	JSL.L CODE_009994						;0C87FC	; Call tilemap fill routine
	PLB										;0C8800	; Restore data bank
	SEP #$20								;0C8801	; 8-bit accumulator
	STZ.W $4204								;0C8803	; Clear multiply/divide register
	LDX.W #$00CE							;0C8806	; Table offset = $CE
	LDY.W #$0082							;0C8809	; Y parameter = $82

CODE_0C880C:									; Loop: Setup calculation
	TYA										;0C880C	; Transfer Y to A
	ASL A									;0C880D	; *2
	STA.W $4205								;0C880E	; Store to multiply register
	LDA.B #$20								;0C8811	; Value = $20
	JSL.L CODE_009726						;0C8813	; Call calculation routine
	; [Additional Mode 7 setup continues...]

; ==============================================================================
; End of Bank $0C Cycle 2
; ==============================================================================
; Lines documented: 400 source lines (500-900)
; Address range: $0C8396-$0C8813 (partial)
; Systems: Screen effects, palette fades, sprite animation, Mode 7 tilemap
; ==============================================================================
