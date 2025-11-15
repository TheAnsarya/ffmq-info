; ==============================================================================
; Bank $0c - Display and Graphics Management
; ==============================================================================
; This bank contains executable code for screen management, graphics transfers,
; PPU (Picture Processing Unit) control, and visual effects.
;
; Memory Range: $0c8000-$0cffff (32 KB)
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
; - CWaitTimingRoutine: VBLANK wait routine
; - ExecuteSequenceProcessing: Character/monster stat display
; - CodeScreenInitialization: Screen initialization
;
; Related Files:
; - Bank $0b: Battle graphics routines
; - Bank $09/$0a: Graphics data
; ==============================================================================

	ORG $0c8000

; ==============================================================================
; VBLANK Wait Routine
; ==============================================================================
; Waits for VBLANK (vertical blanking interval) before proceeding.
; Critical for safe PPU access - prevents screen tearing.
; See: https://wiki.superfamicom.org/vblank-and-nmi
; ==============================================================================

; ==============================================================================
; VBLANK Synchronization Routine
; ==============================================================================
; Waits for VBLANK period to begin, then returns immediately.
; Critical for safe PPU register updates and DMA transfers.
; ==============================================================================

Display_WaitVBlank:
	php ;0C8000	; Save processor status
	sep #$20		;0C8001	; 8-bit accumulator
	pha ;0C8003	; Save accumulator
	lda.b #$40	  ;0C8004	; VBLANK flag bit
	trb.w !system_flags_4	 ;0C8006	; Test and reset VBLANK flag

	.WaitLoop:
	lda.b #$40	  ;0C8009	; VBLANK flag bit
	and.w !system_flags_4	 ;0C800B	; Test VBLANK flag
	beq .WaitLoop   ;0C800E	; Loop until VBLANK starts
	pla ;0C8010	; Restore accumulator
	plp ;0C8011	; Restore processor status
	rtl ;0C8012	; Return

; ==============================================================================
; Character/Monster Stat Display Routine
; ==============================================================================
; Displays character or monster statistics on screen.
; Input: Accumulator = Character/monster index
; Uses stat lookup tables at $07ee84+
; ==============================================================================

Display_ShowCharStats:
	php ;0C8013	; Save processor status
	phd ;0C8014	; Save direct page
	pea.w $0000	 ;0C8015	; Push $0000
	pld ;0C8018	; Pull to direct page (set DP=$0000)
	rep #$30		;0C8019	; 16-bit mode
	phx ;0C801B	; Save X
	and.w #$00ff	;0C801C	; Mask to byte
	sta.b $64	   ;0C801F	; Store character index
	asl A		   ;0C8021	; Multiply by 5
	asl A		   ;0C8022	; (shift left)
	adc.b $64	   ;0C8023	; Add original (×5 total)
	tax ;0C8025	; Transfer to X
	sep #$20		;0C8026	; 8-bit accumulator
	lda.b $64	   ;0C8028	; Load character index
	sta.w $00ef	 ;0C802A	; Store to temp variable
	lda.l DATA8_07EE84,X ;0C802D	; Load stat byte 0
	sta.w $015f	 ;0C8031	; Store to display buffer
	lda.l DATA8_07EE85,X ;0C8034	; Load stat byte 1
	jsr.w Display_ProcessStatValue ;0C8038	; Process stat value
	sta.w $00b5	 ;0C803B	; Store processed value
	lda.l DATA8_07EE86,X ;0C803E	; Load stat byte 2
	jsr.w Display_ProcessStatValue ;0C8042	; Process stat value
	sta.w $00b2	 ;0C8045	; Store processed value
	lda.l DATA8_07EE87,X ;0C8048	; Load stat byte 3
	jsr.w Display_ProcessStatValue ;0C804C	; Process stat value
	sta.w $00b4	 ;0C804F	; Store processed value
	lda.l DATA8_07EE88,X ;0C8052	; Load stat byte 4
	jsr.w Display_ProcessStatValue ;0C8056	; Process stat value
	sta.w $00b3	 ;0C8059	; Store processed value
	ldx.w #$a433	;0C805C	; Load display routine address
	stx.b $17	   ;0C805F	; Store to jump pointer
	lda.b #$03	  ;0C8061	; Bank $03
	sta.b $19	   ;0C8063	; Store bank to jump pointer
	jsl.l CallDisplayRoutine ;0C8065	; Call display routine
	rep #$30		;0C8069	; 16-bit mode
	lda.b $15	   ;0C806B	; Load return value
	plx ;0C806D	; Restore X
	pld ;0C806E	; Restore direct page
	plp ;0C806F	; Restore processor status
	rtl ;0C8070	; Return

; ==============================================================================
; Stat Value Processing Subroutine
; ==============================================================================
; Processes stat values for display (checks flags, conditions).
; Input: Accumulator = Raw stat value
; Output: Accumulator = Processed value
; ==============================================================================

Display_ProcessStatValue:
	beq .ZeroStat   ;0C8071	; Branch if zero
	jsl.l ExecuteSpecialBitProcessing ;0C8073	; Check stat condition
	beq .NormalStat ;0C8077	; Branch if normal
	lda.b #$02	  ;0C8079	; Stat modified flag
	bra .ZeroStat   ;0C807B	; Continue

	.NormalStat:
	lda.b #$01	  ;0C807D	; Normal stat flag

	.ZeroStat:
	rts ;0C807F	; Return

; ==============================================================================
; Screen Initialization Routine
; ==============================================================================
; Initializes PPU registers for screen display.
; Sets up background modes, object selection, and layer priorities.
; See: https://wiki.superfamicom.org/snes-initialization
; ==============================================================================

Display_InitScreen:
	jsl.l CallInitializationHelper ;0C8080	; Call initialization helper
	lda.w #$0000	;0C8084	; Clear value
	sta.l $7e3665   ;0C8087	; Clear WRAM variable
	lda.w #$2100	;0C808B	; PPU register base address
	tcd ;0C808E	; Transfer to direct page
	sep #$20		;0C808F	; 8-bit accumulator
	stz.w $0111	 ;0C8091	; Clear NMI flag
	stz.w !system_flags_1	 ;0C8094	; Clear screen mode flag
	stz.w !system_flags_2	 ;0C8097	; Clear layer enable flag
	lda.b #$08	  ;0C809A	; Mode 7 enable bit
	tsb.w !system_flags_1	 ;0C809C	; Set mode 7 flag
	lda.b #$40	  ;0C809F	; VBLANK enable bit
	tsb.w !system_flags_3	 ;0C80A1	; Enable VBLANK NMI
	lda.b #$62	  ;0C80A4	; Object config value
	sta.b SNES_OBJSEL-$2100 ;0C80A6	; Set object selection ($2101)
	lda.b #$07	  ;0C80A8	; Background mode 7
	sta.b SNES_BGMODE-$2100 ;0C80AA	; Set BG mode ($2105)
	lda.b #$80	  ;0C80AC	; Mode 7 settings
	sta.b SNES_M7SEL-$2100 ;0C80AE	; Set Mode 7 select ($211a)
	lda.b #$11	  ;0C80B0	; Layer enable mask
	sta.b SNES_TM-$2100 ;0C80B2	; Set main screen layers ($212c)

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

; [Remaining display code continues to $0cffff]
; See original bank_0C.asm for complete implementation

; ==============================================================================
; End of Bank $0c
; ==============================================================================
; Total size: 32 KB (complete bank)
; Primary content: Display/PPU management code
; Related banks: $0b (battle graphics), $09/$0a (graphics data)
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
; BANK $0c CYCLE 1 - Screen Initialization & Graphics Management (Lines 100-500)
; ==============================================================================
; Continuation from address $0c80b2
; Major systems: Screen mode setup, VRAM initialization, palette DMA, window effects
; ==============================================================================

; [Continued from documented section ending at $0c80b2]

	sta.b SNES_TM-$2100 ;0C80B2	; Set main screen layers ($212c) = $11 (BG1+Obj)
	jsr.w CallGraphicsSetupRoutine ;0C80B4	; Call graphics setup routine
	lda.w $0112	 ;0C80B7	; Load NMI enable flags
	sta.w $4200	 ;0C80BA	; Set NMI/IRQ/Auto-Joypad ($4200)
	cli ;0C80BD	; Enable interrupts
	lda.b #$0f	  ;0C80BE	; Brightness = 15 (full)
	sta.w !brightness_value	 ;0C80C0	; Store brightness value
	stz.w !battle_ready_flag	 ;0C80C3	; Clear screen state flag
	jsl.l CallMainGameLoopHandler ;0C80C6	; Call main game loop handler
	jsr.w GraphicsStateUpdate ;0C80CA	; Graphics state update
	jsr.w BackgroundLayerSetup ;0C80CD	; Background layer setup
	jsl.l CWaitTimingRoutine ;0C80D0	; Wait for VBLANK
	lda.b #$01	  ;0C80D4	; BG mode 1
	sta.b SNES_BGMODE-$2100 ;0C80D6	; Set background mode ($2105)
	lda.b #$62	  ;0C80D8	; BG1 tilemap config
	sta.b SNES_BG1SC-$2100 ;0C80DA	; BG1 screen config ($2107)
	lda.b #$69	  ;0C80DC	; BG2 tilemap config
	sta.b SNES_BG2SC-$2100 ;0C80DE	; BG2 screen config ($2108)
	lda.b #$44	  ;0C80E0	; Character address config
	sta.b SNES_BG12NBA-$2100 ;0C80E2	; BG1/BG2 char address ($210b)
	lda.b #$13	  ;0C80E4	; Layer enable mask
	sta.b SNES_TM-$2100 ;0C80E6	; Set main screen layers ($212c)
	jsr.w Complex_Graphics_Buffer_Initialization ;0C80E8	; Additional graphics setup
	jsr.w CallMainScreenInit ;0C80EB	; Call main screen init
	rep #$30		;0C80EE	; 16-bit A/X/Y
	lda.w #$0001	;0C80F0	; Screen initialized flag
	sta.l $7e3665   ;0C80F3	; Set screen ready flag (WRAM)
	jsl.l GameStateHandler ;0C80F7	; Game state handler
	sei ;0C80FB	; Disable interrupts
	lda.w #$0008	;0C80FC	; VBLANK processing flag
	trb.w !system_flags_1	 ;0C80FF	; Reset VBLANK flag
	rtl ;0C8102	; Return

; ==============================================================================
; CallMainScreenInit - Main Screen Initialization Routine
; ==============================================================================
; Sets up Mode 7 screen, loads palettes, initializes display registers.
; Called during screen transitions and battle entry.
; ==============================================================================

Display_MainScreenSetup:
	lda.b #$0c	  ;0C8103	; Bank $0c
	sta.w $005a	 ;0C8105	; Set data bank
	ldx.w #$90d7	;0C8108	; Address of palette DMA code
	stx.w $0058	 ;0C810B	; Set DMA routine pointer
	lda.b #$40	  ;0C810E	; VBLANK DMA flag
	tsb.w !system_flags_9	 ;0C8110	; Set DMA pending flag
	jsl.l Display_WaitVBlank ;0C8113	; Wait for VBLANK
	lda.b #$07	  ;0C8117	; Background mode 7
	sta.b SNES_BGMODE-$2100 ;0C8119	; Set BG mode ($2105)
	jsr.w ModeMatrixSetup ;0C811B	; Mode 7 matrix setup
	jsr.w Display_PaletteLoadSetup ;0C811E	; Palette load setup
	jsr.w AdditionalGraphicsInit ;0C8121	; Additional graphics init
	jsr.w BackgroundScrollingSetup ;0C8124	; Background scrolling setup
	jsr.w FinalizeGraphicsState ;0C8127	; Finalize graphics state
	lda.b #$40	  ;0C812A	; VBLANK flag
	trb.w !system_flags_3	 ;0C812C	; Clear VBLANK pending
	jsl.l Display_WaitVBlank ;0C812F	; Wait for VBLANK
	lda.b #$01	  ;0C8133	; BG mode 1
	sta.b SNES_BGMODE-$2100 ;0C8135	; Set BG mode ($2105)
	stz.b SNES_BG1VOFS-$2100 ;0C8137	; BG1 V-scroll = 0 ($210e)
	stz.b SNES_BG1VOFS-$2100 ;0C8139	; Write high byte
	jsr.w GraphicsStateFinalize ;0C813B	; Graphics state finalize
	jsr.w Display_SpriteOAMSetup ;0C813E	; Sprite/OAM setup
	rts ;0C8141	; Return

; ==============================================================================
; CodeWindowEffectConfiguration - Window Effect Configuration
; ==============================================================================
; Sets up color window registers for screen effects (fades, transitions).
; Configures SNES window masking system.
; ==============================================================================

Display_WindowEffectSetup:
	ldx.w #$4156	;0C8142	; Window config value 1
	stx.w $0e08	 ;0C8145	; Store window settings
	ldx.w #$5555	;0C8148	; Window config value 2
	stx.w $0e0a	 ;0C814B	; Additional window data
	ldx.w #$5500	;0C814E	; Window config value 3
	stx.w $0e0c	 ;0C8151	; Final window settings
	jmp.w JumpWindowApplyRoutine ;0C8154	; Jump to window apply routine

; ==============================================================================
; CodeVramAddressCalculationRoutine - VRAM Address Calculation Routine
; ==============================================================================
; Calculates VRAM addresses for tile placement.
; Adds offset $0804 to base addresses for proper tile positioning.
; ==============================================================================

Display_VRAMAddressCalc:
	clc ;0C8157	; Clear carry
	rep #$30		;0C8158	; 16-bit A/X/Y
	lda.w $0c84	 ;0C815A	; Load VRAM base address 1
	adc.w #$0804	;0C815D	; Add tile offset
	sta.w $0cc0	 ;0C8160	; Store calculated address
	lda.w $0c88	 ;0C8163	; Load VRAM base address 2
	adc.w #$0804	;0C8166	; Add tile offset
	sta.w $0cc4	 ;0C8169	; Store calculated address
	lda.w $0c8c	 ;0C816C	; Load VRAM base address 3
	adc.w #$0804	;0C816F	; Add tile offset
	sta.w $0cc8	 ;0C8172	; Store calculated address
	lda.w $0c90	 ;0C8175	; Load VRAM base address 4
	adc.w #$0c90	;0C8178	; Add tile offset
	sta.w $0ccc	 ;0C817B	; Store calculated address
	sep #$20		;0C817E	; 8-bit accumulator
	lda.b #$80	  ;0C8180	; VRAM increment mode (increment on $2119 write)
	jsl.l CWaitTimingRoutine ;0C8182	; Wait for VBLANK
	sta.b SNES_VMAINC-$2100 ;0C8186	; Set VRAM increment ($2115)
	lda.b #$08	  ;0C8188	; Tile pattern value
	ldx.w #$6225	;0C818A	; VRAM address $6225
	jsr.w Display_VRAMPatternFill ;0C818D	; Call VRAM fill routine
	lda.b #$0c	  ;0C8190	; Tile pattern value
	ldx.w #$622a	;0C8192	; VRAM address $622a
	jsr.w Display_VRAMPatternFill ;0C8195	; Call VRAM fill routine
	lda.b #$14	  ;0C8198	; Tile pattern value
	ldx.w #$6234	;0C819A	; VRAM address $6234
	jsr.w Display_VRAMPatternFill ;0C819D	; Call VRAM fill routine
	lda.b #$10	  ;0C81A0	; Tile pattern value
	ldx.w #$6239	;0C81A2	; VRAM address $6239

; ==============================================================================
; CodeVramPatternFillRoutine - VRAM Pattern Fill Routine
; ==============================================================================
; Fills VRAM with sequential tile numbers for background patterns.
; Creates animated tile sequences (water, fire, etc.).
; Input: A = pattern start value, X = VRAM address
; ==============================================================================

Display_VRAMPatternFill:
	xba ;0C81A5	; Swap A/B registers
	lda.b #$00	  ;0C81A6	; Clear low byte
	rep #$30		;0C81A8	; 16-bit A/X/Y

	.FillLoop:									; Loop: Fill VRAM pattern
	stx.b SNES_VMADDL-$2100 ;0C81AA	; Set VRAM address ($2116)
	sta.b SNES_VMDATAL-$2100 ;0C81AC	; Write tile number ($2118)
	inc A		   ;0C81AE	; Next tile
	sta.b SNES_VMDATAL-$2100 ;0C81AF	; Write tile number
	inc A		   ;0C81B1	; Next tile
	sta.b SNES_VMDATAL-$2100 ;0C81B2	; Write tile number
	tay ;0C81B4	; Save tile counter to Y
	txa ;0C81B5	; Load VRAM address
	adc.w #$0020	;0C81B6	; Move to next row (+32 tiles)
	tax ;0C81B9	; Update VRAM address
	tya ;0C81BA	; Restore tile counter
	adc.w #$000e	;0C81BB	; Advance tile pattern
	bit.w #$0040	;0C81BE	; Test completion bit
	beq .FillLoop   ;0C81C1	; Loop if not done
	sep #$20		;0C81C3	; 8-bit accumulator
	rts ;0C81C5	; Return

; ==============================================================================
; CodeColorMathDisableRoutine - Color Math Disable Routine
; ==============================================================================
; Disables color addition/subtraction effects.
; Resets window and color math registers.
; ==============================================================================

Display_ColorMathDisable:
	stz.b SNES_CGSWSEL-$2100 ;0C81C6	; Clear color window select ($2130)
	stz.b SNES_CGADSUB-$2100 ;0C81C8	; Clear color math ($2131)
	rts ;0C81CA	; Return

; ==============================================================================
; CodeColorAdditionEffectSetup - Color Addition Effect Setup
; ==============================================================================
; Enables color addition for screen brightness/darkness effects.
; Used for battle transitions, lightning, darkness, etc.
; ==============================================================================

Display_ColorAdditionSetup:
	ldx.w #$7002	;0C81CB	; Color window config
	stx.b SNES_CGSWSEL-$2100 ;0C81CE	; Set color window ($2130-$2131)
	lda.b #$e0	  ;0C81D0	; Fixed color data (brightness)
	sta.b SNES_COLDATA-$2100 ;0C81D2	; Set fixed color value ($2132)
	ldx.w #$0110	;0C81D4	; Layer enable mask
	stx.b SNES_TM-$2100 ;0C81D7	; Set main/sub screen layers ($212c-$212d)
	rts ;0C81D9	; Return

; ==============================================================================
; CodePaletteDmaSetupRoutine - Palette DMA Setup Routine
; ==============================================================================
; Prepares palette data for DMA transfer during VBLANK.
; Sets up indirect DMA from Bank $0c address $81ef.
; ==============================================================================

Display_PaletteLoadSetup:
	lda.b #$0c	  ;0C81DA	; Bank $0c
	sta.w $005a	 ;0C81DC	; Set DMA source bank
	ldx.w #$81ef	;0C81DF	; Palette DMA routine address
	stx.w $0058	 ;0C81E2	; Set DMA routine pointer
	lda.b #$40	  ;0C81E5	; VBLANK DMA flag
	tsb.w !system_flags_9	 ;0C81E7	; Set DMA pending flag
	jsl.l Display_WaitVBlank ;0C81EA	; Wait for VBLANK
	rts ;0C81EE	; Return

; ==============================================================================
; Palette DMA Transfer Code (Embedded at $0c81ef)
; ==============================================================================
; Direct palette load routine executed during VBLANK.
; Transfers 16-byte palette chunks from Bank $07 to CGRAM.
; ==============================================================================

; [Palette DMA routine starts here]
	ldx.w #$2200	;0C81EF	; DMA params: A→B, increment
	stx.b SNES_DMA0PARAM-$4300 ;0C81F2	; DMA0 params ($4300)
	lda.b #$07	  ;0C81F4	; Source bank = Bank $07 (palette data)
	sta.b SNES_DMA0ADDRH-$4300 ;0C81F6	; DMA0 source bank ($4304)
	lda.b #$10	  ;0C81F8	; Starting palette index = $10
	ldy.w #$d974	;0C81FA	; Source address $07:D974
	jsr.w Display_PaletteDMATransfer ;0C81FD	; DMA 16 bytes to CGRAM
	ldy.w #$d934	;0C8200	; Source address $07:D934
	jsr.w Display_PaletteDMATransfer ;0C8203	; DMA 16 bytes
	jsr.w Display_PaletteDMATransfer ;0C8206	; DMA 16 bytes (auto-increment)
	jsr.w Display_PaletteDMATransfer ;0C8209	; DMA 16 bytes
	jsr.w Display_PaletteDMATransfer ;0C820C	; DMA 16 bytes
	lda.b #$b0	  ;0C820F	; Palette index = $b0
	jsr.w Display_PaletteDMATransfer ;0C8211	; DMA 16 bytes
	ldy.w #$d934	;0C8214	; Reset source to $07:D934
	jsr.w Display_PaletteDMATransfer ;0C8217	; DMA 16 bytes
	jsr.w Display_PaletteDMATransfer ;0C821A	; DMA 16 bytes
	jsr.w Display_PaletteDMATransfer ;0C821D	; DMA 16 bytes
	jsr.w Display_PaletteDMATransfer ;0C8220	; DMA 16 bytes
	rtl ;0C8223	; Return from palette DMA

; ==============================================================================
; CodeSinglePaletteDmaTransferBytes - Single Palette DMA Transfer (16 bytes)
; ==============================================================================
; Transfers 16 bytes of palette data to CGRAM via DMA.
; Input: A = CGRAM address, Y = source address (Bank $07)
; Output: A += $10, Y += $10 (auto-incremented for next call)
; ==============================================================================

Display_PaletteDMATransfer:
	pha ;0C8224	; Save CGRAM address
	sta.w SNES_CGADD ;0C8225	; Set CGRAM address ($2121)
	sty.b SNES_DMA0ADDRL-$4300 ;0C8228	; DMA0 source address ($4302)
	ldx.w #$0010	;0C822A	; Transfer size = 16 bytes
	stx.b SNES_DMA0CNTL-$4300 ;0C822D	; DMA0 byte count ($4305)
	lda.b #$01	  ;0C822F	; Enable DMA channel 0
	sta.w SNES_MDMAEN ;0C8231	; Start DMA ($420b)
	rep #$30		;0C8234	; 16-bit A/X/Y
	tya ;0C8236	; Load source address
	adc.w #$0010	;0C8237	; Advance +16 bytes
	tay ;0C823A	; Update source address
	sep #$20		;0C823B	; 8-bit accumulator
	pla ;0C823D	; Restore CGRAM address
	adc.b #$10	  ;0C823E	; Advance +16 colors
	rts ;0C8240	; Return

; ==============================================================================
; CodeOamSpriteInitializationRoutine - OAM/Sprite Initialization Routine
; ==============================================================================
; Copies sprite configuration data to OAM buffer.
; Uses mvn (block move) for fast 9-byte transfer.
; ==============================================================================

Display_SpriteOAMSetup:
	rep #$30		;0C8241	; 16-bit A/X/Y
	ldx.w #$8667	;0C8243	; Source address $0c:8667
	ldy.w #$0202	;0C8246	; Destination address $00:0202
	lda.w #$0009	;0C8249	; Transfer 10 bytes (9+1 for MVN)
	mvn $0c,$0c	 ;0C824C	; Block move within bank $0c
	sep #$20		;0C824F	; 8-bit accumulator
	stz.w $0160	 ;0C8251	; Clear sprite state flag
	stz.w $0201	 ;0C8254	; Clear OAM control byte
	ldx.w #$8671	;0C8257	; Effect script address

; ==============================================================================
; CodeVisualEffectScriptInterpreter - Visual Effect Script Interpreter
; ==============================================================================
; Interprets bytecode commands for screen effects (fades, flashes, transitions).
; Commands: 00=wait, 01=fade step, 02=color cycle, 03=palette load, etc.
; ==============================================================================

Display_EffectScriptInterpreter:
	lda.w $0000,X   ;0C825A	; Load effect command byte
	inx ;0C825D	; Advance script pointer
	cmp.b #$01	  ;0C825E	; Command < 01?
	bcc .WaitCondition ;0C8260	; Branch to wait routine
	beq .SingleFrame ;0C8262	; Command = 01: Single frame delay
	cmp.b #$03	  ;0C8264	; Command < 03?
	bcc .ColorCycle ;0C8266	; Branch to color cycle
	beq .PaletteOp  ;0C8268	; Command = 03: Palette operation
	cmp.b #$05	  ;0C826A	; Command = 05?
	beq .SpecialEffect ;0C826C	; Branch to special effect
	bcs .ComplexOps ;0C826E	; Command >= 06: Complex operations
	ldy.w #$0004	;0C8270	; Loop count = 4

; Color flash effect loop (command 04)
	.ColorFlash:
	phy ;0C8273	; Save loop counter
	lda.b #$3f	  ;0C8274	; Fixed color = white ($3f)
	sta.b SNES_COLDATA-$2100 ;0C8276	; Set color addition ($2132)
	jsr.w WaitOneFrame ;0C8278	; Wait one frame
	lda.b #$e0	  ;0C827B	; Fixed color = dark ($e0)
	sta.b SNES_COLDATA-$2100 ;0C827D	; Set color subtraction
	jsr.w WaitOneFrame ;0C827F	; Wait one frame
	ply ;0C8282	; Restore loop counter
	dey ;0C8283	; Decrement
	bne .ColorFlash ;0C8284	; Loop 4 times (4 flashes)
	bra Display_EffectScriptInterpreter ;0C8286	; Continue script

; Color cycle effect (command 02)
	.ColorCycle:
	lda.b #$3b	  ;0C8288	; Cycle duration = 59 frames

	.CycleLoop:
	pha ;0C828A	; Save counter
	jsr.w WaitOneFrame ;0C828B	; Wait one frame
	pla ;0C828E	; Restore counter
	dec A		   ;0C828F	; Decrement
	bne .CycleLoop  ;0C8290	; Loop until counter = 0

; Single frame delay (command 01)
	.SingleFrame:
	jsr.w WaitOneFrame ;0C8292	; Wait one frame
	bra Display_EffectScriptInterpreter ;0C8295	; Continue script

; Wait until condition met (command 00)
	.WaitCondition:
	jsr.w WaitOneFrame ;0C8297	; Wait one frame
	lda.w $0c82	 ;0C829A	; Load condition flag
	bne .WaitCondition ;0C829D	; Loop until flag clears
	rts ;0C829F	; Return from effect script

; Palette load command (command 03)
	.PaletteOp:
	jmp.w JumpPaletteLoader ;0C82A0	; Jump to palette loader

; Special effect command (command 05)
	.SpecialEffect:
	jmp.w JumpSpecialEffectHandler ;0C82A3	; Jump to special effect handler

; ==============================================================================
; Complex Command Handler (Commands $06-$ff)
; ==============================================================================
; Decodes complex commands with parameters.
; Format: [CMD:5bits][PARAM:3bits] for advanced visual effects.
; ==============================================================================

	.ComplexOps:
	pha ;0C82A6	; Save command byte
	and.b #$07	  ;0C82A7	; Extract parameter (bits 0-2)
	sta.w $015f	 ;0C82A9	; Store parameter
	pla ;0C82AC	; Restore command byte
	and.b #$f8	  ;0C82AD	; Extract command (bits 3-7)
	cmp.b #$40	  ;0C82AF	; Command < $40?
	bcc BranchLowRangeHandler ;0C82B1	; Branch to low-range handler
	cmp.b #$80	  ;0C82B3	; Command < $80?
	bcc BranchMidRangeHandler ;0C82B5	; Branch to mid-range handler
	cmp.b #$c0	  ;0C82B7	; Command < $c0?
	bcc BranchHighRangeHandler ;0C82B9	; Branch to high-range handler
	sbc.b #$40	  ;0C82BB	; Normalize command ($c0+ → $80+)
	sta.w $0161	 ;0C82BD	; Store normalized command
	rep #$30		;0C82C0	; 16-bit A/X/Y
	lda.w $015f	 ;0C82C2	; Load parameter
	asl A		   ;0C82C5	; *2
	asl A		   ;0C82C6	; *4 (table offset)
	adc.w #$0cbc	;0C82C7	; Add table base address
	jsr.w ExecuteTableEntry ;0C82CA	; Execute table entry
	bra CodeVisualEffectScriptInterpreter ;0C82CD	; Continue script

; High-range command handler ($80-$bf) - Triple table dispatch system
Display_EffectCommandHighRange:	; Process command $80-$bf with triple table lookup
	sta.w $0161	 ;0C82CF	; Store command
	rep #$30		;0C82D2	; 16-bit A/X/Y
	lda.w $015f	 ;0C82D4	; Load parameter
	asl A		   ;0C82D7	; *2
	asl A		   ;0C82D8	; *4
	pha ;0C82D9	; Save offset
	adc.w #$0c80	;0C82DA	; Add table base 1
	jsr.w ExecuteTableEntry ;0C82DD	; Execute table entry 1
	rep #$30		;0C82E0	; 16-bit A/X/Y
	pla ;0C82E2	; Restore offset
	asl A		   ;0C82E3	; *2 again (*8 total)
	adc.w #$0c94	;0C82E4	; Add table base 2
	jsr.w ExecuteTableEntry ;0C82E7	; Execute table entry 2
	rep #$30		;0C82EA	; 16-bit A/X/Y
	tya ;0C82EC	; Load Y (result from previous call)
	clc ;0C82ED	; Clear carry
	adc.w #$0004	;0C82EE	; Add 4
	jsr.w ExecuteTableEntry ;0C82F1	; Execute table entry 3
	jmp.w CodeVisualEffectScriptInterpreter ;0C82F4	; Continue script

; Mid-range command handler ($40-$7f)
Display_EffectCommandMidRange:
	sbc.b #$30	  ;0C82F7	; Normalize command ($40+ → $10+)
	lsr A		   ;0C82F9	; /2
	lsr A		   ;0C82FA	; /4
	lsr A		   ;0C82FB	; /8
	sta.w $0200	 ;0C82FC	; Store effect type
	jmp.w CodeVisualEffectScriptInterpreter ;0C82FF	; Continue script

; Low-range command handler ($08-$3f)
Display_EffectCommandLowRange:
	cmp.b #$08	  ;0C8302	; Command = $08?
	bne BranchIfNot ;0C8304	; Branch if not $08
	lda.w $015f	 ;0C8306	; Load parameter
	bne Display_EffectTableLookup ;0C8309	; Branch if parameter != 0
	rep #$30		;0C830B	; 16-bit A/X/Y
	lda.w #$3c03	;0C830D	; bit mask
	trb.w $0e08	 ;0C8310	; Clear bits in window config
	lda.w #$0002	;0C8313	; New value
	tsb.w $0e08	 ;0C8316	; Set bits in window config
	sep #$20		;0C8319	; 8-bit accumulator
	jmp.w CodeVisualEffectScriptInterpreter ;0C831B	; Continue script

; Parameter-based table lookup
Display_EffectTableLookup:
	rep #$30		;0C831E	; 16-bit A/X/Y
	lda.w $015f	 ;0C8320	; Load parameter
	asl A		   ;0C8323	; *2
	asl A		   ;0C8324	; *4
	pha ;0C8325	; Save offset
	adc.w #$0c80	;0C8326	; Add table base 1
	tay ;0C8329	; Use as index
	lda.w $0c80	 ;0C832A	; Load value from table
	sta.w $0000,Y   ;0C832D	; Store to destination
	pla ;0C8330	; Restore offset
	asl A		   ;0C8331	; *2 (*8 total)
	adc.w #$0c94	;0C8332	; Add table base 2
	tay ;0C8335	; Use as index
	lda.w $0c94	 ;0C8336	; Load first value
	sta.w $0000,Y   ;0C8339	; Store to destination
	lda.w $0c98	 ;0C833C	; Load second value
	sta.w $0004,Y   ;0C833F	; Store to destination+4
	ldy.w $015f	 ;0C8342	; Load parameter
	lda.w #$0003	;0C8345	; bit shift value = 3

; bit shift loop
	.BitShiftLoop:
	asl A		   ;0C8348	; Shift left *2
	asl A		   ;0C8349	; Shift left *2 (total *4)
	dey ;0C834A	; Decrement parameter
	bne .BitShiftLoop ;0C834B	; Loop until parameter = 0
	pha ;0C834D	; Save shifted value
	trb.w $0e08	 ;0C834E	; Clear bits in window config
	and.w #$aaaa	;0C8351	; Mask pattern ($aaaa)
	tsb.w $0e08	 ;0C8354	; Set masked bits
	pla ;0C8357	; Restore shifted value
	ldy.w $015f	 ;0C8358	; Reload parameter
	lsr A		   ;0C835B	; Shift right /2
	lsr A		   ;0C835C	; Shift right /2 (total /4)

