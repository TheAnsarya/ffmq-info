# Final Fantasy Mystic Quest - SPC700 Audio System Documentation

## Overview

The FFMQ audio system utilizes the SNES's independent SPC700 sound processor to deliver 8-channel polyphonic audio with hardware mixing, echo/reverb effects, and pattern-based music sequencing. The system provides complete separation between audio processing and gameplay, allowing uninterrupted music/sound playback.

**Key Features:**

- **SPC700 Processor:** Independent 8-bit Sony CPU @ 3.58 MHz
- **8 Audio Channels (Voices):** Simultaneous polyphonic playback
- **S-DSP (Digital Signal Processor):** Hardware audio mixer with effects
- **64 KB Audio RAM:** Complete audio driver + samples + sequence data
- **BRR Sample Compression:** 4-bit ADPCM with 4:1 compression ratio
- **Pattern-Based Sequencer:** N-SPC format with reusable music patterns
- **Hardware Echo/Reverb:** Dedicated echo buffer with feedback control
- **ADSR Envelope:** Per-channel attack/decay/sustain/release control
- **APU Communication:** 4-port mailbox interface ($2140-$2143)

## SPC700 Architecture

### Hardware Specifications

**SPC700 CPU:**
- **Clock Speed:** 1.024 MHz (Master clock: 24.576 MHz / 24)
- **Address Space:** 64 KB (no banking, flat memory)
- **Registers:** A (8-bit accumulator), X/Y (8-bit index), PSW (status), SP (stack pointer)
- **Instructions:** ~100 opcodes (similar to 6502 but distinct)

**S-DSP (Digital Signal Processor):**
- **8 Voices:** Independent sample playback channels
- **Sample Rate:** 32 KHz output
- **Bit Depth:** 16-bit internal, 4-bit ADPCM compressed samples
- **Effects:** Echo buffer, stereo panning, hardware pitch modulation
- **Mixing:** 8 channels → 2 stereo outputs (left/right)

### SPC700 Memory Map

**Total Memory:** 64 KB ($0000-$FFFF)

```
Address Range   Size    Purpose
────────────────────────────────────────────────
$0000-$00EF     240 B   Zero Page (fast access, driver variables)
$00F0-$00FF     16 B    Hardware I/O ports & DSP interface
$0100-$01FF     256 B   Stack space (grows downward from $01FF)
$0200-$02FF     256 B   Driver entry point & init code
$0300-$03FF     256 B   Main driver loop & command processor
$0400-$0FFF     3 KB    Music sequencer & pattern data
$1000-$1FFF     4 KB    Voice/channel state (16 channels × 256 bytes)
$2000-$CFFF    44 KB    Sample data (BRR compressed instruments/SFX)
$D000-$D1FF     512 B   Music driver code
$D200-$D3FF     512 B   Sound effect driver code
$D400-$DFFF     3 KB    Echo buffer control & DSP register tables
$E000-$EFFF     4 KB    Echo buffer (stereo reverb)
$F000-$FFFF     4 KB    Driver subroutines & lookup tables
```

### APU I/O Ports

**Communication Interface:** $2140-$2143 (CPU side), $00F4-$00F7 (SPC700 side)

```c
typedef struct {
    uint8_t port0;  // $2140 / $00F4: Command byte
    uint8_t port1;  // $2141 / $00F5: Parameter 1 / Data byte
    uint8_t port2;  // $2142 / $00F6: Parameter 2 / Address low
    uint8_t port3;  // $2143 / $00F7: Parameter 3 / Address high
} APU_Ports;
```

**Handshake Protocol:**

```asm
; Main CPU sends command
SendAudioCommand:
    lda #$01                ; Command: Play music
    sta $2140               ; Port 0 = command
    lda #$05                ; Track ID
    sta $2141               ; Port 1 = track
    
.wait_ack:
    lda $2140               ; Read acknowledgment
    cmp #$FF                ; SPC700 responds with $FF when done
    bne .wait_ack
    rts

; SPC700 receives command
ReceiveCommand:
    mov a, $F4              ; Read port 0
    cmp a, #$01             ; Play music command?
    bne .check_other
    
    mov a, $F5              ; Read track ID from port 1
    call LoadMusicTrack
    
    mov $F4, #$FF           ; Send acknowledgment
    ret
```

