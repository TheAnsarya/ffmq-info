; Test file to debug normalization
TestLabel:
	LDA.W #$00FF
	AND.B #$0020
	BEQ  TestLabel
	RTS
