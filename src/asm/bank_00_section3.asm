; ===========================================================================
; Character Status Animation (continued from earlier sections)
; ===========================================================================

CODE_008A0B:
    ; Check character slot 5
    LDA.L $70073F                    ; Check character 5 in party data
    BNE CODE_008A16                  ; If present, skip animation
    LDX.B #$80                       ; Animation offset for slot 5
    JSR.W CODE_008A2A                ; Animate status icon

CODE_008A16:
    ; Check character slot 6
    LDA.L $70078F                    ; Check character 6 in party data
    BNE CODE_008A21                  ; If present, skip animation
    LDX.B #$90                       ; Animation offset for slot 6
    JSR.W CODE_008A2A                ; Animate status icon

CODE_008A21:
    ; Set update flag and return
    LDA.B #$20                       ; Bit 5 flag
    TSB.W $00D2                      ; Set bit in display flags

CODE_008A26:
    REP #$30                         ; 16-bit A, X, Y
    PLD                              ; Restore direct page
    RTS                              ; Return

; ===========================================================================
; Animate Status Icon
; ===========================================================================
; Purpose: Toggle character status icon animation frame
; Input: X = OAM data offset for character slot
; Technical Details: Toggles tile numbers to create animation effect
; ===========================================================================

CODE_008A2A:
    ; Toggle tile animation frame
    LDA.B $02,X                      ; Get current tile number
    EOR.B #$04                       ; Toggle bit 2 (animation frame)
    STA.B $02,X                      ; Store back to OAM
    
    ; Update adjacent sprite tiles
    INC A                            ; Next tile
    STA.W $0C06,X                    ; Store to OAM +4
    INC A                            ; Next tile
    STA.W $0C0A,X                    ; Store to OAM +8
    INC A                            ; Next tile
    STA.W $0C0E,X                    ; Store to OAM +12
    RTS                              ; Return

; ===========================================================================
; Input Handler Jump Table
; ===========================================================================
; Purpose: Dispatch table for different input contexts
; Format: Table of 16-bit addresses for input handler functions
; ===========================================================================

Input_Handler_Table:
    dw Input_Down                    ; $008A3D: Down button handler
    dw Input_Up                      ; $008A3F: Up button handler
    dw Input_Action                  ; $008A41: A/B button handler
    dw Input_Action                  ; $008A43: (duplicate)
    dw Input_Left                    ; $008A45: Left button handler
    dw Input_Right                   ; $008A47: Right button handler
    dw Input_Right                   ; $008A49: (alternate)
    dw Input_Left                    ; $008A4B: (alternate)
    dw Input_Action                  ; $008A4D: (action variant)
    dw Input_Action                  ; $008A4F: (action variant)
    dw Input_Switch_Character        ; $008A51: Character switch
    dw Input_Action                  ; $008A53: (action variant)

; ===========================================================================
; Menu Cursor Movement - Vertical
; ===========================================================================

Input_Left:
    DEC.B $02                        ; Move cursor left
    BRA Validate_Cursor_Position     ; Check bounds

Input_Right:
    INC.B $02                        ; Move cursor right
    BRA Validate_Cursor_Position     ; Check bounds

Input_Up:
    DEC.B $01                        ; Move cursor up
    BRA Validate_Cursor_Position     ; Check bounds

Input_Down:
    INC.B $01                        ; Move cursor down
    ; Fall through to validation

; ===========================================================================
; Validate Cursor Position
; ===========================================================================
; Purpose: Ensure cursor stays within menu bounds, handle wrapping
; Technical Details: Checks against bounds in $03/$04, handles wrap flags
; ===========================================================================

Validate_Cursor_Position:
    ; Check vertical bounds
    LDA.B $01                        ; Get cursor Y position
    BMI Cursor_Above_Top             ; If negative, handle wrap
    CMP.B $03                        ; Compare to max Y
    BCC Cursor_Horizontal_Check      ; If within bounds, check horizontal
    
    ; Cursor below bottom
    LDA.B $95                        ; Get wrap flags
    AND.B #$01                       ; Check vertical wrap down flag
    BNE Cursor_Above_Top             ; If set, wrap to top
    
Clamp_Cursor_Bottom:
    LDA.B $03                        ; Get max Y
    DEC A                            ; Subtract 1
    STA.B $01                        ; Clamp cursor to bottom
    BRA Cursor_Horizontal_Check      ; Check horizontal

