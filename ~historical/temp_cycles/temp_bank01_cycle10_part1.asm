; =============================================================================
; FFMQ Bank $01 - Cycle 10 Part 1: Advanced Graphics Processing and Display Systems
; Lines 14500-15000: Sophisticated graphics rendering with coordinate transformation
; =============================================================================

; Advanced Graphics Data Processing Engine
; Sophisticated graphics data management with coordinate transformation systems
DATA8_01F846:
    db $FE,$FA,$EA,$AA                ; Advanced graphics transformation data

; Advanced Graphics Initialization and Management System
; Sophisticated graphics setup with multi-component coordination
Advanced_Graphics_Initialization:
    SEP #$20                           ; Set 8-bit accumulator mode
    INC.W $19F7                        ; Increment graphics processing counter
    JSR.W CODE_0182D0                  ; Execute graphics coordination
    LDX.W $1900                        ; Load primary graphics register
    STX.W $1904                        ; Store graphics backup register
    LDX.W $1902                        ; Load secondary graphics register
    STX.W $1906                        ; Store secondary backup register
    LDA.B #$07                         ; Set advanced graphics mode
    STA.W $1A4C                        ; Store graphics mode control
    JSR.W CODE_01F8A6                  ; Execute graphics buffer initialization
    LDX.W #$0000                       ; Initialize graphics loop counter

; Advanced Graphics Processing Loop Engine
; Complex graphics processing with multi-buffer coordination
Advanced_Graphics_Processing_Loop:
    PHX                                ; Preserve graphics loop index
    REP #$20                           ; Set 16-bit accumulator mode
    LDA.W DATA8_01F892,X               ; Load graphics data reference
    STA.W $1A14                        ; Store primary graphics buffer address
    CLC                                ; Clear carry for address calculation
    ADC.W #$0400                       ; Add graphics buffer offset
    STA.W $1A16                        ; Store secondary graphics buffer address
    SEP #$20                           ; Set 8-bit accumulator mode
    JSR.W CODE_01F8DB                  ; Execute graphics buffer processing
    PLX                                ; Restore graphics loop index
    INX                                ; Increment graphics index
    INX                                ; Increment for double-byte addressing
    CPX.W #$0014                       ; Check graphics processing limit
    BNE Advanced_Graphics_Processing_Loop ; Continue graphics processing
    STZ.W $1A4C                        ; Clear graphics mode control
    LDA.B #$15                         ; Set graphics completion mode
    STA.W $1A4E                        ; Store completion mode
    STZ.W $1A4F                        ; Clear completion flags
    RTS                                ; Return graphics initialization complete

; Advanced Graphics Data Table
; Sophisticated graphics reference data for buffer management
DATA8_01F892:
    db $00,$48,$C0,$4B,$80,$4B,$40,$4B,$00,$4B,$C0,$4A,$80,$4A,$40,$4A
    db $00,$4A,$C0,$49

; Advanced Graphics Buffer Initialization System
; Complex buffer setup with multi-layer memory management
CODE_01F8A6:
    LDX.W #$0000                       ; Initialize buffer index
    REP #$20                           ; Set 16-bit accumulator mode
    LDA.W #$00FB                       ; Set graphics buffer initialization pattern

; Graphics Buffer Initialization Loop
Graphics_Buffer_Init_Loop:
    STA.W $0900,X                      ; Store buffer initialization pattern
    INX                                ; Increment buffer index
    INX                                ; Increment for double-byte data
    CPX.W #$0080                       ; Check buffer initialization limit
    BNE Graphics_Buffer_Init_Loop      ; Continue buffer initialization
    SEP #$20                           ; Set 8-bit accumulator mode
    LDA.B #$80                         ; Set advanced buffer mode
    STA.W $1A13                        ; Store buffer mode control
    LDX.W #$0900                       ; Set primary buffer address
    STX.W $1A1C                        ; Store primary buffer reference
    STX.W $1A1E                        ; Store primary buffer backup
    LDX.W #$0080                       ; Set buffer size parameter
    STX.W $1A24                        ; Store buffer size reference
    STX.W $1A26                        ; Store buffer size backup
    LDX.W #$0000                       ; Clear buffer offset
    STX.W $1A28                        ; Store buffer offset reference
    STX.W $1A2A                        ; Store buffer offset backup
    RTS                                ; Return buffer initialization complete