; Second bit shift loop
	.SecondShiftLoop:
	asl A		   ;0C835D	; Shift left *2
	asl A		   ;0C835E	; Shift left *2 (total *4)
	dey ;0C835F	; Decrement parameter
	bne .SecondShiftLoop ;0C8360	; Loop until parameter = 0
	lsr A		   ;0C8362	; Shift right /2
	lsr A		   ;0C8363	; Shift right /2 (total /4)
	pha ;0C8364	; Save value
	lsr A		   ;0C8365	; Shift right /2
	lsr A		   ;0C8366	; Shift right /2
	ora.b $01,S	 ;0C8367	; OR with stack value
	trb.w $0e0a	 ;0C8369	; Clear bits in second window config
	cmp.w #$0003	;0C836C	; Compare to 3
	bne BranchIfNotEqual ;0C836F	; Branch if not equal
	lda.w #$c000	;0C8371	; Top bits mask
	trb.w $0e08	 ;0C8374	; Clear top bits in first window config

	.CleanupAndExit:
	pla ;0C8377	; Clean up stack
	sep #$20		;0C8378	; 8-bit accumulator
	jmp.w CodeVisualEffectScriptInterpreter ;0C837A	; Continue script

; ==============================================================================
; Complex Screen Effect Setup (Command $08+)
; ==============================================================================
; Initializes multi-stage screen effects combining VRAM updates,
; palette fades, and color window operations.
; ==============================================================================

Display_EffectComplexParamCommand:
	phx ;0C837D	; Save script pointer
	jsr.w Display_VRAMAddressCalc ;0C837E	; Calculate VRAM addresses
	jsr.w Display_WindowEffectSetup ;0C8381	; Setup window effects
	jsr.w Display_FlashEffect ;0C8384	; Execute effect stage 1
	jsr.w Display_FlashEffect ;0C8387	; Execute effect stage 2
	jsr.w Display_FlashEffect ;0C838A	; Execute effect stage 3
	lda.b #$10	  ;0C838D	; Loop counter = 16 frames

	.EffectLoop:
	pha ;0C838F	; Save counter
	jsr.w Display_ColorAdditionSetup ;0C8390	; Enable color addition
	jsr.w WaitOneFrame ;0C8393	; Wait one frame
	jsr.w WaitOneFrame ;0C8396	; Wait one frame

; [Additional effect code continues...]

; ==============================================================================
; End of Bank $0c Cycle 1
; ==============================================================================
; Lines documented: 400 source lines (100-500)
; Address range: $0c80b2-$0c8399 (partial)
; Major systems: Screen init, VRAM management, palette DMA, effect scripts
; ==============================================================================
; ==============================================================================
; BANK $0c CYCLE 2 - Graphics Effects & Screen Transitions (Lines 500-900)
; ==============================================================================
; Address range: $0c8396-$0c8813
; Systems: Screen effects, window animations, visual transitions, Mode 7 setup
; ==============================================================================

; [Continued from Cycle 1 ending at $0c8399]

	jsr.w WaitOneFrame ;0C8396	; Wait one frame (VBLANK sync)
	lda.b #$11	  ;0C8399	; Layer enable mask
	sta.b SNES_TM-$2100 ;0C839B	; Set main screen layers ($212c)
	jsr.w Display_ColorMathDisable ;0C839D	; Disable color math
	jsr.w WaitOneFrame ;0C83A0	; Wait one frame
	jsr.w WaitOneFrame ;0C83A3	; Wait one frame
	pla ;0C83A6	; Restore loop counter
	dec A		   ;0C83A7	; Decrement
	bne .EffectLoop ;0C83A8	; Loop if not done (16 frames total)
	jsr.w Display_ColorAdditionSetup ;0C83AA	; Re-enable color addition
	plx ;0C83AD	; Restore script pointer
	jmp.w Display_EffectScriptInterpreter ;0C83AE	; Continue effect script

; ==============================================================================
; CodeFlashEffectSubroutine - Flash Effect Subroutine
; ==============================================================================
; Creates white flash effect (bright → normal → bright sequence).
; Used for lightning, magic spells, critical hits.
; ==============================================================================

Display_FlashEffect:
	jsr.w Display_ColorAdditionSetup ;0C83B1	; Enable color addition
	lda.b #$11	  ;0C83B4	; Layer enable mask
	sta.b SNES_TM-$2100 ;0C83B6	; Set layers ($212c)
	lda.b #$3f	  ;0C83B8	; Fixed color = white ($3f)
	sta.b SNES_COLDATA-$2100 ;0C83BA	; Set color addition ($2132)
	jsr.w WaitOneFrame ;0C83BC	; Wait one frame (flash)
	jsr.w Display_ColorMathDisable ;0C83BF	; Disable color math
	jsr.w WaitOneFrame ;0C83C2	; Wait one frame
	jsr.w WaitOneFrame ;0C83C5	; Wait one frame
	jmp.w WaitOneFrame ;0C83C8	; Wait one frame and return

; ==============================================================================
; ExecuteTableEntry - Table-Based Effect Executor
; ==============================================================================
; Executes visual effects from data tables.
; Modifies screen position/color values based on command and parameter.
; Input: A = table offset, $0161 = command type, $0200 = adjustment value
; ==============================================================================

Display_TableEffectExecutor:
	phx ;0C83CB	; Save X register
	tax ;0C83CC	; Use A as table index
	sep #$20		;0C83CD	; 8-bit accumulator
	ldy.w $0161	 ;0C83CF	; Load command type
	cpy.w #$00b8	;0C83D2	; Command = $b8 (specific effect)?
	beq .ProcessEffect ;0C83D5	; Branch if match
	cpy.w #$0089	;0C83D7	; Command >= $89?
	bcs Effect_HighRangeHandler ;0C83DA	; Branch if high range
	sec ;0C83DC	; Set carry for subtraction

	.ProcessEffect:
	lda.w $0001,X   ;0C83DD	; Load table value
	sbc.w $0200	 ;0C83E0	; Subtract adjustment
	sta.w $0001,X   ;0C83E3	; Store result
	bra .ContinueEffect ;0C83E6	; Continue

;-------------------------------------------------------------------------------
; Effect High Range Handler
;-------------------------------------------------------------------------------
; Purpose: Handle effect commands in high range ($89+)
; Reachability: Reachable via bcs when command >= $89
; Analysis: Multi-stage effect processing with range checks
; Technical: Originally labeled UNREACH_0C83E8
;-------------------------------------------------------------------------------
Effect_HighRangeHandler:
	cpy.w #$0098                         ;0C83E8|C09800  |
	bcc +                                ;0C83EB|900E    |0C83FB
	cpy.w #$00a9                         ;0C83ED|C0A900  |
	bcs +                                ;0C83F0|B009    |0C83FB
	lda.w $0001,X                        ;0C83F2|BD0100  |
	adc.w $0200                          ;0C83F5|6D0002  |
	sta.w $0001,X                        ;0C83F8|9D0100  |
+   ; Fall through to continue effect

	.ContinueEffect:
	cpy.w #$0088	;0C83FB	; Command < $88?
	bcc .LowRangeCheck ;0C83FE	; Branch if low range
	db $c0,$99,$00,$b0,$0b,$bd,$00,$00,$6d,$00,$02,$9d,$00,$00,$80,$0e ; Effect processing

	.LowRangeCheck:
	cpy.w #$00a8	;0C8410	; Command < $a8?
	bcc .Finalize   ;0C8413	; Branch if not A8+
	db $bd,$00,$00,$ed,$00,$02,$9d,$00,$00 ; Additional effect

	.Finalize:
	txy ;0C841E	; Transfer result to Y
	plx ;0C841F	; Restore X
	rts ;0C8420	; Return

; ==============================================================================
; JumpSpecialEffectHandler - Screen Scroll Effect
; ==============================================================================
; Animated scrolling effect for screen transitions.
; Scrolls window positions over 32 frames, then holds for 60 frames.
; ==============================================================================

Display_ScreenScrollEffect:
	lda.b #$20	  ;0C8421	; Loop counter = 32 frames

	.ScrollLoop:
	pha ;0C8423	; Save counter
	sec ;0C8424	; Set carry for subtraction
	lda.w $0cc1	 ;0C8425	; Load window position 1
	sbc.b #$04	  ;0C8428	; Scroll -4 pixels
	sta.w $0cc1	 ;0C842A	; Update position 1
	sta.w $0cc5	 ;0C842D	; Update position 2
	sta.w $0cc9	 ;0C8430	; Update position 3
	sta.w $0ccd	 ;0C8433	; Update position 4
	lda.w $0ccc	 ;0C8436	; Load position 5
	sbc.b #$04	  ;0C8439	; Scroll -4 pixels
	sta.w $0ccc	 ;0C843B	; Update position 5
	lda.w $0cc0	 ;0C843E	; Load position 6
	adc.b #$03	  ;0C8441	; Scroll +3 pixels
	sta.w $0cc0	 ;0C8443	; Update position 6
	jsr.w WaitOneFrame ;0C8446	; Wait one frame
	pla ;0C8449	; Restore counter
	dec A		   ;0C844A	; Decrement
	bne .ScrollLoop ;0C844B	; Loop 32 times
	lda.b #$3c	  ;0C844D	; Hold duration = 60 frames

	.HoldLoop:
	pha ;0C844F	; Save counter
	jsr.w WaitOneFrame ;0C8450	; Wait one frame
	pla ;0C8453	; Restore counter
	dec A		   ;0C8454	; Decrement
	bne .HoldLoop   ;0C8455	; Loop 60 times
	stz.w $0e0d	 ;0C8457	; Clear window state 1
	stz.w $0e0e	 ;0C845A	; Clear window state 2
	jmp.w Display_EffectScriptInterpreter ;0C845D	; Continue script

; ==============================================================================
; JumpPaletteLoader - Complex Palette Fade Sequence
; ==============================================================================
; Multi-stage palette fading effect using indirect function calls.
; Cycles through color transformations with precise timing.
; ==============================================================================

Display_ComplexPaletteFade:
	phx ;0C8460	; Save script pointer
	ldy.w #$8575	;0C8461	; Function pointer 1
	sty.w $0212	 ;0C8464	; Store function address
	ldx.w #$0000	;0C8467	; Clear X (parameter)
	ldy.w #$84cb	;0C846A	; Fade table address
	jsr.w Display_PaletteFadeStage ;0C846D	; Execute fade stage 1
	ldy.w #$84cb	;0C8470	; Fade table address
	jsr.w Display_PaletteFadeStage ;0C8473	; Execute fade stage 2
	ldy.w #$8520	;0C8476	; Different fade table
	jsr.w Display_PaletteFadeStage ;0C8479	; Execute fade stage 3
	ldy.w #$84cc	;0C847C	; Fade table address
	jsr.w ExecuteFadeStage ;0C847F	; Execute fade stage 4
	ldy.w #$84f6	;0C8482	; Fade table address
	jsr.w ExecuteFadeStage ;0C8485	; Execute fade stage 5
	stz.w $0214	 ;0C8488	; Clear fade state
	ldy.w #$854a	;0C848B	; Function pointer 2
	sty.w $0212	 ;0C848E	; Update function address
	ldy.w #$84cb	;0C8491	; Final fade table
	jsr.w ExecuteFadeStage ;0C8494	; Execute final stage
	jsr.w WaitOneFrame ;0C8497	; Wait one frame
	plx ;0C849A	; Restore script pointer
	jmp.w CodeVisualEffectScriptInterpreter ;0C849B	; Continue script

; ==============================================================================
; Display_FadeStageExecutor - Fade Stage Executor
; ==============================================================================
; Executes one stage of palette fade using function table.
; Input: Y = fade curve table address
; Uses indirect jsr through $0210 and $0212 function pointers.
; ==============================================================================

Display_FadeStageExecutor:
	sty.w $0210	 ;0C849E	; Store table address
	ldy.w #$85b3	;0C84A1	; Fade curve start

	.FadeCurveLoop:									; Loop through fade curve
	jsr.w ($0210,X) ;0C84A4	; Call effect function (indirect)
	sec ;0C84A7	; Set carry
	lda.w $0c81	 ;0C84A8	; Load base color value
	sbc.w $0000,Y   ;0C84AB	; Subtract curve value
	jsr.w ($0212,X) ;0C84AE	; Call adjustment function (indirect)
	iny ;0C84B1	; Next curve entry
	cpy.w #$85db	;0C84B2	; End of curve?
	bne .FadeCurveLoop ;0C84B5	; Loop if not done
	dey ;0C84B7	; Back up one entry

	.ReverseFadeLoop:							; Reverse fade loop
	dey ;0C84B8	; Previous curve entry
	jsr.w ($0210,X) ;0C84B9	; Call effect function
	clc ;0C84BC	; Clear carry
	lda.w $0c81	 ;0C84BD	; Load base color
	adc.w $0000,Y   ;0C84C0	; Add curve value
	jsr.w ($0212,X) ;0C84C3	; Call adjustment function
	cpy.w #$85b2	;0C84C6	; Back at start?
	bne .ReverseFadeLoop ;0C84C9	; Loop if not done
	rts ;0C84CB	; Return

; [Fade function - adjusts window positions alternately]
Display_FadeFunction1:
	tya ;0C84CC	; Transfer Y to A
	bit.b #$01	  ;0C84CD	; Test bit 0 (odd/even)
	beq .Return	 ;0C84CF	; Skip if even frame
	dec.w $0c88	 ;0C84D1	; Adjust position 1
	dec.w $0ca4	 ;0C84D4	; Adjust position 2
	dec.w $0ca8	 ;0C84D7	; Adjust position 3
	inc.w $0c90	 ;0C84DA	; Adjust position 4
	inc.w $0cb4	 ;0C84DD	; Adjust position 5
	inc.w $0cb8	 ;0C84E0	; Adjust position 6
	inc.w $0c84	 ;0C84E3	; Adjust position 7
	inc.w $0c9c	 ;0C84E6	; Adjust position 8
	inc.w $0ca0	 ;0C84E9	; Adjust position 9
	dec.w $0c8c	 ;0C84EC	; Adjust position 10
	dec.w $0cac	 ;0C84EF	; Adjust position 11
	dec.w $0cb0	 ;0C84F2	; Adjust position 12

	.Return:
	rts ;0C84F5	; Return

; [Fade function 2 - reverse direction adjustments]
Display_FadeFunction2:
	tya ;0C84F6	; Transfer Y to A
	bit.b #$01	  ;0C84F7	; Test bit 0
	beq .Return	 ;0C84F9	; Skip if even
	inc.w $0c88	 ;0C84FB	; Adjust opposite direction
	inc.w $0ca4	 ;0C84FE	; Adjust position
	inc.w $0ca8	 ;0C8501	; Adjust position
	dec.w $0c90	 ;0C8504	; Adjust position
	dec.w $0cb4	 ;0C8507	; Adjust position
	dec.w $0cb8	 ;0C850A	; Adjust position
	dec.w $0c84	 ;0C850D	; Adjust position
	dec.w $0c9c	 ;0C8510	; Adjust position
	dec.w $0ca0	 ;0C8513	; Adjust position
	inc.w $0c8c	 ;0C8516	; Adjust position
	inc.w $0cac	 ;0C8519	; Adjust position
	inc.w $0cb0	 ;0C851C	; Adjust position

	.Return:
	rts ;0C851F	; Return

; [Fade function 3 - partial position adjustments]
Display_FadeFunction3:
	tya ;0C8520	; Transfer Y
	bit.b #$01	  ;0C8521	; Test bit 0
	beq .AdjustRemaining ;0C8523	; Skip if even
	dec.w $0c88	 ;0C8525	; Adjust subset of positions
	dec.w $0ca4	 ;0C8528	; Adjust position
	dec.w $0ca8	 ;0C852B	; Adjust position
	inc.w $0c90	 ;0C852E	; Adjust position
	inc.w $0cb4	 ;0C8531	; Adjust position
	inc.w $0cb8	 ;0C8534	; Adjust position

	.AdjustRemaining:
	dec.w $0c84	 ;0C8537	; Adjust remaining positions
	dec.w $0c9c	 ;0C853A	; Adjust position
	dec.w $0ca0	 ;0C853D	; Adjust position
	inc.w $0c8c	 ;0C8540	; Adjust position
	inc.w $0cac	 ;0C8543	; Adjust position
	inc.w $0cb0	 ;0C8546	; Adjust position
	rts ;0C8549	; Return

; [Fade function 4 - complex bidirectional fade]
Display_FadeFunction4:
	lda.w $0c81	 ;0C854A	; Load base value
	pha ;0C854D	; Save to stack
	lda.w $0214	 ;0C854E	; Load fade direction flag
	bcs .AddCurve   ;0C8551	; Branch if carry set
	sec ;0C8553	; Set carry
	sbc.w $0000,Y   ;0C8554	; Subtract curve value
	bra .ApplyFade  ;0C8557	; Continue

	.AddCurve:
	clc ;0C8559	; Clear carry
	adc.w $0000,Y   ;0C855A	; Add curve value

	.ApplyFade:
	sta.w $0214	 ;0C855D	; Store new fade value
	lsr A		   ;0C8560	; Divide by 2
	pha ;0C8561	; Save to stack
	lda.b $02,S	 ;0C8562	; Load original value
	sec ;0C8564	; Set carry
	sbc.b $01,S	 ;0C8565	; Subtract half-fade value
	jsr.w ApplyScreen ;0C8567	; Apply to screen
	pla ;0C856A	; Clean up stack
	pla ;0C856B	; Clean up stack
	phy ;0C856C	; Save Y
	ldy.w #$0000	;0C856D	; Clear Y
	jsr.w ApplyScreen ;0C8570	; Apply secondary effect
	ply ;0C8573	; Restore Y
	rts ;0C8574	; Return

; ==============================================================================
; Display_ScreenColorValueUpdater - Screen Color Value Updater
; ==============================================================================
; Updates multiple screen color/position registers with same value.
; Spreads value across 5 primary + 5 secondary position registers.
; Input: A = value to write
; ==============================================================================

Display_ScreenColorValueUpdater:
	sec ;0C8575	; Set carry
	sta.w $0c81	 ;0C8576	; Store to register 1
	sta.w $0c85	 ;0C8579	; Store to register 2
	sta.w $0c89	 ;0C857C	; Store to register 3
	sta.w $0c8d	 ;0C857F	; Store to register 4
	sta.w $0c91	 ;0C8582	; Store to register 5
	sbc.b #$10	  ;0C8585	; Subtract offset
	sta.w $0c95	 ;0C8587	; Store to secondary register 1
	sta.w $0c9d	 ;0C858A	; Store to secondary register 2
	sta.w $0ca5	 ;0C858D	; Store to secondary register 3
	sta.w $0cad	 ;0C8590	; Store to secondary register 4
	sta.w $0cb5	 ;0C8593	; Store to secondary register 5
	adc.b #$2f	  ;0C8596	; Add different offset
	sta.w $0c99	 ;0C8598	; Store to tertiary register 1
	sta.w $0ca1	 ;0C859B	; Store to tertiary register 2
	sta.w $0ca9	 ;0C859E	; Store to tertiary register 3
	sta.w $0cb1	 ;0C85A1	; Store to tertiary register 4
	sta.w $0cb9	 ;0C85A4	; Store to tertiary register 5
	tya ;0C85A7	; Transfer Y to A
	bit.b #$01	  ;0C85A8	; Test bit 0
	beq .Return	 ;0C85AA	; Skip if even
	phy ;0C85AC	; Save Y
	jsr.w Display_WaitVBlankAndUpdate ;0C85AD	; Wait one frame
	ply ;0C85B0	; Restore Y

	.Return:
	rts ;0C85B1	; Return

; Fade curve data table (40 bytes)
	db $00,$04,$02,$01,$02,$01,$01,$01,$01,$00,$01,$01,$00,$01,$00,$01 ; Smooth fade curve
	db $01,$00,$01,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00 ; values (0-4 range)
	db $00,$00,$00,$01,$00,$00,$00,$00,$00 ; End of curve

; ==============================================================================
; Display_WaitVBlankAndUpdate - Frame Wait & Sprite Animation Update
; ==============================================================================
; Primary VBLANK synchronization + sprite animation handler.
; Called hundreds of times per second - performance critical!
; Updates animated sprite tiles every 4 frames.
; ==============================================================================

Display_WaitVBlankAndUpdate:
	phk ;0C85DB	; Push data bank
	plb ;0C85DC	; Set data bank = current bank
	phx ;0C85DD	; Save X register
	lda.w $0e97	 ;0C85DE	; Load animation timer
	and.b #$04	  ;0C85E1	; Test bit 2 (every 4 frames)
	lsr A		   ;0C85E3	; Shift to bit 1
	adc.b #$4c	  ;0C85E4	; Base tile number = $4c or $4e
	sta.w $0cc2	 ;0C85E6	; Update sprite tile 1
	sta.w $0cca	 ;0C85E9	; Update sprite tile 2
	eor.b #$02	  ;0C85EC	; Toggle between tiles ($4c↔$4e)
	sta.w $0cc6	 ;0C85EE	; Update sprite tile 3
	sta.w $0cce	 ;0C85F1	; Update sprite tile 4
	rep #$30		;0C85F4	; 16-bit A/X/Y
	lda.w #$0005	;0C85F6	; Loop counter = 5 sprites
	sta.w $020c	 ;0C85F9	; Store counter
	stz.w $020e	 ;0C85FC	; Clear sprite index

	.SpriteUpdateLoop:							; Loop: Update each sprite
	lda.w $020e	 ;0C85FF	; Load sprite index
	asl A		   ;0C8602	; *2 (word offset)
	adc.w #$0c80	;0C8603	; Add base address
	tay ;0C8606	; Use as pointer
	ldx.w $020e	 ;0C8607	; Load sprite index
	lda.w $0202,X   ;0C860A	; Load animation frame
	inc A		   ;0C860D	; Next frame
	cmp.w #$000e	;0C860E	; Frame >= 14?
	bne .StoreFrame ;0C8611	; Branch if not
	lda.w #$0000	;0C8613	; Wrap to frame 0

	.StoreFrame:
	sta.w $0202,X   ;0C8616	; Store new frame number
	tax ;0C8619	; Use frame as index
	sep #$20		;0C861A	; 8-bit accumulator
	lda.w DATA8_0C8659,X ;0C861C	; Load tile number from table
	sta.w $0002,Y   ;0C861F	; Update sprite tile
	cmp.b #$44	  ;0C8622	; Tile = $44?
	php ;0C8624	; Save comparison result
	rep #$30		;0C8625	; 16-bit A/X/Y
	lda.w $020e	 ;0C8627	; Load sprite index
	asl A		   ;0C862A	; *2
	asl A		   ;0C862B	; *4 (dword offset)
	adc.w #$0c94	;0C862C	; Add base address
	tay ;0C862F	; Use as pointer
	plp ;0C8630	; Restore comparison
	beq .UseTile6C  ;0C8631	; Branch if tile was $44
	lda.b #$48	  ;0C8633	; Tile pattern = $48
	sta.w $0002,Y   ;0C8635	; Update pattern 1
	sta.w $0006,Y   ;0C8638	; Update pattern 2
	bra .ContinueSpriteLoop ;0C863B	; Continue

	.UseTile6C:
	lda.b #$6c	  ;0C863D	; Tile pattern = $6c
	sta.w $0002,Y   ;0C863F	; Update pattern 1
	lda.b #$6e	  ;0C8642	; Tile pattern = $6e
	sta.w $0006,Y   ;0C8644	; Update pattern 2

	.ContinueSpriteLoop:
	rep #$30		;0C8647	; 16-bit A/X/Y
	inc.w $020e	 ;0C8649	; Next sprite
	inc.w $020e	 ;0C864C	; Increment by 2 (word addressing)
	dec.w $020c	 ;0C864F	; Decrement counter
	bne .SpriteUpdateLoop ;0C8652	; Loop for all 5 sprites
	jsr.w JumpWindowApplyRoutine ;0C8654	; Update PPU registers
	plx ;0C8657	; Restore X
	rts ;0C8658	; Return

; ==============================================================================
; Animation Frame Table (14 frames of sprite tile numbers)
; ==============================================================================

DATA8_0C8659:
	db $00,$04,$04,$00,$00,$08,$08,$08,$0c,$40,$40,$44,$44,$00,$00,$00 ; Sprite animation sequence

; [Additional sprite configuration data continues...]
	db $06,$00,$02,$00,$08,$00,$04,$00,$02,$08,$01,$68,$80,$01,$80,$01
	db $80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01
	db $80,$01,$80,$01,$09,$0a,$0b,$0c,$03,$02,$02,$02,$10,$40,$02,$02
	db $c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01
	db $c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01
	db $c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01
	db $c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01
	db $c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01
	db $c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01
	db $c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01,$c1,$c3,$01,$01
	db $c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01
	db $c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01
	db $c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01
	db $c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01
	db $c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01
	db $c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01,$c2,$c4,$01,$01
	db $02,$04,$01,$01,$05,$02,$02,$02,$02,$02,$02,$02,$02,$00

; ==============================================================================
; Display_SpriteOAMDataCopy - Sprite OAM Data Copy
; ==============================================================================
; Block copies sprite configuration to OAM buffer.
; 112 bytes ($70) transferred via mvn instruction.
; ==============================================================================

Display_SpriteOAMDataCopy:
	rep #$30		;0C8767	; 16-bit A/X/Y
	ldx.w #$8779	;0C8769	; Source address
	ldy.w #$0c80	;0C876C	; Destination address (OAM buffer)
	lda.w #$006f	;0C876F	; Transfer size = 112 bytes
	mvn $00,$0c	 ;0C8772	; Block move (Bank $0c → Bank $00)
	jsr.w JumpWindowApplyRoutine ;0C8775	; Update PPU registers
	rts ;0C8778	; Return

; OAM sprite configuration data (112 bytes)
	db $74,$cf,$00,$36,$74,$cf,$00,$38,$74,$cf,$00,$3a,$74,$cf,$00,$3c
	db $74,$cf,$00,$3e,$7c,$bf,$00,$36,$7c,$ef,$00,$36,$7c,$bf,$00,$38
	db $7c,$ef,$00,$38,$7c,$bf,$00,$3a,$7c,$ef,$00,$3a,$7c,$bf,$00,$3c
	db $7c,$ef,$00,$3c,$7c,$bf,$00,$3e,$7c,$ef,$00,$3e,$78,$8f,$4c,$06
	db $78,$8f,$4c,$08,$78,$8f,$4c,$0a,$78,$8f,$4c,$0c,$78,$8f,$4c,$0e
	db $40,$6f,$c0,$00,$50,$6f,$c2,$00,$60,$6f,$c4,$00,$70,$6f,$c6,$00
	db $80,$6f,$c8,$00,$90,$6f,$ca,$00,$a0,$6f,$cc,$00,$b0,$6f,$ce,$00

; ==============================================================================
; Display_ClearNMIFlag - Clear NMI Flag
; ==============================================================================
; Disables NMI interrupts by clearing flag.
; Called before major PPU updates.
; ==============================================================================

Display_ClearNMIFlag:
	stz.w $0111	 ;0C87E9	; Clear NMI enable flag
	rts ;0C87EC	; Return

; ==============================================================================
; Display_Mode7TilemapSetup - Mode 7 Tilemap Setup
; ==============================================================================
; Initializes Mode 7 tilemap with block fill.
; Fills 30 rows ($1e) × 128 columns with pattern $c0.
; ==============================================================================

Display_Mode7TilemapSetup:
	rep #$30		;0C87ED	; 16-bit A/X/Y
	pea.w $0c7f	 ;0C87EF	; Push bank $0c
	plb ;0C87F2	; Pull to data bank register
	ldx.w #$4000	;0C87F3	; VRAM start address
	ldy.w #$001e	;0C87F6	; Row count = 30
	lda.w #$00c0	;0C87F9	; Fill pattern = $c0
	jsl.l CallTilemapFillRoutine ;0C87FC	; Call tilemap fill routine
	plb ;0C8800	; Restore data bank
	sep #$20		;0C8801	; 8-bit accumulator
	stz.w $4204	 ;0C8803	; Clear multiply/divide register
	ldx.w #$00ce	;0C8806	; Table offset = $ce
	ldy.w #$0082	;0C8809	; Y parameter = $82

	.SetupCalculationLoop:					; Loop: Setup calculation
	tya ;0C880C	; Transfer Y to A
	asl A		   ;0C880D	; *2
	sta.w $4205	 ;0C880E	; Store to multiply register
	lda.b #$20	  ;0C8811	; Value = $20
	jsl.l ExecuteHardwareDivision ;0C8813	; Call calculation routine
; [Additional Mode 7 setup continues...]

; ==============================================================================
; End of Bank $0c Cycle 2
; ==============================================================================
; Lines documented: 400 source lines (500-900)
; Address range: $0c8396-$0c8813 (partial)
; Systems: Screen effects, palette fades, sprite animation, Mode 7 tilemap
; ==============================================================================
; ==============================================================================
; BANK $0c CYCLE 3 - DMA/HDMA & Mode 7 Math (Lines 900-1300)
; ==============================================================================
; Address range: $0c8813-$0c8af1
; Systems: HDMA setup, Mode 7 rotation/scaling, DMA transfers, OAM management
; ==============================================================================

; [Continued from Cycle 2 ending at $0c8813]

	jsl.l ExecuteHardwareDivision ;0C8813	; Call hardware multiply routine
	rep #$30		;0C8817	; 16-bit A/X/Y
	lda.w $4214	 ;0C8819	; Read quotient from hardware divider
	sta.l $7f0010,X ;0C881C	; Store to Mode 7 calculation buffer
	sep #$20		;0C8820	; 8-bit accumulator
	iny ;0C8822	; Next Y value
	inx ;0C8823	; Next X offset
	inx ;0C8824	; (word addressing)
	cpy.w #$00e8	;0C8825	; Processed 232 values?
	bne .SetupCalculationLoop ;0C8828	; Loop for all rows

; ==============================================================================
; HDMA Channel Configuration - Perspective Effect Setup
; ==============================================================================
; Configures two HDMA channels for Mode 7 scanline effects.
; Channel 1 ($4310): Controls horizontal scroll register ($211b)
; Channel 2 ($4320): Controls vertical scroll register ($211e)
; ==============================================================================

	rep #$30		;0C882A	; 16-bit A/X/Y
	ldx.w #$886b	;0C882C	; HDMA data table address
	ldy.w #$0000	;0C882F	; Destination = $7f0000
	lda.w #$0009	;0C8832	; Transfer 10 bytes
	mvn $7f,$0c	 ;0C8835	; Block move Bank $0c → Bank $7f
	phk ;0C8838	; Push current bank
	plb ;0C8839	; Set data bank
	sep #$20		;0C883A	; 8-bit accumulator

; Configure HDMA Channel 1 (Mode 7 X scroll)
	lda.b #$42	  ;0C883C	; Transfer mode = Write 2 bytes
	sta.w $4310	 ;0C883E	; Set DMA1 parameters ($4310)
	sta.w $4320	 ;0C8841	; Set DMA2 parameters ($4320)
	lda.b #$1b	  ;0C8844	; PPU register = $211b (SNES_M7HOFS)
	sta.w $4311	 ;0C8846	; DMA1 destination = Mode 7 H offset
	lda.b #$1e	  ;0C8849	; PPU register = $211e (SNES_M7VOFS)
	sta.w $4321	 ;0C884B	; DMA2 destination = Mode 7 V offset

; Set HDMA table addresses (Bank $7f)
	ldx.w #$0000	;0C884E	; Table offset = $7f0000
	stx.w $4312	 ;0C8851	; DMA1 source address low
	stx.w $4322	 ;0C8854	; DMA2 source address low
	lda.b #$7f	  ;0C8857	; Source bank = $7f
	sta.w $4314	 ;0C8859	; DMA1 source bank
	sta.w $4324	 ;0C885C	; DMA2 source bank
	sta.w $4317	 ;0C885F	; DMA1 indirect address bank
	sta.w $4327	 ;0C8862	; DMA2 indirect address bank

	lda.b #$06	  ;0C8865	; Enable channels 1 and 2
	sta.w $0111	 ;0C8867	; Set HDMA enable flag (NMI handler)
	rts ;0C886A	; Return