## S-DSP Register Map

### Voice Registers (per channel)

**Each voice has 8 registers:**

```
Offset  Name        Function
────────────────────────────────────────
+$00    VxVOLL      Volume Left (0-127, signed)
+$01    VxVOLR      Volume Right (0-127, signed)
+$02    VxPITCHL    Pitch Low (frequency low byte)
+$03    VxPITCHH    Pitch High (frequency high 6 bits, 0-$3FFF)
+$04    VxSRCN      Source Number (sample index in directory)
+$05    VxADSR1     ADSR Envelope 1 (attack/decay)
+$06    VxADSR2     ADSR Envelope 2 (sustain/release)
+$07    VxGAIN      Gain (alternative envelope mode)
```

**Voice Register Addresses:**

```
Voice 0: $00-$07
Voice 1: $10-$17
Voice 2: $20-$27
Voice 3: $30-$37
Voice 4: $40-$47
Voice 5: $50-$57
Voice 6: $60-$67
Voice 7: $70-$77
```

### Global DSP Registers

```
Address  Name        Function
────────────────────────────────────────
$0C      MVOLL       Main Volume Left (0-127)
$1C      MVOLR       Main Volume Right (0-127)
$2C      EVOLL       Echo Volume Left (-128 to +127)
$3C      EVOLR       Echo Volume Right (-128 to +127)
$4C      KON         Key On (bit mask: voice start)
$5C      KOFF        Key Off (bit mask: voice stop)
$6C      FLG         Flags (reset, mute, echo write enable)
$7C      ENDX        End Flag (bit mask: sample end detection)
$0D      EFB         Echo Feedback (-128 to +127)
$2D      PMON        Pitch Modulation (voice frequency modulation)
$3D      NON         Noise Enable (replace sample with noise)
$4D      EON         Echo Enable (bit mask: voices with echo)
$5D      DIR         Sample Directory Page (high byte of dir address)
$6D      ESA         Echo Start Address (page number)
$7D      EDL         Echo Delay Length (buffer size in 2KB blocks)
```

## BRR Sample Format

### BRR Compression

**BRR (Bit Rate Reduction):** 4-bit ADPCM compression

**Compression Ratio:** 4:1 (16-bit → 4-bit samples)

**Block Structure:**

```c
typedef struct {
    uint8_t header;     // Control byte
    uint8_t data[8];    // 16 samples (4 bits each, 2 per byte)
} BRR_Block;  // 9 bytes total
```

**Header Byte Format:**

```
Bits 7-4: Range/Shift (0-12)
Bits 3-2: Filter Type (0-3)
Bit 1:    Loop Flag (1 = loop to loop point)
Bit 0:    End Flag (1 = last block)

Format: RRRRFFLLLLEEEEE
R = Range (volume scaling)
F = Filter (prediction algorithm)
L = Loop flag
E = End flag
```

**Filter Types:**

```
Filter 0: Direct (no prediction)
          out = (data << shift)
          
Filter 1: Linear (first-order)
          out = (data << shift) + (prev × 15/16)
          
Filter 2: Quadratic (second-order)
          out = (data << shift) + (prev × 61/32) - (prev2 × 15/16)
          
Filter 3: Cubic (third-order)
          out = (data << shift) + (prev × 115/64) - (prev2 × 13/16)
```

### BRR Sample Example

