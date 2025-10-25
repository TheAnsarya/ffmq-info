;==============================================================================
; Final Fantasy Mystic Quest - NMI (VBlank) Interrupt Handler Analysis
;==============================================================================
; NMI Vector: $00FFE6 → Points to $011B
; IRQ Vector: $00FFEE → Points to $0117  
; Called during VBlank to handle screen updates and game timing
;
; CRITICAL: This is the heartbeat of the game's graphics system!
; Every frame, this interrupt fires and coordinates all screen updates.
;==============================================================================

;------------------------------------------------------------------------------
; NMI Handler Entry Point
;------------------------------------------------------------------------------
; Address: $00011B (referenced from vector at $FFE6)
; 
; The NMI (Non-Maskable Interrupt) fires at the start of VBlank period
; (~60 times per second on NTSC systems). This is when it's safe to update
; VRAM, OAM, and palettes without causing visual glitches.
;
; Key responsibilities:
; 1. Set VBlank flag ($00D8.6) to signal main code
; 2. Execute pending graphics transfers (DMA operations)
; 3. Update sprites (OAM data)
; 4. Update scroll registers
; 5. Handle screen transitions
;------------------------------------------------------------------------------

; NOTE: The actual NMI handler code is located in a different bank
; Looking at the vectors:
; - $FFE6 points to $011B (NMI handler)
; - This would be in ROM address $00011B (bank $00)
; 
; However, based on grep search finding NMITIMEN writes in bank_00,
; the handler is likely near the beginning of the ROM.

;------------------------------------------------------------------------------
; NMI-Related Code References Found
;------------------------------------------------------------------------------
; From bank_00.asm analysis:
;
; 1. NMITIMEN Setup (Enable NMI):
;    - $00807D: Loads $0112 and writes to NMITIMEN ($4200)
;    - This enables VBlank NMI interrupt
;
; 2. NMITIMEN Disable:
;    - $008249: STZ NMITIMEN (disables interrupts)
;    - Used during initialization/shutdown
;
; 3. NMI Handler Reference:
;    - $00806E: JSL $00011F (calls routine near NMI vector)
;    - This suggests initialization code for NMI system
;
; 4. VBlank Wait Function (WaitForVBlank):
;    - Located at $0C8000 (bank_0C.asm)
;    - Most frequently called function in entire game!
;    - Waits for VBlank flag at $00D8.6
;
; Pattern identified:
; - NMI handler SETS $00D8.6 (VBlank occurred)
; - WaitForVBlank routine CLEARS $00D8.6 and waits for it to be set
; - This synchronizes game logic with screen refresh

;------------------------------------------------------------------------------
; VBlank Flag System
;------------------------------------------------------------------------------
; RAM Address: $00D8 (byte)
; Bit 6 ($40): VBlank occurrence flag
;
; Set by: NMI handler (when VBlank interrupt fires)
; Cleared by: WaitForVBlank function at $0C8000
;
; Usage pattern:
;   1. Game code calls WaitForVBlank ($0C8000)
;   2. WaitForVBlank clears $00D8.6 and spins in loop
;   3. NMI interrupt fires at start of VBlank
;   4. NMI handler sets $00D8.6
;   5. WaitForVBlank detects flag and returns
;   6. Game code continues, knowing VBlank just started
;
; This ensures ALL screen updates happen during VBlank period!

;------------------------------------------------------------------------------
; DMA Transfer System (Called from NMI)
;------------------------------------------------------------------------------
; The game uses DMA (Direct Memory Access) to quickly copy data to VRAM
; during VBlank. NMI handler coordinates these transfers.
;
; DMA Channel 5 Parameters (found in ram_map.asm):
;   $01EB-$01EF: Additional DMA parameters
;   $01F0-$01F1: OAM transfer size
;   $01F2-$01F3: Extended OAM size
;   $01F4-$01F5: VRAM transfer size
;   $01F6-$01F8: Source address (bank $7F)
;
; Pattern from CODE_008385 (DMA Transfer to VRAM):
;   - Setup DMA5 params: $1801 (word, increment, to $2118/VMDATAL)
;   - Source: Bank $7F + offset in $01F6-$01F8
;   - Size: $01F4-$01F5 bytes
;   - Dest VRAM: $01F8-$01F9 address
;   - VMAINC = $84 (word increment mode)
;   - Trigger: Write $20 to MDMAEN ($420B) - start DMA ch 5
;
; This happens INSIDE NMI to ensure safe VRAM access!

;------------------------------------------------------------------------------
; OAM (Sprite) Update System
;------------------------------------------------------------------------------
; From CODE_008543 analysis:
; 
; Two OAM transfers happen per frame during NMI:
; 1. Main OAM ($0C00): 512 bytes → $2102 (OAMADDL)
;    - Sprite positions, tile numbers, attributes
;    - Size: $01F0 bytes (from DMA params)
;
; 2. Extended OAM ($0E00): 32 bytes → $2102+$100
;    - High X bits, sprite sizes
;    - Size: $01F2 bytes (from DMA params)
;
; DMA setup for OAM:
;   - Mode: $0400 (byte transfer to fixed address)
;   - Dest: $2104 (OAMDATA)
;   - Source: $00:0C00 (main OAM RAM)
;   - Trigger via MDMAEN ($420B)