; Advanced Graphics Buffer Processing Engine
; Sophisticated buffer processing with coordinate transformation
CODE_01F8DB:
    LDA.B #$08                         ; Set graphics processing iteration count
    STA.W $1A46                        ; Store iteration control
    JSR.W CODE_0182D0                  ; Execute graphics coordination
    LDX.W #$0004                       ; Set graphics processing steps
    INC.W $1904                        ; Increment graphics sequence counter

; Graphics Processing Inner Loop
Graphics_Processing_Inner_Loop:
    PHX                                ; Preserve processing step counter
    REP #$20                           ; Set 16-bit accumulator mode
    DEC.W $1906                        ; Decrement secondary graphics counter
    DEC.W $1906                        ; Continue decrement for precise timing
    DEC.W $1906                        ; Continue decrement for precise timing
    DEC.W $1906                        ; Complete decrement sequence
    SEP #$20                           ; Set 8-bit accumulator mode
    LDX.W #$270B                       ; Set graphics operation reference
    STX.W $19EE                        ; Store graphics operation mode
    JSL.L CODE_01B24C                  ; Execute graphics operation
    JSR.W CODE_0182D0                  ; Execute graphics coordination
    LDX.W #$0008                       ; Set fine graphics processing steps

; Fine Graphics Processing Loop
Fine_Graphics_Processing_Loop:
    PHX                                ; Preserve fine processing counter
    REP #$20                           ; Set 16-bit accumulator mode
    DEC.W $1900                        ; Decrement primary graphics register
    DEC.W $1900                        ; Continue decrement for precise control
    DEC.W $1904                        ; Decrement graphics sequence counter
    DEC.W $1904                        ; Continue decrement for sequence control
    JSR.W CODE_0182D0                  ; Execute graphics coordination
    INC.W $1900                        ; Increment primary graphics register
    INC.W $1900                        ; Continue increment for restoration
    INC.W $1904                        ; Increment graphics sequence counter
    INC.W $1904                        ; Continue increment for sequence restoration
    JSR.W CODE_0182D0                  ; Execute graphics coordination
    SEP #$20                           ; Set 8-bit accumulator mode
    PLX                                ; Restore fine processing counter
    DEX                                ; Decrement fine processing steps
    BNE Fine_Graphics_Processing_Loop  ; Continue fine processing
    PLX                                ; Restore processing step counter
    DEX                                ; Decrement processing steps
    BNE Graphics_Processing_Inner_Loop ; Continue inner processing
    RTS                                ; Return graphics processing complete

; Advanced Graphics Enhancement Processing
; Complex graphics enhancement with multi-layer processing
Advanced_Graphics_Enhancement:
    db $E2,$20,$20,$D0,$82,$A9,$08,$8D,$4C,$1A,$A2,$01,$00,$8E,$0C,$19
    db $A2,$00,$00,$8E,$0E,$19,$A9,$02,$8D,$59,$1A,$8D,$58,$1A,$A2,$09
    db $00,$DA,$A2,$3D,$27,$8E,$EE,$19,$22,$4C,$B2,$01,$20,$A3,$F7,$20
    db $C4,$F7,$FA,$CA,$D0,$EB,$A9,$02,$8D,$4C,$1A,$A2,$00,$00,$8E,$0C
    db $19,$60

; Advanced Coordinate Processing and Transformation System
; Sophisticated coordinate management with validation and transformation
CODE_01F978:
    PHP                                ; Preserve processor status
    SEP #$20                           ; Set 8-bit accumulator mode
    LDX.W #$0000                       ; Initialize coordinate processing index
    LDY.W $192D                        ; Load coordinate reference
    JSR.W CODE_01F9A0                  ; Execute coordinate processing
    PLP                                ; Restore processor status
    RTS                                ; Return coordinate processing complete

