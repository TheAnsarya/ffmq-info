; Temporary wrapper for building bank $00 only
; This allows us to verify our documented code against the original ROM

arch 65816

; Set origin to bank $00
org $008000

; Include SNES hardware register definitions
incsrc "../src/asm/snes_registers.asm"

; Include our documented bank $00 code
incsrc "../src/asm/bank_00_documented.asm"