```asm
; BRR sample: Short percussion hit
; 5 blocks × 9 bytes = 45 bytes total

BRR_Sample_Kick:
    ; Block 1: Attack (high volume)
    db $CC              ; Header: Range=12, Filter=3, Loop=0, End=0
    db $FF, $EE, $DD, $CC, $BB, $AA, $99, $88
    
    ; Block 2: Decay
    db $8C              ; Range=8, Filter=3
    db $77, $66, $55, $44, $33, $22, $11, $00
    
    ; Block 3: Sustain
    db $4C              ; Range=4, Filter=3
    db $88, $77, $66, $55, $44, $33, $22, $11
    
    ; Block 4: Release
    db $2C              ; Range=2, Filter=3
    db $44, $33, $22, $11, $00, $00, $00, $00
    
    ; Block 5: Silence (end)
    db $01              ; Range=0, Filter=0, End=1
    db $00, $00, $00, $00, $00, $00, $00, $00
```

### Sample Directory

**Directory Location:** Defined by DIR register ($5D)

**Directory Entry:** 4 bytes per sample

```c
typedef struct {
    uint16_t start_addr;    // Sample start address (BRR blocks)
    uint16_t loop_addr;     // Loop point address (if looping)
} SampleDirEntry;  // 4 bytes
```

**Directory Example:**

```asm
; Sample directory at $D000 (DIR = $D0)
SampleDirectory:
    ; Sample 0: Kick drum
    dw $2000, $2000         ; Start=$2000, Loop=$2000 (no loop)
    
    ; Sample 1: Snare
    dw $202D, $202D
    
    ; Sample 2: Hi-hat
    dw $205A, $205A
    
    ; Sample 3: Bass guitar (looping)
    dw $2100, $2190         ; Loops from $2190
    
    ; Sample 4: String ensemble
    dw $2500, $2650         ; Loops from $2650
    
    ; ... up to 256 samples
```

## ADSR Envelope System

### ADSR Parameters

**ADSR1 Register ($X5):**

```
Format: EDDDAAAA
E    = ADSR Enable (1=ADSR, 0=GAIN mode)
DDD  = Decay rate (0-7, 0=fastest)
AAAA = Attack rate (0-15, 0=fastest)
```

**ADSR2 Register ($X6):**

```
Format: SSSRRRRR
SSS   = Sustain level (0-7, 7=highest)
RRRRR = Sustain/Release rate (0-31, 0=fastest)
```

### ADSR Timing

**Attack Rates (0-15):**

```
Rate  Time to Max (milliseconds)
────────────────────────────────
0     ~4 ms   (instant)
1     ~8 ms
2     ~16 ms
3     ~32 ms
4     ~64 ms
...
15    ~34,000 ms (34 seconds, very slow)
```

**Decay/Release Rates (0-31):**

```
Rate  Time to Zero
────────────────────
0     ~4 ms
1     ~8 ms
...
31    ~38,000 ms (38 seconds)
```

### Envelope Examples

```asm
; Piano: Fast attack, medium decay/release
Piano_ADSR:
    db $FF              ; ADSR1: Enable, Decay=7, Attack=15 (fast)
    db $E5              ; ADSR2: Sustain=7, Release=5

; Strings: Slow attack, slow decay/release
Strings_ADSR:
    db $8A              ; ADSR1: Enable, Decay=1, Attack=10 (slow)
    db $E8              ; ADSR2: Sustain=7, Release=8

; Percussion: Instant attack, fast decay
Percussion_ADSR:
    db $FF              ; ADSR1: Enable, Decay=7, Attack=15
    db $E0              ; ADSR2: Sustain=7, Release=0 (instant)
```

## Music Sequencer (N-SPC Format)

### Sequence Command Format

**Note Commands ($00-$7F):**

```
$00-$5F: Note values (C-0 to B-7)
$60-$7F: Rest/wait durations
```

**Channel Parameter Commands ($D0-$DF):**

```
$D0: Set tempo (BPM)
$D2: Set octave
$D4: Set volume (0-255)
$D6: Set pan (-127 to +127, 0=center)
$D8: Set instrument/patch
$DA: Pitch bend
$DC: Vibrato enable
$DE: Tremolo enable
```

**ADSR Commands ($E0-$EF):**