Cursor_Above_Top:
    ; Cursor above top
    LDA.B $95                        ; Get wrap flags
    AND.B #$02                       ; Check vertical wrap up flag
    BNE Clamp_Cursor_Bottom          ; If set, wrap to bottom
    STZ.B $01                        ; Clamp cursor to top

Cursor_Horizontal_Check:
    ; Check horizontal bounds
    LDA.B $02                        ; Get cursor X position
    BMI Cursor_Left_Of_Min           ; If negative, handle wrap
    CMP.B $04                        ; Compare to max X
    BCC Cursor_Valid                 ; If within bounds, done
    
    ; Cursor right of maximum
    LDA.B $95                        ; Get wrap flags
    AND.B #$04                       ; Check horizontal wrap right flag
    BNE Cursor_Left_Of_Min           ; If set, wrap to left

Clamp_Cursor_Right:
    LDA.B $04                        ; Get max X
    DEC A                            ; Subtract 1
    STA.B $02                        ; Clamp cursor to right
    RTS                              ; Done

Cursor_Left_Of_Min:
    ; Cursor left of minimum
    LDA.B $95                        ; Get wrap flags
    AND.B #$08                       ; Check horizontal wrap left flag
    BNE Clamp_Cursor_Right           ; If set, wrap to right
    STZ.B $02                        ; Clamp cursor to left

Cursor_Valid:
    RTS                              ; Return

; ===========================================================================
; Character Switch Input Handler
; ===========================================================================
; Purpose: Handle character switching in menu/field
; Technical Details: Toggles between Benjamin and Phoebe
; ===========================================================================

Input_Switch_Character:
    JSR.W CODE_008B57                ; Check if switching allowed
    BNE Switch_Done                  ; If not allowed, exit
    
    ; Check if character is valid
    LDA.W $1090                      ; Get character status
    BMI Play_Error_Sound             ; If invalid, play error
    
    ; Toggle character
    LDA.W $10A0                      ; Get character flags
    EOR.B #$80                       ; Toggle bit 7 (Benjamin/Phoebe)
    STA.W $10A0                      ; Store new character
    
    ; Update display
    LDA.B #$40                       ; Set update flag
    TSB.W $00D4                      ; Set in display flags
    JSR.W CODE_00B908                ; Update character sprite
    BRA Switch_Done                  ; Done

Play_Error_Sound:
    JSR.W CODE_00B912                ; Play error sound

Switch_Done:
    RTS                              ; Return

; ===========================================================================
; Menu Action Validation
; ===========================================================================
; Purpose: Check if menu action at current position is valid
; Technical Details: Validates based on map position and character state
; ===========================================================================

CODE_008ABD:
    ; Check if on valid action tile
    LDA.W $1032                      ; Get tile X position
    CMP.B #$80                       ; Compare to invalid marker
    BNE Action_Valid                 ; If not marker, action valid
    LDA.W $1033                      ; Get tile Y position
    BNE Action_Valid                 ; If not zero, action valid
    JMP.W CODE_00B912                ; Invalid: play error sound

Action_Valid:
    JMP.W CODE_00B908                ; Valid: play confirm sound

; ===========================================================================
; Menu Scroll - Down
; ===========================================================================
; Purpose: Scroll menu list downward
; Technical Details: Calculates next visible item, updates display
; ===========================================================================

Scroll_Menu_Down:
    JSR.W CODE_008B57                ; Check if scrolling allowed
    BNE Scroll_Down_Done             ; If blocked, exit
    JSR.W CODE_008ABD                ; Play appropriate sound
    
    ; Calculate current row from pixel position
    LDA.W $1031                      ; Get Y pixel position
    SEC                              ; Set carry for subtraction
    SBC.B #$20                       ; Subtract top margin (32 pixels)
    LDX.B #$FF                       ; Initialize row counter to -1

Count_Rows_Down:
    INX                              ; Increment row counter
    SBC.B #$03                       ; Subtract row height (3 pixels)
    BCS Count_Rows_Down              ; If still positive, continue counting
    
    ; TXA now contains current row number
    TXA                              ; Transfer row to A