;------------------------------------------------------------------------------
; Graphics Update Flags
;------------------------------------------------------------------------------
; The game uses flag bytes to signal what needs updating during NMI.
; These are checked in the NMI handler to determine which operations to perform.
;
; $00D2 flags (found in CODE_008337+):
;   Bit 7 ($80): VRAM tilemap update pending
;   Bit 6 ($40): Full background refresh needed
;   Bit 5 ($20): Palette update required
;   Bit 4 ($10): Menu cursor update
;
; $00DD flags:
;   Bit 6 ($40): Major DMA transfer pending (sets up at CODE_008385)
;
; $00D4 flags:
;   Bit 7 ($80): Enemy palette update
;   Bit 6 ($40): Character status update
;   Bit 5 ($20): OAM sprite update
;   Bit 1 ($02): Full tilemap reload
;
; Pattern:
;   Main code SETS these flags when changes occur
;   NMI handler CHECKS flags and performs operations
;   NMI handler CLEARS flags after processing
;   This prevents duplicate work!

;------------------------------------------------------------------------------
; Screen Update Sequence (Typical NMI Flow)
;------------------------------------------------------------------------------
; Based on CODE_008337 analysis (main NMI processing loop):
;
; 1. NMI interrupt fires
; 2. Save registers, set Direct Page to $4300 (DMA registers)
; 3. Clear DMA busy flag
; 4. Check $00E2.6 - if set, execute callback at [$0058]
; 5. Check $00D4.1 - if set, do tilemap transfer
; 6. Check $00DD.6 - if set, do major DMA operation (CODE_008385)
; 7. Check $00D2.7 - if set, do VRAM update
; 8. Check $00D2.5 - if set, do palette transfer (CODE_008543)
; 9. Check $00D2.6 - if set, do background refresh
; 10. Set VBlank flag ($00D8.6)
; 11. Restore registers and RTI (return from interrupt)
;
; This explains why WaitForVBlank is so critical - it ensures
; game logic only proceeds AFTER all screen updates complete!

;------------------------------------------------------------------------------
; IRQ Handler
;------------------------------------------------------------------------------
; IRQ Vector: $00FFEE → Points to $0117
; 
; Less commonly used than NMI. Typically for special effects:
; - Mid-screen palette changes (color math)
; - Horizontal scroll effects (wavy backgrounds)
; - HDMA (Horizontal-DMA) for per-scanline effects
;
; From vector table at end of bank_00.asm

;------------------------------------------------------------------------------
; Summary of NMI System
;------------------------------------------------------------------------------
; 
; The NMI interrupt is the synchronization point for ALL graphics:
; 
; Main Loop Pattern:
;   while (true) {
;       // Game logic updates
;       UpdatePlayer();
;       UpdateEnemies();
;       UpdateMenu();
;       
;       // Prepare graphics data
;       BuildOAM();        // Sets $00D2.5
;       BuildTilemap();    // Sets $00DD.6
;       UpdatePalettes();  // Sets $00D2.5
;       
;       // Wait for VBlank and let NMI do the transfers
;       WaitForVBlank();   // Spins until $00D8.6 set by NMI
;   }
;
; NMI Handler Pattern:
;   NMI_Handler() {
;       if ($00DD.6) DMA_TransferToVRAM();
;       if ($00D2.7) Update_Tilemap();
;       if ($00D2.5) Transfer_Palettes();
;       $00D8 |= $40;  // Signal VBlank occurred
;       RTI;
;   }
;
; This architecture ensures:
; 1. No screen tearing (all updates during VBlank)
; 2. Consistent frame rate (code waits for VBlank)
; 3. Efficient use of VBlank time (DMA transfers)
; 4. Clean separation of logic and rendering
;
; DISCOVERY: The VBlank flag at $00D8.6 is the CRITICAL synchronization
; point that makes the entire game's graphics system work!

;------------------------------------------------------------------------------
; TODO: Deep Analysis Required
;------------------------------------------------------------------------------
; To complete this analysis, need to:
; 1. Locate actual NMI handler code at $00011B
; 2. Trace complete execution flow through handler
; 3. Document all flag checks and corresponding operations
; 4. Map all DMA transfer patterns used
; 5. Document callback system at $0058-$005A
; 6. Analyze IRQ handler at $0117 (if used)
; 7. Find HDMA setup code (if present)
;
; The NMI handler is likely in bank $00 near beginning of ROM,
; but Diztinguish may have disassembled it in a confusing way.
; Need to manually trace from vector $011B.

;==============================================================================
; Analysis Confidence: MEDIUM-HIGH
; - VBlank flag system: VERIFIED (seen across many files)
; - DMA patterns: VERIFIED (CODE_008385, CODE_008543)
; - Flag system: VERIFIED (extensive usage found)
; - Actual NMI handler code: NOT YET LOCATED (need manual trace)
; - Complete flow: INFERRED from evidence, needs verification
;==============================================================================