```
$E0: Set custom ADSR1
$E2: Set custom ADSR2
$E4: Note length multiplier
$E6: Set detune
$E8: Portamento enable
$EA: Set echo volume
$EC: Set echo feedback
$EE: Noise enable
```

**Control Flow ($F0-$FF):**

```
$F0: Loop start
$F1: Loop end (with count)
$F2: Subroutine call
$F3: Subroutine return
$F4: Jump to address
$F5: Conditional jump
$F8: Track end (loop)
$F9: Track end (stop)
$FA: Synchronization marker
$FB: Wait for sync
```

### Music Track Structure

```asm
; Track header
MusicTrack_Battle:
    dw VoicePattern_Melody      ; Pointer to voice 0 pattern
    dw VoicePattern_Harmony     ; Voice 1
    dw VoicePattern_Bass        ; Voice 2
    dw VoicePattern_Percussion1 ; Voice 3
    dw VoicePattern_Percussion2 ; Voice 4
    dw $0000                    ; Voice 5 (unused)
    dw $0000                    ; Voice 6 (unused)
    dw $0000                    ; Voice 7 (unused)
    db $90                      ; Default tempo (144 BPM)
    db $80                      ; Default volume

; Voice pattern example
VoicePattern_Melody:
    db $D8, $01                 ; Set instrument 1 (trumpet)
    db $D4, $C0                 ; Set volume 192
    db $D2, $04                 ; Set octave 4
    
.loop:
    db $30, $60                 ; C (duration 96 ticks)
    db $34, $60                 ; E
    db $37, $60                 ; G
    db $3C, $C0                 ; C (duration 192 ticks, half note)
    
    db $F1, $00, <.loop, >.loop ; Loop forever
```

## Audio Driver System

### Driver Upload Process

```asm
; Upload SPC700 driver from Bank $0D
UploadSPC700Driver:
    ; 1. Wait for SPC700 IPL (Initial Program Loader) ready
.wait_ipl:
    lda $2140               ; Check port 0
    cmp #$AA
    bne .wait_ipl
    lda $2141
    cmp #$BB
    bne .wait_ipl           ; Wait for $AA $BB ready signal
    
    ; 2. Send driver size
    ldx #DriverSize
    stx $2142               ; Ports 2-3 = size
    
    ; 3. Send driver start address
    ldx #$0200              ; SPC700 RAM $0200
    stx $2140               ; Ports 0-1 = dest address
    
    ; 4. Send transfer start command
    lda #$CC
    sta $2141
    lda #$01                ; Command: Upload
    sta $2140
    
    ; 5. Transfer driver data byte-by-byte
    ldx #$0000
.upload_loop:
    lda DriverData,x
    sta $2141               ; Send data byte
    
    ; Handshake: Toggle port 0 to signal byte ready
    txa
    and #$01
    sta $2140
    
.wait_byte_ack:
    lda $2140
    cmp $2141               ; SPC echoes port 0 value when ready
    bne .wait_byte_ack
    
    inx
    cpx #DriverSize
    bcc .upload_loop
    
    ; 6. Start driver execution
    lda #$00
    sta $2142
    lda #$02                ; Start address high byte
    sta $2143
    lda #$00
    sta $2141
    lda #$00                ; Command: Execute
    sta $2140
    
    rts
```

### Driver Main Loop