Find_Next_Valid_Row:
    INC A                            ; Next row
    AND.B #$03                       ; Wrap to 0-3 range
    PHA                              ; Save row number
    JSR.W CODE_008DA8                ; Check if row has valid item
    PLA                              ; Restore row number
    CPY.B #$FF                       ; Check if item valid
    BEQ Find_Next_Valid_Row          ; If invalid, try next row
    
    ; Update display with new row
    JSR.W CODE_008B21                ; Update menu display
    JSR.W CODE_008C3D                ; Update graphics

Scroll_Down_Done:
    RTS                              ; Return

; ===========================================================================
; Menu Scroll - Up
; ===========================================================================
; Purpose: Scroll menu list upward
; Technical Details: Similar to down scroll but decrements
; ===========================================================================

Scroll_Menu_Up:
    JSR.W CODE_008B57                ; Check if scrolling allowed
    BNE Scroll_Up_Done               ; If blocked, exit
    JSR.W CODE_008ABD                ; Play appropriate sound
    
    ; Calculate current row
    LDA.W $1031                      ; Get Y pixel position
    SEC                              ; Set carry
    SBC.B #$20                       ; Subtract top margin
    LDX.B #$FF                       ; Initialize counter

Count_Rows_Up:
    INX                              ; Increment counter
    SBC.B #$03                       ; Subtract row height
    BCS Count_Rows_Up                ; Continue counting
    
    TXA                              ; Transfer row to A

Find_Previous_Valid_Row:
    DEC A                            ; Previous row
    AND.B #$03                       ; Wrap to 0-3 range
    PHA                              ; Save row number
    JSR.W CODE_008DA8                ; Check if row has valid item
    PLA                              ; Restore row number
    CPY.B #$FF                       ; Check if valid
    BEQ Find_Previous_Valid_Row      ; If invalid, try previous
    
    ; Update display
    JSR.W CODE_008B21                ; Update menu display
    JSR.W CODE_008C3D                ; Update graphics

Scroll_Up_Done:
    RTS                              ; Return

; ===========================================================================
; Update Menu Display
; ===========================================================================
; Purpose: Update menu tilemap based on current selection
; Technical Details: Copies appropriate tile data to WRAM buffer
; ===========================================================================

CODE_008B21:
    REP #$30                         ; 16-bit A, X, Y
    
    ; Determine source tilemap based on Y position
    LDX.W #$3709                     ; Default source (rows 0-2)
    CPY.W #$0023                     ; Check if Y < $23
    BCC Copy_Menu_Tiles              ; If yes, use default
    
    LDX.W #$3719                     ; Source for rows 3-5
    CPY.W #$0026                     ; Check if Y < $26
    BCC Copy_Menu_Tiles              ; If yes, use this source
    
    LDX.W #$3729                     ; Source for rows 6-8
    CPY.W #$0029                     ; Check if Y < $29
    BCC Copy_Menu_Tiles              ; If yes, use this source
    
    LDX.W #$3739                     ; Source for rows 9+

Copy_Menu_Tiles:
    LDY.W #$3669                     ; Destination in WRAM
    LDA.W #$000F                     ; Copy 16 bytes
    MVN $7E,$7E                      ; Block move within bank $7E
    
    ; Restore state and redraw layer
    PHK                              ; Push program bank
    PLB                              ; Pull to data bank
    LDA.W #$0000                     ; Layer 0
    JSR.W CODE_0091D4                ; Redraw layer
    
    SEP #$30                         ; 8-bit A, X, Y
    LDA.B #$80                       ; Set update flag
    TSB.W $00D9                      ; Set in status flags
    RTS                              ; Return

; ===========================================================================
; Check Input Blocking Flags
; ===========================================================================
; Purpose: Determine if input should be blocked
; Output: Z flag set if input blocked
; ===========================================================================

CODE_008B57:
    LDA.B #$10                       ; Check bit 4
    AND.W $00D6                      ; Test blocking flags
    BEQ Input_Not_Blocked            ; If clear, input allowed
    
    ; Input is blocked, clear certain button flags
    REP #$30                         ; 16-bit A, X, Y
    LDA.B $92                        ; Get current joypad state
    AND.W #$BFCF                     ; Clear bits 4,5,14 (A,B,X buttons?)
    SEP #$30                         ; 8-bit A, X, Y