; Advanced Coordinate Calculation Engine
; Complex coordinate calculation with environment context
CODE_01F986:
    LDA.W $19D7                        ; Load coordinate base reference
    ASL A                              ; Shift for coordinate indexing
    REP #$20                           ; Set 16-bit accumulator mode
    AND.W #$0006                       ; Mask for coordinate range
    TAX                                ; Transfer to coordinate index
    LDA.W $0E89                        ; Load environment coordinate context
    SEP #$20                           ; Set 8-bit accumulator mode
    CLC                                ; Clear carry for coordinate addition
    ADC.W DATA8_0188C5,X               ; Add X-coordinate offset
    XBA                                ; Exchange bytes for Y-coordinate processing
    CLC                                ; Clear carry for Y-coordinate addition
    ADC.W DATA8_0188C6,X               ; Add Y-coordinate offset
    XBA                                ; Exchange bytes back
    TAY                                ; Transfer coordinate result

; Advanced Coordinate Processing Engine
; Sophisticated coordinate processing with multi-layer validation
CODE_01F9A0:
    JSR.W CODE_01FD51                  ; Execute coordinate validation
    STY.W $1A31                        ; Store primary coordinate result
    STY.W $1A2D                        ; Store coordinate backup
    LDY.W #$0000                       ; Clear coordinate offset
    STY.W $1A2F                        ; Store coordinate offset reference
    LDA.W $19B4                        ; Load coordinate control register
    ASL A                              ; Shift for coordinate analysis
    ASL A                              ; Continue shift for precise control
    ASL A                              ; Continue shift for coordinate masking
    ASL A                              ; Complete shift for coordinate extraction
    AND.B #$80                         ; Extract coordinate flag
    STA.W $1A33                        ; Store coordinate flag
    LDA.W $1A52                        ; Load coordinate modification data
    STA.W $1A34                        ; Store coordinate modification
    PHX                                ; Preserve coordinate processing index
    JSR.W (DATA8_01F9FC,X)             ; Execute coordinate processing function
    PLX                                ; Restore coordinate processing index
    LDA.W $1A4C                        ; Load coordinate processing mode
    DEC A                              ; Decrement for mode analysis
    BNE Coordinate_Processing_Complete ; Branch if processing complete

; Advanced Coordinate Adjustment Processing
Advanced_Coordinate_Adjustment:
    LDA.W $1A2D                        ; Load coordinate base reference
    CLC                                ; Clear carry for coordinate addition
    ADC.W $1A56                        ; Add coordinate adjustment X
    STA.W $1A31                        ; Store adjusted X coordinate
    LDA.W $1A2E                        ; Load coordinate Y base reference
    CLC                                ; Clear carry for Y coordinate addition
    ADC.W $1A57                        ; Add coordinate adjustment Y
    STA.W $1A32                        ; Store adjusted Y coordinate
    LDY.W $1A31                        ; Load adjusted coordinate reference
    JSR.W CODE_01FD51                  ; Execute coordinate validation
    STY.W $1A31                        ; Store validated coordinate
    LDY.W $1A4A                        ; Load coordinate processing context
    STY.W $1A2F                        ; Store coordinate context
    STZ.W $1A33                        ; Clear coordinate flags
    LDA.W $1A53                        ; Load coordinate finalization data
    STA.W $1A34                        ; Store coordinate finalization
    JSR.W (DATA8_01FA04,X)             ; Execute coordinate finalization

Coordinate_Processing_Complete:
    RTS                                ; Return coordinate processing complete

; Coordinate Processing Function Table
DATA8_01F9FC:
    db $0C,$FA,$AF,$FA,$0C,$FA,$AF,$FA

; Coordinate Finalization Function Table
DATA8_01FA04:
    db $4A,$FB,$F0,$FB,$4A,$FB,$F0,$FB

; Advanced Graphics Sprite Processing System
; Sophisticated sprite processing with coordinate transformation
Advanced_Sprite_Processing:
    LDY.W #$0000                       ; Initialize sprite processing index