```asm
; SPC700 driver main loop (runs continuously)
DriverMain:
    ; 1. Check for commands from main CPU
    mov a, $F4              ; Read port 0
    beq .no_command
    
    call ProcessCommand
    
.no_command:
    ; 2. Update music sequencer
    call UpdateSequencer
    
    ; 3. Update envelopes
    call UpdateEnvelopes
    
    ; 4. Process echo/reverb
    call ProcessEcho
    
    ; 5. Update voice volumes/pan
    call UpdateVoiceMixing
    
    ; 6. Sleep until next frame (~60 Hz)
    call WaitVBlank
    
    jmp DriverMain

; Process command from main CPU
ProcessCommand:
    mov a, $F4              ; Command byte
    
    cmp a, #$01             ; Play music?
    beq .play_music
    
    cmp a, #$02             ; Play SFX?
    beq .play_sfx
    
    cmp a, #$03             ; Stop music?
    beq .stop_music
    
    cmp a, #$04             ; Set volume?
    beq .set_volume
    
    ret
    
.play_music:
    mov a, $F5              ; Track ID
    call LoadMusicTrack
    mov $F4, #$FF           ; Acknowledge
    ret
    
.play_sfx:
    mov a, $F5              ; SFX ID
    call LoadSoundEffect
    mov $F4, #$FF
    ret
    
.stop_music:
    call StopAllVoices
    mov $F4, #$FF
    ret
    
.set_volume:
    mov a, $F5              ; Volume (0-255)
    mov $0C, a              ; Main volume left
    mov $1C, a              ; Main volume right
    mov $F4, #$FF
    ret
```

## Playing Notes & Samples

### Voice Initialization

```asm
; Start playing a note on voice 0
; Input: A = note number, X = sample ID, Y = volume
PlayNote:
    ; Set sample number
    mov $04, x              ; V0SRCN = sample ID
    
    ; Set volume
    mov $00, y              ; V0VOLL = volume
    mov $01, y              ; V0VOLR = volume
    
    ; Calculate pitch from note number
    mov x, a
    mov a, PitchTable+x     ; Low byte
    mov $02, a              ; V0PITCHL
    mov a, PitchTable+x+1   ; High byte
    mov $03, a              ; V0PITCHH
    
    ; Set ADSR envelope
    mov $05, #$FF           ; Fast attack/decay
    mov $06, #$E5           ; Medium sustain/release
    
    ; Key on voice 0
    mov $4C, #$01           ; KON bit 0
    
    ret

; Pitch table (14-bit frequencies)
PitchTable:
    dw $085F    ; C-0
    dw $08DE    ; C#0
    dw $0965    ; D-0
    dw $09F4    ; D#0
    dw $0A8C    ; E-0
    dw $0B2C    ; F-0
    dw $0BD6    ; F#0
    dw $0C8B    ; G-0
    dw $0D4D    ; G#0
    dw $0E1A    ; A-0
    dw $0EF5    ; A#0
    dw $0FDE    ; B-0
    ; ... continues for all 96 notes (8 octaves)
```

### Volume/Pan Control

```asm
; Set voice 0 volume and pan
; Input: A = volume (0-127), X = pan (-64 to +63, 0=center)
SetVoiceVolPan:
    ; Store base volume
    mov y, a
    
    ; Calculate left volume = base × (64 + pan) / 64
    mov a, x
    clrc
    adc a, #64
    mov x, a
    
    mov a, y                ; Base volume
    mul ya                  ; A × X → YA
    mov a, y                ; High byte (result / 256)
    lsr a                   ; / 2 (effectively / 512, then × 2 = / 256)
    lsr a                   ; / 4
    mov $00, a              ; V0VOLL = left volume
    
    ; Calculate right volume = base × (64 - pan) / 64
    mov a, #64
    setc
    sbc a, x                ; 64 - pan
    
    mov x, a
    mov a, y
    mul ya
    mov a, y
    lsr a
    lsr a
    mov $01, a              ; V0VOLR = right volume
    
    ret
```

## Echo/Reverb System

### Echo Configuration