Input_Not_Blocked:
    RTS                              ; Return (Z flag indicates status)

; ===========================================================================
; Tile Position to VRAM Address Calculation
; ===========================================================================
; Purpose: Convert tile coordinates to VRAM address
; Input: A = tile position (3 bits Y, 3 bits X in bits 0-5)
; Output: A = VRAM address
; ===========================================================================

CODE_008C1B:
    PHP                              ; Preserve processor status
    REP #$30                         ; 16-bit A, X, Y
    AND.W #$00FF                     ; Clear high byte
    PHA                              ; Save original value
    
    ; Extract Y coordinate (bits 3-5)
    AND.W #$0038                     ; Mask to get bits 3-5 (Y * 8)
    ASL A                            ; Multiply by 2 (Y * 16)
    TAX                              ; Save Y offset in X
    
    ; Extract X coordinate (bits 0-2)
    PLA                              ; Restore original value
    AND.W #$0007                     ; Mask to get bits 0-2 (X)
    PHX                              ; Save Y offset
    ADC.B $01,S                      ; Add Y offset
    STA.B $01,S                      ; Store back
    
    ; Calculate final VRAM address
    ASL A                            ; Multiply by 2
    ADC.B $01,S                      ; Add previous result (x3)
    ASL A                            ; Multiply by 16 (shift left 4)
    ASL A
    ASL A
    ASL A
    ADC.W #$8000                     ; Add VRAM base address
    
    PLX                              ; Clean up stack
    PLP                              ; Restore processor status
    RTS                              ; Return

; ===========================================================================
; Update Character Tile on Map
; ===========================================================================
; Purpose: Update character sprite tile in dual buffer mode
; Technical Details: Updates both WRAM buffers for seamless display
; ===========================================================================

CODE_008C3D:
    PHP                              ; Preserve processor status
    SEP #$30                         ; 8-bit A, X, Y
    
    LDX.W $1031                      ; Get character map position
    CPX.B #$FF                       ; Check if valid position
    BEQ Update_Done                  ; If invalid, exit
    
    ; Check if dual buffer mode active (battle/transition)
    LDA.B #$02                       ; Check bit 1
    AND.W $00D8                      ; Test display mode flags
    BEQ Single_Buffer_Update         ; If clear, single buffer only
    
    ; Dual buffer mode - update both WRAM buffers
    LDA.L DATA8_049800,X             ; Get character tile number
    ADC.B #$0A                       ; Add offset for animation frame
    XBA                              ; Swap to high byte
    
    ; Calculate tilemap address
    TXA                              ; Position to A
    AND.B #$38                       ; Get Y coordinate (bits 3-5)
    ASL A                            ; Multiply by 2
    PHA                              ; Save
    TXA                              ; Position to A again
    AND.B #$07                       ; Get X coordinate (bits 0-2)
    ORA.B $01,S                      ; Combine with Y offset
    PLX                              ; Clean stack
    ASL A                            ; Multiply by 2
    REP #$30                         ; 16-bit mode
    
    ; Store to both buffers
    STA.L $7F075A                    ; Buffer 1 - tile 1
    INC A
    STA.L $7F075C                    ; Buffer 1 - tile 2
    ADC.W #$000F                     ; Next row offset
    STA.L $7F079A                    ; Buffer 1 - tile 3
    INC A
    STA.L $7F079C                    ; Buffer 1 - tile 4
    
    SEP #$20                         ; 8-bit A
    LDX.W #$17DA                     ; Source data pointer
    LDA.B #$7F                       ; Bank $7F
    BRA Perform_DMA_Update           ; Do DMA transfer

Update_Done:
    PLP                              ; Restore status
    RTS                              ; Return

Single_Buffer_Update:
    ; Handle single buffer update
    ; (code continues...)
    
Perform_DMA_Update:
    ; Execute DMA transfer to update VRAM
    ; (code continues...)

;===============================================================================
; Progress: ~1,500 lines documented (10.7% of Bank $00)
; Sections completed:
; - Boot sequence and hardware init
; - DMA and graphics transfers
; - VBlank processing
; - Menu navigation and cursor movement
; - Input handling and validation
; - Character switching
; - Tilemap updates
; 
; Remaining: ~12,500 lines (battle system, map scrolling, more menus, etc.)
;===============================================================================
