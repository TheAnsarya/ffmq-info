
; DATA: Character start stats ($0650b0)
; 
; TODO: map out whole structure
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
; 
CharacterStartStats:
	print "DATA: Character start stats ($0650b0) -- is at $",pc

	db "DemoPlay********"
	db $01,$00,$00,$00,$28,$00,$28,$00,$03,$01,$00,$03,$01,$00,$00,$00
	db $00,$00,$07,$0C,$08,$0A,$07,$06,$08,$0A,$00,$06,$00,$00,$00,$00
	db $00,$20,$80,$00,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00
	db $4B,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$06,$08,$0A

	db "Kaeli***********"
	db $03,$00,$00,$00,$78,$00,$78,$00,$03,$00,$00,$03,$00,$00,$00,$00
	db $81,$00,$0B,$1D,$0B,$0E,$0B,$0B,$0B,$09,$00,$12,$00,$05,$00,$00
	db $00,$23,$10,$00,$00,$02,$01,$00,$10,$00,$40,$41,$40,$41,$12,$00
	db $4C,$12,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$0B,$0B,$09

	db "Tristam*********"
	db $07,$00,$00,$00,$68,$01,$68,$01,$07,$00,$00,$07,$00,$00,$00,$00
	db $82,$00,$1C,$20,$21,$10,$17,$0A,$1C,$10,$05,$16,$05,$00,$00,$00
	db $63,$2E,$00,$02,$00,$40,$40,$00,$10,$00,$20,$80,$20,$80,$15,$00
	db $4E,$18,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$17,$0A,$1C,$10

	db "Phoebe**********"
	db $0F,$00,$00,$00,$A8,$02,$A8,$02,$15,$0A,$05,$15,$0A,$05,$00,$00
	db $83,$00,$2F,$24,$24,$36,$2F,$14,$24,$31,$00,$10,$00,$05,$00,$00
	db $63,$26,$02,$00,$00,$01,$01,$00,$72,$80,$10,$01,$10,$01,$13,$00
	db $52,$0F,$1E,$46,$00,$00,$3C,$00,$28,$00,$00,$00,$2F,$14,$24,$31

	db "Reuben**********"
	db $17,$00,$00,$00,$10,$04,$10,$04,$17,$00,$00,$17,$00,$00,$00,$00
	db $84,$00,$54,$50,$3D,$23,$54,$3D,$3D,$23,$00,$13,$00,$00,$00,$00
	db $00,$2C,$00,$08,$00,$80,$82,$00,$10,$00,$20,$00,$20,$00,$12,$00
	db $56,$14,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$54,$3D,$3D,$23

	db "Kaeli***********"
	db $1F,$00,$00,$00,$00,$05,$00,$05,$23,$11,$00,$23,$11,$00,$00,$00
	db $85,$00,$60,$61,$4D,$3C,$60,$49,$4D,$37,$00,$18,$00,$05,$00,$00
	db $00,$25,$04,$00,$00,$82,$01,$00,$71,$00,$40,$41,$40,$41,$16,$00
	db $5A,$17,$41,$23,$00,$00,$00,$64,$00,$00,$00,$00,$60,$49,$4D,$37

	db "Tristam*********"
	db $17,$00,$00,$00,$60,$04,$60,$04,$17,$00,$00,$17,$00,$00,$00,$00
	db $86,$00,$49,$36,$55,$1F,$44,$1F,$50,$1A,$05,$17,$05,$05,$00,$00
	db $63,$2E,$00,$02,$00,$40,$42,$00,$10,$00,$20,$80,$20,$80,$17,$00
	db $56,$19,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$44,$1F,$50,$1A

	db "Phoebe**********"
	db $22,$00,$00,$00,$C8,$05,$C8,$05,$28,$14,$0A,$28,$14,$0A,$00,$00
	db $87,$00,$46,$47,$47,$63,$46,$27,$42,$5E,$00,$20,$05,$05,$00,$00
	db $63,$2D,$00,$04,$00,$81,$05,$00,$76,$C0,$1C,$31,$18,$31,$24,$00
	db $5C,$21,$28,$3C,$00,$00,$0F,$19,$1E,$1E,$00,$00,$46,$27,$42,$5E

	db "Reuben**********"
	db $1F,$00,$00,$00,$28,$05,$28,$05,$1F,$00,$07,$1F,$00,$07,$00,$00
	db $88,$00,$63,$57,$46,$29,$63,$44,$46,$29,$00,$13,$00,$00,$00,$00
	db $00,$2C,$00,$08,$00,$80,$82,$00,$10,$40,$20,$00,$20,$00,$12,$00
	db $5A,$14,$41,$23,$00,$00,$00,$00,$00,$64,$00,$00,$63,$44,$46,$29