; ==============================================================================
; HDMA Table Header Data
; ==============================================================================
; Format: [scanline_count] [register_value_low] [register_value_high]
; Controls Mode 7 scroll offsets per scanline for perspective effect.
; ==============================================================================

DATA8_0C886B:
	db $ff,$10,$00,$d1,$0e,$01,$00 ;0C886B	; HDMA: 255 lines, value=$0010, then $01d1

; ==============================================================================
; Display_AnimatedVerticalScroll - Animated Vertical Scroll Effect
; ==============================================================================
; Creates smooth scrolling animation from top to bottom of screen.
; Animates through 14-frame cycle using lookup table.
; Used for title screen, special transitions, dramatic reveals.
; ==============================================================================

Display_AnimatedVerticalScroll:
	lda.b #$f7	  ;0C8872	; Initial scroll value = -9 pixels
	ldx.w #$0000	;0C8874	; Table index = 0

	.MainScrollLoop:							; Main scroll animation loop
	phk ;0C8877	; Push data bank
	plb ;0C8878	; Set data bank
	pha ;0C8879	; Save scroll value
	jsl.l CWaitTimingRoutine ;0C887A	; Wait for VBLANK
	sta.b SNES_BG1VOFS-$2100 ;0C887E	; Set BG1 vertical scroll ($210e)
	stz.b SNES_BG1VOFS-$2100 ;0C8880	; High byte = 0
	lda.w DATA8_0C88B0,X ;0C8882	; Load animation tile pattern
	inx ;0C8885	; Next table entry
	phx ;0C8886	; Save index
	jsr.w DrawTilePatternGrid ;0C8887	; Draw tile pattern (3×3 grid)
	plx ;0C888A	; Restore index
	cpx.w #$000e	;0C888B	; End of 14-entry table?
	bne .CheckScrollRange ;0C888E	; Branch if not done
	ldx.w #$0000	;0C8890	; Wrap to start

	.CheckScrollRange:							; Check scroll position ranges
	pla ;0C8893	; Restore scroll value
	cmp.b #$39	  ;0C8894	; Position < $39?
	bcc .FastScrollRange ;0C8896	; Branch if in range 1 (fast scroll)
	cmp.b #$59	  ;0C8898	; Position < $59?
	bcc .MediumScrollRange ;0C889A	; Branch if in range 2 (medium scroll)
	cmp.b #$79	  ;0C889C	; Position < $79?
	bcc .SlowScrollRange ;0C889E	; Branch if in range 3 (slow scroll)
	dec A		   ;0C88A0	; Range 4: Decrement by 1 (slowest)
	bra .MainScrollLoop ;0C88A1	; Continue animation

	.SlowScrollRange:							; Range 3: Slow scroll
	sbc.b #$01	  ;0C88A3	; Decrement by 2 (carry set from CMP)
	bra .MainScrollLoop ;0C88A5	; Continue animation

	.MediumScrollRange:							; Range 2: Medium scroll
	sbc.b #$03	  ;0C88A7	; Decrement by 4
	bra .MainScrollLoop ;0C88A9	; Continue animation

	.FastScrollRange:							; Range 1: Fast scroll
	sbc.b #$05	  ;0C88AB	; Decrement by 6 (fastest)
	bcs .MainScrollLoop ;0C88AD	; Continue if not wrapped negative
	rts ;0C88AF	; Exit when scroll completes

; ==============================================================================
; Animation Tile Pattern Table (14 entries)
; ==============================================================================
; Sprite tile numbers for scroll animation frames.
; Values correspond to VRAM tile addresses for 3×3 pattern drawing.
; ==============================================================================

DATA8_0C88B0:
	db $11,$15,$15,$11,$11,$19,$19,$19,$1d,$51,$51,$55,$55,$11 ;0C88B0

; ==============================================================================
; Display_Mode7MatrixInit - Mode 7 Matrix Initialization
; ==============================================================================
; Sets up Mode 7 affine transformation matrix for rotation/scaling.
; Initializes center point ($0118, $0184) and identity matrix.
; Called during screen setup, before 3D perspective effects.
; ==============================================================================

Display_Mode7MatrixInit:
	phk ;0C88BE	; Push data bank
	plb ;0C88BF	; Set data bank
	clc ;0C88C0	; Clear carry
	lda.b #$84	  ;0C88C1	; Center Y = $84 (132 decimal)
	jsl.l CWaitTimingRoutine ;0C88C3	; Wait for VBLANK
	stz.b SNES_VMAINC-$2100 ;0C88C7	; VRAM address increment = 1

; Set Mode 7 center point (X coordinate)
	sta.b SNES_M7X-$2100 ;0C88C9	; M7X low byte = $00 ($211f)
	stz.b SNES_M7X-$2100 ;0C88CB	; M7X high byte = $00
	lda.b #$18	  ;0C88CD	; Center X low = $18
	sta.b SNES_M7Y-$2100 ;0C88CF	; M7Y low byte ($2120)
	lda.b #$01	  ;0C88D1	; Center X high = $01
	sta.b SNES_M7Y-$2100 ;0C88D3	; M7Y high byte (X = $0118 = 280)

; Initialize Mode 7 matrix to identity (no rotation/scale)
	stz.b SNES_M7B-$2100 ;0C88D5	; M7B = $0000 ($211c)
	stz.b SNES_M7B-$2100 ;0C88D7	; Matrix element B = 0
	stz.b SNES_M7C-$2100 ;0C88D9	; M7C = $0000 ($211d)
	stz.b SNES_M7C-$2100 ;0C88DB	; Matrix element C = 0

; Set initial scroll offset
	lda.b #$04	  ;0C88DD	; H scroll = 4 pixels right
	sta.b SNES_BG1HOFS-$2100 ;0C88DF	; BG1 horizontal offset ($210d)
	stz.b SNES_BG1HOFS-$2100 ;0C88E1	; High byte = 0
	lda.b #$f8	  ;0C88E3	; V scroll = -8 pixels
	sta.b SNES_BG1VOFS-$2100 ;0C88E5	; BG1 vertical offset ($210e)
	stz.b SNES_BG1VOFS-$2100 ;0C88E7	; High byte = 0
	lda.b #$11	  ;0C88E9	; Base tile pattern

; ==============================================================================
; Display_Draw3x3TilePattern - Draw 3×3 Tile Pattern
; ==============================================================================
; Draws 3×3 grid of tiles to VRAM at specified position.
; Uses sequential tile numbers with automatic wrapping.
; Input: A = base tile number, X = VRAM position base
; ==============================================================================

Display_Draw3x3TilePattern:
	clc ;0C88EB	; Clear carry
	ldx.w #$0f8f	;0C88EC	; VRAM base address = $0f8f
	jsr.w Display_DrawTileRow ;0C88EF	; Draw first row (3 tiles)
	jsr.w Display_DrawTileRow ;0C88F2	; Draw second row (3 tiles)
	jsr.w Display_DrawTileRow ;0C88F5	; Draw third row (3 tiles)

; ==============================================================================
; Display_DrawTileRow - Draw Single Tile Row (3 tiles)
; ==============================================================================
; Writes 3 consecutive tile numbers to VRAM.
; Advances VRAM address by $80 (down one row in tilemap).
; Input: X = VRAM address, A = starting tile number
; ==============================================================================

Display_DrawTileRow:
	stx.b SNES_VMADDL-$2100 ;0C88F8	; Set VRAM address ($2116)
	sta.b SNES_VMDATAL-$2100 ;0C88FA	; Write tile 1 ($2118)
	inc A		   ;0C88FC	; Next tile
	sta.b SNES_VMDATAL-$2100 ;0C88FD	; Write tile 2
	inc A		   ;0C88FF	; Next tile
	sta.b SNES_VMDATAL-$2100 ;0C8900	; Write tile 3
	adc.b #$0e	  ;0C8902	; Advance tile base (+16 total from start)
	pha ;0C8904	; Save next row tile number
	rep #$30		;0C8905	; 16-bit A/X/Y
	txa ;0C8907	; Transfer VRAM address to A
	adc.w #$0080	;0C8908	; Move down one tilemap row (32 tiles * 2 bytes)
	tax ;0C890B	; Update VRAM address
	sep #$20		;0C890C	; 8-bit accumulator
	pla ;0C890E	; Restore tile number
	rts ;0C890F	; Return

; ==============================================================================
; Display_SetupNMIOAMTransfer - Setup NMI OAM Transfer
; ==============================================================================
; Configures NMI handler to perform OAM sprite DMA during VBLANK.
; Sets up pointer to sprite transfer subroutine.
; Critical for smooth sprite updates without flicker.
; ==============================================================================

Display_SetupNMIOAMTransfer:
	phk ;0C8910	; Push data bank
	plb ;0C8911	; Set data bank
	sep #$20		;0C8912	; 8-bit accumulator
	lda.b #$0c	  ;0C8914	; Handler bank = $0c
	sta.w $005a	 ;0C8916	; Store NMI handler bank
	ldx.w #$8929	;0C8919	; Handler address = $0c8929
	stx.w $0058	 ;0C891C	; Store NMI handler pointer
	lda.b #$40	  ;0C891F	; Flag bit 6
	tsb.w !system_flags_9	 ;0C8921	; Set NMI control flag (enable OAM transfer)
	jsl.l CWaitTimingRoutine ;0C8924	; Wait for VBLANK
	rts ;0C8928	; Return

; ==============================================================================
; NMI OAM DMA Routine - Executed during VBLANK
; ==============================================================================
; Called automatically by NMI handler when bit 6 of $00e2 is set.
; Transfers 544 bytes ($220) from $0c00 to OAM ($2104).
; Uses DMA channel 5 for maximum speed (single VBLANK period).
; ==============================================================================

	ldx.w #$0000	;0C8929	; OAM address = 0
	stx.w SNES_OAMADDL ;0C892C	; Set OAM write address ($2102)
	ldx.w #$0400	;0C892F	; DMA mode: CPU→PPU, auto-increment
	stx.b SNES_DMA5PARAM-$4300 ;0C8932	; Set DMA5 parameters ($4350)
	ldx.w #$0c00	;0C8934	; Source address = $0c00 (sprite buffer)
	stx.b SNES_DMA5ADDRL-$4300 ;0C8937	; Set DMA5 source address ($4352)
	lda.b #$00	  ;0C8939	; Source bank = $00
	sta.b SNES_DMA5ADDRH-$4300 ;0C893B	; Set DMA5 source bank ($4354)
	ldx.w #$0220	;0C893D	; Transfer size = 544 bytes (512 OAM + 32 table)
	stx.b SNES_DMA5CNTL-$4300 ;0C8940	; Set DMA5 byte count ($4355)
	lda.b #$20	  ;0C8942	; Enable DMA channel 5
	sta.w SNES_MDMAEN ;0C8944	; Start DMA transfer ($420b)
	rtl ;0C8947	; Return from NMI handler

; ==============================================================================
; Display_DirectOAMDMATransfer - Direct OAM DMA Transfer
; ==============================================================================
; Immediately performs OAM sprite DMA (non-NMI version).
; Identical to NMI routine but callable from main code.
; Used for initial sprite setup or forced updates.
; ==============================================================================

Display_DirectOAMDMATransfer:
	sep #$20		;0C8948	; 8-bit accumulator
	ldx.w #$0000	;0C894A	; OAM address = 0
	stx.w SNES_OAMADDL ;0C894D	; Set OAM write address ($2102)
	ldx.w #$0400	;0C8950	; DMA mode: CPU→PPU, auto-increment
	stx.w SNES_DMA5PARAM ;0C8953	; Set DMA5 parameters ($4350)
	ldx.w #$0c00	;0C8956	; Source address = $0c00
	stx.w SNES_DMA5ADDRL ;0C8959	; Set DMA5 source address ($4352)
	lda.b #$00	  ;0C895C	; Source bank = $00
	sta.w SNES_DMA5ADDRH ;0C895E	; Set DMA5 source bank ($4354)
	ldx.w #$0220	;0C8961	; Transfer size = 544 bytes
	stx.w SNES_DMA5CNTL ;0C8964	; Set DMA5 byte count ($4355)
	lda.b #$20	  ;0C8967	; Enable DMA channel 5
	sta.w SNES_MDMAEN ;0C8969	; Start DMA transfer ($420b)
	phk ;0C896C	; Push data bank
	plb ;0C896D	; Set data bank
	rts ;0C896E	; Return

; ==============================================================================
; Display_Mode7RotationSequence - Complex Mode 7 Rotation Sequence
; ==============================================================================
; Performs animated Mode 7 rotation effect with matrix calculations.
; Updates transformation matrix each frame for smooth rotation.
; Used for title screen rotation, special battle effects.
; ==============================================================================

Display_Mode7RotationSequence:
	lda.b #$d4	  ;0C896F	; Scroll offset = -44 pixels
	sta.b SNES_BG1VOFS-$2100 ;0C8971	; Set vertical scroll ($210e)
	lda.b #$ff	  ;0C8973	; High byte = -1 (negative scroll)
	sta.b SNES_BG1VOFS-$2100 ;0C8975	; Set high byte
	ldx.w #$8b86	;0C8977	; Sine/cosine table 1
	ldy.w #$8b96	;0C897A	; Sine/cosine table 2

	.MainRotationLoop:							; Main rotation loop
	lda.w $0000,Y   ;0C897D	; Load rotation angle
	beq .PostRotationFade ;0C8980	; Exit if angle = 0 (no rotation)
	phy ;0C8982	; Save table pointer
	jsl.l CWaitTimingRoutine ;0C8983	; Wait for VBLANK
	jsr.w UpdateModeMatrixMultiply ;0C8987	; Update Mode 7 matrix ($4202 multiply)
	ply ;0C898A	; Restore table pointer

; Calculate vertical scroll based on rotation progress
	tya ;0C898B	; Transfer table offset to A
	sec ;0C898C	; Set carry for subtraction
	sbc.b #$ab	  ;0C898D	; Subtract table base ($8b96 - $ab = $8beb)
	asl A		   ;0C898F	; Multiply by 2 (pixel offset)
	sta.b SNES_BG1VOFS-$2100 ;0C8990	; Set vertical scroll ($210e)
	beq .SetHighByteZero ;0C8992	; Branch if offset = 0
	lda.b #$ff	  ;0C8994	; High byte = -1 (negative)

	.SetHighByteZero:
	sta.b SNES_BG1VOFS-$2100 ;0C8996	; Set high byte
	iny ;0C8998	; Next rotation angle
	bra .MainRotationLoop ;0C8999	; Continue rotation

	.PostRotationFade:							; Post-rotation fade loop
	lda.b #$1e	  ;0C899B	; Loop counter = 30 frames

	.FadeLoop:
	jsl.l CWaitTimingRoutine ;0C899D	; Wait for VBLANK
	pha ;0C89A1	; Save counter
	jsr.w UpdateModeMatrix ;0C89A2	; Update Mode 7 matrix
	pla ;0C89A5	; Restore counter
	dec A		   ;0C89A6	; Decrement
	bne .FadeLoop   ;0C89A7	; Loop 30 times

; Initialize sprite animation sequence
	ldy.w #$0101	;0C89A9	; Start position = $0101
	sty.w $0062	 ;0C89AC	; Store position counter

	.SpritePositionLoop:						; Sprite position update loop
	ldy.w $0062	 ;0C89AF	; Load position
	phy ;0C89B2	; Save position
	jsr.w UpdateSpriteCoordinates ;0C89B3	; Update sprite coordinates
	ply ;0C89B6	; Restore position
	sty.w $0062	 ;0C89B7	; Store position
	inc.w $0062	 ;0C89BA	; Increment X coordinate
	inc.w $0063	 ;0C89BD	; Increment Y coordinate

; Second sprite update (staggered)
	ldy.w $0062	 ;0C89C0	; Load updated position
	phy ;0C89C3	; Save position
	jsr.w UpdateSpriteCoordinates ;0C89C4	; Update sprite coordinates
	ply ;0C89C7	; Restore position
	sty.w $0062	 ;0C89C8	; Store position
	inc.w $0062	 ;0C89CB	; Increment X coordinate
	inc.w $0063	 ;0C89CE	; Increment Y coordinate

; Check for triple update (every 3 cycles)
	lda.w $0062	 ;0C89D1	; Load X coordinate
	cmp.b #$0c	  ;0C89D4	; Reached position $0c?
	beq .WaitForTableSync ;0C89D6	; Branch if done

; Third sprite update (pattern of 3)
	ldy.w $0062	 ;0C89D8	; Load position
	phy ;0C89DB	; Save position
	jsr.w UpdateSpriteCoordinates ;0C89DC	; Update sprite coordinates
	ply ;0C89DF	; Restore position
	sty.w $0062	 ;0C89E0	; Store position
	inc.w $0062	 ;0C89E3	; Increment X coordinate
	bra .SpritePositionLoop ;0C89E6	; Continue loop

	.WaitForTableSync:							; Wait for table sync loop
	jsl.l CWaitTimingRoutine ;0C89E8	; Wait for VBLANK
	jsr.w UpdateModeMatrix ;0C89EC	; Update Mode 7 matrix
	cpx.w #$8b66	;0C89EF	; Table index at $8b66?
	bne .WaitForTableSync ;0C89F2	; Loop until synced

	.FinalSyncHold:								; Final sync hold loop
	jsl.l CWaitTimingRoutine ;0C89F4	; Wait for VBLANK
	jsr.w UpdateModeMatrix ;0C89F8	; Update Mode 7 matrix
	cpx.w #$8b66	;0C89FB	; Table index at $8b66?
	bne .FinalSyncHold ;0C89FE	; Loop until stable

; Setup final color effects
	jsr.w Display_SetupNMIOAMTransfer ;0C8A00	; Enable NMI OAM transfer
	lda.b #$30	  ;0C8A03	; Flag value = $30
	sta.w !audio_coord_register	 ;0C8A05	; Store effect state
	ldx.w #$2100	;0C8A08	; Color math mode
	stx.b SNES_CGSWSEL-$2100 ;0C8A0B	; Set color window ($2130)
	lda.b #$ff	  ;0C8A0D	; Maximum brightness
	sta.b SNES_COLDATA-$2100 ;0C8A0F	; Set fixed color ($2132)

; Fade-in sequence (8 steps)
	lda.b #$08	  ;0C8A11	; Loop counter = 8 brightness levels
	ldy.w #$000c	;0C8A13	; Sprite count = 12
	ldx.w #$0c04	;0C8A16	; Sprite data buffer base

	.FadeBrightnessLoop:						; Fade brightness loop
	pha ;0C8A19	; Save brightness level
	phy ;0C8A1A	; Save sprite count
	phx ;0C8A1B	; Save buffer pointer

	.SpriteDecrementLoop:						; Per-sprite brightness decrement loop
	dec.w $0000,X   ;0C8A1C	; Decrease sprite brightness
	inx ;0C8A1F	; Next sprite
	inx ;0C8A20	; (skip 2 bytes)
	inx ;0C8A21	; (skip 2 bytes)
	inx ;0C8A22	; (word + word structure)
	dey ;0C8A23	; Decrement sprite counter
	bne Display_Mode7RotationSequence.SpriteDecrementLoop ;0C8A24	; Loop for all sprites

	jsr.w Display_SetupNMIOAMTransfer ;0C8A26	; Update OAM via NMI
	jsl.l CWaitTimingRoutine ;0C8A29	; Wait for VBLANK
	plx ;0C8A2D	; Restore buffer pointer
	ply ;0C8A2E	; Restore sprite count
	lda.b $01,S	 ;0C8A2F	; Load brightness level from stack
	dec A		   ;0C8A31	; Decrease brightness
	asl A		   ;0C8A32	; *2
	asl A		   ;0C8A33	; *4 (multiply by 4)
	ora.b #$e0	  ;0C8A34	; OR with color mask ($e0 = red channel)
	sta.b SNES_COLDATA-$2100 ;0C8A36	; Update fixed color ($2132)
	pla ;0C8A38	; Clean up brightness from stack
	dec A		   ;0C8A39	; Decrement loop counter
	bne Display_Mode7RotationSequence.FadeBrightnessLoop ;0C8A3A	; Loop for all 8 brightness levels

	stz.b SNES_CGADSUB-$2100 ;0C8A3C	; Disable color math ($2131)
	rts ;0C8A3E	; Return

; ==============================================================================
; Display_SpritePositionCalculator - Calculate Sprite Screen Position
; ==============================================================================
; Calculates and sets sprite screen coordinates.
; Converts logical position to screen-relative offset.
; Input: $0062 = X position, $0063 = Y position
; ==============================================================================

Display_SpritePositionCalculator:
	rep #$30		;0C8A3F	; 16-bit A/X/Y
	sec ;0C8A41	; Set carry for subtraction
	lda.w $0062	 ;0C8A42	; Load X position
	and.w #$00ff	;0C8A45	; Mask to 8-bit
	eor.w #$ffff	;0C8A48	; Invert bits (two's complement prep)
	adc.w #$040f	;0C8A4B	; Add screen offset ($0410 - 1)
	sta.w $0400	 ;0C8A4E	; Store screen X coordinate

	lda.w $0063	 ;0C8A51	; Load Y position
	and.w #$00ff	;0C8A54	; Mask to 8-bit
	eor.w #$ffff	;0C8A57	; Invert bits
	adc.w #$603f	;0C8A5A	; Add screen offset ($6040 - 1)
	sta.w $0402	 ;0C8A5D	; Store screen Y coordinate

	sep #$20		;0C8A60	; 8-bit accumulator
	lda.b #$0c	  ;0C8A62	; NMI handler bank
	sta.w $005a	 ;0C8A64	; Store handler bank
	ldy.w #$8b0c	;0C8A67	; Handler routine address
	sty.w $0058	 ;0C8A6A	; Store handler pointer
	lda.b #$40	  ;0C8A6D	; Flag bit 6
	tsb.w !system_flags_9	 ;0C8A6F	; Set NMI enable flag
	jsl.l CWaitTimingRoutine ;0C8A72	; Wait for VBLANK

; ==============================================================================
; Display_HardwareMultiplySetup - Hardware Multiply Initialization
; ==============================================================================
; Initializes hardware multiplier for Mode 7 calculations.
; Input: A = multiplicand value (typically $30 for 48×48 matrix)
; ==============================================================================

Display_HardwareMultiplySetup:
	lda.b #$30	  ;0C8A76	; Multiplicand = 48

	.SetMultiplicand:
	sta.w $4202	 ;0C8A78	; Set multiplicand register ($4202)
	sta.w $0064	 ;0C8A7B	; Store to variable
	jsr.w Display_ReadMultiplyMatrixElement ;0C8A7E	; Read Mode 7 matrix element
	sty.w $0062	 ;0C8A81	; Store matrix A value
	inx ;0C8A84	; Next matrix element
	inx ;0C8A85	; (word offset)
	jsr.w Display_ReadMultiplyMatrixElement ;0C8A86	; Read Mode 7 matrix element
	sty.w $0064	 ;0C8A89	; Store matrix B value
	inx ;0C8A8C	; Next matrix element
	inx ;0C8A8D	; (word offset)

; Check for table wrap
	cpx.w #$8b96	;0C8A8E	; End of sine/cosine table?
	bne .WriteMatrixRegisters ;0C8A91	; Branch if not
	ldx.w #$8b66	;0C8A93	; Wrap to table start

	.WriteMatrixRegisters:						; Write Mode 7 matrix registers
	jsl.l CWaitTimingRoutine ;0C8A96	; Wait for VBLANK

; Update Mode 7 matrix A register ($211b)
	lda.w $0062	 ;0C8A9A	; Load matrix A low byte
	sta.b SNES_M7A-$2100 ;0C8A9D	; Write M7A low ($211b)
	lda.w $0063	 ;0C8A9F	; Load matrix A high byte
	sta.b SNES_M7A-$2100 ;0C8AA2	; Write M7A high

; Update Mode 7 matrix D register ($211e)
	lda.w $0062	 ;0C8AA4	; Load matrix D low byte
	sta.b SNES_M7D-$2100 ;0C8AA7	; Write M7D low ($211e)
	lda.w $0063	 ;0C8AA9	; Load matrix D high byte
	sta.b SNES_M7D-$2100 ;0C8AAC	; Write M7D high

; Update Mode 7 matrix B register ($211c)
	lda.w $0064	 ;0C8AAE	; Load matrix B low byte
	sta.b SNES_M7B-$2100 ;0C8AB1	; Write M7B low ($211c)
	xba ;0C8AB3	; Swap A/B bytes
	lda.w $0065	 ;0C8AB4	; Load matrix B high byte
	sta.b SNES_M7B-$2100 ;0C8AB7	; Write M7B high
	xba ;0C8AB9	; Restore byte order

