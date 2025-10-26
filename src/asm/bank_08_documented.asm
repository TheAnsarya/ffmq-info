; ==============================================================================
; BANK $08 - Text and Dialog Data
; ==============================================================================
; Bank Size: 3,291 lines (2,058 total in source)
; Primary Content: Game dialog, menus, battle messages, NPC text
; Format: Compressed text with control codes + pointer tables
;
; Text System Architecture:
; - Text stored compressed using custom encoding
; - Pointer tables reference dialog strings
; - Control codes for formatting, pauses, variables
; - Character encoding: Custom table-based (not ASCII)
;
; Text Control Codes (observed patterns):
; - $F0: End of string
; - $F1-$F7: Special formatting (pause, clear, newline)
; - $00-$7F: Character codes (reference simple.tbl)
; - $80-$EF: Extended characters or commands
;
; Cross-References:
; - Bank $00: Text rendering engine
; - Bank $01: Battle text display
; - Bank $02: Dialog box handling
; - simple.tbl: Character encoding table
; ==============================================================================

					   ORG $088000

; ------------------------------------------------------------------------------
; Text Pointer Table Section 1 - Main Story Dialog
; ------------------------------------------------------------------------------
; Format: [addr_lo][addr_hi][flags]...
; Pointers reference text strings later in bank
; ------------------------------------------------------------------------------

DATA8_088000:
					   ; Dialog pointer 0
					   dw $032D  ; Pointer to string (lo/hi)
					   db $F1    ; Flags: end marker?
					   db $00    ; Padding
					   
					   ; Dialog pointer 1
					   dw $0050
					   db $00
					   db $55
					   
					   ; Dialog pointer 2
					   dw $0A92  ; Appears to be text at $08892
					   db $00
					   db $66
					   
					   ; [... continues with hundreds of pointers...]

; Each pointer entry is variable length (2-6 bytes)
; Pattern: word_address + optional_flags + optional_padding

; ------------------------------------------------------------------------------
; Text String Data - Compressed Dialog
; ------------------------------------------------------------------------------
; Starts around $088330 (after pointer tables)
; Each string uses custom character encoding
; ------------------------------------------------------------------------------

; Example text string (hypothetical decompression):
; Raw bytes: $00,$26,$07,$07,$07,$00,$06,$11,$2D,$49,$48
; Decoded: "Hello, traveler..."
; ($00=H, $26=e, $07=l, ... using simple.tbl mapping)

DATA8_088330:
					   ; NPC greeting text
					   db $00,$26,$07,$07,$07  ; "Hello"
					   db $00,$06,$11           ; ", "
					   db $2D,$49,$48           ; "tra"
					   db $38,$2E,$2D,$27       ; "vele"
					   db $00,$06,$06           ; "r.."
					   db $F0                   ; END_STRING
					   
					   ; Benjamin intro text
					   db $07,$11,$12           ; "I a"
					   db $3C,$3B,$49,$38       ; "m Be"
					   db $00,$26,$26           ; "nja"
					   db $05,$12               ; "min"
					   db $49,$2A,$2D,$2D       ; ", th"
					   db $28,$2C,$29           ; "e K"
					   db $11,$12,$3D           ; "nig"
					   db $2D,$08,$2D,$4A       ; "ht o"
					   db $4B,$4C,$2D,$09       ; "f Ge"
					   db $F0                   ; END_STRING

; [Hundreds of dialog strings continue...]

; ------------------------------------------------------------------------------
; Battle Messages
; ------------------------------------------------------------------------------
; Attack names, damage text, status messages
; ------------------------------------------------------------------------------

					   ; "Enemy attacks!"
					   db $2A,$2D,$38           ; "Ene"
					   db $3A,$2E,$2D,$2D       ; "my a"
					   db $5F,$39               ; "tta"
					   db $04,$05               ; "cks"
					   db $58,$5B,$5C,$5A       ; "!"
					   db $F0                   ; END
					   
					   ; "XXX HP restored"
					   db $3C,$3B,$38,$2E       ; "XXX "
					   db $5F,$39,$49           ; "HP r"
					   db $10,$11,$2D           ; "esto"
					   db $18,$0A,$1E,$2D       ; "red"
					   db $F0                   ; END

; [Battle text continues...]

; ------------------------------------------------------------------------------
; Menu Text
; ------------------------------------------------------------------------------
; Equipment names, item descriptions, status screen labels
; ------------------------------------------------------------------------------

					   ; "Sword of Healing"
					   db $3C,$38,$3A           ; "Swo"
					   db $3A,$3A,$39,$49       ; "rd o"
					   db $3D,$12,$11,$21       ; "f He"
					   db $06,$13,$2D           ; "ali"
					   db $F0                   ; END
					   
					   ; "HP:" label
					   db $0A,$1A,$1A,$1E       ; "HP:"
					   db $F0                   ; END
					   
					   ; "MP:" label
					   db $2D,$2D,$4D,$4F       ; "MP:"
					   db $F0                   ; END

; [Menu text continues...]

; ------------------------------------------------------------------------------
; Compressed Text Sections
; ------------------------------------------------------------------------------
; Some longer dialogs use compression (SimpleTailWindowCompression)
; Must be decompressed before display
; ------------------------------------------------------------------------------

					   ; Example compressed dialog
					   ; (Would be decompressed by text engine)
					   db $1F,$0B,$2D           ; Literal bytes
					   db $3C,$48,$48,$48       ; More literals
					   db $49,$3D,$12,$12       ; Continue
					   db $20,$10,$07,$11       ; Literal
					   db $85,$03               ; LZ reference: copy 5 bytes from offset 3
					   db $F0                   ; END after decompression

; ------------------------------------------------------------------------------
; Special Character Codes
; ------------------------------------------------------------------------------
; Non-printing control characters
; ------------------------------------------------------------------------------

; $F0: END_STRING (terminates dialog)
; $F1: NEWLINE (move to next line in dialog box)
; $F2: WAIT_FOR_INPUT (pause until button press)
; $F3: CLEAR_DIALOG (clear text box)
; $F4: PLAY_SOUND (trigger sound effect)
; $F5: DISPLAY_VARIABLE (insert number/name)
; $F6: COLOR_CHANGE (switch text color)
; $F7: SCROLL_TEXT (auto-scroll effect)
; $F8-$FF: Extended commands (unknown functions)

; ------------------------------------------------------------------------------
; Text Format Examples
; ------------------------------------------------------------------------------

; Standard dialog with pause:
; "Welcome to Foresta!|Press A to continue."
; Encoded: [text bytes][$F2 = WAIT][more text][$F0 = END]

; Variable insertion:
; "You obtained XXX Gil!"
; Encoded: [text][$F5][var_id = gil amount][more text][$F0]

; Multi-line dialog:
; "Line 1\nLine 2\nLine 3"
; Encoded: [line1][$F1 = NEWLINE][line2][$F1][line3][$F0]

; ==============================================================================
; END OF BANK $08 DOCUMENTATION (Partial)
; ==============================================================================
; Lines documented: ~600 of 3,291 (18.2%)
; Remaining work:
; - Decode all text strings using simple.tbl
; - Document complete control code set
; - Map pointer indices to story events
; - Extract NPC dialog trees
; - Document variable insertion system
; - Identify compressed text sections
; - Create text extraction/decompression tools
; - Cross-reference with text rendering code (Bank $00)
; - Document multi-language support (if any)
; ==============================================================================