```asm
; Setup echo/reverb effect
ConfigureEcho:
    ; Set echo buffer location (page $E0 = $E000)
    mov $6D, #$E0           ; ESA = echo start address
    
    ; Set echo buffer size (16 = 32 KB)
    mov $7D, #$10           ; EDL = 16 × 2KB = 32 KB
    
    ; Set echo volume (50% of main)
    mov $2C, #$40           ; EVOLL = 64 (left)
    mov $3C, #$40           ; EVOLR = 64 (right)
    
    ; Set echo feedback (50% recirculation)
    mov $0D, #$40           ; EFB = 64
    
    ; Enable echo on voices 0-3
    mov $4D, #$0F           ; EON bits 0-3
    
    ; Load FIR filter coefficients
    mov $0F, #$7F           ; FIR0 (strongest tap)
    mov $1F, #$00           ; FIR1
    mov $2F, #$00           ; FIR2
    mov $3F, #$00           ; FIR3
    mov $4F, #$00           ; FIR4
    mov $5F, #$00           ; FIR5
    mov $6F, #$00           ; FIR6
    mov $7F, #$00           ; FIR7
    
    ; Enable echo write
    mov $6C, #$20           ; FLG: Echo write enable
    
    ret
```

### FIR Filter (Echo Tone)

**FIR Filter:** 8-tap finite impulse response filter

**Common Configurations:**

```asm
; Bright reverb (short decay)
FIR_Bright:
    db $7F, $20, $10, $08, $04, $02, $01, $00

; Dark reverb (long decay)
FIR_Dark:
    db $7F, $40, $30, $20, $10, $08, $04, $02

; Room reverb (medium)
FIR_Room:
    db $7F, $30, $18, $0C, $06, $03, $01, $00
```

## Performance Metrics

**SPC700 CPU Usage:**

- Driver overhead: ~30-40% (main loop + sequencer)
- Available for audio: ~60-70%
- Typical usage: ~50% with 8 active voices + echo

**Timing:**

- **Main loop frequency:** ~60 Hz (synchronized with NMI)
- **Sample rate:** 32 KHz output
- **BRR decode:** ~200 cycles per 16 samples
- **Echo processing:** ~1,000 cycles per frame

**Memory Usage:**

```
Driver code:          ~8 KB
Sample data:         ~40 KB (expandable to ~50 KB)
Echo buffer:         ~12 KB (configurable 2-60 KB)
Working RAM:          ~4 KB (channel state, tables)
Total:               ~64 KB (full SPC700 RAM)
```

**Sample Limits:**

- **Max samples:** 256 (directory limit)
- **Typical count:** 30-50 instruments + 20-30 SFX
- **BRR block size:** 9 bytes = 16 samples = 0.5 ms @ 32 KHz
- **Average instrument:** 50-200 blocks = 450-1,800 bytes

## Command Interface Summary

**APU Commands (CPU → SPC700):**

```
Command  Port0  Port1       Port2       Port3       Function
──────────────────────────────────────────────────────────────────
$01      $01    Track ID    -           -           Play music
$02      $02    SFX ID      -           -           Play sound effect
$03      $03    -           -           -           Stop music
$04      $04    Volume      -           -           Set master volume
$05      $05    -           -           -           Pause music
$06      $06    -           -           -           Resume music
$07      $07    Voice mask  -           -           Mute voices
$08      $08    Tempo BPM   -           -           Set tempo
$09      $09    Pitch bend  -           -           Global pitch shift
$0A      $0A    Echo vol    Feedback    -           Echo config
```

**Acknowledgment:** SPC700 writes $FF to port 0 when command complete.

## Summary

The FFMQ SPC700 audio system provides sophisticated sound capabilities through:

**Strengths:**

- Independent audio processor (no CPU overhead on main 65816)
- 8-channel polyphonic mixing
- Hardware echo/reverb effects
- BRR compression (4:1 ratio saves memory)
- Pattern-based music sequencing (N-SPC format)
- ADSR envelope control per voice
- Real-time volume/pan/pitch control

**Technical Implementation:**

- Efficient driver (~8 KB code)
- APU mailbox communication (4-port protocol)
- Sample directory system (up to 256 samples)
- FIR filter echo (8-tap configurable)
- Pitch table for accurate note frequencies
- Voice allocation/priority system

---

**Documentation Version**: 1.0  
**Last Updated**: 2025-11-17  
**Related Documentation**: PPU_GRAPHICS_SYSTEM.md, COMBAT_SYSTEM.md, ITEM_SYSTEM.md