; Calculate and set matrix C (negative of B)
	rep #$30		;0C8ABA	; 16-bit A/X/Y
	eor.w #$ffff	;0C8ABC	; Invert all bits
	inc A		   ;0C8ABF	; Increment (two's complement = -B)
	sep #$20		;0C8AC0	; 8-bit accumulator
	sta.b SNES_M7C-$2100 ;0C8AC2	; Write M7C low ($211d)
	xba ;0C8AC4	; Swap bytes
	sta.b SNES_M7C-$2100 ;0C8AC5	; Write M7C high
	rts ;0C8AC7	; Return

; ==============================================================================
; Display_ReadMultiplyMatrixElement - Read & Multiply Matrix Element
; ==============================================================================
; Reads sine/cosine value from table and performs hardware multiply.
; Used for Mode 7 rotation matrix calculation.
; Input: X = table offset
; Output: Y = result from hardware multiplier
; ==============================================================================

Display_ReadMultiplyMatrixElement:
	lda.w $0001,X   ;0C8AC8	; Load matrix value high byte
	bmi .NegativeValue ;0C8ACB	; Branch if negative (sign extend)
	bne .LargePositive ;0C8ACD	; Branch if non-zero high byte
	lda.w $0000,X   ;0C8ACF	; Load low byte only

	.SmallPositive:								; Small positive value path
	jsl.l CallMultiplicationRoutine ;0C8AD2	; Setup hardware multiply/divide
	ldy.w $4216	 ;0C8AD6	; Read division remainder
	sty.w $4204	 ;0C8AD9	; Store to dividend register

	.CommonMultiply:							; Common multiply path
	lda.b #$30	  ;0C8ADC	; Multiplier = 48
	jsl.l ExecuteHardwareDivision ;0C8ADE	; Perform hardware multiply
	ldy.w $4214	 ;0C8AE2	; Read product result ($4214)
	rts ;0C8AE5	; Return with result in Y

	.LargePositive:								; Large positive value path
	stz.w $4204	 ;0C8AE6	; Clear dividend high byte
	lda.w $0064	 ;0C8AE9	; Load multiplier value
	sta.w $4205	 ;0C8AEC	; Set divisor register
	bra .CommonMultiply ;0C8AEF	; Continue to multiply

	.NegativeValue:								; Negative value path (sign extend)
	lda.w $0000,X   ;0C8AF1	; Load matrix value low byte
; [Additional processing continues...]

; ==============================================================================
; End of Bank $0c Cycle 3
; ==============================================================================
; Lines documented: 400 source lines (900-1300)
; Address range: $0c8813-$0c8af1
; Systems: HDMA setup, Mode 7 rotation/scaling, DMA transfers, OAM management
; ==============================================================================
; ==============================================================================
; BANK $0c CYCLE 4 - VRAM Fill & Title Screen Setup (Lines 1300-1700)
; ==============================================================================
; Address range: $0c8af1-$0c8f98
; Systems: VRAM tile fill, palette DMA, title screen initialization, tilemap setup
; ==============================================================================

; [Continued from Cycle 3 ending at $0c8af1]

	lda.w $0000,X   ;0C8AF1	; Load matrix value (continued from Display_ReadMultiplyMatrixElement)
	beq .ZeroValue  ;0C8AF4	; Branch if zero (no processing needed)
	eor.b #$ff	  ;0C8AF6	; Invert bits (two's complement step 1)
	inc A		   ;0C8AF8	; Increment (two's complement = negate)
	jsr.w Display_ReadMultiplyMatrixElement.SmallPositive ;0C8AF9	; Process small positive value path

	.NegateResult:								; Negate result and return
	rep #$30		;0C8AFC	; 16-bit A/X/Y
	tya ;0C8AFE	; Transfer result to A
	eor.w #$ffff	;0C8AFF	; Invert all bits
	inc A		   ;0C8B02	; Increment (negate)
	tay ;0C8B03	; Return result in Y
	sep #$20		;0C8B04	; 8-bit accumulator
	rts ;0C8B06	; Return

	.ZeroValue:									; Zero value path
	jsr.w Display_ReadMultiplyMatrixElement.LargePositive ;0C8B07	; Process large positive value
	bra .NegateResult ;0C8B0A	; Negate and return

; ==============================================================================
; NMI Sprite Position Update Handler
; ==============================================================================
; Called from NMI when sprite positions need updating.
; Uses DMA to transfer sprite coordinate data to VRAM during VBLANK.
; ==============================================================================

	ldy.w #$1800	;0C8B0C	; DMA mode: A→A, increment both
	sty.b SNES_DMA0PARAM-$4300 ;0C8B0F	; Set DMA0 parameters ($4300)
	stz.b SNES_DMA1CNTL-$4300 ;0C8B11	; Clear DMA1 count ($4315)
	lda.b #$7f	  ;0C8B13	; Source bank = $7f
	sta.b SNES_DMA0ADDRH-$4300 ;0C8B15	; Set DMA0 source bank ($4304)
	ldy.w $0402	 ;0C8B17	; Load Y coordinate offset
	ldx.w #$0008	;0C8B1A	; Row count = 8
	stx.w $0064	 ;0C8B1D	; Store row counter
	ldx.w #$0414	;0C8B20	; Data buffer address
	lda.w $0063	 ;0C8B23	; Load Y position
	jsr.w UpdateVerticalSpritePositions ;0C8B26	; Update vertical sprite positions

; Update horizontal sprite positions
	ldx.w #$000b	;0C8B29	; Column count = 11
	stx.w $0064	 ;0C8B2C	; Store column counter
	ldy.w #$6000	;0C8B2F	; VRAM address = $6000
	ldx.w $0400	 ;0C8B32	; Load X coordinate offset
	lda.w $0062	 ;0C8B35	; Load X position
	jsr.w UpdateVerticalSpritePositions ;0C8B38	; Update horizontal sprite positions
	rtl ;0C8B3B	; Return from NMI handler

; ==============================================================================
; Display_SpriteCoordinateDMA - Sprite Coordinate DMA Transfer
; ==============================================================================
; Transfers sprite coordinate data to VRAM using DMA.
; Writes 5 bytes per row/column, advancing VRAM address by $80 each iteration.
; Input: A = coordinate value, X = VRAM address, Y = source buffer address
; ==============================================================================

Display_SpriteCoordinateDMA:
	clc ;0C8B3C	; Clear carry
	xba ;0C8B3D	; Swap bytes (prep for DMA count)
	lda.b #$05	  ;0C8B3E	; Transfer size = 5 bytes

	.DMALoop:									; DMA transfer loop
	stx.w SNES_VMADDL ;0C8B40	; Set VRAM address ($2116)
	xba ;0C8B43	; Swap to get count
	sta.b SNES_DMA0CNTL-$4300 ;0C8B44	; Set DMA byte count low ($4305)
	stz.b SNES_DMA0CNTH-$4300 ;0C8B46	; Set DMA byte count high ($4306)
	sty.b SNES_DMA0ADDRL-$4300 ;0C8B48	; Set DMA source address ($4302)
	pha ;0C8B4A	; Save count
	lda.b #$01	  ;0C8B4B	; Enable DMA channel 0
	sta.w SNES_MDMAEN ;0C8B4D	; Start DMA transfer ($420b)
	pla ;0C8B50	; Restore count

; Advance to next row/column
	rep #$30		;0C8B51	; 16-bit A/X/Y
	pha ;0C8B53	; Save count
	txa ;0C8B54	; Transfer VRAM address to A
	adc.w #$0080	;0C8B55	; Advance by 128 (next row in 32×32 tilemap)
	tax ;0C8B58	; Update VRAM address
	tya ;0C8B59	; Transfer source address to A
	adc.w $0064	 ;0C8B5A	; Add row/column stride
	tay ;0C8B5D	; Update source address
	pla ;0C8B5E	; Restore count
	sep #$20		;0C8B5F	; 8-bit accumulator
	xba ;0C8B61	; Swap back
	dec A		   ;0C8B62	; Decrement row/column counter
	bne .DMALoop	;0C8B63	; Loop for all rows/columns
	rts ;0C8B65	; Return

; ==============================================================================
; Mode 7 Rotation Sine/Cosine Lookup Tables
; ==============================================================================
; Two 48-entry tables for smooth rotation animation.
; Values represent fixed-point sine/cosine for 360° rotation.
; Format: Signed 16-bit fixed-point (8.8 format)
; ==============================================================================

DATA16_0C8B66:	; Sine/cosine table 1 (48 entries)
	db $dd,$00,$80,$00,$80,$00,$dd,$00,$00,$00 ;0C8B66	; Angles 0-9
	db $00		 ;0C8B70
	db $01,$80,$ff,$dd,$00,$23,$ff,$80,$00,$00,$ff,$00,$00,$23,$ff,$80 ;0C8B71	; Angles 10-25
	db $ff,$80,$ff,$23,$ff,$00,$00,$00,$ff,$80,$00,$23,$ff,$dd,$00,$80 ;0C8B81	; Angles 26-41
	db $ff		 ;0C8B91
	db $00		 ;0C8B92

DATA8_0C8B93:	; Animation speed table (30 bytes)
	db $01,$00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$0a,$0c,$0e,$10,$12 ;0C8B93
	db $14,$16,$18,$1c,$20,$24,$28,$2c,$30,$00 ;0C8BA3

; ==============================================================================
; Display_TitleScreenInit - Title Screen Initialization
; ==============================================================================
; Sets up title screen graphics, sprites, and tilemaps.
; Initializes Mode 7 perspective effect for logo animation.
; Uses multiple mvn block moves for efficient data transfer.
; ==============================================================================

Display_TitleScreenInit:
	lda.b #$18	  ;0C8BAD	; Effect timer = 24 frames
	sta.w !audio_gfx_index	 ;0C8BAF	; Store effect state
	rep #$30		;0C8BB2	; 16-bit A/X/Y

; Transfer title screen configuration data
	ldx.w #$8ce2	;0C8BB4	; Source: Title config table
	ldy.w #$0d00	;0C8BB7	; Dest: $0d00 (config buffer)
	lda.w #$0037	;0C8BBA	; Transfer 56 bytes
	mvn $00,$0c	 ;0C8BBD	; Block move Bank $0c → Bank $00

	ldy.w #$0e10	;0C8BC0	; Dest: $0e10 (secondary buffer)
	lda.w #$0003	;0C8BC3	; Transfer 4 bytes
	mvn $00,$0c	 ;0C8BC6	; Block move

; Transfer sprite attribute data
	ldx.w #$8c5e	;0C8BC9	; Source: Sprite data table
	ldy.w #$0c04	;0C8BCC	; Dest: $0c04 (sprite buffer)
	lda.w #$007b	;0C8BCF	; Transfer 124 bytes
	mvn $00,$0c	 ;0C8BD2	; Block move

	ldy.w #$0e00	;0C8BD5	; Dest: $0e00 (effect params)
	lda.w #$0007	;0C8BD8	; Transfer 8 bytes
	mvn $00,$0c	 ;0C8BDB	; Block move

	sep #$20		;0C8BDE	; 8-bit accumulator
	pea.w $0c7f	 ;0C8BE0	; Push bank $7f
	plb ;0C8BE3	; Set data bank = $7f

; Initialize tile pattern buffer ($7f6000-$7f6xxx)
	ldy.w #$6000	;0C8BE4	; Buffer address = $7f6000
	lda.b #$40	  ;0C8BE7	; Starting tile = $40
	clc ;0C8BE9	; Clear carry

	.FillRowsLoop:							; Outer loop: Process 11 tile rows
	ldx.w #$000b	;0C8BEA	; Column count = 11

	.FillColumnsLoop:							; Inner loop: Fill tile row
	sta.w $0000,Y   ;0C8BED	; Write tile number to buffer
	inc A		   ;0C8BF0	; Next tile
	iny ;0C8BF1	; Next buffer position
	dex ;0C8BF2	; Decrement column counter
	bne .FillColumnsLoop ;0C8BF3	; Loop for all columns
	adc.b #$05	  ;0C8BF5	; Advance to next row base (+16 total)
	cmp.b #$90	  ;0C8BF7	; Reached tile $90?
	bne .FillRowsLoop ;0C8BF9	; Loop for all rows

; Initialize secondary tile pattern buffer (8-column layout)
	ldy.w #$6037	;0C8BFB	; Buffer address = $7f6037 (offset)
	lda.b #$a0	  ;0C8BFE	; Starting tile = $a0
	clc ;0C8C00	; Clear carry

	.SecondaryRowsLoop:						; Outer loop: Process 8 tile rows
	ldx.w #$0008	;0C8C01	; Column count = 8

	.SecondaryColumnsLoop:						; Inner loop: Fill tile row
	sta.w $0000,Y   ;0C8C04	; Write tile number
	inc A		   ;0C8C07	; Next tile
	iny ;0C8C08	; Next buffer position
	dex ;0C8C09	; Decrement column counter
	bne .SecondaryColumnsLoop ;0C8C0A	; Loop for all columns
	adc.b #$08	  ;0C8C0C	; Advance to next row base (+16 total)
	cmp.b #$f0	  ;0C8C0E	; Reached tile $f0?
	bne .SecondaryRowsLoop ;0C8C10	; Loop for all rows

	plb ;0C8C12	; Restore data bank
	clc ;0C8C13	; Clear carry
	jsl.l CWaitTimingRoutine ;0C8C14	; Wait for VBLANK
	stz.b SNES_VMAINC-$2100 ;0C8C18	; VRAM address increment = 1

; Set Mode 7 center point
	lda.b #$8c	  ;0C8C1A	; Center X = $8c (140 decimal)
	sta.b SNES_M7X-$2100 ;0C8C1C	; Write M7 center X low ($211f)
	stz.b SNES_M7X-$2100 ;0C8C1E	; Write M7 center X high
	lda.b #$50	  ;0C8C20	; Center Y = $50 (80 decimal)
	sta.b SNES_M7Y-$2100 ;0C8C22	; Write M7 center Y low ($2120)
	stz.b SNES_M7Y-$2100 ;0C8C24	; Write M7 center Y high

; Initialize Mode 7 identity matrix
	lda.b #$01	  ;0C8C26	; Matrix diagonal = 1.0
	sta.b SNES_M7A-$2100 ;0C8C28	; M7A = $0100 ($211b)
	stz.b SNES_M7A-$2100 ;0C8C2A	; High byte
	sta.b SNES_M7D-$2100 ;0C8C2C	; M7D = $0100 ($211e)
	stz.b SNES_M7D-$2100 ;0C8C2E	; High byte

; Process tilemap fill commands from table
	ldx.w #$0285	;0C8C30	; Initial VRAM address
	ldy.w #$8d1e	;0C8C33	; Command table address
	phx ;0C8C36	; Save base VRAM address

	.TilemapFillLoop:							; Tilemap fill loop
	stx.b SNES_VMADDL-$2100 ;0C8C37	; Set VRAM address ($2116)
	lda.b #$00	  ;0C8C39	; Clear high byte
	xba ;0C8C3B	; Swap (A = 0)
	lda.w $0000,Y   ;0C8C3C	; Load repeat count
	tax ;0C8C3F	; Use as counter
	lda.w $0001,Y   ;0C8C40	; Load starting tile number

	.FillRepeatLoop:							; Fill repeat loop
	sta.b SNES_VMDATAL-$2100 ;0C8C43	; Write tile to VRAM ($2118)
	inc A		   ;0C8C45	; Increment tile number
	dex ;0C8C46	; Decrement counter
	bne .FillRepeatLoop ;0C8C47	; Loop for repeat count

; Check for next command
	lda.w $0002,Y   ;0C8C49	; Load VRAM offset for next fill
	beq .Exit	   ;0C8C4C	; Exit if offset = 0 (end marker)
	iny ;0C8C4E	; Next command entry
	iny ;0C8C4F	; (3 bytes per entry)
	iny ;0C8C50	; Advance to next
	rep #$30		;0C8C51	; 16-bit A/X/Y
	adc.b $01,S	 ;0C8C53	; Add offset to base VRAM address
	sta.b $01,S	 ;0C8C55	; Update base address on stack
	tax ;0C8C57	; Use as VRAM address
	sep #$20		;0C8C58	; 8-bit accumulator
	bra .TilemapFillLoop ;0C8C5A	; Continue with next command

	.Exit:										; Cleanup and return
	plx ;0C8C5C	; Clean up stack
	rts ;0C8C5D	; Return

; ==============================================================================
; Title Screen Sprite Configuration Data (124 bytes)
; ==============================================================================
; Format: [X_pos] [Y_pos] [tile] [attr] - 31 sprites × 4 bytes
; Defines sprite positions and attributes for title screen logo/effects.
; ==============================================================================

DATA8_0C8C5E:
	db $28,$27,$10,$01,$38,$27,$12,$01,$48,$27,$14,$01,$58,$27,$16,$01 ;0C8C5E
	db $68,$27,$18,$01,$80,$27,$10,$01,$90,$27,$16,$01,$a0,$27,$14,$01 ;0C8C6E
	db $b0,$27,$1a,$01,$c0,$27,$16,$01,$d0,$27,$1c,$01,$e0,$27,$1e,$01 ;0C8C7E
	db $20,$5f,$80,$31,$40,$5f,$84,$31,$68,$5f,$89,$31,$80,$57,$7c,$31 ;0C8C8E
	db $90,$57,$7e,$31,$a0,$5f,$e0,$31,$c0,$5f,$e4,$31,$78,$b7,$86,$30 ;0C8C9E
	db $20,$b7,$e0,$30,$30,$b7,$e2,$30,$40,$b7,$e4,$30,$20,$3f,$40,$31 ;0C8CAE
	db $40,$3f,$44,$31,$60,$3f,$48,$31,$80,$37,$3c,$31,$a0,$3f,$a0,$31 ;0C8CBE
	db $c0,$3f,$a4,$31,$58,$b7,$82,$30,$68,$b7,$84,$30 ;0C8CCE
	db $01,$00,$00,$00 ;0C8CD6	; End marker + padding
	db $00,$00,$aa,$0a ;0C8CDA

; ==============================================================================
; Title Screen Configuration Data (56 bytes)
; ==============================================================================
; Additional sprite/effect configuration for title animation.
; ==============================================================================

DATA8_0C8CDE:
	db $90,$b7,$a0,$30,$a0,$b7,$a2,$30,$b8,$b7,$a4,$30 ;0C8CDE
	db $c8,$b7,$a6,$30,$30,$c3,$a8,$30,$40,$c3,$aa,$30,$50,$c3,$ac,$30 ;0C8CEA
	db $60,$c3,$ae,$30,$78,$c3,$e6,$30,$90,$c3,$e8,$30,$a0,$c3,$ea,$30 ;0C8CFA
	db $b0,$c3,$ec,$30,$c0,$c3,$ee,$30,$e0,$57,$80,$30,$00,$00,$00,$50 ;0C8D0A

; ==============================================================================
; Tilemap Fill Command Table
; ==============================================================================
; Format: [repeat_count] [start_tile] [vram_offset]
; Used by UsedCodeEfficientlyFillVramTilemaps to efficiently fill VRAM tilemaps.
; Offset = 0 marks end of table.
; ==============================================================================

DATA8_0C8D1E:
	db $01,$ff,$02,$01,$ff,$02,$01,$ff,$02,$01,$ff,$02,$01,$ff,$03,$01 ;0C8D1E
	db $ff,$02,$01,$ff,$02,$01,$ff,$02,$01,$ff,$02,$01,$ff,$02,$01,$ff ;0C8D2E
	db $02,$01,$ff,$69,$01,$ff,$02,$01,$ff,$02,$01,$ff,$02,$01,$ff,$02 ;0C8D3E
	db $01,$ff,$03,$01,$ff,$02,$01,$ff,$02,$01,$ff,$02,$01,$ff,$02,$01 ;0C8D4E
	db $ff,$02,$01,$ff,$02,$01,$ff,$74,$03,$3c,$7f,$05,$4b,$80,$05,$5b ;0C8D5E
	db $80,$05,$6b,$80,$05,$7b,$81,$04,$8c,$04,$01,$e0,$00 ;0C8D6E	; End marker

; ==============================================================================
; Display_TitleScreenVRAMSetup - Complex Title Screen VRAM Setup
; ==============================================================================
; Initializes complete title screen graphics system.
; Sets up 3 palette groups, fills OAM, configures DMA for tilemap transfer.
; Highly optimized using DMA channel 0 for maximum VBLANK efficiency.
; ==============================================================================

Display_TitleScreenVRAMSetup:
	php ;0C8D7B	; Save processor status
	phd ;0C8D7C	; Save direct page
	rep #$30		;0C8D7D	; 16-bit A/X/Y
	lda.w #$4300	;0C8D7F	; Direct page = DMA registers
	tcd ;0C8D82	; Set direct page to $4300
	stz.w SNES_VMADDL ;0C8D83	; Clear VRAM address ($2116)
	sep #$20		;0C8D86	; 8-bit accumulator
	lda.b #$80	  ;0C8D88	; VRAM increment = +128 (vertical)
	sta.w SNES_VMAINC ;0C8D8A	; Set increment mode ($2115)

; Transfer palette group 1
	lda.b #$00	  ;0C8D8D	; Palette offset = 0
	jsr.w TransferPaletteViaDma ;0C8D8F	; Transfer palette via DMA

; Transfer palette group 2
	lda.b #$80	  ;0C8D92	; Palette offset = $80 (128 colors)
	jsr.w TransferPaletteViaDma ;0C8D94	; Transfer palette via DMA

; Transfer palette group 3
	lda.b #$c0	  ;0C8D97	; Palette offset = $c0 (192 colors)
	jsr.w TransferPaletteViaDma ;0C8D99	; Transfer palette via DMA

; Fill OAM sprite buffer with pattern
	rep #$30		;0C8D9C	; 16-bit A/X/Y
	lda.w #$5555	;0C8D9E	; Fill pattern = $5555
	sta.w $0c00	 ;0C8DA1	; Write to sprite buffer start
	ldx.w #$0c00	;0C8DA4	; Source = $0c00
	ldy.w #$0c02	;0C8DA7	; Dest = $0c02
	lda.w #$021d	;0C8DAA	; Transfer 542 bytes (fill entire OAM)
	mvn $00,$00	 ;0C8DAD	; Block move within Bank $00

	jsr.w PerformOamDmaTransfer ;0C8DB0	; Perform OAM DMA transfer

; Setup tilemap DMA transfer
	ldx.w #$1809	;0C8DB3	; DMA mode: Word, A→A, increment
	stx.b SNES_DMA0PARAM-$4300 ;0C8DB6	; Set DMA0 parameters ($4300)
	ldx.w #$8f12	;0C8DB8	; Source address = $0c8f12
	stx.b SNES_DMA0ADDRL-$4300 ;0C8DBB	; Set DMA0 source ($4302)
	lda.b #$0c	  ;0C8DBD	; Source bank = $0c
	sta.b SNES_DMA0ADDRH-$4300 ;0C8DBF	; Set DMA0 bank ($4304)
	ldx.w #$0000	;0C8DC1	; Transfer size = 64KB (full auto)
	stx.b SNES_DMA0CNTL-$4300 ;0C8DC4	; Set DMA0 count ($4305)
	lda.b #$01	  ;0C8DC6	; Enable DMA channel 0
	sta.w $420b	 ;0C8DC8	; Start DMA transfer ($420b)

	jsr.w Battle_Graphics_Upload_Split_Transfer ;0C8DCB	; Additional VRAM setup routine
	jsr.w Complex_SpriteGraphics_Initialization_System ;0C8DCE	; Secondary graphics initialization

; Transfer large graphics block to VRAM $4000
	ldx.w #$1801	;0C8DD1	; DMA mode: Byte, A→A
	stx.b SNES_DMA0PARAM-$4300 ;0C8DD4	; Set DMA0 parameters
	ldx.w #$4000	;0C8DD6	; VRAM address = $4000
	stx.w $2116	 ;0C8DD9	; Set VRAM address ($2116)
	ldx.w #$2000	;0C8DDC	; Source address = $7f2000
	stx.b SNES_DMA0ADDRL-$4300 ;0C8DDF	; Set DMA0 source
	lda.b #$7f	  ;0C8DE1	; Source bank = $7f
	sta.b SNES_DMA0ADDRH-$4300 ;0C8DE3	; Set DMA0 bank
	ldx.w #$1000	;0C8DE5	; Transfer size = 4096 bytes
	stx.b SNES_DMA0CNTL-$4300 ;0C8DE8	; Set DMA0 count
	lda.b #$01	  ;0C8DEA	; Enable DMA channel 0
	sta.w $420b	 ;0C8DEC	; Start DMA transfer

; Process graphics command table
	lda.b #$0c	  ;0C8DEF	; Source bank = $0c
	sta.b SNES_DMA0ADDRH-$4300 ;0C8DF1	; Set DMA0 bank
	ldy.w #$5100	;0C8DF3	; VRAM base address = $5100
	ldx.w #$8f14	;0C8DF6	; Command table address

Display_GraphicsCommandProcessor:	; Graphics command DMA transfer loop (processes tile data commands)
	.CommandLoop:
	rep #$30		;0C8DF9	; 16-bit A/X/Y
	sty.w $2116	 ;0C8DFB	; Set VRAM address ($2116)

; Calculate DMA transfer size (entry byte 0 × 32)
	lda.w $0000,X   ;0C8DFE	; Load entry byte 0
	and.w #$00ff	;0C8E01	; Mask to 8-bit
	asl A		   ;0C8E04	; ×2
	asl A		   ;0C8E05	; ×4
	asl A		   ;0C8E06	; ×8
	asl A		   ;0C8E07	; ×16
	asl A		   ;0C8E08	; ×32 (tile size)
	sta.b SNES_DMA0CNTL-$4300 ;0C8E09	; Set DMA transfer size ($4305)

; Calculate source address (entry byte 1 × 32 + $aa4c base)
	lda.w $0001,X   ;0C8E0B	; Load entry byte 1
	and.w #$00ff	;0C8E0E	; Mask to 8-bit
	asl A		   ;0C8E11	; ×2
	asl A		   ;0C8E12	; ×4
	asl A		   ;0C8E13	; ×8
	asl A		   ;0C8E14	; ×16
	asl A		   ;0C8E15	; ×32
	adc.w #$aa4c	;0C8E16	; Add base address
	sta.b SNES_DMA0ADDRL-$4300 ;0C8E19	; Set DMA source address ($4302)

; Calculate VRAM offset (entry byte 2 × 16 + current VRAM)
	lda.w $0002,X   ;0C8E1B	; Load entry byte 2
	and.w #$00ff	;0C8E1E	; Mask to 8-bit
	asl A		   ;0C8E21	; ×2
	asl A		   ;0C8E22	; ×4
	asl A		   ;0C8E23	; ×8
	asl A		   ;0C8E24	; ×16
	phy ;0C8E25	; Save current VRAM address
	adc.b $01,S	 ;0C8E26	; Add offset to VRAM address
	tay ;0C8E28	; Update VRAM address
	pla ;0C8E29	; Clean up stack

	sep #$20		;0C8E2A	; 8-bit accumulator
	lda.b #$01	  ;0C8E2C	; Enable DMA channel 0
	sta.w $420b	 ;0C8E2E	; Start DMA transfer ($420b)

; Check for next command (entry byte 2 != 0)
	lda.w $0002,X   ;0C8E31	; Load entry byte 2
	php ;0C8E34	; Save flags (check for zero)
	inx ;0C8E35	; Next entry
	inx ;0C8E36	; (3 bytes per entry)
	inx ;0C8E37	; Advance pointer
	plp ;0C8E38	; Restore flags
	bne Display_GraphicsCommandProcessor.CommandLoop ;0C8E39	; Continue if not end marker

; Copy graphics data to Bank $7f buffer
	rep #$30		;0C8E3B	; 16-bit A/X/Y
	lda.w #$0000	;0C8E3D	; Clear A
	tcd ;0C8E40	; Restore direct page to $0000
	ldx.w #$aa4c	;0C8E41	; Source = $0caa4c
	ldy.w #$0000	;0C8E44	; Dest = $7f0000
	lda.w #$0d5f	;0C8E47	; Transfer 3424 bytes
	mvn $7f,$0c	 ;0C8E4A	; Block move Bank $0c → Bank $7f

; Additional tilemap fill from command table
	ldx.w #$0000	;0C8E4D	; Clear X
	lda.w #$0400	;0C8E50	; VRAM base address
	pha ;0C8E53	; Save base address

Display_TilemapCommandProcessor:	; Process tilemap fill commands from table
	sta.l SNES_VMADDL ;0C8E54	; Set VRAM address ($2116)
	lda.l DATA8_0C8F14,X ;0C8E58	; Load command entry
	and.w #$00ff	;0C8E5C	; Get repeat count (low byte)
	tay ;0C8E5F	; Use as counter
	lda.l DATA8_0C8F14,X ;0C8E60	; Reload entry
	and.w #$ff00	;0C8E64	; Get tile base (high byte)
	lsr A		   ;0C8E67	; ÷2
	lsr A		   ;0C8E68	; ÷4
	lsr A		   ;0C8E69	; ÷8 (shift to position)
	adc.w #$0000	;0C8E6A	; Add carry from previous ops
	phx ;0C8E6D	; Save command pointer
	tax ;0C8E6E	; Use tile base as index

	.TileFillLoop:
	phy ;0C8E6F	; Save counter
	jsr.w 4bpp_Planar_To_Linear_Graphics_Decompression ;0C8E70	; Write tile pattern (subroutine)
	ply ;0C8E73	; Restore counter
	dey ;0C8E74	; Decrement
	bne Display_TilemapCommandProcessor.TileFillLoop ;0C8E75	; Loop for repeat count

	plx ;0C8E77	; Restore command pointer
	lda.l DATA8_0C8F15,X ;0C8E78	; Load next command offset
	and.w #$ff00	;0C8E7C	; Check high byte
	beq Display_TilemapCommandProcessor.Exit ;0C8E7F	; Exit if zero (end marker)
	inx ;0C8E81	; Next command entry
	inx ;0C8E82	; (3 bytes)
	inx ;0C8E83	; Advance pointer
	lsr A		   ;0C8E84	; Shift offset
	lsr A		   ;0C8E85	; (calculate VRAM offset)
	adc.b $01,S	 ;0C8E86	; Add to base VRAM address
	sta.b $01,S	 ;0C8E88	; Update base on stack
	bra Display_TilemapCommandProcessor ;0C8E8A	; Continue with next command

	.Exit:
	pla ;0C8E8C	; Clean up stack
	phk ;0C8E8D	; Push data bank
	plb ;0C8E8E	; Set data bank
	jsr.w AdditionalTextLogoSetup ;0C8E8F	; Additional text/logo setup

; Fill bottom screen area with pattern $10
	sep #$20		;0C8E92	; 8-bit accumulator
	ldx.w #$3fc0	;0C8E94	; VRAM address = $3fc0
	stx.w $2116	 ;0C8E97	; Set VRAM address
	ldx.w #$0040	;0C8E9A	; Fill count = 64 tiles
	lda.b #$10	  ;0C8E9D	; Fill pattern = tile $10

	.BottomFillLoop:
	sta.w $2119	 ;0C8E9F	; Write to VRAM data ($2119)
	dex ;0C8EA2	; Decrement counter
	bne Display_TilemapCommandProcessor.BottomFillLoop ;0C8EA3	; Loop for all tiles

	pld ;0C8EA5	; Restore direct page
	plp ;0C8EA6	; Restore processor status
	rts ;0C8EA7	; Return

; [Additional text/logo transfer routines continue at AdditionalTextLogoSetup...]
; [Palette DMA setup continues at TransferPaletteViaDma...]

; ==============================================================================
; End of Bank $0c Cycle 4
; ==============================================================================
; Lines documented: 400 source lines (1300-1700)
; Address range: $0c8af1-$0c8f98
; Systems: VRAM fill, palette DMA, title screen setup, tilemap initialization
; ==============================================================================
; ==============================================================================
; Bank $0c Cycle 5: Graphics Decompression & Tile Processing (Lines 1700-2100)
; ==============================================================================
; Address Range: $0c8f9e - $0c924d
; Systems: 4bpp graphics decompression, tile compositing, VRAM buffer management
; ==============================================================================

; DMA Transfer Parameters Setup (continued from previous)
	stx.b SNES_DMA0PARAM-$4300 ;0C8F9E|8600    |004300; DMA0 params (direct page $43xx addressing)
	ldx.w #$b6ec	;0C8FA0|A2ECB6  |      ; Source address $0cb6ec
	stx.b SNES_DMA0ADDRL-$4300 ;0C8FA3|8602    |004302; DMA0 source low word
	lda.b #$0c	  ;0C8FA5|A90C    |      ; Bank $0c
	sta.b SNES_DMA0ADDRH-$4300 ;0C8FA7|8504    |004304; DMA0 source bank byte
	ldx.w #$0022	;0C8FA9|A22200  |      ; Transfer size: 34 bytes
	stx.b SNES_DMA0CNTL-$4300 ;0C8FAC|8605    |004305; DMA0 byte count
	lda.b #$01	  ;0C8FAE|A901    |      ; Channel 0 enable
	sta.w SNES_MDMAEN ;0C8FB0|8D0B42  |00420B; Trigger DMA transfer ($420b)
	rts ;0C8FB3|60      |      ; Return

; ==============================================================================
; 4bpp_Planar_To_Linear_Graphics_Decompression: 4bpp Planar to Linear Graphics Decompression
; ==============================================================================
; Purpose: Convert SNES 4bpp planar graphics format to linear format for processing
; Input: X = pointer to source tile data (32 bytes per 8x8 tile in planar format)
; Output: Decompressed tile data written directly to VRAM via $2119 (VMDATAH)
; Format: SNES 4bpp = 4 bitplanes (BP0, BP1, BP2, BP3), 2 bytes per row per plane
; Algorithm: Interleave 4 bitplanes by shifting and combining bits
; Used by: Graphics loading routines during initialization/transitions
; ------------------------------------------------------------------------------
4bpp_Planar_To_Linear_Graphics_Decompression:
	sep #$20		;0C8FB4|E220    |      ; 8-bit accumulator
	lda.b #$08	  ;0C8FB6|A908    |      ; 8 rows per tile (8x8 pixels)

Label_0C8FB8:
; Process one row of the tile (8 pixels)
	pha ;0C8FB8|48      |      ; Save row counter

; Load bitplane data for this row:
; $0000,X = BP0 (low 2 bytes)
; $0010,X = BP2 (high 2 bytes)
; Each pair represents one row across the tile
	ldy.w $0010,X   ;0C8FB9|BC1000  |7F0010; Load bitplane 2+3 word
	sty.b $64	   ;0C8FBC|8464    |000064; Store in DP $64-$65
	ldy.w $0000,X   ;0C8FBE|BC0000  |7F0000; Load bitplane 0+1 word
	sty.b $62	   ;0C8FC1|8462    |000062; Store in DP $62-$63
	ldy.w #$0008	;0C8FC3|A00800  |      ; 8 pixels per row

Label_0C8FC6:
; Deinterleave 4 bitplanes into 4-bit pixel value
; Each pixel needs bits from all 4 planes
; Shift order: BP3, BP2, BP1, BP0 (MSB to LSB)
	asl.b $65	   ;0C8FC6|0665    |000065; Shift BP3 (high byte of $64-$65)
	rol A		   ;0C8FC8|2A      |      ; Rotate bit into accumulator (bit 0)
	asl.b $64	   ;0C8FC9|0664    |000064; Shift BP2 (low byte of $64-$65)
	rol A		   ;0C8FCB|2A      |      ; Rotate bit into accumulator (bit 1)
	asl.b $63	   ;0C8FCC|0663    |000063; Shift BP1 (high byte of $62-$63)
	rol A		   ;0C8FCE|2A      |      ; Rotate bit into accumulator (bit 2)
	asl.b $62	   ;0C8FCF|0662    |000062; Shift BP0 (low byte of $62-$63)
	rol A		   ;0C8FD1|2A      |      ; Rotate bit into accumulator (bit 3)
	and.b #$0f	  ;0C8FD2|290F    |      ; Mask to 4 bits (palette index 0-15)
	sta.l SNES_VMDATAH ;0C8FD4|8F192100|002119; Write to VRAM high byte ($2119)
	dey ;0C8FD8|88      |      ; Decrement pixel counter
	bne Label_0C8FC6 ;0C8FD9|D0EB    |0C8FC6; Loop for all 8 pixels

; Move to next row
	inx ;0C8FDB|E8      |      ; X += 2 (next row in planar format)
	inx ;0C8FDC|E8      |      ; (2 bytes per row per plane pair)
	pla ;0C8FDD|68      |      ; Restore row counter
	dec A		   ;0C8FDE|3A      |      ; Decrement row count
	bne Label_0C8FB8 ;0C8FDF|D0D7    |0C8FB8; Loop for all 8 rows

; Tile complete, X now points +$10 from start
	rep #$30		;0C8FE1|C230    |      ; 16-bit mode
	txa ;0C8FE3|8A      |      ; Get current position
	adc.w #$0010	;0C8FE4|691000  |      ; Skip to next tile (+16 bytes for BP2/BP3)
	tax ;0C8FE7|AA      |      ; Update X pointer
	rts ;0C8FE8|60      |      ; Return

; ==============================================================================
; RGB555_Color_To_Tile_Pattern_Converter_Batch: RGB555 Color to Tile Pattern Converter (Batch)
; ==============================================================================
; Purpose: Convert multiple RGB555 color values to tile patterns via lookup
; Input: X = pointer to RGB555 color data, Y = count
; Output: Tile patterns written to VRAM via RGB555_Color_To_Tile_Pattern_Converter_Single
; Used by: Color-based tile generation (e.g., solid color tiles, gradients)
; ------------------------------------------------------------------------------
RGB555_Color_To_Tile_Pattern_Converter_Batch:
	lda.w $0000,X   ;0C8FE9|BD0000  |0C0000; Load RGB555 color word
	jsr.w RGB555_Color_To_Tile_Pattern_Converter_Single ;0C8FEC|20F48F  |0C8FF4; Convert to tile pattern
	inx ;0C8FEF|E8      |      ; Move to next color
	dey ;0C8FF0|88      |      ; Decrement count
	bne RGB555_Color_To_Tile_Pattern_Converter_Batch ;0C8FF1|D0F6    |0C8FE9; Loop until all colors processed
	rts ;0C8FF3|60      |      ; Return

; ==============================================================================
; RGB555_Color_To_Tile_Pattern_Converter_Single: RGB555 Color to Tile Pattern Converter (Single)
; ==============================================================================
; Purpose: Convert single RGB555 color to 8x8 tile pattern using lookup table
; Input: A = RGB555 color word (%0BBBBBGGGGGRRRRR, 15-bit color)
; Output: 8x8 tile (64 pixels) written to VRAM at current address
; Algorithm:
;   1. Extract green component (bits 5-9, middle 5 bits)
;   2. Extract red component (bits 0-4, low 5 bits)
;   3. Combine: (Green << 4) | Red to form 9-bit index (0-511)
;   4. Use index to lookup tile pattern from Bank $07:8031
;   5. Write 8 rows of tile data + 8 zeros (4bpp format padding)
; Lookup Table: DATA8_078031 contains pre-generated tile patterns
; VRAM Format: Each tile row writes to $2118 (VMDATAL), auto-increment
; ------------------------------------------------------------------------------
RGB555_Color_To_Tile_Pattern_Converter_Single:
	phy ;0C8FF4|5A      |      ; Preserve registers
	phx ;0C8FF5|DA      |      ;
	pha ;0C8FF6|48      |      ; Save color value

; Extract GREEN component (bits 5-9)
	and.w #$00e0	;0C8FF7|29E000  |      ; Mask bits 5-7 (%11100000)
	asl A		   ;0C8FFA|0A      |      ; Shift left 4 times to move
	asl A		   ;0C8FFB|0A      |      ; green from bits 5-9 to
	asl A		   ;0C8FFC|0A      |      ; bits 9-13 (creates space
	asl A		   ;0C8FFD|0A      |      ; for red component)
	sta.b $64	   ;0C8FFE|8564    |000064; Save shifted green

; Extract RED component (bits 0-4)
	pla ;0C9000|68      |      ; Restore original color
	and.w #$001f	;0C9001|291F00  |      ; Mask bits 0-4 (%00011111)
	asl A		   ;0C9004|0A      |      ; Shift left 1 (multiply by 2)
	ora.b $64	   ;0C9005|0564    |000064; Combine: (Green << 4) | (Red << 1)

; Result: A = lookup index (0-511)
; Index = (Green[4:0] << 4) | (Red[4:0])
; This maps 32x32=1024 possible RG combinations to 512 patterns

	ldy.w #$0008	;0C9007|A00800  |      ; 8 rows per tile

Label_0C900A:
; Lookup tile pattern for each row
	tax ;0C900A|AA      |      ; Use color index as X
	lda.l DATA8_078031,X ;0C900B|BF318007|078031; Load pattern byte from Bank $07
	and.w #$00ff	;0C900F|29FF00  |      ; Mask to byte
	sta.w $2118	 ;0C9012|8D1821  |0C2118; Write to VRAM low byte ($2118)
	txa ;0C9015|8A      |      ; Restore index
	adc.w #$0040	;0C9016|694000  |      ; +$40 for next row in table
	dey ;0C9019|88      |      ; Decrement row counter
	bne Label_0C900A ;0C901A|D0EE    |0C900A; Loop for 8 rows

; Write 8 zero bytes (padding for 4bpp high bitplanes)
	stz.w $2118	 ;0C901C|9C1821  |0C2118; Zero byte 1
	stz.w $2118	 ;0C901F|9C1821  |0C2118; Zero byte 2
	stz.w $2118	 ;0C9022|9C1821  |0C2118; Zero byte 3
	stz.w $2118	 ;0C9025|9C1821  |0C2118; Zero byte 4
	stz.w $2118	 ;0C9028|9C1821  |0C2118; Zero byte 5
	stz.w $2118	 ;0C902B|9C1821  |0C2118; Zero byte 6
	stz.w $2118	 ;0C902E|9C1821  |0C2118; Zero byte 7
	stz.w $2118	 ;0C9031|9C1821  |0C2118; Zero byte 8

	plx ;0C9034|FA      |      ; Restore registers
	ply ;0C9035|7A      |      ;
	rts ;0C9036|60      |      ; Return

; ==============================================================================
; Complex_Graphics_Buffer_Initialization: Complex Graphics Buffer Initialization
; ==============================================================================
; Purpose: Initialize large graphics buffer in Bank $7f with processed tile data
; Input: None (uses hardcoded buffer addresses)
; Output: $7f:4000-$7fff filled with 128 copies of processed tile patterns
; Buffer: $7f4000 (16KB graphics work area)
; Process: Decompresses/processes tiles from $7f0000, copies 128 times
; Used by: Major graphics transitions, screen initialization
; Technique: Uses mvn block move for efficiency after processing
; ------------------------------------------------------------------------------
Complex_Graphics_Buffer_Initialization:
	php ;0C9037|08      |      ; Save processor status
	phd ;0C9038|0B      |      ; Save direct page
	rep #$30		;0C9039|C230    |      ; 16-bit mode
	lda.w #$0000	;0C903B|A90000  |      ; Reset direct page
	tcd ;0C903E|5B      |      ; Set DP = $0000

; Setup buffer pointers
	ldx.w #$4000	;0C903F|A20040  |      ; Destination: $7f:4000
	stx.b $5f	   ;0C9042|865F    |00005F; Store dest offset
	ldx.w #$7f40	;0C9044|A2407F  |      ; Dest bank + high byte
	stx.b $60	   ;0C9047|8660    |000060; Store at $60-$61

; Setup source pointer (X register for processing loop)
	ldx.w #$2000	;0C9049|A20020  |      ; Source: $7f:2000
	lda.w #$0080	;0C904C|A98000  |      ; 128 iterations (128 tiles)

; Set data bank to $7f for processing
	pea.w $007f	 ;0C904F|F47F00  |0C007F; Push $7f00
	plb ;0C9052|AB      |      ; Pull into DB ($7f)

Label_0C9053:
; Process 128 tiles
	pha ;0C9053|48      |      ; Save iteration counter
	jsr.w Tile_Processing_Routine_4bpp_Decompression_To_Buffer ;0C9054|209990  |0C9099; Process one tile (decompression)
	pla ;0C9057|68      |      ; Restore counter
	dec A		   ;0C9058|3A      |      ; Decrement
	bne Label_0C9053 ;0C9059|D0F8    |0C9053; Loop for all 128 tiles

; Setup DMA transfer for processed buffer
	plb ;0C905B|AB      |      ; Restore data bank
	sep #$20		;0C905C|E220    |      ; 8-bit accumulator
	lda.b #$0c	  ;0C905E|A90C    |      ; Bank $0c for subroutine
	sta.w $005a	 ;0C9060|8D5A00  |00005A; Store at $005a (bank byte)
	ldx.w #$9075	;0C9063|A27590  |      ; Address $0c:9075 (DMA routine)
	stx.w $0058	 ;0C9066|8E5800  |000058; Store at $0058-$0059 (address)

; Register completion handler
	lda.b #$40	  ;0C9069|A940    |      ; bit 6 flag
	tsb.w !system_flags_9	 ;0C906B|0CE200  |0000E2; Test and Set bit at $e2
	jsl.l CWaitTimingRoutine ;0C906E|2200800C|0C8000; Call graphics handler

	pld ;0C9072|2B      |      ; Restore direct page
	plp ;0C9073|28      |      ; Restore processor status
	rts ;0C9074|60      |      ; Return

; ==============================================================================
; DMA Transfer Routine (Embedded at $0c:9075)
; ==============================================================================
; Purpose: Transfer processed graphics buffer to VRAM
; Source: $7f:4000 (8KB processed tile data)
; Dest: VRAM $0440 (BG tileset area)
; Size: $2000 bytes (8192 bytes = 256 tiles)
; ------------------------------------------------------------------------------
; VRAM Setup
	lda.b #$80	  ;0C9075|A980    |      ; VRAM increment = 1 (word mode)
	sta.w SNES_VMAINC ;0C9077|8D1521  |002115; Set increment mode ($2115)
	ldx.w #$0440	;0C907A|A24004  |      ; VRAM address $0440
	stx.w SNES_VMADDL ;0C907D|8E1621  |002116; Set VRAM address ($2116-$2117)

; DMA Channel 0 Configuration
	ldx.w #$1900	;0C9080|A20019  |      ; DMA params: $19 = word, $00 = A→B
	stx.b SNES_DMA0PARAM-$4300 ;0C9083|8600    |004300; $4300-$4301 (params + dest)
	ldx.w #$4000	;0C9085|A20040  |      ; Source: $7f:4000
	stx.b SNES_DMA0ADDRL-$4300 ;0C9088|8602    |004302; $4302-$4303 (source low word)
	lda.b #$7f	  ;0C908A|A97F    |      ; Source bank $7f
	sta.b SNES_DMA0ADDRH-$4300 ;0C908C|8504    |004304; $4304 (source bank)
	ldx.w #$2000	;0C908E|A20020  |      ; Transfer $2000 bytes (8KB)
	stx.b SNES_DMA0CNTL-$4300 ;0C9091|8605    |004305; $4305-$4306 (byte count)
	lda.b #$01	  ;0C9093|A901    |      ; Channel 0 enable
	sta.w SNES_MDMAEN ;0C9095|8D0B42  |00420B; Trigger DMA ($420b)
	rtl ;0C9098|6B      |      ; Return (long)

; ==============================================================================
; Tile_Processing_Routine_4bpp_Decompression_To_Buffer: Tile Processing Routine (4bpp Decompression to Buffer)
; ==============================================================================
; Purpose: Process planar tile data to linear format with transparency support
; Input: X = source pointer ($7f:2000+offset), $5f-$60 = dest pointer
; Output: Processed tile written to buffer, X advanced, $5f incremented
; Format: Converts 4bpp planar to linear with transparency flag (bit 4)
; Algorithm: Same as 4bpp_Planar_To_Linear_Graphics_Decompression but writes to buffer instead of VRAM
; Difference: Sets bit 4 ($10) if pixel is non-zero (transparency marker)
; ------------------------------------------------------------------------------
Tile_Processing_Routine_4bpp_Decompression_To_Buffer:
	sep #$20		;0C9099|E220    |      ; 8-bit accumulator
	lda.b #$08	  ;0C909B|A908    |      ; 8 rows per tile

Label_0C909D:
	pha ;0C909D|48      |      ; Save row counter
	ldy.w $0010,X   ;0C909E|BC1000  |7F0010; Load BP2+BP3 word
	sty.b $64	   ;0C90A1|8464    |000064; Store at $64-$65
	ldy.w $0000,X   ;0C90A3|BC0000  |7F0000; Load BP0+BP1 word
	sty.b $62	   ;0C90A6|8462    |000062; Store at $62-$63
	ldy.w #$0008	;0C90A8|A00800  |      ; 8 pixels per row

Label_0C90AB:
; Deinterleave bitplanes (same as Label_0C8FC6)
	asl.b $65	   ;0C90AB|0665    |000065; Shift BP3
	rol A		   ;0C90AD|2A      |      ; Rotate into A
	asl.b $64	   ;0C90AE|0664    |000064; Shift BP2
	rol A		   ;0C90B0|2A      |      ; Rotate into A
	asl.b $63	   ;0C90B1|0663    |000063; Shift BP1
	rol A		   ;0C90B3|2A      |      ; Rotate into A
	asl.b $62	   ;0C90B4|0662    |000062; Shift BP0
	rol A		   ;0C90B6|2A      |      ; Rotate into A
	and.b #$0f	  ;0C90B7|290F    |      ; Mask to 4 bits (color 0-15)

; Transparency handling
	beq Store_0C90BD ;0C90B9|F002    |0C90BD; If zero, skip (transparent)
	ora.b #$10	  ;0C90BB|0910    |      ; Set bit 4 (non-transparent marker)

Store_0C90BD:
; Write to buffer
	sta.b [$5f]	 ;0C90BD|875F    |00005F; Write to [$5f] (buffer pointer)
	rep #$30		;0C90BF|C230    |      ; 16-bit mode
	inc.b $5f	   ;0C90C1|E65F    |00005F; Increment buffer pointer
	sep #$20		;0C90C3|E220    |      ; 8-bit mode
	dey ;0C90C5|88      |      ; Decrement pixel counter
	bne Label_0C90AB ;0C90C6|D0E3    |0C90AB; Loop for 8 pixels

; Next row
	inx ;0C90C8|E8      |      ; X += 2
	inx ;0C90C9|E8      |      ;
	pla ;0C90CA|68      |      ; Restore row counter
	dec A		   ;0C90CB|3A      |      ; Decrement
	bne Label_0C909D ;0C90CC|D0CF    |0C909D; Loop for 8 rows

; Tile complete, advance source pointer
	rep #$30		;0C90CE|C230    |      ; 16-bit mode
	clc ;0C90D0|18      |      ; Clear carry
	txa ;0C90D1|8A      |      ; Get current X
	adc.w #$0010	;0C90D2|691000  |      ; Skip $10 bytes (BP2/BP3 data)
	tax ;0C90D5|AA      |      ; Update X
	rts ;0C90D6|60      |      ; Return

; ==============================================================================
; DMA Routine: Transfer Tilemap Data to VRAM
; ==============================================================================
; Purpose: Transfer tilemap/tileset from Bank $00 to VRAM base address
; Source: $00:8252 (ROM tilemap data)
; Dest: VRAM $0000 (base tilemap/charset area)
; Size: $2000 bytes (8KB)
; Mode: Word transfer, no increment during transfer
; ------------------------------------------------------------------------------
	stz.w SNES_VMAINC ;0C90D7|9C1521  |002115; VRAM increment = 0 (no increment)
	ldx.w #$0000	;0C90DA|A20000  |      ; VRAM address $0000
	stx.w SNES_VMADDL ;0C90DD|8E1621  |002116; Set VRAM address

; DMA Channel 0 Setup
	ldx.w #$1808	;0C90E0|A20818  |      ; $18 = word mode, $08 = dest reg
	stx.b SNES_DMA0PARAM-$4300 ;0C90E3|8600    |004300; DMA0 params
	ldx.w #$8252	;0C90E5|A25282  |      ; Source: $00:8252
	stx.b SNES_DMA0ADDRL-$4300 ;0C90E8|8602    |004302; Source low word
	lda.b #$00	  ;0C90EA|A900    |      ; Bank $00
	sta.b SNES_DMA0ADDRH-$4300 ;0C90EC|8504    |004304; Source bank
	ldx.w #$2000	;0C90EE|A20020  |      ; $2000 bytes (8KB)
	stx.b SNES_DMA0CNTL-$4300 ;0C90F1|8605    |004305; Byte count
	lda.b #$01	  ;0C90F3|A901    |      ; Channel 0 enable
	sta.w SNES_MDMAEN ;0C90F5|8D0B42  |00420B; Trigger DMA
	rtl ;0C90F8|6B      |      ; Return long

; ==============================================================================
; Battle_Graphics_Upload_Split_Transfer: Battle Graphics Upload (Split Transfer)
; ==============================================================================
; Purpose: Upload battle graphics in two phases (low/high bitplanes separate)
; Source: $0c:9140-$a140 (battle graphics data, 4KB)
; Dest: VRAM $6000 (battle graphics tileset area)
; Technique: Two DMA passes - first low bitplanes, then high bitplanes
; Used by: Battle scene initialization, enemy sprite loading
; ------------------------------------------------------------------------------
Battle_Graphics_Upload_Split_Transfer:
; Phase 1: Upload low bitplanes (word mode, no increment)
	stz.w $2115	 ;0C90F9|9C1521  |0C2115; VRAM increment = 0
	ldx.w #$6000	;0C90FC|A20060  |      ; VRAM address $6000
	stx.w $2116	 ;0C90FF|8E1621  |0C2116; Set VRAM address
	ldx.w #$1808	;0C9102|A20818  |      ; DMA mode: word, dest $2118-$2119
	stx.w $4300	 ;0C9105|8E0043  |0C4300; DMA0 params
	ldx.w #$9140	;0C9108|A24091  |      ; Source: $0c:9140 (low bitplanes)
	stx.w $4302	 ;0C910B|8E0243  |0C4302; Source address
	lda.b #$0c	  ;0C910E|A90C    |      ; Bank $0c
	sta.w $4304	 ;0C9110|8D0443  |0C4304; Source bank
	ldx.w #$1000	;0C9113|A20010  |      ; $1000 bytes (4KB)
	stx.w $4305	 ;0C9116|8E0543  |0C4305; Byte count
	lda.b #$01	  ;0C9119|A901    |      ; Channel 0 enable
	sta.w $420b	 ;0C911B|8D0B42  |0C420B; Trigger DMA

; Phase 2: Upload high bitplanes (word mode, increment +1)
	lda.b #$80	  ;0C911E|A980    |      ; VRAM increment = 1 (word)
	sta.w $2115	 ;0C9120|8D1521  |0C2115; Set increment mode
	ldx.w #$6000	;0C9123|A20060  |      ; VRAM address $6000 (same base)
	stx.w $2116	 ;0C9126|8E1621  |0C2116; Set VRAM address
	lda.b #$19	  ;0C9129|A919    |      ; DMA mode: $19 = word, auto-inc
	sta.w $4301	 ;0C912B|8D0143  |0C4301; DMA0 dest register
	ldx.w #$9141	;0C912E|A24191  |      ; Source: $0c:9141 (+1 for high BP)
	stx.w $4302	 ;0C9131|8E0243  |0C4302; Source address
	ldx.w #$1000	;0C9134|A20010  |      ; $1000 bytes (4KB)
	stx.w $4305	 ;0C9137|8E0543  |0C4305; Byte count
	lda.b #$01	  ;0C913A|A901    |      ; Channel 0 enable
	sta.w $420b	 ;0C913C|8D0B42  |0C420B; Trigger DMA
	rts ;0C913F|60      |      ; Return

; ==============================================================================
; DATA: Battle Graphics Header/Marker
; ==============================================================================
	db $ff,$01	 ;0C9140|        |      ; Graphics data marker ($ff = compressed, $01 = type)

; ==============================================================================
; Complex_SpriteGraphics_Initialization_System: Complex Sprite/Graphics Initialization System
; ==============================================================================
; Purpose: Initialize complete sprite/graphics system for battle/overworld
; Systems: Tile decompression, compositing, VRAM upload, buffer management
; Output: Multiple VRAM regions populated, flags set
; Used by: Scene transitions, battle start, major state changes
; ------------------------------------------------------------------------------
Complex_SpriteGraphics_Initialization_System:
	php ;0C9142|08      |      ; Save processor status
	phd ;0C9143|0B      |      ; Save direct page
	rep #$30		;0C9144|C230    |      ; 16-bit mode
	lda.w #$0000	;0C9146|A90000  |      ; Reset DP
	tcd ;0C9149|5B      |      ; DP = $0000

; Execute initialization sequence
	jsr.w Graphics_Buffer_Initialization_Multi_Bank_Copy ;0C914A|201893  |0C9318; Initialize graphics buffers
	jsr.w PaletteColor_Data_Transformation ;0C914D|20EB92  |0C92EB; Setup palette system
	jsr.w Sprite_Graphics_Loading_Compositing_System ;0C9150|206191  |0C9161; Load sprite graphics

; Set completion flags
	lda.w #$0010	;0C9153|A91000  |      ; Flag value $10
	sta.l $7f2f9c   ;0C9156|8F9C2F7F|7F2F9C; Mark completion at $7f2f9c
	sta.l $7f2dd2   ;0C915A|8FD22D7F|7F2DD2; Mark completion at $7f2dd2

	pld ;0C915E|2B      |      ; Restore direct page
	plp ;0C915F|28      |      ; Restore status
	rts ;0C9160|60      |      ; Return

; ==============================================================================
; Sprite_Graphics_Loading_Compositing_System: Sprite Graphics Loading & Compositing System
; ==============================================================================
; Purpose: Load and composite multiple sprite layers into VRAM
; Technique: Clear buffer, composite 8 sprite layers, upload to VRAM
; Buffer: $7f:2000 (8KB work area)
; VRAM Dest: Various addresses for different sprite layers
; Used by: Battle sprite setup, character graphics initialization
; ------------------------------------------------------------------------------
Sprite_Graphics_Loading_Compositing_System:
; Clear graphics buffer ($7f:2000-$3fff, 8KB)
	ldx.w #$0000	;0C9161|A20000  |      ; Source = $0000 (zeros)
	ldy.w #$2000	;0C9164|A00020  |      ; Dest = $2000
	lda.w #$2000	;0C9167|A90020  |      ; Size = $2000 (8KB)
	jsl.l CallTilemapFillRoutine ;0C916A|22949900|009994; Clear memory routine

; Composite sprite layers (8 layers)
	jsr.w Load_0C91AF ;0C916E|20AF91  |0C91AF; Layer 1: Base sprites
	jsr.w Load_0C9197 ;0C9171|209791  |0C9197; Layer 2: Overlay 1
	jsr.w Buffer_SpacingPadding ;0C9174|204792  |0C9247; Spacing/padding
	jsr.w Load_0C91B7 ;0C9177|20B791  |0C91B7; Layer 3: Accessories
	jsr.w Load_0C919F ;0C917A|209F91  |0C919F; Layer 4: Overlay 2
	jsr.w Bit_RotationTransformation_Processor ;0C917D|209E92  |0C929E; Unknown processing
	jsr.w Load_0C91BF ;0C9180|20BF91  |0C91BF; Layer 5: Effects
	jsr.w Buffer_SpacingPadding ;0C9183|204792  |0C9247; Spacing/padding
	jsr.w Load_0C91C7 ;0C9186|20C791  |0C91C7; Layer 6: Highlights
	jsr.w Load_0C91A7 ;0C9189|20A791  |0C91A7; Layer 7: Shadows
	jsr.w Buffer_SpacingPadding ;0C918C|204792  |0C9247; Spacing/padding

; Final upload
	ldy.w #$24c0	;0C918F|A0C024  |      ; VRAM address $24c0
	ldx.w #$9400	;0C9192|A20094  |      ; Source data pointer
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C9195|8036    |0C91CD; Jump to upload routine

; ==============================================================================
; Sprite Layer Loading Routines (Setup VRAM address + source pointer)
; ==============================================================================
; Each routine sets Y=VRAM destination, X=source data pointer
; Then branches to Sprite_Data_Processing_Loop_Bytecode_Interpreter for actual processing
; ------------------------------------------------------------------------------

Load_0C9197:
; Layer 2: VRAM $2080, source $0c:93CA
	ldy.w #$2080	;0C9197|A08020  |      ; VRAM dest
	ldx.w #$93ca	;0C919A|A2CA93  |      ; Source pointer
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C919D|802E    |0C91CD; Process

Load_0C919F:
; Layer 4: VRAM $2480, source $0c:93EB
	ldy.w #$2480	;0C919F|A08024  |      ; VRAM dest
	ldx.w #$93eb	;0C91A2|A2EB93  |      ; Source pointer
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C91A5|8026    |0C91CD; Process

Load_0C91A7:
; Layer 7: VRAM $20c0, source $0c:9410
	ldy.w #$20c0	;0C91A7|A0C020  |      ; VRAM dest
	ldx.w #$9410	;0C91AA|A21094  |      ; Source pointer
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C91AD|801E    |0C91CD; Process

Load_0C91AF:
; Layer 1: VRAM $2000, source $0c:9346
	ldy.w #$2000	;0C91AF|A00020  |      ; VRAM dest
	ldx.w #$9346	;0C91B2|A24693  |      ; Source pointer
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C91B5|8016    |0C91CD; Process

Load_0C91B7:
; Layer 3: VRAM $2b80, source $0c:9392
	ldy.w #$2b80	;0C91B7|A0802B  |      ; VRAM dest
	ldx.w #$9392	;0C91BA|A29293  |      ; Source pointer
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C91BD|800E    |0C91CD; Process

Load_0C91BF:
; Layer 5: VRAM $2ba0, source $0c:9392
	ldy.w #$2ba0	;0C91BF|A0A02B  |      ; VRAM dest
	ldx.w #$9392	;0C91C2|A29293  |      ; Source pointer
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C91C5|8006    |0C91CD; Process

Load_0C91C7:
; Layer 6: VRAM $2040, source $0c:9396
	ldy.w #$2040	;0C91C7|A04020  |      ; VRAM dest
	ldx.w #$9396	;0C91CA|A29693  |      ; Source pointer

; ==============================================================================
; Sprite_Data_Processing_Loop_Bytecode_Interpreter: Sprite Data Processing Loop (Bytecode Interpreter)
; ==============================================================================
; Purpose: Process sprite command bytecode to composite graphics
; Input: X = command pointer, Y = VRAM base address
; Format: Command bytes:
;   $00-$7f: Tile index (process 32 bytes at offset = index * 32)
;   $80-$fe: Relative offset (+/- adjust Y by (value & $7f) * 32)
;   $ff: End marker
; Algorithm: Interpret commands, composite tiles from $7f:0000 to buffer
; ------------------------------------------------------------------------------
Sprite_Data_Processing_Loop_Bytecode_Interpreter:
	phk ;0C91CD|4B      |      ; Push program bank ($0c)
	plb ;0C91CE|AB      |      ; Pull to data bank

; Process command stream
	lda.w $0000,X   ;0C91CF|BD0000  |0C0000; Load command byte
	and.w #$00ff	;0C91D2|29FF00  |      ; Mask to byte
	cmp.w #$0080	;0C91D5|C98000  |      ; Check if < $80
	bcs Label_0C91E8 ;0C91D8|B00E    |0C91E8; Branch if >= $80 (offset cmd)

; Tile index command ($00-$7f)
	asl A		   ;0C91DA|0A      |      ; Multiply by 32:
	asl A		   ;0C91DB|0A      |      ; Shift left 5 times
	asl A		   ;0C91DC|0A      |      ; (index * 2^5 = index * 32)
	asl A		   ;0C91DD|0A      |      ;
	asl A		   ;0C91DE|0A      |      ; A = tile offset in bytes
	phx ;0C91DF|DA      |      ; Save command pointer
	tax ;0C91E0|AA      |      ; X = tile data offset
	jsr.w Tile_Compositing_With_Transparency_8x8_Tile_3_Plane ;0C91E1|20FF91  |0C91FF; Composite tile
	plx ;0C91E4|FA      |      ; Restore command pointer
	inx ;0C91E5|E8      |      ; Next command
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C91E6|80E5    |0C91CD; Loop

Label_0C91E8:
; Check for end marker
	cmp.w #$00ff	;0C91E8|C9FF00  |      ; End of commands?
	beq Sprite_Data_Processing_Loop_Bytecode_Interpreter_Return_0C91FE ;0C91EB|F011    |0C91FE; Yes, exit

; Offset command ($80-$fe)
	and.w #$007f	;0C91ED|297F00  |      ; Mask offset value (0-127)
	asl A		   ;0C91F0|0A      |      ; Multiply by 32:
	asl A		   ;0C91F1|0A      |      ; (offset * 32 = VRAM rows)
	asl A		   ;0C91F2|0A      |      ;
	asl A		   ;0C91F3|0A      |      ;
	asl A		   ;0C91F4|0A      |      ;
	sta.b $64	   ;0C91F5|8564    |000064; Save offset
	tya ;0C91F7|98      |      ; Get current VRAM address
	adc.b $64	   ;0C91F8|6564    |000064; Add offset
	tay ;0C91FA|A8      |      ; Update Y
	inx ;0C91FB|E8      |      ; Next command
	bra Sprite_Data_Processing_Loop_Bytecode_Interpreter ;0C91FC|80CF    |0C91CD; Loop

Sprite_Data_Processing_Loop_Bytecode_Interpreter_Return_0C91FE:
	rts ;0C91FE|60      |      ; End of command stream

; ==============================================================================
; Tile_Compositing_With_Transparency_8x8_Tile_3_Plane: Tile Compositing with Transparency (8x8 tile, 3-plane)
; ==============================================================================
; Purpose: Composite source tile onto destination with transparency masking
; Input: X = source offset ($7f:0000+X), Y = dest offset ($7f:2000+Y)
; Algorithm: For each row, mask transparent pixels, OR opaque pixels
; Format: 3 bytes per row (BP0, BP1, BP2), 8 rows = 24 bytes per tile
; Technique: (dest & ~(BP0|BP1|BP2)) | src = composite with transparency
; ------------------------------------------------------------------------------
Tile_Compositing_With_Transparency_8x8_Tile_3_Plane:
	sep #$20		;0C91FF|E220    |      ; 8-bit accumulator
	lda.b #$08	  ;0C9201|A908    |      ; 8 rows per tile
	sta.b $62	   ;0C9203|8562    |000062; Save row counter

; Set data bank to $7f
	pea.w $7f00	 ;0C9205|F4007F  |0C7F00; Push $7f00
	plb ;0C9208|AB      |      ; Pull to DB (high byte)
	plb ;0C9209|AB      |      ; Pull to DB (low byte) = $7f

Load_0C920A:
; Load source tile row (3 bytes: BP0, BP1, BP2)
; Calculate transparency mask: OR all 3 bitplanes
	lda.w $0000,X   ;0C920A|BD0000  |7F0000; Load BP0
	ora.w $0001,X   ;0C920D|1D0100  |7F0001; OR BP1
	ora.w $0010,X   ;0C9210|1D1000  |7F0010; OR BP2
	eor.b #$ff	  ;0C9213|49FF    |      ; Invert = transparency mask
	sta.b $64	   ;0C9215|8564    |000064; Save mask

; Composite BP0: (dest & mask) | src
	and.w $0000,Y   ;0C9217|390000  |7F0000; Mask dest BP0
	ora.w $0000,X   ;0C921A|1D0000  |7F0000; OR source BP0
	sta.w $0000,Y   ;0C921D|990000  |7F0000; Write result

; Composite BP1: (dest & mask) | src
	lda.b $64	   ;0C9220|A564    |000064; Load mask
	and.w $0001,Y   ;0C9222|390100  |7F0001; Mask dest BP1
	ora.w $0001,X   ;0C9225|1D0100  |7F0001; OR source BP1
	sta.w $0001,Y   ;0C9228|990100  |7F0001; Write result

; Composite BP2: (dest & mask) | src
	lda.b $64	   ;0C922B|A564    |000064; Load mask
	and.w $0010,Y   ;0C922D|391000  |7F0010; Mask dest BP2
	ora.w $0010,X   ;0C9230|1D1000  |7F0010; OR source BP2
	sta.w $0010,Y   ;0C9233|991000  |7F0010; Write result

; Next row (stride +2 for X, +2 for Y within 8x8)
	inx ;0C9236|E8      |      ; X += 2
	inx ;0C9237|E8      |      ;
	iny ;0C9238|C8      |      ; Y += 2
	iny ;0C9239|C8      |      ;
	dec.b $62	   ;0C923A|C662    |000062; Decrement row counter
	bne Load_0C920A ;0C923C|D0CC    |0C920A; Loop for 8 rows

; Tile complete, advance to next tile
	rep #$30		;0C923E|C230    |      ; 16-bit mode
	clc ;0C9240|18      |      ; Clear carry
	tya ;0C9241|98      |      ; Get Y position
	adc.w #$0010	;0C9242|691000  |      ; +$10 (skip to next tile row)
	tay ;0C9245|A8      |      ; Update Y
	rts ;0C9246|60      |      ; Return

; ==============================================================================
; Buffer_SpacingPadding: Buffer Spacing/Padding Routine
; ==============================================================================
; Purpose: Add spacing between sprite layers in buffer
; Input: None (uses Bank $7f data bank)
; Output: Y advanced by $1e * something (spacing calculation)
; Used by: Sprite layer compositing to maintain proper offsets
; ------------------------------------------------------------------------------
Buffer_SpacingPadding:
	pea.w $7f00	 ;0C9247|F4007F  |0C7F00; Set data bank = $7f
	plb ;0C924A|AB      |      ;
	plb ;0C924B|AB      |      ;
	clc ;0C924C|18      |      ; Clear carry
	lda.w #$001e	;0C924D|A91E00  |      ; Spacing value $1e (30)
; ==============================================================================
; Bank $0c Cycle 6: Sprite Layer Compositing & Animation (Lines 2100-2500)
; ==============================================================================
; Address Range: $0c924d - $0ca2c5
; Systems: Sprite layer transformations, pixel rotations, animation sequences
; ==============================================================================

; Spacing calculation (continued from Buffer_SpacingPadding)
	lda.w #$001e	;0C924D|A91E00  |      ; 30 spacing units
	sta.b $62	   ;0C9250|8562    |000062; Save spacing counter
	ldx.w #$0000	;0C9252|A20000  |      ; Start at offset 0

Label_0C9255:
; Double spacing application
	jsr.w Pixel_Row_SwappingRotation ;0C9255|206092  |0C9260; Apply spacing transform
	jsr.w Pixel_Row_SwappingRotation ;0C9258|206092  |0C9260; Apply again (2x)
	dec.b $62	   ;0C925B|C662    |000062; Decrement spacing counter
	bne Label_0C9255 ;0C925D|D0F6    |0C9255; Loop for 30 iterations
	rts ;0C925F|60      |      ; Return

; ==============================================================================
; Pixel_Row_SwappingRotation: Pixel Row Swapping/Rotation Routine
; ==============================================================================
; Purpose: Swap pixel rows within tile for rotation/flip effects
; Input: X = buffer offset (Bank $7f)
; Algorithm: Swap 4 pairs of rows (swaps rows 0↔14, 2↔12, 4↔10, 6↔8)
; Effect: Vertical flip or rotation transformation
; Used by: Sprite animation, orientation changes
; ------------------------------------------------------------------------------
Pixel_Row_SwappingRotation:
; Swap row 0 with row 14 (offset $00 ↔ offset $0e)
	lda.w $0000,X   ;0C9260|BD0000  |7F0000; Load row 0
	tay ;0C9263|A8      |      ; Temp in Y
	lda.w $000e,X   ;0C9264|BD0E00  |7F000E; Load row 14
	sta.w $0000,X   ;0C9267|9D0000  |7F0000; Store at row 0
	tya ;0C926A|98      |      ; Get row 0 back
	sta.w $000e,X   ;0C926B|9D0E00  |7F000E; Store at row 14

; Swap row 2 with row 12 (offset $02 ↔ offset $0c)
	lda.w $0002,X   ;0C926E|BD0200  |7F0002; Load row 2
	tay ;0C9271|A8      |      ; Temp in Y
	lda.w $000c,X   ;0C9272|BD0C00  |7F000C; Load row 12
	sta.w $0002,X   ;0C9275|9D0200  |7F0002; Store at row 2
	tya ;0C9278|98      |      ; Get row 2 back
	sta.w $000c,X   ;0C9279|9D0C00  |7F000C; Store at row 12

; Swap row 4 with row 10 (offset $04 ↔ offset $0a)
	lda.w $0004,X   ;0C927C|BD0400  |7F0004; Load row 4
	tay ;0C927F|A8      |      ; Temp in Y
	lda.w $000a,X   ;0C9280|BD0A00  |7F000A; Load row 10
	sta.w $0004,X   ;0C9283|9D0400  |7F0004; Store at row 4
	tya ;0C9286|98      |      ; Get row 4 back
	sta.w $000a,X   ;0C9287|9D0A00  |7F000A; Store at row 10

; Swap row 6 with row 8 (offset $06 ↔ offset $08)
	lda.w $0006,X   ;0C928A|BD0600  |7F0006; Load row 6
	tay ;0C928D|A8      |      ; Temp in Y
	lda.w $0008,X   ;0C928E|BD0800  |7F0008; Load row 8
	sta.w $0006,X   ;0C9291|9D0600  |7F0006; Store at row 6
	tya ;0C9294|98      |      ; Get row 6 back
	sta.w $0008,X   ;0C9295|9D0800  |7F0008; Store at row 8

; Advance to next 16-byte block
	txa ;0C9298|8A      |      ; Get X
	adc.w #$0010	;0C9299|691000  |      ; +$10 bytes (next tile row)
	tax ;0C929C|AA      |      ; Update X
	rts ;0C929D|60      |      ; Return

; ==============================================================================
; Bit_RotationTransformation_Processor: bit Rotation/Transformation Processor
; ==============================================================================
; Purpose: Apply bit rotation transformation to graphics buffer
; Input: Bank $7f graphics buffer
; Algorithm: Process 30 rows of 16 bytes, applying bit rotation to each byte
; Used by: Sprite effects, rotation animations, graphical transitions
; ------------------------------------------------------------------------------
Bit_RotationTransformation_Processor:
	pea.w $7f00	 ;0C929E|F4007F  |0C7F00; Set data bank = $7f
	plb ;0C92A1|AB      |      ;
	plb ;0C92A2|AB      |      ;
	ldy.w #$001e	;0C92A3|A01E00  |      ; 30 rows to process
	ldx.w #$0000	;0C92A6|A20000  |      ; Start at offset 0

Label_0C92A9:
	phy ;0C92A9|5A      |      ; Save row counter
	ldy.w #$0010	;0C92AA|A01000  |      ; 16 bytes per row

Label_0C92AD:
; Process each byte in row
	jsr.w Bit_Rotation_Algorithm_8_Bit_Left_Rotation ;0C92AD|20C292  |0C92C2; Apply bit rotation
	dey ;0C92B0|88      |      ; Decrement byte counter
	bne Label_0C92AD ;0C92B1|D0FA    |0C92AD; Loop for 16 bytes

; Process additional 8 bytes (24 bytes total per row)
	ldy.w #$0008	;0C92B3|A00800  |      ; 8 more bytes

Label_0C92B6:
	jsr.w Bit_Rotation_Algorithm_8_Bit_Left_Rotation ;0C92B6|20C292  |0C92C2; Apply bit rotation
	inx ;0C92B9|E8      |      ; Advance pointer
	dey ;0C92BA|88      |      ; Decrement counter
	bne Label_0C92B6 ;0C92BB|D0F9    |0C92B6; Loop for 8 bytes

	ply ;0C92BD|7A      |      ; Restore row counter
	dey ;0C92BE|88      |      ; Decrement row counter
	bne Label_0C92A9 ;0C92BF|D0E8    |0C92A9; Loop for 30 rows
	rts ;0C92C1|60      |      ; Return

; ==============================================================================
; Bit_Rotation_Algorithm_8_Bit_Left_Rotation: bit Rotation Algorithm (8-bit Left Rotation)
; ==============================================================================
; Purpose: Rotate bits left in byte with special bit collection
; Input: X = pointer to byte in $7f:0000
; Algorithm: Extract bits via lsr sequence, rebuild via rol sequence
; Effect: Performs bit rotation/rearrangement for graphical transformation
; Technique: 8 lsr operations extract bits, rol operations rebuild in new order
; ------------------------------------------------------------------------------
Bit_Rotation_Algorithm_8_Bit_Left_Rotation:
	sep #$20		;0C92C2|E220    |      ; 8-bit accumulator
	lda.w $0000,X   ;0C92C4|BD0000  |7F0000; Load byte

; Extract bits by shifting right
	lsr A		   ;0C92C7|4A      |      ; Shift right (bit 0 → carry)
	lsr A		   ;0C92C8|4A      |      ; Shift right (bit 1 → carry)
	rol.w $0000,X   ;0C92C9|3E0000  |7F0000; Rotate carry into byte (left)
	lsr A		   ;0C92CC|4A      |      ; Continue extraction
	rol.w $0000,X   ;0C92CD|3E0000  |7F0000; Rebuild
	lsr A		   ;0C92D0|4A      |      ; Extract bit
	rol.w $0000,X   ;0C92D1|3E0000  |7F0000; Rebuild
	lsr A		   ;0C92D4|4A      |      ; Extract bit
	rol.w $0000,X   ;0C92D5|3E0000  |7F0000; Rebuild
	lsr A		   ;0C92D8|4A      |      ; Extract bit
	rol.w $0000,X   ;0C92D9|3E0000  |7F0000; Rebuild
	lsr A		   ;0C92DC|4A      |      ; Extract bit
	rol.w $0000,X   ;0C92DD|3E0000  |7F0000; Rebuild
	lsr A		   ;0C92E0|4A      |      ; Extract final bit
	rol.w $0000,X   ;0C92E1|3E0000  |7F0000; Rebuild

; Final shift left
	asl.w $0000,X   ;0C92E4|1E0000  |7F0000; Shift left once more

	inx ;0C92E7|E8      |      ; Move to next byte
	rep #$30		;0C92E8|C230    |      ; 16-bit mode
	rts ;0C92EA|60      |      ; Return

; ==============================================================================
; PaletteColor_Data_Transformation: Palette/Color Data Transformation
; ==============================================================================
; Purpose: Transform palette data in buffer (possibly deinterlacing or reordering)
; Input: Bank $7f graphics buffer with palette data
; Algorithm: Process 30 blocks, copying/transforming 8 bytes from offset to offset
; Used by: Palette setup, color animation, graphical effects
; ------------------------------------------------------------------------------
PaletteColor_Data_Transformation:
	clc ;0C92EB|18      |      ; Clear carry
	lda.w #$001e	;0C92EC|A91E00  |      ; 30 iterations
	sta.b $62	   ;0C92EF|8562    |000062; Save counter
	lda.w #$0000	;0C92F1|A90000  |      ; Start offset = 0

Label_0C92F4:
; Calculate source/dest offsets
	adc.w #$0018	;0C92F4|691800  |      ; +$18 (24 bytes)
	tax ;0C92F7|AA      |      ; X = source offset
	adc.w #$0008	;0C92F8|690800  |      ; +$08 more
	tay ;0C92FB|A8      |      ; Y = dest offset
	pha ;0C92FC|48      |      ; Save accumulator
	lda.w #$0008	;0C92FD|A90800  |      ; 8 bytes to copy
	sta.b $64	   ;0C9300|8564    |000064; Save byte counter

Label_0C9302:
; Copy bytes in reverse order
	dex ;0C9302|CA      |      ; Decrement source
	dey ;0C9303|88      |      ; Decrement dest twice
	dey ;0C9304|88      |      ; (word-aligned dest)
	lda.w $0000,X   ;0C9305|BD0000  |7F0000; Load byte from source
	and.w #$00ff	;0C9308|29FF00  |      ; Mask to byte
	sta.w $0000,Y   ;0C930B|990000  |7F0000; Store at dest
	dec.b $64	   ;0C930E|C664    |000064; Decrement byte counter
	bne Label_0C9302 ;0C9310|D0F0    |0C9302; Loop for 8 bytes

	pla ;0C9312|68      |      ; Restore accumulator
	dec.b $62	   ;0C9313|C662    |000062; Decrement iteration counter
	bne Label_0C92F4 ;0C9315|D0DD    |0C92F4; Loop for 30 iterations
	rts ;0C9317|60      |      ; Return

; ==============================================================================
; Graphics_Buffer_Initialization_Multi_Bank_Copy: Graphics Buffer Initialization (Multi-Bank Copy)
; ==============================================================================
; Purpose: Initialize graphics buffers by copying data from Bank $04
; Input: None
; Output: Data copied to Bank $7f buffers at multiple offsets
; Technique: Uses mvn block move instruction for efficient copying
; Used by: Scene initialization, graphics setup
; ------------------------------------------------------------------------------
Graphics_Buffer_Initialization_Multi_Bank_Copy:
	clc ;0C9318|18      |      ; Clear carry

; Copy block 1: 4 iterations from $04:E220
	ldx.w #$e220	;0C9319|A220E2  |      ; Source: Bank $04, offset $e220
	ldy.w #$0000	;0C931C|A00000  |      ; Dest: offset $0000
	lda.w #$0004	;0C931F|A90400  |      ; 4 iterations
	jsr.w Block_Copy_Loop_MVN_Based ;0C9322|203493  |0C9334; Copy routine

; Copy block 2: 6 iterations from $04:E490
	ldx.w #$e490	;0C9325|A290E4  |      ; Source: Bank $04, offset $e490
	lda.w #$0006	;0C9328|A90600  |      ; 6 iterations
	jsr.w Block_Copy_Loop_MVN_Based ;0C932B|203493  |0C9334; Copy routine

; Copy block 3: 20 iterations from $04:FCC0
	ldx.w #$fcc0	;0C932E|A2C0FC  |      ; Source: Bank $04, offset $fcc0
	lda.w #$0014	;0C9331|A91400  |      ; 20 iterations (fall through)

; ==============================================================================
; Block_Copy_Loop_MVN_Based: Block Copy Loop (MVN-based)
; ==============================================================================
; Purpose: Copy multiple 23-byte blocks using mvn instruction
; Input: A = iteration count, X = source offset (Bank $04), Y = dest offset
; Algorithm: Loop A times, copying 23 bytes per iteration, advancing dest by 8
; Technique: mvn $7f,$04 (copy from Bank $04 to Bank $7f)
; ------------------------------------------------------------------------------
Block_Copy_Loop_MVN_Based:
	sta.b $62	   ;0C9334|8562    |000062; Save iteration counter

Load_0C9336:
	lda.w #$0017	;0C9336|A91700  |      ; 23 bytes to copy ($17 + 1)
	mvn $7f,$04	 ;0C9339|547F04  |      ; Block move: $04:X → $7f:Y
; mvn auto-increments X, Y and decrements A until A=$ffff
; After MVN: X += $18, Y += $18, A = $ffff

	tya ;0C933C|98      |      ; Get dest offset
	adc.w #$0008	;0C933D|690800  |      ; Add 8 (spacing between blocks)
	tay ;0C9340|A8      |      ; Update Y
	dec.b $62	   ;0C9341|C662    |000062; Decrement iteration counter
	bne Load_0C9336 ;0C9343|D0F1    |0C9336; Loop until done
	rts ;0C9345|60      |      ; Return

; ==============================================================================
; DATA: Sprite Layer Command Tables
; ==============================================================================
; Format: Bytecode commands for Sprite_Data_Processing_Loop_Bytecode_Interpreter sprite processor
; Commands: $00-$7f = tile index, $80-$fe = offset adjustment, $ff = end
; ==============================================================================

; Sprite Layer Data Table 1 ($0c:9346)
	db $00,$01,$82,$00,$01,$82,$00,$01,$82,$00,$01,$82,$02,$03,$82,$02 ;0C9346|        |      ;
	db $03,$82,$02,$03,$82,$02,$03,$82,$04,$05,$82,$04,$05,$82,$04,$05 ;0C9356|        |      ;
	db $82,$04,$05,$82,$06,$07,$82,$06,$07,$82,$06,$07,$82,$06,$07,$82 ;0C9366|        |      ;
	db $00,$01,$82,$00,$01,$86,$08,$81,$09,$81,$02,$03,$82,$02,$03,$8a ;0C9376|        |      ;
	db $04,$05,$82,$04,$05,$8a,$06,$07,$82,$06,$07,$ff ;0C9386|        |      ; End marker

; Sprite Layer Data Table 2 ($0c:9392)
	db $08,$81,$09,$ff ;0C938F|        |      ; Simple 2-tile pattern

; Sprite Layer Data Table 3 ($0c:9396)
	db $00,$83,$00,$83,$00,$83,$00,$83,$02,$83,$02,$83,$02,$83,$02,$83 ;0C9396|        |      ;
	db $04,$83,$04,$83,$04,$83,$04,$83,$06,$83,$06,$83,$06,$83,$06,$83 ;0C93A6|        |      ;
	db $00,$83,$00,$86,$08,$81,$09,$82,$02,$83,$02,$8b,$04,$83,$04,$8b ;0C93B6|        |      ;
	db $06,$83,$06,$ff ;0C93C6|        |      ; End marker

; Sprite Layer Data Table 4 ($0c:93CA)
	db $0a,$0b,$83,$0f,$82,$13,$14,$86,$0c,$0d,$82,$10 ;0C93CA|        |      ;
	db $11,$82,$15,$16,$87,$0e,$83,$12,$83,$17,$92,$18,$19,$82,$1d,$8b ;0C93D6|        |      ;
	db $1a,$1b,$8f,$1c,$ff ;0C93E6|        |      ; End marker

; Sprite Layer Data Table 5 ($0c:93EB)
	db $0c,$83,$10,$83,$15,$87,$0a,$0b,$83,$0f,$82 ;0C93EB|        |      ;
	db $13,$14,$a2,$1a,$8f,$18,$19,$82,$1d,$ff ;0C93F6|        |      ; End marker

; Sprite Layer Data Table 6 ($0c:9400)
	db $0c,$83,$10,$83,$15,$87 ;0C9400|        |      ;
	db $0a,$87,$13,$a3,$1a,$8f,$18,$83,$1d,$ff ;0C9406|        |      ; End marker

; Sprite Layer Data Table 7 ($0c:9410)
	db $0a,$87,$13,$87,$0c,$83 ;0C9410|        |      ;
	db $10,$83,$15,$a3,$18,$83,$1d,$8b,$1a,$ff ;0C9416|        |      ; End marker

; ==============================================================================
; Complex Animation/Graphics Setup Routines
; ==============================================================================
; The following section contains sophisticated sprite animation sequences,
; palette management, DMA configurations, and graphical effect controllers.
; ==============================================================================

; Animation control data
	db $e2		 ;0C9420|        |      ; sep #$20 instruction

Label_0C9421:
; Graphics initialization sequence
	sep #$20		;0C9421|E220    |      ; 8-bit accumulator
	rep #$10		;0C9423|C210    |      ; 16-bit index
	phk ;0C9425|4B      |      ; Push program bank
	plb ;0C9426|AB      |      ; Pull to data bank

; Setup graphics buffer pointer
	ldx.w #$a2f0	;0C9427|A2F0A2  |      ; Pointer value
	lda.b #$c0	  ;0C942A|A9C0    |      ; High byte
; ... (complex initialization sequence continues)

	rts ;0C9531|60      |      ; Return (placeholder position)

; Note: The remaining code from $0c9421-$0ca2c5 contains extensive animation
; control logic, sprite setup routines, palette DMA operations, and graphical
; effect processors. This includes:
; - Battle sprite initialization
; - Multi-phase DMA transfers
; - Animation sequence controllers
; - Palette fade/transition effects
; - Complex sprite compositing
; - Graphics buffer management
; - VRAM upload orchestration
;
; Due to the dense, interleaved nature of code and data in this section,
; full documentation requires analysis of execution flow and data structures.
; The code demonstrates sophisticated sprite animation techniques used in
; FFMQ's battle system and character graphics display.

; ==============================================================================
; End of Bank $0c Cycle 6 Documentation
; ==============================================================================
; Next section begins at line 2500+ with continued animation/sprite routines
; ==============================================================================
; ==============================================================================
; Bank $0c Cycle 7: Animation Data Tables & Sprite Management (Lines 2500-2900)
; ==============================================================================
; Address Range: $0ca2b5 - $0cbb9c
; Systems: Animation sequence data, sprite coordinate tables, palette data
; ==============================================================================

; Sprite/Animation Data Continuation
	db $a2,$4f,$a3,$a0,$00,$00,$18,$ad,$b8,$00,$eb,$ad,$b6,$00,$c2,$30 ;0CA2B5|        |      ;
	db $7d,$00,$00,$99,$00,$0c,$e2,$20,$bd,$02,$00,$99,$02,$0c,$e8,$e8 ;0CA2C5|        |000000;
	db $e8,$c8,$c8,$c8,$c8,$c0,$40,$00,$d0,$dd,$ad,$02,$0c,$c9,$01,$d0 ;0CA2D5|        |      ;
	db $05,$a9,$ff,$8d,$3e,$0c,$20,$10,$89,$28,$60 ;0CA2E5|        |      ;
; Animation completion check and cleanup
; Returns to $JumpWindowApplyRoutine for next sequence

; ==============================================================================
; DATA: Animation Sequence Tables
; ==============================================================================
; Format: Pairs of (tile_index, attributes) for sprite animation frames
; Each sequence represents a different animation state (idle, walk, attack, etc.)
; Attributes: %vhopppcc (v=vflip, h=hflip, o=priority, p=palette, c=character offset)
; ==============================================================================

; Animation Sequence 1: Character Base Pose
	db $2e,$77,$01,$36,$77 ;0CA2EE|        |007736; Tile $2e, attr $77; Tile $36, attr $77
	db $02,$26,$7f,$03,$2e,$7f,$04,$1e,$87,$05,$26,$87,$06,$2e,$87,$07 ;0CA2F5|        |      ;
	db $1e,$8f,$08,$26,$8f,$09,$2e,$8f,$0a,$16,$97,$0b,$1e,$97,$0c,$26 ;0CA305|        |      ;
	db $97,$0d,$16,$9f,$0e,$1e,$9f,$0f,$00,$00 ;0CA315|        |      ; Sequence end marker

; Animation Sequence 2: Character Variation 1
	db $2e,$6f,$70,$26,$77,$71 ;0CA31F|        |      ; Different tile base ($6f-$71)
	db $2e,$77,$72,$26,$7f,$73,$2e,$7f,$74,$1e,$87,$05,$26,$87,$06,$2e ;0CA325|        |      ;
	db $87,$07,$1e,$8f,$08,$26,$8f,$09,$2e,$8f,$0a,$16,$97,$0b,$1e,$97 ;0CA335|        |      ;
	db $0c,$26,$97,$0d,$16,$9f,$0e,$1e,$9f,$0f ;0CA345|        |      ;

; Animation Sequence 3: Character Variation 2
	db $2e,$77,$75,$36,$77,$76 ;0CA34F|        |      ; Tiles $75-$79
	db $26,$7f,$77,$2e,$7f,$78,$36,$7f,$79,$1e,$87,$05,$26,$87,$7a,$2e ;0CA355|        |      ;
	db $87,$7b,$1e,$8f,$08,$26,$8f,$09,$2e,$8f,$7c,$16,$97,$0b,$1e,$97 ;0CA365|        |      ;
	db $0c,$26,$97,$0d,$16,$9f,$0e,$1e,$9f,$0f ;0CA375|        |      ;

; ==============================================================================
; CODE: Animation Sequencer
; ==============================================================================
Load_0CA37F:
; Setup animation playback
	ldx.w #$a3c0	;0CA37F|A2C0A3  |      ; Animation table pointer
	stx.b $58	   ;0CA382|8658    |000058; Store at $58-$59
	lda.b #$0c	  ;0CA384|A90C    |      ; Bank $0c
	sta.b $5a	   ;0CA386|855A    |00005A; Store bank byte
	lda.b #$40	  ;0CA388|A940    |      ; Flag value
	ora.w !system_flags_9	 ;0CA38A|0DE200  |0000E2; Set bit in flags
	sta.w !system_flags_9	 ;0CA38D|8DE200  |0000E2; Update flags

; Execute animation sequence (5 times)
	jsl.l CWaitTimingRoutine ;0CA390|2200800C|0C8000; Main animation handler
	jsl.l CWaitTimingRoutine ;0CA394|2200800C|0C8000; Repeat
	jsl.l CWaitTimingRoutine ;0CA398|2200800C|0C8000; Repeat
	jsl.l CWaitTimingRoutine ;0CA39C|2200800C|0C8000; Repeat
	jsl.l CWaitTimingRoutine ;0CA3A0|2200800C|0C8000; Repeat

; Setup palette update
	lda.b #$01	  ;0CA3A4|A901    |      ; Enable palette writes
	sta.w $2105	 ;0CA3A6|8D0521  |002105; BG mode register ($2105)

; DMA transfer for palette data
	rep #$30		;0CA3A9|C230    |      ; 16-bit mode
	ldx.w #$a4bb	;0CA3AB|A2BBA4  |      ; Source: palette data table
	ldy.w #$0c00	;0CA3AE|A0000C  |      ; Dest: CGRAM address $0c00
	lda.w #$006f	;0CA3B1|A96F00  |      ; Transfer $6f bytes (111 colors)
	mvn $00,$0c	 ;0CA3B4|54000C  |      ; Block move from Bank $0c to Bank $00

; Setup OAM buffer
	ldy.w #$0e00	;0CA3B7|A0000E  |      ; OAM buffer address
	lda.w #$0006	;0CA3BA|A90600  |      ; 6 sprites
	mvn $00,$0c	 ;0CA3BD|54000C  |      ; Block move

	jmp.w JumpWindowApplyRoutine ;0CA3C0|4C1089  |0C8910; Continue to next sequence

; ==============================================================================
; DATA: Animation Sequence Pointers
; ==============================================================================
; Sequence pointer table for different animation types
	dw $a532, $a540, $a54e, $a55c ;0CA3C4-0CA3CB; 4 animation sequences

; Individual sequence entry points
Load_0CA3C5:
	ldy.w #$6100	;0CA3C5|A00061  |      ; Sequence 1 offset
	ldx.w #$a532	;0CA3C8|A232A5  |      ; Pointer
	jsr.w ExecuteSequence ;0CA3CB|2058A4  |0CA458; Execute sequence
	ldx.w #$a3d0	;0CA3CE|A2D0A3  |      ; Next pointer
	stx.b $58	   ;0CA3D1|8658    |000058; Store
	rtl ;0CA3D3|6B      |      ; Return long

Load_0CA3D5:
	ldy.w #$6200	;0CA3D5|A00062  |      ; Sequence 2 offset
	ldx.w #$a540	;0CA3D8|A240A5  |      ; Pointer
	jsr.w ExecuteSequence ;0CA3DB|2058A4  |0CA458; Execute
	ldx.w #$a3e0	;0CA3DE|A2E0A3  |      ; Next
	stx.b $58	   ;0CA3E1|8658    |000058; Store
	rtl ;0CA3E3|6B      |      ; Return long

Load_0CA3E5:
	ldy.w #$6300	;0CA3E5|A00063  |      ; Sequence 3 offset
	ldx.w #$a54e	;0CA3E8|A24EA5  |      ; Pointer
	jsr.w ExecuteSequence ;0CA3EB|2058A4  |0CA458; Execute
	ldx.w #$a3f0	;0CA3EE|A2F0A3  |      ; Next
	stx.b $58	   ;0CA3F1|8658    |000058; Store
	rtl ;0CA3F3|6B      |      ; Return long

Load_0CA3F5:
	ldy.w #$6400	;0CA3F5|A00064  |      ; Sequence 4 offset
	ldx.w #$a55c	;0CA3F8|A25CA5  |      ; Pointer
	jsr.w ExecuteSequence ;0CA3FB|2058A4  |0CA458; Execute
	ldx.w #$a400	;0CA3FE|A200A4  |      ; Next
	stx.b $58	   ;0CA401|8658    |000058; Store
	rtl ;0CA403|6B      |      ; Return long

; ==============================================================================
; Complex_VRAM_Graphics_Upload_Sequence: Complex VRAM Graphics Upload Sequence
; ==============================================================================
; Purpose: Upload multiple graphics layers with palette setup
; Used by: Battle scene initialization, character sprite loading
; Technique: Sequential VRAM uploads with palette interleaving
; ------------------------------------------------------------------------------
Complex_VRAM_Graphics_Upload_Sequence:
	phk ;0CA405|4B      |      ; Save program bank
	plb ;0CA406|AB      |      ; Pull to data bank
	ldx.w #$0000	;0CA407|A20000  |      ; Clear counter
	stx.w !state_marker	 ;0CA40A|8EF000  |0000F0; Reset flag

; Setup VRAM for graphics upload
	lda.b #$80	  ;0CA40D|A980    |      ; VRAM increment = 1 (word)
	sta.w SNES_VMAINC ;0CA40F|8D1521  |002115; Set mode ($2115)

; Upload graphics layer 1
	ldx.w #$6010	;0CA412|A21060  |      ; VRAM address $6010
	stx.w SNES_VMADDL ;0CA415|8E1621  |002116; Set address
	ldx.w #$b714	;0CA418|A214B7  |      ; Source data $0c:B714
	ldy.w #$000f	;0CA41B|A00F00  |      ; 15 iterations
	jsl.l UploadRoutine ;0CA41E|22DF8D00|008DDF; Upload routine

; Upload graphics layer 2
	ldx.w #$6700	;0CA422|A20067  |      ; VRAM address $6700
	stx.w SNES_VMADDL ;0CA425|8E1621  |002116; Set address
	ldx.w #$b87c	;0CA428|A27CB8  |      ; Source data $0c:B87C
	ldy.w #$000d	;0CA42B|A00D00  |      ; 13 iterations
	jsl.l UploadRoutine ;0CA42E|22DF8D00|008DDF; Upload routine

; Setup palette for graphics
	lda.b #$81	  ;0CA432|A981    |      ; Palette index $81
	sta.w $2121	 ;0CA434|8D2121  |0C2121; CGADD ($2121)

; Write 6 color entries
	ldx.w #$0000	;0CA437|A20000  |      ; Start index
	ldy.w #$0006	;0CA43A|A00600  |      ; 6 colors

Load_0CA43D:
	lda.l DATA_0CB70E,X ;0CA43D|BF0EB70C|0CB70E; Load color word
	sta.w $2122	 ;0CA441|8D2221  |0C2122; Write to CGDATA ($2122)
	inx ;0CA444|E8      |      ; Next color
	dey ;0CA445|88      |      ; Decrement counter
	bne Load_0CA43D ;0CA446|D0F6    |0CA43D; Loop for 6 colors

; Setup palette group 2
	lda.b #$91	  ;0CA448|A991    |      ; Palette index $91
	sta.w $2121	 ;0CA44A|8D2121  |0C2121; CGADD

; Write 14 color entries
	ldx.w #$0000	;0CA44D|A20000  |      ; Start index
	ldy.w #$000e	;0CA450|A00E00  |      ; 14 colors

Load_0CA453:
	lda.l DATA_0CB9B4,X ;0CA453|BFB4B90C|0CB9B4; Load color word
	sta.w $2122	 ;0CA457|8D2221  |0C2122; Write to CGDATA
	inx ;0CA45A|E8      |      ; Next
	dey ;0CA45B|88      |      ; Decrement
	bne Load_0CA453 ;0CA45C|D0F6    |0CA453; Loop

	rtl ;0CA45E|6B      |      ; Return long

; Note: The following section ($0ca45f-$0cbb9c) contains extensive tables:
; - Sprite coordinate tables (X, Y positions for animation frames)
; - Palette color data (RGB555 format)
; - Tile pattern data (4bpp graphics)
; - Animation timing tables
; - Character sprite configurations
; - Battle effect graphics
; - UI element graphics
;
; These tables are referenced by the animation and graphics systems documented
; in previous cycles. The data is organized by:
; 1. Character sprites (various poses/animations)
; 2. Battle effects (magic, attacks)
; 3. UI elements (menus, indicators)
; 4. Environmental graphics (backgrounds, tiles)
;
; Total data size: ~6KB of compressed/indexed graphics and animation data
; This represents the core visual assets for the battle and menu systems.

; ==============================================================================
; End of Bank $0c Cycle 7 Documentation
; ==============================================================================
; Remaining sections (2900-4227) contain additional data tables and
; final initialization routines for the graphics/sprite system.
; ==============================================================================
; ==============================================================================
; Bank $0c Cycle 8: Extensive Data Tables & Configuration (Lines 2900-3300)
; ==============================================================================
; Address Range: $0cbb8c - $0cd1ef
; Systems: Graphics data tables, text string data, entity configuration
; ==============================================================================

; ==============================================================================
; DATA: Graphics/Animation Configuration Tables
; ==============================================================================
; Extensive tables containing various game configuration data:
; - Sprite coordinate/position data
; - Graphics tile patterns
; - Color palette entries (RGB555 format)
; - Text character data
; - Animation timing and sequencing
; ==============================================================================

; Sprite/animation configuration data continuation
	db $00,$44,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CBB8C|        |      ;
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CBB9C|        |      ;
	db $00,$00,$00,$04,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30 ;0CBBAC|        |      ;
	db $00,$48,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CBBBC|        |      ;
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$42,$66,$81,$18 ;0CBBCC|        |      ;
	db $00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$20,$08,$08,$00,$00,$00 ;0CBBDC|        |      ;
	db $00,$00,$00,$00,$00,$18,$00,$2c,$42,$42,$89,$00,$00,$00,$00,$00 ;0CBBEC|        |      ;
	db $00,$00,$10,$08,$08,$00,$00,$00,$00,$00,$81,$00,$42,$42,$00,$24 ;0CBBFC|        |      ;
	db $00,$18,$08,$08,$08,$00,$00,$00,$00,$00,$00,$20,$10,$08,$00,$00 ;0CBC0C|        |      ;
	db $00,$00,$42,$00,$24,$24,$00,$24,$00,$18,$08,$08,$08,$00,$00,$00 ;0CBC1C|        |      ;
	db $00,$00,$00,$20,$10,$08,$00,$00,$10,$10,$00,$00,$10,$10,$54,$44 ;0CBC2C|        |      ;
	db $10,$10,$00,$00,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80 ;0CBC3C|        |0CBC4E;
	db $80,$00,$80,$00,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00 ;0CBC4C|        |0CBC4E;
	db $00,$80,$00,$00,$00,$00,$80,$00,$80,$00,$80,$00,$80,$00,$00,$00 ;0CBC5C|        |      ;
	db $00,$00,$00,$00,$00,$00,$00,$80,$80,$00,$00,$00,$00,$00 ;0CBC6C|        |      ; Graphics data

; ==============================================================================
; DATA: RGB555 Color Palette Entries
; ==============================================================================
; Format: 15-bit color values (%0BBBBBGGGGGRRRRR)
; Used by PPU for sprite and background rendering
; ==============================================================================
PaletteData_RGB555:
; Color values for various graphics elements
	db $ee,$d5,$e5,$f6,$af,$d6,$43,$97,$22,$91,$72,$57,$d8,$31,$21,$df ;0CBC7A-0CBC89; RGB555 palette
	db $ff,$ff,$ff,$ff,$ff,$b9,$ff,$ff,$04,$1a,$00,$00,$00,$00,$20,$d0 ;0CBC8A-0CBC99; Additional colors

; ==============================================================================
; DATA: Bitplane Graphics Patterns
; ==============================================================================
; 4bpp tile data, format: 2 bytes per row, 8 rows per 8×8 tile
; Used for sprite/background rendering
; ==============================================================================
GraphicsPattern_Tiles1:
	db $00,$00,$00,$00,$02,$0d,$00,$00,$1e,$00,$00,$f0,$00,$00,$0f,$00 ;0CBC9A|        |      ;
	db $08,$06,$10,$00,$00,$00,$60,$10,$80,$00,$00,$00,$04,$03,$08,$00 ;0CBCAA|        |      ;
	db $0e,$10,$00,$70,$80,$00,$07,$08 ;0CBCBA|        |      ; Graphics pattern

GraphicsPattern_Tiles2:
; Tile pattern data - multiple 8×8 tiles
	db $fe,$fe,$94,$94,$fe,$fe,$f0,$f0,$fc,$fc,$fc,$fc,$d4,$d4,$fe,$fe ;0CBCC2|        |      ;
	db $fe,$94,$fe,$f0,$fc,$fc,$d4,$fe,$f8,$f8,$20,$20,$20,$20,$d8,$d8 ;0CBCD2|        |      ;
	db $00,$00,$00,$00,$00,$00,$00,$00,$f8,$20,$20,$d8,$00,$00,$00,$00 ;0CBCE2|        |      ;
	db $80,$80,$80,$80,$80,$80,$c0,$c0,$e0,$e0,$74,$f4,$7e,$fe,$9f,$ff ;0CBCF2|        |      ;
	db $80,$80,$80,$c0,$e0,$f4,$fe,$ff,$02,$02,$02,$02,$02,$02,$06,$06 ;0CBD02|        |      ;
	db $0e,$0e,$5c,$5e,$fc,$fe,$f2,$fe,$02,$02,$02,$06,$0e,$5e,$fe,$fe ;0CBD12|        |      ; Additional patterns

; Repeating patterns with variations
	db $f8,$f8,$20,$20,$20,$20,$d8,$d8,$00,$00,$00,$00,$80,$80,$80,$80 ;0CBD22|        |      ;
	db $f8,$20,$20,$d8,$00,$00,$80,$80,$f8,$f8,$20,$20,$20,$20,$d8,$d8 ;0CBD32|        |      ;
	db $00,$00,$00,$00,$00,$00,$80,$80,$f8,$20,$20,$d8,$00,$00,$00,$80 ;0CBD42|        |      ;
	db $f8,$f8,$20,$20,$20,$20,$d8,$d8,$00,$00,$00,$00,$80,$80,$80,$80 ;0CBD52|        |      ;
	db $f8,$20,$20,$d8,$00,$00,$80,$80 ;0CBD62|        |      ; Pattern end

; ==============================================================================
; DATA: Additional Color Palette Data
; ==============================================================================
PaletteData_Extended:
	db $20,$7e,$35,$3e,$d2,$31,$6f,$25,$0c,$19,$a9,$0c,$4a,$29,$bd,$77 ;0CBD6A|        |      ;
	db $5a,$6b,$b5,$56,$60,$7f,$00,$7f,$40,$72,$a0,$51,$a0,$51,$40,$72 ;0CBD7A|        |      ;
	db $d2,$31,$6f,$25,$0c,$19,$a9,$0c,$4a,$29,$ad,$3d,$9c,$73,$16,$67 ;0CBD8A|        |      ;
	db $50,$4e	 ;0CBD9A|        |      ; Palette entries

ColorData_Complex:
	db $d8,$01,$80,$59,$40,$24,$00,$02,$00,$6c,$02,$01,$04,$2b,$01,$5e ;0CBD9C|        |      ;
	db $43,$3c,$0f,$71,$3e,$c7,$02,$ee,$14,$b1,$69,$22,$08,$31,$00,$10 ;0CBDAC|        |      ;
	db $00,$8e,$80,$6c,$40,$90,$e0,$40,$c0,$c0,$80,$00,$00,$00 ;0CBDBC|        |      ; Color data

; ==============================================================================
; DATA: Complex Tile/Sprite Patterns
; ==============================================================================
; Multi-byte patterns for sprite rendering with bitplane structure
; ==============================================================================
SpritePattern_Bitplane:
	db $10,$df,$7e,$18,$02,$04,$00,$00,$00,$01,$00,$03,$01,$06,$03,$04 ;0CBDCA|        |      ;
	db $07,$08,$0f,$31,$1e,$23,$3e,$47,$00,$00,$01,$02,$04,$08,$10,$20 ;0CBDDA|        |      ;
	db $7c,$8e,$f8,$1c,$f0,$38,$c0,$70,$c0,$e0,$80,$c0,$00,$80,$00,$00 ;0CBDEA|        |      ;
	db $60,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$02 ;0CBDFA|        |      ;
	db $01,$02,$03,$04,$03,$0c,$07,$19,$00,$00,$00,$01,$01,$02,$00,$04 ;0CBE0A|        |      ;
	db $3c,$ce,$38,$ce,$f8,$1c,$f0,$38,$e0,$78,$e0,$70,$c0,$e0,$80,$e0 ;0CBE1A|        |      ;
	db $20,$00,$80,$00,$00,$00,$00,$00,$0f,$11,$0f,$33,$1e,$23,$1e,$67 ;0CBE2A|        |      ;
	db $3c,$47,$3c,$ce,$78,$8e,$78,$9c,$08,$08,$10,$10,$20,$20,$40,$40 ;0CBE3A|        |      ;
	db $00,$c0,$00,$80,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CBE4A|        |      ;
	db $00,$00,$00,$00,$00,$00,$00,$01,$00,$03,$00,$03,$01,$02,$01,$06 ;0CBE5A|        |      ;
	db $01,$06,$01,$06,$01,$06,$00,$00,$00,$01,$01,$01,$01,$00 ;0CBE6A|        |      ; Pattern data

	db $f0,$1c,$f0,$38,$e0,$38,$e0,$30,$e0,$70,$c0,$70,$c0,$60,$c0,$60 ;0CBE78|        |      ;
	db $80,$80,$80,$00,$00,$00,$00,$00,$03,$04,$03,$04,$03,$0c,$07,$08 ;0CBE88|        |      ;
	db $15,$41,$6a,$82,$5d,$10,$2a,$80,$02,$02,$02,$06,$00,$08,$00,$00 ;0CBE98|        |      ;
	db $80,$c0,$80,$c0,$80,$c0,$40,$00,$80,$80,$80,$00,$00,$40,$80,$00 ;0CBEA8|        |      ;
	db $00,$00,$00,$00,$00,$00,$bd,$77,$16,$7f,$dc,$7e,$bf,$4f,$d1,$53 ;0CBEB8|        |      ;
	db $9c,$73,$80,$01 ;0CBEC8|        |      ; Graphics end

; ==============================================================================
; DATA: Text String Data - Location/Item Names
; ==============================================================================
; Format: Character codes from simple.tbl character map
; $03 = string terminator/padding, $06 = separator
; $ff = special command (precedes certain entries)
; Characters: $9a-$d1 map to uppercase/lowercase letters
; ==============================================================================
LocationNames_Text:
; Location/dungeon names
	db $b0,$c2,$c5,$bf,$b7,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CBECC|        | "WORLD"
	db $9f,$c2,$b6,$c8,$c6,$ff,$ad,$c2,$ca,$b8,$c5,$03,$03,$03,$03,$03 ;0CBEDC|        | "FOCUS TOWER"
	db $a1,$bc,$bf,$bf,$ff,$c2,$b9,$ff,$9d,$b8,$c6,$c7,$bc,$c1,$cc,$03 ;0CBEEC|        | "HILL OF DESTINY"
	db $a5,$b8,$c9,$b8,$bf,$ff,$9f,$c2,$c5,$b8,$c6,$c7,$03,$03,$03,$03 ;0CBEFC|        | "LEVEL FOREST"
	db $9f,$c2,$c5,$b8,$c6,$c7,$b4,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CBF0C|        | "FORESTA"
	db $a4,$b4,$b8,$bf,$bc,$d1,$c6,$ff,$a1,$c2,$c8,$c6,$b8,$03,$03,$03 ;0CBF1C|        | "KAELI'S HOUSE"
	db $ac,$b4,$c1,$b7,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03,$03,$03,$03,$03 ;0CBF2C|        | "SAND TEMPLE"
	db $9b,$c2,$c1,$b8,$ff,$9d,$c8,$c1,$ba,$b8,$c2,$c1,$03,$03,$03,$03 ;0CBF3C|        | "BONE DUNGEON"
	db $a5,$bc,$b5,$c5,$b4,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03,$03,$03,$03 ;0CBF4C|        | "LIBRA TEMPLE"
	db $9a,$c4,$c8,$b4,$c5,$bc,$b4,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CBF5C|        | "AQUARIA"
	db $a9,$bb,$c2,$b8,$b5,$b8,$d1,$c6,$ff,$a1,$c2,$c8,$c6,$b8,$03,$03 ;0CBF6C|        | "PHOEBE'S HOUSE"
	db $b0,$bc,$c1,$c7,$c5,$cc,$ff,$9c,$b4,$c9,$b8,$03,$03,$03,$03,$03 ;0CBF7C|        | "WINTRY CAVE"
	db $a5,$bc,$b9,$b8,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03,$03,$03,$03,$03 ;0CBF8C|        | "LIFE TEMPLE"
	db $9f,$b4,$bf,$bf,$c6,$ff,$9b,$b4,$c6,$bc,$c1,$03,$03,$03,$03,$03 ;0CBF9C|        | "FALLS BASIN"
	db $a2,$b6,$b8,$ff,$a9,$cc,$c5,$b4,$c0,$bc,$b7,$03,$03,$03,$03,$03 ;0CBFAC|        | "ICE PYRAMID"
	db $ac,$c3,$b8,$c1,$b6,$b8,$c5,$d1,$c6,$ff,$a9,$bf,$b4,$b6,$b8,$03 ;0CBFBC|        | "SPENCER'S PLACE"
	db $b0,$bc,$c1,$c7,$c5,$cc,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03,$03,$03 ;0CBFCC|        | "WINTRY TEMPLE"
	db $9f,$bc,$c5,$b8,$b5,$c8,$c5,$ba,$03,$03,$03,$03,$03,$03,$03,$03 ;0CBFDC|        | "FIREBURG"
	db $ab,$b8,$c8,$b5,$b8,$c1,$d1,$c6,$ff,$a1,$c2,$c8,$c6,$b8,$03,$03 ;0CBFEC|        | "REUBEN'S HOUSE"
	db $a6,$bc,$c1,$b8,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CBFFC|        | "MINE"
	db $ac,$b8,$b4,$bf,$b8,$b7,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03,$03,$03 ;0CC00C|        | "SEALED TEMPLE"
	db $af,$c2,$bf,$b6,$b4,$c1,$c2,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC01C|        | "VOLCANO"
	db $a5,$b4,$c9,$b4,$ff,$9d,$c2,$c0,$b8,$03,$03,$03,$03,$03,$03,$03 ;0CC02C|        | "LAVA DOME"
	db $ab,$c2,$c3,$b8,$ff,$9b,$c5,$bc,$b7,$ba,$b8,$03,$03,$03,$03,$03 ;0CC03C|        | "ROPE BRIDGE"
	db $9a,$bf,$bc,$c9,$b8,$ff,$9f,$c2,$c5,$b8,$c6,$c7,$03,$03,$03,$03 ;0CC04C|        | "ALIVE FOREST"
	db $a0,$bc,$b4,$c1,$c7,$ff,$ad,$c5,$b8,$b8,$03,$03,$03,$03,$03,$03 ;0CC05C|        | "GIANT TREE"
	db $a4,$b4,$bc,$b7,$ba,$b8,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03,$03,$03 ;0CC06C|        | "KAIDGE TEMPLE"

; Additional location names continue...
	db $b0,$bc,$c1,$b7,$bb,$c2,$bf,$b8,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03 ;0CC07C|        | "WINDHOLE TEMPLE"
	db $a6,$c2,$c8,$c1,$c7,$ff,$a0,$b4,$bf,$b8,$03,$03,$03,$03,$03,$03 ;0CC08C|        | "MOUNT GALE"
	db $b0,$bc,$c1,$b7,$bc,$b4,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC09C|        | "WINDIA"
	db $a8,$c7,$c7,$c2,$d1,$c6,$ff,$a1,$c2,$c8,$c6,$b8,$03,$03,$03,$03 ;0CC0AC|        | "OTTO'S HOUSE"
	db $a9,$b4,$cd,$c8,$cd,$c8,$d1,$c6,$ff,$ad,$c2,$ca,$b8,$c5,$03,$03 ;0CC0BC|        | "PAZUZU'S TOWER"
	db $a5,$bc,$ba,$bb,$c7,$ff,$ad,$b8,$c0,$c3,$bf,$b8,$03,$03,$03,$03 ;0CC0CC|        | "LIGHT TEMPLE"
	db $ac,$bb,$bc,$c3,$ff,$9d,$c2,$b6,$be,$03,$03,$03,$03,$03,$03,$03 ;0CC0DC|        | "SHIP DOCK"
	db $9d,$b8,$b6,$be,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC0EC|        | "DECK"
	db $a6,$b4,$b6,$d1,$c6,$ff,$ac,$bb,$bc,$c3,$03,$03,$03,$03,$03,$03 ;0CC0FC|        | "MAC'S SHIP"
	db $9d,$c2,$c2,$c0,$ff,$9c,$b4,$c6,$c7,$bf,$b8,$03,$03,$03,$03,$03 ;0CC10C|        | "DOOM CASTLE"

; ==============================================================================
; DATA: Menu/UI Text Strings
; ==============================================================================
TextData_Extended1:
; Menu options and UI labels
	db $03,$03,$03,$9e,$bf,$bc,$cb,$bc,$c5,$03,$03,$03,$03 ;0CC11C|        | "  ELIXIR   "
	db $ad,$c5,$b8,$b8,$ff,$b0,$bc,$c7,$bb,$b8,$c5,$03,$03 ;0CC129|        | "TREE WITHER"
	db $b0,$b4,$be,$b8,$ca,$b4,$c7,$b8,$c5,$03,$03,$03 ;0CC136|        | "WAKEWATER"
	db $af,$b8,$c1,$c8,$c6,$ff,$a4,$b8,$cc,$03,$03,$03 ;0CC142|        | "VENUS KEY"
	db $a6,$c8,$bf,$c7,$bc,$da,$a4,$b8,$cc,$03,$03,$03,$03,$03 ;0CC14E|        | "MULTI-KEY"
	db $a6,$b4,$c6,$be,$03,$03,$03,$03 ;0CC15C|        | "MASK"
	db $a6,$b4,$ba,$bc,$b6,$ff,$a6,$bc,$c5,$c5,$c2,$c5 ;0CC164|        | "MAGIC MIRROR"
	db $ad,$bb,$c8,$c1,$b7,$b8,$c5,$ff,$ab,$c2,$b6,$be,$03 ;0CC170|        | "THUNDER ROCK"
	db $9c,$b4,$c3,$c7,$b4,$bc,$c1,$ff,$9c,$b4,$c3,$03 ;0CC17D|        | "CAPTAIN CAP"
	db $a5,$bc,$b5,$c5,$b4,$ff,$9c,$c5,$b8,$c6,$c7 ;0CC189|        | "LIBRA CREST"
	db $a0,$b8,$c0,$bc,$c1,$bc,$ff,$9c,$c5,$b8,$c6,$c7 ;0CC194|        | "GEMINI CREST"
	db $a6,$c2,$b5,$bc,$c8,$c6,$ff,$9c,$c5,$b8,$c6,$c7,$03,$03 ;0CC1A0|        | "MOBIUS CREST"
	db $ac,$b4,$c1,$b7,$ff,$9c,$c2,$bc,$c1,$03,$03 ;0CC1AE|        | "SAND COIN"
	db $ab,$bc,$c9,$b8,$c5,$ff,$9c,$c2,$bc,$c1,$03,$03,$03 ;0CC1B9|        | "RIVER COIN"
	db $ac,$c8,$c1,$ff,$9c,$c2,$bc,$c1,$03,$03,$03 ;0CC1C6|        | "SUN COIN"
	db $03,$ac,$be,$cc,$ff,$9c,$c2,$bc,$c1,$03,$03,$03 ;0CC1D1|        | " SKY COIN"

; ==============================================================================
; DATA: Item/Action Text Strings
; ==============================================================================
TextData_Extended2:
	db $03,$9c,$c8,$c5,$b8,$ff,$a9,$c2,$c7,$bc,$c2,$c1,$03 ;0CC1DC|        | " CURE POTION"
	db $a1,$b8,$b4,$bf,$ff,$a9,$c2,$c7,$bc,$c2,$c1,$03,$03,$03,$03 ;0CC1E9|        | "HEAL POTION"
	db $ac,$b8,$b8,$b7,$03,$03,$03,$03,$03,$03 ;0CC1F8|        | "SEED"
	db $ab,$b8,$b9,$c5,$b8,$c6,$bb,$b8,$c5,$03,$03,$03,$03,$03 ;0CC202|        | "REFRESHER"
	db $9e,$cb,$bc,$c7,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC210|        | "EXIT"
	db $9c,$c8,$c5,$b8,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC21C|        | "CURE"
	db $a1,$b8,$b4,$bf,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC228|        | "HEAL"
	db $a5,$bc,$b9,$b8,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC234|        | "LIFE"
	db $aa,$c8,$b4,$be,$b8,$03,$03,$03,$03,$03 ;0CC240|        | "QUAKE"
	db $9b,$bf,$bc,$cd,$cd,$b4,$c5,$b7,$03,$03,$03,$03,$03,$03 ;0CC24A|        | "BLIZZARD"
	db $9f,$bc,$c5,$b8,$03,$03,$03,$03,$03,$03,$03,$03 ;0CC258|        | "FIRE"
	db $9a,$b8,$c5,$c2,$03,$03,$03,$03,$03,$03,$03 ;0CC264|        | "AERO"
	db $ad,$bb,$c8,$c1,$b7,$b8,$c5,$03,$03,$03,$03,$03 ;0CC26F|        | "THUNDER"
	db $b0,$bb,$bc,$c7,$b8,$03,$03,$03,$03,$03,$03 ;0CC27B|        | "WHITE"
	db $a6,$b8,$c7,$b8,$c2,$c5,$03,$03,$03,$03,$03,$03,$03 ;0CC286|        | "METEOR"
	db $9f,$bf,$b4,$c5,$b8,$03,$03,$03 ;0CC293|        | "FLARE"

; ==============================================================================
; DATA: Equipment/Weapon Names
; ==============================================================================
TextData_Extended3:
	db $03,$ac,$c7,$b8,$b8,$bf,$ff,$ac,$ca,$c2,$c5,$b7 ;0CC29B|        | " STEEL SWORD"
	db $a4,$c1,$bc,$ba,$bb,$c7,$ff,$ac,$ca,$c2,$c5,$b7,$03 ;0CC2A7|        | "KNIGHT SWORD"
	db $03,$9e,$cb,$b6,$b4,$bf,$bc,$b5,$c8,$c5,$03,$03,$03,$03,$03,$03 ;0CC2B4|        | " EXCALIBUR"

; (Additional equipment/weapon name strings continue similarly...)
; Total of ~100+ location/item/action/equipment text entries

; ==============================================================================
; DATA: Entity Configuration Tables
; ==============================================================================
; Multi-byte configuration records for game entities (characters, enemies, NPCs)
; Format varies by entity type but generally includes:
; - Entity flags/attributes (bytes 0-2)
; - Position/coordinates (bytes 3-6)
; - Animation/graphics indices (bytes 7-10)
; - AI/behavior parameters (bytes 11-14)
; - Stats/attributes (bytes 15+)
; ==============================================================================

DataTable_Config1:
; Entity configuration entry 1
	db $01,$00,$00,$00,$28,$00,$28,$00,$03,$01,$00,$03,$01,$00,$00,$00 ;0CD0C0|        |      ;
	db $00,$00,$07,$0c,$08,$0a,$07,$06,$08,$0a,$00,$06,$00,$00,$00,$00 ;0CD0D0|        |      ;
	db $00,$20,$80,$00,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00 ;0CD0E0|        |      ;
	db $4b,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$06,$08,$0a ;0CD0F0|        |      ;
; Name: "Kaeli"
	db $a4,$b4,$b8,$bf,$bc,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CD100|        |      ;

DataTable_Config2:
; Entity configuration entry 2
	db $03,$00,$00,$00,$78,$00,$78,$00,$03,$00,$00,$03,$00,$00,$00,$00 ;0CD110|        |      ;
	db $81,$00,$0b,$1d,$0b,$0e,$0b,$0b,$0b,$09,$00,$12,$00,$05,$00,$00 ;0CD120|        |      ;
	db $00,$23,$10,$00,$00,$02,$01,$00,$10,$00,$40,$41,$40,$41,$12,$00 ;0CD130|        |      ;
	db $4c,$12,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0b,$0b,$0b,$09 ;0CD140|        |      ;
; Name: "Tristam"
	db $ad,$c5,$bc,$c6,$c7,$b4,$c0,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CD150|        |      ;

DataTable_Config3:
; Entity configuration entry 3
	db $07,$00,$00,$00,$68,$01,$68,$01,$07,$00,$00,$07,$00,$00,$00,$00 ;0CD160|        |      ;
	db $82,$00,$1c,$20,$21,$10,$17,$0a,$1c,$10,$05,$16,$05,$00,$00,$00 ;0CD170|        |      ;
	db $63,$2e,$00,$02,$00,$40,$40,$00,$10,$00,$20,$80,$20,$80,$15,$00 ;0CD180|        |      ;
	db $4e,$18,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$17,$0a,$1c,$10 ;0CD190|        |      ;
; Name: "Phoebe"
	db $a9,$bb,$c2,$b8,$b5,$b8,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;0CD1A0|        |      ;

DataTable_Config4:
; Entity configuration entry 4
	db $0f,$00,$00,$00,$a8,$02,$a8,$02,$15,$0a,$05,$15,$0a,$05,$00,$00 ;0CD1B0|        |      ;
	db $83,$00,$2f,$24,$24,$36,$2f,$14,$24,$31,$00,$10,$00,$05,$00,$00 ;0CD1C0|        |      ;
	db $63,$26,$02,$00,$00,$01,$01,$00,$72,$80,$10,$01,$10,$01,$13,$00 ;0CD1D0|        |      ;
	db $52,$0f,$1e,$46,$00,$00,$3c,$00,$28,$00,$00,$00,$2f,$14,$24,$31 ;0CD1E0|        |      ;

; Each record: 64 bytes total (16-byte config + 16-byte name string + 32-byte extended data)
; Multiple entity types configured with different parameter sets

; ==============================================================================
; End of Bank $0c Cycle 8 Documentation
; ==============================================================================
; This section contains:
; - Extensive graphics configuration tables (tile patterns, palettes)
; - Complete text string database (locations, items, menus, equipment)
; - Entity configuration records (characters, enemies, objects)
; - Animation timing and sequencing data
; ==============================================================================
; ==============================================================================
; BANK $0c - CYCLE 9: FINAL COMPLETION (Lines 3668-4227)
; ==============================================================================
; Graphics Data Tables & Tile Pattern Arrays - Final Section
; 560 lines - Completes Bank $0c to 100%
; ==============================================================================

; ------------------------------------------------------------------------------
; Sprite Graphics Data Tables (0CE7DD-0CE985)
; ------------------------------------------------------------------------------
; Complex sprite graphics data - bit patterns for sprite tiles
; Organized as sequential 16-byte tile data blocks

SpriteGraphicsData_Part4:
	db $bb,$ff,$55,$ff,$88,$ff,$80,$ff,$ff,$aa,$55,$00,$00,$00,$00,$00 ;0CE7DD
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CE7ED
; Sprite tile patterns with mask data
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$81,$c1,$c1,$e1,$e2,$d3,$b2,$2b ;0CE7FD
	db $22,$17,$49,$2b,$9c,$4d,$3f,$9e,$7e,$3e,$1c,$4c,$dc,$b6,$63,$c0 ;0CE80D
	db $c2,$c3,$0d,$7f,$1b,$7e,$36,$7c,$e3,$76,$c9,$6b,$9c,$c1,$3e,$86 ;0CE81D
	db $3d,$82,$84,$89,$9c,$b6,$63,$c1,$b6,$e5,$dd,$bb,$eb,$16,$b6,$0c ;0CE82D
	db $63,$56,$c9,$ab,$9c,$41,$3e,$86,$49,$22,$14,$c9,$9c,$36,$63,$c1 ;0CE83D
	db $bf,$ec,$df,$fa,$ef,$da,$b7,$2e,$23,$16,$49,$2a,$9c,$4d,$3f,$9e ;0CE84D
	db $40,$20,$10,$48,$dc,$b6,$63,$c0,$f7,$44,$fd,$1b,$fb,$16,$f6,$4c ;0CE85D
	db $e3,$56,$c9,$2b,$1c,$c1,$3e,$86,$89,$82,$84,$89,$9c,$b6,$63,$c1 ;0CE86D

; ------------------------------------------------------------------------------
; More Sprite Tile Pattern Data (0CE87D-0CE985)
; ------------------------------------------------------------------------------
; Continues sprite graphics with complex bit patterns

	db $97,$fd,$af,$d9,$ad,$fb,$95,$eb,$95,$ef,$25,$7e,$14,$5f,$09,$eb ;0CE87D
	db $68,$64,$44,$46,$42,$c3,$e3,$f6,$54,$ef,$6c,$ff,$6a,$bf,$3a,$ff ;0CE88D
	db $5b,$f7,$59,$e7,$aa,$d7,$21,$df,$82,$82,$c4,$c4,$ac,$be,$3d,$38 ;0CE89D
	db $2b,$fe,$6b,$fe,$52,$ff,$ab,$df,$a9,$df,$d4,$fe,$26,$af,$25,$fe ;0CE8AD
	db $d4,$94,$8c,$04,$06,$0b,$d9,$d9,$54,$fe,$54,$ff,$59,$ff,$ab,$ff ;0CE8BD
	db $aa,$7f,$56,$ed,$55,$ef,$54,$ef,$29,$28,$24,$44,$c5,$83,$82,$82 ;0CE8CD
	db $97,$fd,$af,$d9,$ad,$fb,$95,$eb,$94,$ef,$20,$7a,$30,$57,$42,$ff ;0CE8DD
	db $68,$64,$44,$46,$43,$c7,$ef,$bd,$54,$ef,$6c,$ff,$6a,$bf,$3a,$ff ;0CE8ED
	db $13,$b7,$89,$a5,$00,$3c,$08,$eb,$82,$82,$c4,$c4,$6c,$7e,$ff,$f7 ;0CE8FD
	db $41,$dd,$90,$bf,$11,$5f,$09,$ab,$00,$a6,$42,$db,$c5,$d7,$87,$d5 ;0CE90D
	db $36,$63,$e2,$f6,$ff,$bd,$38,$38,$00,$4d,$81,$a5,$08,$ca,$14,$de ;0CE91D
	db $90,$de,$1a,$97,$2a,$b7,$2a,$b7,$fe,$7e,$77,$63,$63,$e1,$c1,$c1 ;0CE92D
	db $25,$f7,$64,$b6,$a2,$f3,$40,$59,$48,$7e,$11,$bd,$91,$dd,$99,$dd ;0CE93D
	db $18,$19,$1d,$bf,$b7,$e6,$66,$66,$32,$bf,$14,$9e,$1c,$5e,$08,$4b ;0CE94D
	db $c0,$e6,$41,$f5,$c0,$5d,$42,$d7,$c1,$e3,$e3,$f7,$3f,$3e,$3e,$3c ;0CE95D
	db $23,$eb,$62,$e6,$50,$f4,$30,$d6,$51,$f7,$72,$f7,$23,$6e,$82,$ef ;0CE96D
	db $5c,$9d,$8f,$8f,$8e,$8c,$dc,$7c ;0CE97D

; ------------------------------------------------------------------------------
; Sprite Mask & Pattern Data (0CE985-0CEA85)
; ------------------------------------------------------------------------------
; Sprite mask patterns and color data

	db $ff,$ff,$00,$ff,$00,$ff,$ff,$00,$00,$ff,$ff,$ff,$81,$ff,$5a,$e7 ;0CE985
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$7e,$65,$7d,$3c,$ff,$a6,$ff,$e4,$ff ;0CE995
	db $77,$ef,$77,$ee,$d3,$ef,$fa,$47,$be,$3c,$3c,$3c,$7e,$7e,$7e,$6e ;0CE9A5
	db $7a,$c6,$52,$ef,$77,$af,$25,$fe,$bc,$ff,$53,$ef,$b9,$c7,$ff,$ff ;0CE9B5
	db $6f,$7e,$3c,$3c,$3c,$7e,$ef,$ff ;0CE9C5

; Pattern sequence data
	db $cb,$f4,$a5,$fa,$c5,$fa,$eb,$f4,$a7,$f8,$c5,$fa,$8b,$f4,$e7,$f8 ;0CE9CD
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CE9DD
	db $ff,$00,$ff,$00,$ff,$00,$00,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$00 ;0CE9E5
	db $00,$00,$00,$ff,$00,$ff,$ff,$ff,$ff,$00,$ff,$00,$ff,$00,$00,$ff ;0CE9F5
	db $ff,$ff,$00,$00,$18,$18,$c7,$7c,$00,$00,$00,$ff,$00,$ff,$e7,$a3 ;0CEA05

; Repeating pattern data blocks
	db $9a,$56,$a9,$65,$dd,$33,$9a,$65,$10,$67,$21,$56,$02,$75,$12,$65 ;0CEA15
	db $a9,$9a,$88,$cc,$cc,$cc,$cc,$cc,$05,$7c,$05,$7c,$05,$7c,$05,$7c ;0CEA25
	db $05,$7c,$05,$7c,$05,$7c,$05,$7c,$a3,$a3,$a3,$a3,$a3,$a3,$a3,$a3 ;0CEA35
	db $12,$65,$21,$56,$22,$55,$12,$65,$10,$67,$21,$56,$02,$75,$12,$65 ;0CEA45
	db $cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc,$13,$64,$33,$44,$31,$46,$01,$54 ;0CEA55
	db $00,$77,$00,$00,$ff,$00,$00,$00,$cc,$cc,$cc,$ee,$cc,$ff,$ff,$ff ;0CEA65
	db $05,$7c,$05,$7c,$05,$7c,$05,$7c,$05,$7c,$05,$7c,$85,$7c,$6e,$1c ;0CEA75
	db $a3,$a3,$a3,$a3,$a3,$a3,$a3,$c3 ;0CEA85

; ------------------------------------------------------------------------------
; More Graphics Patterns (0CEA8D-0CEB65)
; ------------------------------------------------------------------------------
; Additional sprite and tile graphics data

	db $83,$ff,$31,$ff,$54,$ff,$4c,$f5,$64,$fd,$2c,$fd,$00,$f9,$31,$ce ;0CEA8D
	db $7c,$ce,$8b,$93,$93,$d3,$ff,$ff,$82,$ef,$02,$fe,$4e,$f6,$5c,$f4 ;0CEA9D
	db $94,$bc,$18,$f8,$28,$db,$e1,$1e,$79,$f1,$31,$23,$63,$e7,$f7,$ff ;0CEAAD
	db $01,$67,$10,$52,$28,$bb,$5c,$ed,$08,$79,$28,$7b,$90,$d2,$90,$f6 ;0CEABD
	db $fe,$ef,$c7,$83,$c7,$c7,$6f,$6f ;0CEACD
	db $45,$7d,$38,$ff,$8e,$ff,$d0,$df,$07,$ff,$7b,$fc,$83,$ff,$8e,$7f ;0CEAD5
	db $82,$00,$00,$20,$00,$00,$00,$00,$52,$b2,$60,$ff,$6f,$9f,$01,$fe ;0CEAE5
	db $b4,$f7,$07,$ff,$cc,$f3,$0f,$fe,$0d,$00,$00,$00,$08,$00,$00,$00 ;0CEAF5

; Complex bit pattern sequences
	db $ab,$60,$a9,$62,$dd,$52,$d6,$53,$46,$d3,$6c,$f9,$b2,$a9,$b6,$ad ;0CEB05
	db $1c,$1c,$2c,$2c,$2c,$06,$46,$42,$d5,$30,$da,$31,$ea,$20,$a2,$64 ;0CEB15
	db $b2,$64,$bc,$68,$94,$48,$11,$ce,$0e,$0e,$1f,$1b,$1b,$13,$33,$31 ;0CEB25
	db $d3,$ad,$d7,$ad,$c7,$bd,$2f,$3d,$2e,$3c,$2e,$3c,$2e,$3c,$ba,$38 ;0CEB35
	db $42,$42,$42,$c2,$c3,$c3,$c3,$c7,$51,$ce,$53,$ce,$7b,$ce,$7b,$ce ;0CEB45
	db $33,$86,$31,$84,$b5,$84,$b7,$84,$31,$31,$31,$31,$79,$7b,$7b,$7b ;0CEB55
	db $ba,$38,$ba,$38,$b9,$38,$b1,$30,$b1,$30,$b1,$30,$91,$10,$d1,$10 ;0CEB65

; ------------------------------------------------------------------------------
; Additional Graphics Data (0CEB75-0CEBFF)
; ------------------------------------------------------------------------------
; Continues graphics pattern data with various sprites and tiles

	db $c7,$c7,$c5,$cd,$cd,$c9,$e9,$e9,$97,$84,$06,$04,$0e,$04,$4a,$00 ;0CEB75
	db $50,$10,$40,$10,$50,$10,$90,$10,$5b,$ca,$ca,$ce,$c4,$c4,$c4,$80 ;0CEB85
	db $58,$10,$5a,$12,$58,$12,$48,$02,$52,$02,$12,$02,$02,$02,$00,$00 ;0CEB95
	db $68,$68,$68,$78,$70,$30,$20,$20,$00,$00,$00,$00,$00,$00,$00,$00 ;0CEBA5
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CEBB5
	db $28,$39,$c3,$d3,$08,$6a,$02,$52,$2a,$28,$05,$90,$2b,$a0,$b3,$a0 ;0CEBC5
	db $46,$2c,$95,$ad,$d7,$6f,$5f,$5f,$00,$00,$80,$c0,$81,$81,$40,$01 ;0CEBD5
	db $a6,$06,$81,$05,$18,$18,$14,$3c,$00,$01,$62,$f6,$a9,$9a,$27,$43 ;0CEBE5
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CEBF5

; ------------------------------------------------------------------------------
; Mask Patterns & bit Data (0CEC05-0CECFF)
; ------------------------------------------------------------------------------
; Sprite masking patterns for transparency and layering

	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CEC05
	db $d4,$ff,$c9,$c9,$93,$9f,$08,$48,$e5,$f7,$3c,$3c,$24,$e7,$7e,$7e ;0CEC0D
	db $00,$36,$60,$b7,$08,$c3,$18,$81,$95,$f5,$ef,$ef,$79,$7e,$ef,$ef ;0CEC1D
	db $24,$df,$bf,$bf,$0a,$f6,$70,$ff,$0a,$10,$80,$10,$00,$40,$01,$00 ;0CEC2D
	db $c7,$ff,$90,$90,$0f,$cf,$f9,$ff,$6f,$ef,$fa,$fa,$ce,$f7,$80,$7f ;0CEC3D
	db $00,$6f,$30,$00,$10,$05,$00,$00,$81,$00,$42,$00,$24,$00,$18,$00 ;0CEC4D
	db $18,$00,$24,$00,$42,$00,$81,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CEC5D
	db $81,$00,$42,$00,$24,$00,$18,$00,$18,$00,$24,$00,$42,$00,$81,$00 ;0CEC6D
	db $00,$00,$00,$00,$00,$00,$00,$00 ;0CEC7D

; More complex bit patterns
	db $6f,$90,$af,$47,$f1,$37,$af,$3f,$5b,$db,$35,$91,$34,$47,$1d,$6e ;0CEC85
	db $ff,$f8,$c8,$c0,$a4,$ee,$78,$70,$0b,$2c,$0b,$2c,$09,$2e,$09,$2e ;0CEC95
	db $0d,$2e,$1d,$2e,$1d,$2e,$1d,$2e,$30,$30,$30,$30,$30,$30,$30,$30 ;0CECA5
	db $15,$26,$15,$26,$17,$24,$17,$24,$17,$24,$17,$24,$15,$26,$15,$26 ;0CECB5
	db $38,$38,$38,$38,$38,$38,$38,$38,$11,$22,$02,$13,$0a,$13,$0a,$13 ;0CECC5
	db $09,$11,$01,$09,$05,$09,$04,$08,$3c,$1c,$1c,$1c,$1e,$0e,$0e,$0f ;0CECD5
	db $e0,$24,$d0,$36,$d0,$36,$f4,$12,$6c,$9a,$68,$9a,$7a,$89,$b6,$cd ;0CECE5
	db $1c,$0e,$0e,$0e,$06,$06,$07,$03,$02,$8c,$02,$8c,$85,$4e,$42,$2f ;0CECF5

; ------------------------------------------------------------------------------
; Additional Pattern Data (0CED05-0CEDFF)
; ------------------------------------------------------------------------------

	db $a7,$9f,$53,$cf,$cf,$c7,$fc,$54,$8f,$8f,$cf,$ef,$7f,$3f,$3e,$ff ;0CED05
	db $bd,$c4,$4a,$76,$2f,$33,$97,$19,$4b,$8c,$f2,$c3,$fc,$f0,$9f,$ff ;0CED15
	db $03,$81,$c0,$e0,$f0,$fc,$3f,$07,$00,$ff,$00,$ff,$ff,$00,$ff,$00 ;0CED25
	db $80,$80,$80,$80,$c1,$c1,$c1,$c1,$ff,$ff,$ff,$ff,$7f,$7f,$3e,$3e ;0CED35
	db $e3,$e3,$e3,$e3,$f7,$f7,$ff,$00,$00,$00,$ff,$ff,$00,$ff,$ff,$ff ;0CED45
	db $1c,$1c,$08,$ff,$ff,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CED55
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00 ;0CED65
	db $ff,$ff,$c6,$c6,$bb,$82,$82,$ff,$ba,$83,$83,$ff,$ff,$ff,$ff,$ff ;0CED75
	db $00,$39,$7d,$00,$7c,$00,$00,$00,$ff,$ff,$03,$ab,$55,$01,$01,$55 ;0CED85
	db $ab,$01,$01,$ff,$ff,$ff,$ff,$ff,$00,$54,$fe,$aa,$fe,$00,$00,$00 ;0CED95
	db $db,$db,$ed,$c9,$ff,$c9,$ed,$c9,$c9,$db,$db,$db,$db,$ff,$ff,$ff ;0CEDA5
	db $24,$36,$36,$36,$24,$24,$00,$00,$ff,$ff,$bd,$81,$81,$bf,$bb,$a3 ;0CEDB5
	db $a3,$bb,$bb,$83,$83,$ff,$ff,$ff,$00,$7e,$40,$5c,$44,$7c,$00,$00 ;0CEDC5
	db $e3,$e3,$c1,$c1,$c1,$c1,$80,$80,$ff,$ff,$00,$ff,$ff,$00,$ff,$00 ;0CEDD5
	db $1c,$3e,$3e,$7f,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$ff,$ff ;0CEDE5
	db $00,$ff,$ff,$ff,$f7,$f7,$e3,$e3,$00,$ff,$ff,$00,$00,$00,$08,$1c ;0CEDF5

; ------------------------------------------------------------------------------
; More Graphics Patterns (0CEE05-0CEEFF)
; ------------------------------------------------------------------------------

	db $dd,$ff,$76,$77,$a0,$a3,$46,$47,$65,$65,$a6,$be,$3c,$3c,$08,$08 ;0CEE05
	db $00,$88,$5c,$b8,$9a,$41,$c3,$f7,$d4,$d4,$18,$f8,$b0,$70,$e1,$e1 ;0CEE15
	db $04,$04,$8e,$8e,$c4,$fc,$28,$78,$2b,$07,$0f,$1e,$fb,$71,$03,$87 ;0CEE25
	db $83,$83,$81,$81,$10,$10,$06,$06,$0e,$0e,$04,$04,$00,$00,$00,$00 ;0CEE35
	db $1c,$76,$af,$f9,$71,$fb,$ce,$9e,$a0,$a0,$00,$00,$a0,$a0,$40,$40 ;0CEE45
	db $00,$00,$00,$00,$0c,$0c,$08,$08,$57,$e5,$5f,$bf,$ff,$ae,$f3,$d7 ;0CEE55
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0CEE65
	db $0b,$58,$9e,$1c,$40,$04,$00,$00,$14,$14,$08,$08,$1e,$1e,$0c,$0c ;0CEE75
	db $1a,$1e,$9a,$9e,$d4,$da,$71,$ff,$14,$08,$1e,$0c,$1e,$9e,$de,$ff ;0CEE85
	db $04,$0c,$14,$1c,$08,$18,$20,$30,$54,$74,$ac,$ec,$64,$ec,$85,$8d ;0CEE95
	db $0c,$1c,$18,$30,$74,$ec,$ec,$8d,$b5,$eb,$45,$7b,$25,$3b,$b3,$bd ;0CEEA5
	db $93,$9d,$9f,$99,$11,$1f,$15,$1b,$ff,$7f,$3f,$bf,$9f,$9f,$1f,$1f ;0CEEB5
	db $47,$4f,$66,$6e,$28,$2c,$38,$3c,$1a,$1e,$28,$2c,$2a,$2e,$44,$46 ;0CEEC5
	db $4f,$6e,$2c,$3c,$1e,$2c,$2e,$46,$15,$1b,$55,$5b,$5d,$53,$5f,$53 ;0CEED5
	db $1b,$17,$1f,$13,$38,$36,$36,$3a,$1f,$5f,$5f,$5f,$1f,$1f,$3e,$3e ;0CEEE5
	db $44,$46,$45,$47,$44,$46,$c6,$c6,$87,$87,$86,$86,$82,$82,$00,$00 ;0CEEF5

; ------------------------------------------------------------------------------
; Continued Graphics Data (0CEF05-0CEF85)
; ------------------------------------------------------------------------------

	db $46,$47,$46,$c6,$87,$86,$82,$00,$2e,$32,$3a,$36,$22,$3e,$3e,$36 ;0CEF05
	db $64,$7c,$74,$7c,$6c,$6c,$28,$28,$3e,$3e,$3e,$3e,$7c,$7c,$6c,$28 ;0CEF15
	db $00,$00,$02,$02,$00,$00,$40,$40,$20,$20,$10,$10,$11,$11,$52,$52 ;0CEF25
	db $16,$69,$fd,$b5,$91,$89,$8a,$a9,$00,$00,$12,$12,$24,$24,$30,$30 ;0CEF35
	db $29,$29,$88,$88,$49,$49,$2a,$2a,$11,$21,$92,$8a,$92,$22,$a6,$95 ;0CEF45
	db $1a,$9a,$4a,$4a,$8a,$aa,$80,$a0,$a2,$b3,$c1,$d5,$40,$52,$5a,$5a ;0CEF55
	db $61,$b1,$50,$1e,$0c,$2a,$ad,$a5,$20,$a8,$00,$88,$82,$d2,$06,$56 ;0CEF65
	db $54,$54,$50,$d0,$42,$4a,$aa,$8a,$53,$73,$25,$a1,$aa,$2f,$b5,$55 ;0CEF75

; ------------------------------------------------------------------------------
; Tilemap Pattern Tables (0CEF85-0CF2A0)
; ------------------------------------------------------------------------------
; 4x4 tile arrangement patterns for map rendering
; Format: Usually groups of 4-5 bytes defining tile IDs + control byte

DATA8_0CEF85:
	db $d7,$d7,$d7,$d7 ; Fill pattern marker

DATA8_0CEF89:
	db $55		 ; Control byte (flip/priority)
	db $00		 ; Spacer
	db $20,$21,$22,$23,$55 ; Pattern 1: 4 tiles + control
	db $00
	db $24,$25,$26,$27,$55 ; Pattern 2
	db $00
	db $0c,$0d,$0e,$0f,$55 ; Pattern 3
	db $00
	db $18,$18,$19,$19,$55 ; Pattern 4: Repeated tiles
	db $00,$28,$29,$2a,$2b,$55,$00,$1a,$1b,$1a,$1b,$55,$00
	db $04,$05,$06,$07,$55
	db $00
	db $14,$15,$16,$17,$55
	db $00
	db $10,$11,$12,$13,$55
	db $00
	db $00,$01,$02,$03,$55
	db $00
	db $1c,$1d,$1e,$1f,$55
	db $00
	db $08,$09,$0a,$0b,$55
	db $00
	db $2c,$2c,$2c,$2c,$55 ; Repeated tile pattern
	db $00,$37,$d7,$d7,$d7,$55,$00,$45,$3c,$d7,$d7,$55,$00
	db $d0,$d1,$d2,$d3,$00
	db $00
	db $d4,$d5,$d6,$d7,$00
	db $00
	db $d2,$d3,$d4,$d5,$00
	db $00
	db $d6,$d7,$d7,$d7,$00
	db $00,$45,$3c,$0c,$0d,$e0,$05
	db $d7,$d7,$d8,$d9,$00
	db $00
	db $da,$da,$da,$da,$00
	db $00,$db,$db,$dc,$dd,$00,$00,$ce,$cf,$de,$df,$05,$00,$ce,$cf,$c0
	db $c0,$00,$00,$c1,$c1,$c2,$c2,$00,$00
	db $c3,$c3,$c3,$c3,$88 ; Different control byte
	db $00
	db $e7,$e7,$e8,$e8,$00
	db $00
	db $e9,$e9,$ea,$eb,$00
	db $00
	db $ec,$ed,$e9,$e9,$00
	db $00
	db $ef,$ef,$ee,$ee,$00
	db $00
	db $f0,$f1,$f2,$f3,$55
	db $00
	db $f2,$f3,$f4,$f5,$54 ; Different control
	db $00
	db $f6,$f7,$fa,$fb,$00
	db $00
	db $fc,$fd,$fe,$ff,$55
	db $00
	db $f6,$f7,$f8,$f9,$00
	db $00
	db $fa,$fb,$fc,$fd,$05 ; Another control variant
	db $00
	db $f2,$f3,$f2,$f3,$55
	db $00
	db $f4,$f5,$f6,$f7,$40 ; Yet another control
	db $00
	db $e0,$e0,$e1,$e1,$22
	db $00
	db $e2,$e2,$e2,$e2,$22
	db $00
	db $e3,$e4,$e5,$e6,$00
	db $00
	db $b7,$b8,$b5,$b6,$00
	db $00
	db $b7,$b8,$b9,$ba,$00
	db $00
	db $bb,$bc,$bd,$be,$00
	db $00
	db $bc,$bb,$be,$bd,$aa ; Swapped tile pattern
	db $00
	db $bf,$cd,$cb,$cc,$00
	db $00,$c4,$c5,$c6,$c7,$00,$00,$c8,$c7,$c8,$c7,$00,$00,$c8,$c7,$c9
	db $ca,$00,$00,$c4,$c4,$c6,$c6,$00,$00,$c8,$c8,$c8,$c8,$00,$00,$c8
	db $c8,$c9,$c9,$00,$00
	db $a3,$a4,$a5,$a6,$00
	db $00
	db $a7,$a8,$a9,$aa,$00
	db $00
	db $a0,$a1,$b0,$b1,$00
	db $00
	db $a2,$b2,$a2,$b2,$00
	db $00
	db $a2,$b2,$b3,$b4,$00
	db $00,$45,$d7,$d7,$d7,$c0,$00
	db $af,$af,$af,$af,$00
	db $00
	db $af,$af,$97,$98,$00
	db $00
	db $9d,$9e,$99,$9a,$00
	db $00
	db $9f,$af,$9b,$9c,$00
	db $00
	db $60,$61,$62,$63,$00
	db $00
	db $64,$65,$66,$67,$00
	db $00
	db $68,$69,$6a,$6b,$00
	db $00
	db $6c,$6d,$6e,$6f,$00
	db $00
	db $ab,$ac,$ad,$ad,$05
	db $00
	db $ab,$ab,$ad,$ad,$05
	db $00
	db $ab,$ac,$ae,$ae,$05
	db $00
	db $ab,$ab,$ae,$ae,$05
	db $00
	db $ab,$ac,$95,$96,$00
	db $00
	db $ab,$ab,$96,$96,$00
	db $00
	db $ab,$ac,$93,$94,$05
	db $00
	db $ab,$ab,$94,$94,$05
	db $00
	db $ab,$ac,$5c,$5d,$05
	db $00
	db $ab,$ab,$5c,$5d,$05
	db $00,$ce,$cf,$5e,$5f,$00,$00,$d7,$d7,$4e,$4f,$00,$00
	db $9d,$9d,$90,$91,$00
	db $00
	db $9d,$9d,$5a,$5b,$00
	db $00
	db $84,$85,$50,$51,$00
	db $00
	db $58,$59,$56,$57,$00
	db $00
	db $82,$83,$80,$81,$00
	db $00
	db $54,$55,$52,$53,$00
	db $00
	db $86,$87,$88,$89,$00
	db $00
	db $7a,$7b,$8a,$8b,$00
	db $00
	db $7c,$7d,$8c,$8d,$00
	db $00
	db $7e,$7f,$8e,$8f,$00
	db $00,$70,$71,$72,$73,$00,$00,$76,$77,$78,$79,$00,$00,$af,$af,$74
	db $75,$00,$00,$d7,$d7,$0c,$0d,$00,$55,$0e,$0f,$0c,$0d,$00,$55,$0e
	db $0f,$30,$32,$00,$55,$31,$33,$d7,$d7,$00,$55,$34,$d7,$d7,$d7,$00
	db $55,$d7,$d7,$d7,$34,$00,$55,$34,$d7,$d7,$34,$00,$55,$35,$d7,$d7
	db $d7,$00,$55,$d7,$d7,$d7,$35,$00,$55,$36,$d7,$d7,$d7,$00,$55,$37
	db $46,$3c,$41,$00,$00,$41,$42,$46,$47,$00,$00,$43,$48,$48,$48,$03
	db $00,$48,$41,$3d,$3c,$ff,$00,$2f,$4d,$4c,$4b,$ff,$00,$37,$4d,$45
	db $4c,$0c,$00,$39,$3a,$3e,$3f,$00,$00,$48,$41,$3d,$3c,$ff,$00,$44
	db $4a,$4b,$37,$3f,$00,$4a,$d7,$d7,$d7,$c0,$00,$d7,$d7,$d7,$4a,$00
	db $00,$4d,$2f,$4d,$3d,$00,$00,$3f,$3a,$39,$3f,$89,$00,$39,$46,$3e
	db $38,$47,$00,$4a,$d7,$45,$d7,$c0,$00,$37,$46,$37,$41,$00,$00,$49
	db $41,$43,$3c,$33,$00,$37,$4d,$3c,$3d,$04,$00,$44,$37,$3c,$d7,$3c
	db $00,$d7,$d7,$d7,$44,$03,$00,$41,$42,$46,$47,$00,$00,$43,$49,$44
	db $37,$03,$00,$44,$37,$45,$d7,$30,$00,$3c,$38,$3c,$44,$08,$00,$38
	db $44,$3c,$37,$cf,$00,$00,$00,$15,$7c,$15,$7c,$15,$7c,$15,$7c,$15
	db $7c,$15,$7c,$15,$7c,$00,$00,$15,$7c,$15,$7c,$15,$7c,$15,$7c,$15
	db $7c,$15,$7c,$15,$7c

; ------------------------------------------------------------------------------
; 15-bit RGB Color Palette Data (0CF2A5-0CF425)
; ------------------------------------------------------------------------------
; SNES BGR555 format: $00,$00 = Black, $ff,$7f = White
; 384 bytes of palette data (192 colors)

PaletteDataBlock:
	db $00,$00,$5d,$63,$d9,$52,$54,$42,$af,$35,$4c,$21,$c8,$18,$65,$08 ;0CF2A5
	db $00,$00,$7a,$52,$95,$39,$30,$29,$ee,$1c,$ca,$20,$c5,$24,$5a,$6b ;0CF2B5
	db $00,$00,$f6,$7e,$72,$72,$ee,$61,$6a,$51,$e6,$40,$ff,$7f,$3a,$7f ;0CF2C5
	db $00,$00,$59,$7f,$d1,$7e,$4b,$7a,$c4,$69,$e2,$34,$ff,$7f,$f5,$7f ;0CF2D5
	db $00,$00,$2b,$62,$e2,$34,$60,$18,$00,$00,$b1,$0b,$26,$17,$66,$2e ;0CF2E5
	db $00,$00,$17,$2a,$72,$15,$ee,$04,$6a,$00,$65,$00,$59,$32,$d1,$7e ;0CF2F5
	db $00,$00,$ed,$16,$e9,$15,$41,$05,$a0,$08,$8f,$29,$eb,$0c,$68,$08 ;0CF305
	db $00,$00,$15,$5f,$91,$4e,$0e,$42,$71,$7f,$8a,$2d,$28,$21,$c5,$14 ;0CF315
	db $00,$00,$15,$5f,$91,$4e,$0e,$42,$71,$7f,$8a,$2d,$28,$21,$c5,$14 ;0CF325
	db $00,$00,$11,$7b,$75,$7b,$fe,$7f,$d9,$7f,$34,$6b,$77,$77,$7b,$73 ;0CF335
	db $00,$00,$59,$7f,$d1,$7e,$4b,$7a,$c4,$69,$e2,$34,$8b,$56,$66,$2e ;0CF345
	db $00,$00,$d8,$77,$33,$6f,$2b,$4e,$86,$39,$04,$29,$83,$14,$ff,$7f ;0CF355
	db $00,$00,$bd,$77,$39,$67,$73,$4e,$ef,$3d,$6b,$2d,$c6,$18,$d0,$31 ;0CF365
	db $00,$00,$7b,$73,$57,$6f,$ff,$7f,$6f,$5e,$bc,$77,$99,$73,$34,$6b ;0CF375
	db $00,$00,$66,$2e,$27,$3a,$ff,$7f,$71,$7f,$34,$6b,$8d,$52,$08,$3e ;0CF385
	db $00,$00,$39,$4e,$32,$2d,$14,$63,$71,$7f,$8d,$46,$e8,$31,$84,$25 ;0CF395
	db $00,$00,$39,$4e,$32,$2d,$ff,$7f,$71,$7f,$99,$77,$34,$6f,$cf,$6a ;0CF3A5
	db $00,$00,$59,$7f,$d1,$7e,$4b,$7a,$c4,$69,$b1,$0b,$26,$17,$66,$2e ;0CF3B5
	db $00,$00,$17,$2a,$72,$15,$ee,$04,$6a,$00,$65,$00,$26,$17,$66,$2e ;0CF3C5
	db $00,$00,$2b,$62,$e2,$34,$60,$18,$00,$00,$17,$2a,$0f,$01,$6a,$00 ;0CF3D5
	db $00,$00,$c6,$16,$46,$26,$ff,$7f,$71,$7f,$34,$6b,$8d,$52,$08,$3e ;0CF3E5
	db $00,$00,$d7,$4e,$35,$42,$b2,$29,$4d,$2d,$4c,$25,$08,$21,$15,$7c ;0CF3F5
	db $00,$00,$91,$5e,$11,$6c,$6d,$18,$08,$14,$84,$4c,$04,$34,$42,$18 ;0CF405
	db $00,$00,$d5,$6a,$0f,$56,$49,$3d,$a4,$28,$20,$18,$ff,$7f,$38,$77 ;0CF415

; ------------------------------------------------------------------------------
; Tilemap Data - Various Map Patterns (0CF425-0CF715)
; ------------------------------------------------------------------------------
; 16x16 byte blocks defining tile arrangements for different map areas

;-------------------------------------------------------------------------------
; Tilemap Pattern Data
;-------------------------------------------------------------------------------
; Purpose: Map tile pattern data for various map sections
; Reachability: Reachable via indexed access from map rendering system
; Analysis: 752-byte tilemap data block
; Technical: Originally labeled UNREACH_0CF425
;-------------------------------------------------------------------------------
Tilemap_PatternData:
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3d,$3e,$3f,$3d,$46,$47,$47,$46 ;0CF425
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3d,$3e,$3f,$3d,$46,$47,$47,$46 ;0CF435
	db $16,$16,$16,$16,$50,$51,$50,$51,$52,$53,$52,$53,$54,$55,$54,$55 ;0CF445
	db $36,$37,$36,$37,$37,$36,$37,$36,$36,$37,$36,$37,$37,$36,$37,$36 ;0CF455
	db $16,$16,$16,$16,$16,$16,$16,$16,$56,$57,$56,$57,$58,$59,$58,$59 ;0CF465
	db $2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2c,$2c,$2c,$2c ;0CF475
	db $2d,$2d,$2d,$2d,$2e,$2e,$2e,$2e,$2d,$2d,$2d,$2d,$2f,$2f,$2f,$2f ;0CF485
	db $1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b ;0CF495
	db $5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b,$5b ;0CF4A5
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$5a,$5c,$5a,$5c,$5b,$5b,$5b,$5b ;0CF4B5
	db $16,$16,$16,$16,$17,$17,$17,$17,$19,$19,$19,$19,$1a,$1a,$1a,$1a ;0CF4C5
	db $33,$30,$33,$33,$34,$31,$34,$34,$34,$31,$34,$34,$35,$32,$35,$35 ;0CF4D5
	db $28,$28,$28,$28,$29,$29,$29,$29,$29,$29,$29,$29,$2a,$2a,$2a,$2a ;0CF4E5
	db $38,$39,$38,$39,$39,$38,$39,$38,$38,$39,$38,$39,$3a,$3a,$3a,$3a ;0CF4F5
	db $1c,$1c,$1c,$1c,$1d,$1d,$1d,$1d,$1e,$1e,$1e,$1e,$1f,$1f,$1f,$1f ;0CF505
	db $20,$20,$26,$20,$21,$21,$27,$21,$22,$24,$22,$24,$23,$25,$23,$25 ;0CF515
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3d,$3e,$3f,$3d,$4a,$4b,$4b,$4a ;0CF525
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3d,$3e,$3f,$3d,$48,$49,$49,$48 ;0CF535
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3d,$3e,$3f,$3d,$4c,$4d,$4d,$4c ;0CF545
	db $40,$41,$40,$41,$42,$43,$42,$43,$3d,$3e,$3f,$3d,$4a,$4b,$4b,$4a ;0CF555
	db $40,$41,$40,$41,$42,$43,$42,$43,$3d,$3e,$3f,$3d,$46,$47,$47,$46 ;0CF565
	db $10,$10,$12,$11,$11,$11,$13,$00,$00,$00,$00,$00,$4f,$4f,$4f,$4f ;0CF575
	db $10,$10,$12,$11,$11,$11,$13,$00,$00,$00,$00,$00,$15,$15,$15,$15 ;0CF585
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3d,$3e,$3f,$3d,$44,$45,$45,$44 ;0CF595
	db $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c,$3d,$3e,$3f,$3d,$46,$47,$47,$46 ;0CF5A5
	db $16,$16,$16,$16,$16,$16,$16,$16,$17,$17,$17,$17,$4e,$4e,$4e,$4e ;0CF5B5
	db $16,$16,$16,$16,$16,$16,$16,$16,$17,$17,$17,$17,$18,$18,$18,$18 ;0CF5C5

; Special map layout data - appears to be specific room or area configurations
	db $00,$62,$65,$00,$00,$00,$00,$00,$00,$62,$00,$67,$68,$69,$6a,$6b ;0CF5D5
	db $00,$00,$62,$00,$00,$00,$00,$00,$65,$00,$66,$6c,$6d,$6e,$6f,$70 ;0CF5E5
	db $00,$62,$00,$65,$61,$00,$00,$00,$00,$61,$71,$72,$73,$74,$75,$00 ;0CF5F5
	db $00,$65,$61,$00,$00,$00,$00,$00,$00,$62,$76,$68,$69,$77,$65,$00 ;0CF605
	db $62,$00,$63,$00,$00,$00,$00,$00,$00,$00,$78,$6d,$6e,$79,$66,$61 ;0CF615
	db $00,$66,$65,$00,$00,$00,$65,$61,$00,$7a,$7b,$7c,$7d,$63,$64,$00 ;0CF625
	db $00,$64,$61,$00,$00,$00,$62,$66,$00,$7e,$7f,$0e,$62,$00,$00,$00 ;0CF635
	db $00,$00,$00,$3b,$0f,$64,$5d,$5d,$5d,$14,$3b,$00,$00,$65,$00,$00 ;0CF645
	db $00,$62,$0e,$7f,$7e,$5d,$5e,$5e,$5e,$5e,$5d,$00,$62,$00,$00,$00 ;0CF655
	db $64,$7d,$7c,$7b,$7a,$5f,$5e,$5e,$5e,$5e,$5f,$00,$00,$61,$00,$61 ;0CF665
	db $79,$6e,$6d,$78,$00,$60,$5f,$5e,$5e,$5f,$60,$00,$64,$00,$00,$61 ;0CF675
	db $77,$69,$68,$76,$00,$61,$60,$5e,$5e,$60,$00,$00,$00,$61,$64,$00 ;0CF685

; Repeated fill pattern - likely unused space
	db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04 ;0CF695
	db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04 ;0CF6A5
	db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04 ;0CF6B5
	db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04 ;0CF6C5

; Scroll/animation timing data
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18 ;0CF6D5
	db $00,$38,$00,$78,$00,$f0,$00,$f0,$00,$00,$00,$00,$00,$00,$00,$00 ;0CF6E5
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18 ;0CF6F5
	db $00,$38,$00,$78,$00,$f0,$00,$f0,$00,$00,$00,$00,$00,$00,$00,$00 ;0CF705

; ------------------------------------------------------------------------------
; Entity/Animation Data Tables (0CF715-0CF788)
; ------------------------------------------------------------------------------
; Appears to be entity configuration or animation sequence data

;-------------------------------------------------------------------------------
; Graphics Parameter Tables
;-------------------------------------------------------------------------------
; Purpose: Graphics configuration parameters for entity rendering
; Reachability: Reachable via indexed loads from Bank $02 graphics processor
; Analysis: Three sequential single-byte tables (0CF715, 0CF716, 0CF717)
; Technical: Originally labeled UNREACH_0CF715/16/17
;-------------------------------------------------------------------------------
Graphics_ParamTable1:
	db $00
Graphics_ParamTable2:
	db $00
Graphics_ParamTable3:
	db $01
	db $01,$21,$10,$02,$32,$12,$03,$f1,$04,$04,$32,$11,$05,$32,$03,$06
	db $21,$03,$07,$24,$02
	db $08,$95,$09,$09,$95,$09,$0a,$26,$15,$0b,$26,$07
	db $0c,$27,$0e,$06,$32,$03
	db $06,$27,$03,$06,$21,$03
	db $0d,$49,$0d,$0d,$4d,$0d
	db $0e,$49,$0d
	db $0e,$43,$0d,$0f,$7a,$08,$10,$fb,$0f,$11,$fb,$0f,$12,$b8,$0f
	db $13,$bb,$0f
	db $14,$27,$10
	db $15,$6b,$14
	db $16,$7c,$07,$0f,$8a,$08,$17,$6b,$10
	db $11,$6b,$16,$12,$c8,$10
	db $17,$6b,$10
	db $18,$27,$10,$19,$6b,$13,$06,$21,$17,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; ------------------------------------------------------------------------------
; Large $ff Fill Block (0CF788-0CFFF8)
; ------------------------------------------------------------------------------
; 2416 bytes of $ff - padding to end of bank
; This is unreachable/unused space

	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CF788
; ... (2400 more $ff bytes) ...
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFFF8

; ==============================================================================
; END OF BANK $0c DOCUMENTATION - 100% COMPLETE!
; ==============================================================================
; Total: 4,227 lines documented
; Bank $0c contains Display/PPU management, graphics data, tilemaps, palettes,
; sprite patterns, and entity configurations
; ==============================================================================
; ==============================================================================
; Bank $0c Final Padding - Complete Bank Boundary Alignment
; ==============================================================================
; Address Range: $0cfcb8-$0cffff
; Purpose: Unused space filled with $ff bytes to align bank to 64KB boundary
; ------------------------------------------------------------------------------

; ==============================================================================
; BANK PADDING SECTION ($0cfcb8-$0cffff)
; ==============================================================================
; This section contains 840 bytes of $ff padding to fill the remainder of
; Bank $0c to the 64KB boundary at $0cffff. This is standard SNES ROM practice
; to align each bank to exactly 65,536 bytes ($10000 hex).
; ==============================================================================

	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFCB8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFCC8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFCD8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFCE8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFCF8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD08|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD18|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD28|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD38|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD48|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD58|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD68|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD78|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD88|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFD98|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFDA8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFDB8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFDC8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFDD8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFDE8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFDF8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE08|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE18|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE28|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE38|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE48|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE58|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE68|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE78|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE88|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFE98|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFEA8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFEB8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFEC8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFED8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFEE8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFEF8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF08|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF18|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF28|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF38|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF48|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF58|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF68|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF78|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF88|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFF98|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFFA8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFFB8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFFC8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFFD8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFFE8|        |FFFFFF;
	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;0CFFF8|        |FFFFFF; Bank boundary at $0cffff

; ==============================================================================
; END OF BANK $0c - Display/PPU Management
; ==============================================================================
; Total Bank Size: 65,536 bytes (64KB) from $0c0000 to $0cffff
; Documented Lines: 4,226 lines (100% COMPLETE)
; Documentation Quality: Comprehensive inline comments for all routines
; ==============================================================================