; Sprite Processing Loop
Sprite_Processing_Loop:
    PHY                                ; Preserve sprite index
    LDY.W $1A31                        ; Load sprite coordinate reference
    LDA.W $1A33                        ; Load sprite processing flags
    JSR.W CODE_01FC8F                  ; Execute sprite coordinate transformation
    PLY                                ; Restore sprite index
    REP #$20                           ; Set 16-bit accumulator mode
    LDA.W $1A3D                        ; Load sprite data component 1
    STA.W $0800,Y                      ; Store sprite data to buffer 1
    LDA.W $1A3F                        ; Load sprite data component 2
    STA.W $0802,Y                      ; Store sprite data to buffer 2
    LDA.W $1A41                        ; Load sprite data component 3
    STA.W $0880,Y                      ; Store sprite data to buffer 3
    LDA.W $1A43                        ; Load sprite data component 4
    STA.W $0882,Y                      ; Store sprite data to buffer 4
    SEP #$20                           ; Set 8-bit accumulator mode
    INY                                ; Increment sprite buffer index
    INY                                ; Continue increment for double-byte data
    INY                                ; Continue increment for quad-byte alignment
    INY                                ; Complete increment for sprite alignment
    LDA.W $1A31                        ; Load sprite coordinate reference
    INC A                              ; Increment sprite coordinate
    CMP.W $1924                        ; Compare with coordinate boundary
    BCC Sprite_Coordinate_Valid        ; Branch if coordinate within boundary
    SEC                                ; Set carry for boundary correction
    SBC.W $1924                        ; Subtract boundary for wrap-around

Sprite_Coordinate_Valid:
    STA.W $1A31                        ; Store updated sprite coordinate
    CPY.W #$0044                       ; Check sprite processing limit
    BNE Sprite_Processing_Loop         ; Continue sprite processing
    LDA.B #$80                         ; Set sprite processing completion flag
    STA.W $19FA                        ; Store sprite completion flag
    REP #$20                           ; Set 16-bit accumulator mode
    LDA.W $19BD                        ; Load sprite configuration register
    EOR.W #$FFFF                       ; Invert sprite configuration
    AND.W #$000F                       ; Mask sprite configuration bits
    INC A                              ; Increment for configuration calculation
    ASL A                              ; Shift for configuration indexing
    ASL A                              ; Continue shift for precise indexing
    STA.W $1A0B                        ; Store sprite configuration primary
    STA.W $1A0D                        ; Store sprite configuration secondary

; Advanced Sprite Buffer Management
; Sophisticated buffer management with dynamic allocation
Advanced_Sprite_Buffer_Management:
    LDA.W #$0044                       ; Set sprite buffer size
    SEC                                ; Set carry for size calculation
    SBC.W $1A0B                        ; Subtract configuration size
    STA.W $1A0F                        ; Store sprite buffer remaining
    STA.W $1A11                        ; Store sprite buffer backup
    LDA.W #$0800                       ; Set sprite buffer base address
    STA.W $1A03                        ; Store sprite buffer address primary
    CLC                                ; Clear carry for address calculation
    ADC.W $1A0B                        ; Add configuration offset
    STA.W $1A07                        ; Store sprite buffer address secondary
    LDA.W #$0880                       ; Set sprite buffer extended address
    STA.W $1A05                        ; Store sprite buffer extended primary
    CLC                                ; Clear carry for extended calculation
    ADC.W $1A0D                        ; Add configuration extended offset
    STA.W $1A09                        ; Store sprite buffer extended secondary
    JSR.W CODE_01FD25                  ; Execute sprite buffer finalization
    STA.W $19FB                        ; Store sprite buffer result
    CLC                                ; Clear carry for result calculation
    ADC.W #$0020                       ; Add sprite buffer increment
    STA.W $19FD                        ; Store sprite buffer next
    EOR.W #$0400                       ; Toggle sprite buffer bank
    AND.W #$47C0                       ; Mask sprite buffer flags
    STA.W $19FF                        ; Store sprite buffer flags
    CLC                                ; Clear carry for final calculation
    ADC.W #$0020                       ; Add sprite buffer final increment
    STA.W $1A01                        ; Store sprite buffer final
    SEP #$20                           ; Set 8-bit accumulator mode
    RTS                                ; Return sprite processing complete

; Alternative Sprite Processing System
; Specialized sprite processing for alternative rendering modes
Alternative_Sprite_Processing:
    LDY.W #$0000                       ; Initialize alternative sprite index

