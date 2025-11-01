														; Test file for format_asm.ps1 validation
														; This file contains various ASM patterns to test formatting

														; Test 1: Label-only lines
TestLabel1:
TestLabel2:
AnotherLabel:

														; Test 2: Comment-only lines
														; This is a comment
														; This is an indented comment
														; This is a more indented comment

														; Test 3: Instructions without labels (should align to opcode column)
					   LDA					 #$00
					   STA					 $2100
					   JSR					 Subroutine
RTS:

														; Test 4: Label + instruction on same line
LabelWithCode:		 LDA					   #$FF
AnotherOne:			STA						$7E0000

														; Test 5: Instructions with operands and comments
					   LDA					 #$1234	  ; Load value
					   STA.L				   $7E3667   ; Store to RAM
					   JSL					 CODE_0D8000 ; Long jump

														; Test 6: Directives (ORG, DB, etc.)
					   ORG					 $008000
DB											 $00,$01,$02,$03
DW											 $1234,$5678

														; Test 7: Mixed spacing (spaces instead of tabs)
					   LDA					 #$00		; This line uses spaces
					   STA					 $2100	   ; This too
					   LDX					 #$1234	  ; Mixed spacing

														; Test 8: Long operands
					   LDA.L				   $7E3667
					   STA.W				   SNES_NMITIMEN
					   JSR.W				   CODE_008247

														; Test 9: Complex label names
_PrivateLabel:
Public_Label_123:
CODE_008000:
DATA8_0D8008:

														; Test 10: Blank lines (should be preserved)


														; Multiple blank lines above

														; Test 11: Trailing whitespace (should be removed)
TrailingSpaces:
					   LDA					 #$00

														; Test 12: No final newline (should be added)
