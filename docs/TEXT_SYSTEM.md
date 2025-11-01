# Text System Architecture

Complete documentation of the Final Fantasy Mystic Quest text rendering and dialogue system.

## Table of Contents

- [System Overview](#system-overview)
- [Text Encoding](#text-encoding)
- [Text Rendering](#text-rendering)
- [Dialogue System](#dialogue-system)
- [Text Windows](#text-windows)
- [Font System](#font-system)
- [Text Data Organization](#text-data-organization)
- [Control Codes](#control-codes)
- [Text Decompression](#text-decompression)
- [Code Locations](#code-locations)

## System Overview

The FFMQ text system handles all in-game text display including:

- **Dialogue boxes** with character portraits
- **Menu text** (items, equipment, status)
- **Battle text** (damage numbers, spell names)
- **Location names** and screen titles
- **System messages** and tutorials

### Key Components

```
┌─────────────────┐
│ Text Data (ROM) │ ← Compressed text strings
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Text Engine     │ ← Decodes and renders
├─────────────────┤
│ - Decode text   │
│ - Draw to BG3   │
│ - Handle control│
│ - Word wrap     │
└────────┬────────┘
         │
         v
┌─────────────────┐
│  BG3 Layer      │ ← 2bpp text layer
└─────────────────┘
```

## Text Encoding

### Character Encoding Table

FFMQ uses a custom text encoding system:

```
Value   Character   Notes
───────────────────────────────────────
$00     [END]       End of string
$01     [NL]        Newline
$02     [WAIT]      Wait for button press
$03-$0c [CTRL]      Control codes (see below)
$0d     [SPACE]     Space character
$0e-$27 0-9, A-Z    Alphanumeric (uppercase)
$28-$41 a-z         Lowercase letters
$42-$5f !?.,        Punctuation
$60-$7f [SPECIAL]   Special characters
$80-$ff [DTE]       Dual-Tile Encoding (2 chars)
```

### Dual-Tile Encoding (DTE)

Common letter pairs encoded as single bytes to save space:

```
$80 = "th"
$81 = "he"
$82 = "in"
$83 = "er"
$84 = "an"
$85 = "re"
$86 = "on"
$87 = "at"
... (128 common pairs)
```

**Example**:
```
Text: "The hero entered the castle"
Raw:  "Th[DTE]e her[DTE]o [DTE]enter[DTE]ed th[DTE]e castle"
Encoded: $80e $fe1o $82$83$8f $80e castle
Savings: ~30% compression
```

### Encoding Algorithm

```python
def encode_text(text: str) -> bytes:
    """Encode text string to FFMQ format."""
    result = bytearray()
    i = 0
    
    while i < len(text):
        # Check for two-character DTE match
        if i + 1 < len(text):
            pair = text[i:i+2].lower()
            if pair in DTE_TABLE:
                result.append(DTE_TABLE[pair])
                i += 2
                continue
        
        # Single character encoding
        char = text[i]
        if char in CHAR_TABLE:
            result.append(CHAR_TABLE[char])
        else:
            result.append(0x0D)  # Unknown → space
        i += 1
    
    result.append(0x00)  # End marker
    return bytes(result)
```

## Text Rendering

### Rendering Pipeline

```
1. Game triggers text display
   ↓
2. Load text pointer from script
   ↓
3. Decompress text (if compressed)
   ↓
4. Decode characters one by one
   │
   ├─ Regular character → Draw tile to BG3
   ├─ Control code → Execute command
   └─ DTE code → Decode to 2 characters
   ↓
5. Update cursor position
   ↓
6. Check for line wrap
   ↓
7. Repeat until [END] or [WAIT]
   ↓
8. Wait for player input (if [WAIT])
   ↓
9. Continue or close window
```

### Character Drawing

**Code Flow** (from `text_engine.asm`):

```asm
; ==============================================================================
; DrawCharacter - Draw single character to text layer
; ==============================================================================
; Inputs:
;   A = Character code
;   X = Screen position (tilemap offset)
; Outputs:
;   X = Updated position (incremented)
; ==============================================================================
DrawCharacter:
    cmp #$00            ; Check for end marker
    beq .end_text
    
    cmp #$01            ; Check for newline
    beq .newline
    
    cmp #$02            ; Check for wait
    beq .wait_input
    
    ; Convert character code to tile number
    jsr GetCharacterTile
    
    ; Write to BG3 tilemap in VRAM
    sta TextBuffer,x    ; Store in buffer
    inx                 ; Increment position
    
    ; Check for line end
    cpx #$20            ; 32 characters per line
    bcc .done
    
.newline:
    ; Move to next line
    txa
    and #$e0            ; Keep line start
    clc
    adc #$20            ; Add 32 (next line)
    tax
    
.done:
    rts
    
.wait_input:
    ; Set wait flag
    lda #$01
    sta TextWaitFlag
    rts
    
.end_text:
    ; Mark text complete
    lda #$ff
    sta TextCompleteFlag
    rts
```

### Tilemap Layout (BG3)

```
BG3 Tilemap (30×20 characters):
┌────────────────────────────────┐
│                                │ Row 0
│  ┌──────────────────────────┐  │
│  │ Text Window (28×4)       │  │ Rows 15-18
│  │                          │  │
│  │ [Text content here...]   │  │
│  │                          │  │
│  └──────────────────────────┘  │
│                                │ Row 19
└────────────────────────────────┘
```

**VRAM Structure**:
```
BG3 Tilemap at $7800:
  Each tile: 16 bits (vhopppcc cccccccc)
  Layout: 32×32 tiles (1024 entries × 2 bytes)
  
Text area typically: Rows 15-18, Columns 1-28
```

## Dialogue System

### Dialogue Triggers

Dialogue initiated by:

1. **NPC Interaction** - Talk to character
2. **Story Events** - Automatic cutscenes
3. **Battle Events** - Enemy/boss dialogue
4. **Item Usage** - Item descriptions
5. **System Messages** - Errors, confirmations

### Dialogue Flow

```
Event Triggered
   ↓
Load Dialogue ID
   ↓
┌────────────────────┐
│ Dialogue Manager   │
├────────────────────┤
│ 1. Open window     │
│ 2. Load portrait   │ (if character speaking)
│ 3. Load text       │
│ 4. Render text     │
│ 5. Wait for input  │
│ 6. Next page?      │ → Loop or Close
└────────────────────┘
   ↓
Close Window
   ↓
Resume Game
```

### Multi-Page Dialogues

**Pagination System**:

```
Page 1: "Welcome to the"
        "village, traveler!"
        [WAIT]
        
Page 2: "The Dark King has"
        "taken our crystal."
        [END]
```

**Control flow**:
```asm
DialogueScript_OldMan:
    .dw Text_OldMan_Page1
    .dw Text_OldMan_Page2
    .dw $0000               ; End of dialogue
    
Text_OldMan_Page1:
    .db "Welcome to the", $01
    .db "village, traveler!", $02  ; $02 = WAIT
    
Text_OldMan_Page2:
    .db "The Dark King has", $01
    .db "taken our crystal.", $00  ; $00 = END
```

## Text Windows

### Window Types

FFMQ uses several window styles:

```
1. Dialogue Window (Bottom)
   ┌──────────────────────────┐
   │ Speaker Name             │
   ├──────────────────────────┤
   │ Text content here with   │
   │ automatic word wrapping  │
   └──────────────────────────┘

2. Menu Window (Full)
   ┌──────────────────────────┐
   │ Items        Magic       │
   │ Equipment    Status      │
   │ Save         Config      │
   └──────────────────────────┘

3. Battle Text (Top)
   ┌──────────────────────────┐
   │ Benjamin casts Cure!     │
   │ HP recovered 50          │
   └──────────────────────────┘

4. Choice Window (Centered)
       ┌──────────┐
       │ ► Yes    │
       │   No     │
       └──────────┘
```

### Window Rendering

**Border Tiles**:
```
Tile Map:
  $e0 = ┌ (Top-left corner)
  $e1 = ─ (Top edge)
  $e2 = ┐ (Top-right corner)
  $e3 = │ (Left edge)
  $e4 = │ (Right edge)
  $e5 = └ (Bottom-left corner)
  $e6 = ─ (Bottom edge)
  $e7 = ┘ (Bottom-right corner)
  $e8 = [Space/Fill]
```

**Draw Algorithm**:
```asm
; ==============================================================================
; DrawWindow - Draw bordered window on BG3
; ==============================================================================
; Inputs:
;   $00 = X position (tiles)
;   $01 = Y position (tiles)
;   $02 = Width (tiles)
;   $03 = Height (tiles)
; ==============================================================================
DrawWindow:
    ; Calculate VRAM position
    lda $01             ; Y position
    asl a               ; × 32 (row size)
    asl a
    asl a
    asl a
    asl a
    clc
    adc $00             ; + X position
    tax                 ; X = tilemap offset
    
    ; Draw top edge
    lda #$e0            ; Top-left corner
    sta TextBuffer,x
    inx
    
    ldy $02             ; Width
    dey                 ; Minus 2 (corners)
    dey
.topEdge:
    lda #$e1            ; Top edge
    sta TextBuffer,x
    inx
    dey
    bne .topEdge
    
    lda #$e2            ; Top-right corner
    sta TextBuffer,x
    
    ; ... (continue for sides and bottom)
    
    rts
```

## Font System

### Font Data

Font stored as 2bpp tiles in VRAM:

```
Character Set:
  Tiles $00-$3f: Uppercase A-Z, 0-9, symbols
  Tiles $40-$5f: Lowercase a-z
  Tiles $60-$7f: Punctuation and special
  Tiles $80-$9f: Japanese kana (unused in English)
  Tiles $a0-$bf: Additional symbols
```

### Font Loading

```asm
; ==============================================================================
; LoadFont - Load font tiles to VRAM
; ==============================================================================
LoadFont:
    ; Set VRAM destination (BG3 character area)
    lda #<$4000         ; VRAM address for BG3 tiles
    sta $2116
    lda #>$4000
    sta $2117
    
    ; DMA font data from ROM
    ldx #<FontData
    ldy #>FontData
    lda #^FontData
    jsr LoadGraphicsToVRAM
    
    rts

FontData:
    .incbin "assets/data/font_2bpp.bin"
```

**Font Palette** (BG3 uses palette 7):
```
Color 0: Transparent
Color 1: Text shadow (dark gray)
Color 2: Text main (white/light)
Color 3: Text highlight (yellow/bright)
```

### Variable-Width Font

FFMQ uses fixed-width font (8×8 pixels per character) for simplicity.

**Note**: Some text (like damage numbers in battle) uses proportional spacing via sprite-based rendering.

## Text Data Organization

### Text Pointers

Text organized in pointer tables:

```asm
; Main dialogue pointer table
DialoguePointers:
    .dw Dialogue_000    ; NPC 0
    .dw Dialogue_001    ; NPC 1
    .dw Dialogue_002    ; NPC 2
    ; ... (hundreds of entries)
    
; System message pointers
SystemMessages:
    .dw Msg_ItemReceived
    .dw Msg_LevelUp
    .dw Msg_GameOver
    ; ... (system messages)
```

### Text Sections

```
ROM Bank $0d (Text Bank):
  $0d:0000-$0d:3FFF: Dialogue text (compressed)
  $0d:4000-$0d:7FFF: Menu text
  $0d:8000-$0d:9FFF: Battle text
  $0d:A000-$0d:BFFF: Item/equipment descriptions
  $0d:C000-$0d:DFFF: Location names
  $0d:E000-$0d:FFFF: System messages
```

## Control Codes

### Standard Control Codes

```
Code    Name        Description
──────────────────────────────────────────────
$00     END         End of string
$01     NEWLINE     Move to next line
$02     WAIT        Wait for button press (continue)
$03     CLOSE       Close text window
$04     PORTRAIT    Load character portrait
$05     SPEED       Set text display speed
$06     COLOR       Change text color
$07     SHAKE       Screen shake effect
$08     SOUND       Play sound effect
$09     PAUSE       Pause for N frames
$0a     CHOICE      Display choice window
$0b     NAME        Insert player/character name
$0c     NUMBER      Display numeric value
```

### Control Code Examples

**Portrait Display**:
```
.db $04, $01        ; PORTRAIT, Benjamin
.db "Hello!", $00
```

**Choice Window**:
```
.db "Will you help?", $01
.db $0a             ; CHOICE
.db "Yes", $00
.db "No", $00
.db $00             ; End choices
```

**Name Insertion**:
```
.db $0b, $00        ; NAME, Player
.db " received the", $01
.db "Excalibur!", $00
```

Result: "Benjamin received the Excalibur!"

### Custom Text Speed

```asm
; Set text speed (frames per character)
.db $05, $02        ; SPEED, 2 frames (fast)
.db "Quick text!", $00

.db $05, $08        ; SPEED, 8 frames (slow)
.db "Dramatic... slow... text...", $00
```

## Text Decompression

### Compression Format

FFMQ uses dictionary-based compression:

```
Compressed Format:
  - Uncompressed: $00-$7f (literal bytes)
  - Dictionary:   $80-$ff (references)
  
Dictionary Reference:
  High bit set ($80-$ff) = lookup in dictionary
  Value & $7f = dictionary index
  
Example:
  $85 → Dictionary[5] = "the "
  $92 → Dictionary[18] = "ing"
```

### Decompression Algorithm

```asm
; ==============================================================================
; DecompressText - Decompress text string
; ==============================================================================
; Inputs:
;   $10-$11 = Source pointer (compressed text)
;   $12-$13 = Destination pointer (buffer)
; ==============================================================================
DecompressText:
    ldy #$00            ; Source index
    ldx #$00            ; Destination index
    
.loop:
    lda ($10),y         ; Read compressed byte
    beq .done           ; $00 = end
    
    bmi .dictionary     ; Bit 7 set = dictionary
    
    ; Literal byte
    sta ($12),x         ; Write to buffer
    inx
    iny
    bra .loop
    
.dictionary:
    and #$7f            ; Get dictionary index
    asl a               ; × 2 (word pointers)
    tax
    
    ; Load dictionary entry
    lda DictionaryPointers,x
    sta $14
    lda DictionaryPointers+1,x
    sta $15
    
    ; Copy dictionary string
    phx
    phy
    jsr CopyDictionaryEntry
    ply
    plx
    
    iny
    bra .loop
    
.done:
    lda #$00            ; Null terminate
    sta ($12),x
    rts
```

## Code Locations

### Core Text Engine

**File**: `src/asm/text_engine.asm`

```asm
; Main text rendering
RenderText:                 ; Main text rendering loop
    ; Located at $0d:8000
    
DrawCharacter:              ; Draw single character
    ; Located at $0d:8123
    
ProcessControlCode:         ; Handle control codes
    ; Located at $0d:8234
    
WordWrap:                   ; Auto word wrapping
    ; Located at $0d:8345
```

### Dialogue System

**File**: `src/asm/bank_0D_documented.asm`

```asm
ShowDialogue:               ; Display dialogue window
    ; Located at $0d:9000
    
LoadPortrait:               ; Load character portrait
    ; Located at $0d:9123
    
WaitForInput:               ; Wait for button press
    ; Located at $0d:9234
    
CloseDialogue:              ; Close text window
    ; Located at $0d:9345
```

### Text Utilities

**File**: `src/asm/bank_0D_documented.asm`

```asm
DecompressText:             ; Decompress text data
    ; Located at $0d:A000
    
GetTextPointer:             ; Look up text by ID
    ; Located at $0d:A123
    
DrawWindow:                 ; Draw bordered window
    ; Located at $0d:A234
    
LoadFont:                   ; Load font to VRAM
    ; Located at $0d:A345
```

## Performance Considerations

### Text Rendering Speed

**Fast text**: 1-2 frames per character  
**Slow text**: 4-8 frames per character  
**Instant**: All characters at once (menus)

**VBlank usage**:
- Rendering characters during gameplay
- Limited VRAM access (use buffer)
- Update during VBlank only

### Memory Usage

```
Text Buffer: 1KB (256 characters × 4 bytes)
Window Buffer: 2KB (32×32 tiles × 2 bytes)
Decompression Buffer: 512 bytes
```

## Debug Tools

### Text Viewer (Mesen-S)

- **Tilemap Viewer**: See BG3 text layer
- **Memory Viewer**: Inspect text buffer
- **Debugger**: Breakpoint on text routines

### Manual Testing

```asm
; Test text rendering
DebugShowText:
    ldx #<TestText
    ldy #>TestText
    lda #^TestText
    jsr ShowDialogue
    rts
    
TestText:
    .db "Debug test", $01
    .db "message!", $00
```

## See Also

- **[MODDING_GUIDE.md](MODDING_GUIDE.md#dialogue-and-text)** - How to edit dialogue
- **[data_formats.md](data_formats.md)** - Text data structures
- **[GRAPHICS_SYSTEM.md](GRAPHICS_SYSTEM.md)** - BG3 layer rendering

---

**For modding dialogue**, see [MODDING_GUIDE.md](MODDING_GUIDE.md#dialogue-and-text).

**For technical details on graphics**, see [GRAPHICS_SYSTEM.md](GRAPHICS_SYSTEM.md).