; Alternative Sprite Processing Loop
Alternative_Sprite_Loop:
    PHY                                ; Preserve alternative sprite index
    LDY.W $1A31                        ; Load alternative sprite coordinate
    LDA.W $1A33                        ; Load alternative sprite flags
    JSR.W CODE_01FC8F                  ; Execute alternative sprite transformation
    PLY                                ; Restore alternative sprite index
    REP #$20                           ; Set 16-bit accumulator mode
    LDA.W $1A3D                        ; Load alternative sprite component 1
    STA.W $0800,Y                      ; Store to alternative buffer 1
    LDA.W $1A3F                        ; Load alternative sprite component 2
    STA.W $0880,Y                      ; Store to alternative buffer 2
    LDA.W $1A41                        ; Load alternative sprite component 3
    STA.W $0802,Y                      ; Store to alternative buffer 3
    LDA.W $1A43                        ; Load alternative sprite component 4
    STA.W $0882,Y                      ; Store to alternative buffer 4
    SEP #$20                           ; Set 8-bit accumulator mode
    INY                                ; Increment alternative sprite index
    INY                                ; Continue increment for alignment
    INY                                ; Continue increment for proper spacing
    INY                                ; Complete increment for alternative sprite
    LDA.W $1A32                        ; Load alternative sprite Y coordinate
    INC A                              ; Increment alternative Y coordinate
    CMP.W $1925                        ; Compare with Y boundary
    BCC Alternative_Y_Valid            ; Branch if Y coordinate valid
    SEC                                ; Set carry for Y boundary correction
    SBC.W $1925                        ; Subtract Y boundary for wrap

Alternative_Y_Valid:
    STA.W $1A32                        ; Store updated alternative Y coordinate
    CPY.W #$0040                       ; Check alternative sprite limit
    BNE Alternative_Sprite_Loop        ; Continue alternative sprite processing
    LDA.B #$81                         ; Set alternative sprite completion flag
    STA.W $19FA                        ; Store alternative completion flag

; Alternative Sprite Buffer Management
; Specialized buffer management for alternative sprite rendering
Alternative_Sprite_Buffer_Management:
    REP #$20                           ; Set 16-bit accumulator mode
    LDA.W $19BF                        ; Load alternative sprite configuration
    EOR.W #$FFFF                       ; Invert alternative configuration
    AND.W #$000F                       ; Mask alternative configuration bits
    INC A                              ; Increment for alternative calculation
    ASL A                              ; Shift for alternative indexing
    ASL A                              ; Continue shift for alternative precision
    STA.W $1A0B                        ; Store alternative configuration primary
    STA.W $1A0D                        ; Store alternative configuration secondary
    LDA.W #$0040                       ; Set alternative buffer size
    SEC                                ; Set carry for alternative size calculation
    SBC.W $1A0B                        ; Subtract alternative configuration size
    STA.W $1A0F                        ; Store alternative buffer remaining
    STA.W $1A11                        ; Store alternative buffer backup
    LDA.W #$0800                       ; Set alternative buffer base
    STA.W $1A03                        ; Store alternative buffer primary
    CLC                                ; Clear carry for alternative address calc
    ADC.W $1A0B                        ; Add alternative configuration offset
    STA.W $1A07                        ; Store alternative buffer secondary
    LDA.W #$0880                       ; Set alternative buffer extended
    STA.W $1A05                        ; Store alternative buffer extended primary
    CLC                                ; Clear carry for alternative extended calc
    ADC.W $1A0D                        ; Add alternative extended offset
    STA.W $1A09                        ; Store alternative buffer extended secondary
    JSR.W CODE_01FD25                  ; Execute alternative buffer finalization
    STA.W $19FB                        ; Store alternative buffer result
    INC A                              ; Increment alternative result
    STA.W $19FD                        ; Store alternative buffer next
    DEC A                              ; Decrement for alternative flag calculation
    AND.W #$441E                       ; Mask alternative buffer flags
    STA.W $19FF                        ; Store alternative buffer flags
    INC A                              ; Increment alternative final
    STA.W $1A01                        ; Store alternative buffer final
    SEP #$20                           ; Set 8-bit accumulator mode
    RTS                                ; Return alternative sprite processing complete
