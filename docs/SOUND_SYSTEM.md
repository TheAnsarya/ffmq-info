# Sound System Architecture

Complete documentation of the Final Fantasy Mystic Quest sound and music system.

## Table of Contents

- [System Overview](#system-overview)
- [SPC700 Architecture](#spc700-architecture)
- [Music Format](#music-format)
- [Sound Effects](#sound-effects)
- [Audio Driver](#audio-driver)
- [Music Playback](#music-playback)
- [Sound Channels](#sound-channels)
- [Instrument System](#instrument-system)
- [Music Data Organization](#music-data-organization)
- [Code Locations](#code-locations)

## System Overview

FFMQ uses the SNES SPC700 audio processor for all sound and music:

- **8 independent audio channels**
- **64KB audio RAM** for samples and driver code
- **Sample-based synthesis** (BRR format)
- **Sequenced music** with pattern-based arrangements
- **Real-time sound effects** mixed with music

### Audio Architecture

```
┌────────────────────┐
│  Main CPU (65816)  │
├────────────────────┤
│ - Trigger music    │
│ - Play SFX         │
│ - Send commands    │
└─────────┬──────────┘
          │ (SPC communication ports)
          v
┌────────────────────┐
│  SPC700 Processor  │
├────────────────────┤
│ - Audio driver     │
│ - Mix 8 channels   │
│ - Process effects  │
└─────────┬──────────┘
          │
          v
┌────────────────────┐
│  DSP (Audio Chip)  │
├────────────────────┤
│ - Sample playback  │
│ - ADSR envelopes   │
│ - Echo/reverb      │
│ - Final mix        │
└────────────────────┘
          │
          v
      🔊 Stereo Output
```

## SPC700 Architecture

### Audio RAM Layout (64KB)

```
Address     Size    Purpose
────────────────────────────────────────────
$0000-$00FF  256B   Zero page (variables)
$0100-$01FF  256B   Stack
$0200-$02FF  256B   Communication buffer
$0300-$07FF  1.25KB Audio driver code
$0800-$0FFF  2KB    Instrument table
$1000-$1FFF  4KB    Music sequence data
$2000-$5FFF  16KB   Sample data (BRR format)
$6000-$BFFF  24KB   Additional samples
$C000-$EFFF  12KB   Echo buffer
$F000-$FFFF  4KB    Audio driver (continued)
```

### SPC700 Registers

```
I/O Ports (Main CPU ↔ SPC700):
  $2140: Port 0 - Command byte
  $2141: Port 1 - Data byte 1
  $2142: Port 2 - Data byte 2
  $2143: Port 3 - Data byte 3

DSP Registers (Sound chip):
  $00-$0F: Voice 0 registers
  $10-$1F: Voice 1 registers
  ...
  $70-$7F: Voice 7 registers
  $0C: Main volume L
  $1C: Main volume R
  $2C: Echo volume L
  $3C: Echo volume R
  $4C: Key on
  $5C: Key off
  $6C: Flags (mute, echo, etc.)
  $7C: Echo feedback
```

## Music Format

### Music Structure

FFMQ uses a custom sequence format:

```
Music File Structure:
┌─────────────────────┐
│ Header              │
├─────────────────────┤
│ - Tempo             │
│ - Instrument set ID │
│ - Channel count     │
│ - Loop point        │
└─────────────────────┘
          │
          v
┌─────────────────────┐
│ Channel Data (×8)   │
├─────────────────────┤
│ Channel 0: Melody   │
│ Channel 1: Harmony  │
│ Channel 2: Bass     │
│ Channel 3: Drums    │
│ Channel 4: Pad      │
│ Channel 5: Effects  │
│ Channel 6: (unused) │
│ Channel 7: (unused) │
└─────────────────────┘
          │
          v
┌─────────────────────┐
│ Pattern Data        │
├─────────────────────┤
│ Note events         │
│ Controller events   │
│ Timing data         │
└─────────────────────┘
```

### Music Commands

```
Command Byte Format:

$00-$7F: Note On
  - Value = Note number (C0-G8)
  - Next byte = Duration

$80: Rest
  - Next byte = Duration

$81: Note Off (all channels)

$82: Loop Point
  - Mark loop position

$83: Loop End
  - Jump back to loop point

$84: Tempo Change
  - Next byte = New tempo

$85: Volume Change
  - Next byte = Volume (0-127)

$86: Pan Change
  - Next byte = Pan (0=L, 64=C, 127=R)

$87: Pitch Bend
  - Next 2 bytes = Bend amount

$88: Vibrato
  - Next 2 bytes = Rate, Depth

$89: Program Change
  - Next byte = Instrument ID

$8A-$8F: Reserved

$90-$FF: Pattern Call
  - Jump to pattern ($90-$FF = pattern 0-111)
```

### Note Duration Encoding

```
Duration Values:
  $01 = 1/64 note
  $02 = 1/32 note
  $04 = 1/16 note
  $08 = 1/8 note
  $0C = Dotted 1/8
  $10 = 1/4 note
  $18 = Dotted 1/4
  $20 = 1/2 note
  $30 = Dotted 1/2
  $40 = Whole note
  
Special:
  $00 = Previous duration (repeat)
  $FF = Hold (tie to next note)
```

## Sound Effects

### SFX System

Sound effects use dedicated channels:

```
SFX Priority System:
  Channel 6: High priority SFX
  Channel 7: Low priority SFX
  
Priority Levels:
  0: Music (channels 0-5)
  1: Ambient SFX (footsteps, wind)
  2: Action SFX (menu select, door)
  3: Battle SFX (attacks, spells)
  4: Critical SFX (level up, victory)
  
Higher priority can interrupt lower priority
```

### SFX Trigger

```asm
; ==============================================================================
; PlaySoundEffect - Trigger sound effect
; ==============================================================================
; Inputs:
;   A = Sound effect ID
; ==============================================================================
PlaySoundEffect:
    ; Check if already playing higher priority SFX
    cmp CurrentSFXPriority
    bcc .ignore             ; Lower priority? Ignore
    
    ; Store new SFX
    sta $2140               ; Send to SPC700 port 0
    lda #$01                ; SFX command
    sta $2141               ; Send command
    
    ; Wait for acknowledgment
.wait:
    lda $2140
    cmp #$AA                ; Check ACK byte
    bne .wait
    
.ignore:
    rts
```

### Common Sound Effects

```
SFX ID  Name                Usage
─────────────────────────────────────────────
$00     Menu Cursor         Cursor movement
$01     Menu Select         Confirm selection
$02     Menu Cancel         Back/cancel
$03     Menu Invalid        Invalid action
$10     Door Open           Opening doors
$11     Chest Open          Opening treasure
$12     Item Get            Item acquisition
$20     Sword Slash         Physical attack
$21     Magic Cast          Spell casting
$22     Explosion           Fire/explosion magic
$23     Thunder             Lightning magic
$24     Ice Break           Ice magic
$30     Enemy Hit           Damage to enemy
$31     Party Hit           Damage to party
$32     Critical Hit        Critical damage
$40     Level Up            Character level up
$41     Victory Fanfare     Battle victory
$42     Game Over           Party defeated
```

## Audio Driver

### Driver Initialization

```asm
; ==============================================================================
; InitializeAudio - Setup SPC700 and load driver
; ==============================================================================
InitializeAudio:
    ; Wait for SPC700 ready
    lda #$AA
.waitReady:
    cmp $2140
    bne .waitReady
    
    ; Send driver code size
    lda #<DriverSize
    sta $2142
    lda #>DriverSize
    sta $2143
    
    ; Send driver load command
    lda #$CC
    sta $2141
    lda #$01                ; Upload command
    sta $2140
    
    ; Transfer driver code
    ldx #$0000
.uploadLoop:
    lda AudioDriver,x
    sta $2141               ; Send byte
    lda #$00
    sta $2140               ; Trigger transfer
    
.waitAck:
    lda $2140
    bne .waitAck            ; Wait for SPC ack
    
    inx
    cpx #DriverSize
    bcc .uploadLoop
    
    ; Start driver
    lda #$00
    sta $2140               ; Send start command
    
    rts
```

### Driver Main Loop

```
SPC700 Driver Loop (runs at ~60 Hz):

1. Check for commands from main CPU
   │
   ├─ Play music
   ├─ Play SFX
   ├─ Stop music
   └─ Change volume
   ↓
2. Update music sequencer
   │
   ├─ Advance timer
   ├─ Process note events
   ├─ Update envelopes
   └─ Handle loops
   ↓
3. Mix active channels
   │
   ├─ Combine 8 channels
   ├─ Apply volume
   └─ Apply pan
   ↓
4. Process echo/reverb
   ↓
5. Output to DSP
   ↓
6. Repeat
```

## Music Playback

### Music Playback Flow

```
1. Game triggers music change
   ↓
2. Send music ID to SPC700
   ↓
3. SPC700 receives command
   ↓
4. Stop current music
   │
   ├─ Key off all channels
   ├─ Reset channel states
   └─ Clear pattern buffers
   ↓
5. Load new music data
   │
   ├─ Read music header
   ├─ Load instrument set
   ├─ Initialize channels
   └─ Set tempo
   ↓
6. Begin playback
   │
   └─ Process sequence data
       ↓
7. Loop at loop point
```

### Music Sequencer

```asm
; SPC700 Code (pseudo-code in 65816 syntax for clarity)
; ==============================================================================
; UpdateMusicSequencer - Process music sequence
; ==============================================================================
UpdateMusicSequencer:
    ; Update tempo timer
    lda TempoTimer
    clc
    adc CurrentTempo
    sta TempoTimer
    bcc .done               ; Not time for next event
    
    ; Process each channel
    ldx #$00
.channelLoop:
    lda ChannelActive,x
    beq .nextChannel        ; Skip if inactive
    
    ; Get next event
    ldy ChannelPointer,x
    lda (MusicData),y
    
    ; Check event type
    cmp #$80
    bcc .noteOn
    
    cmp #$82
    beq .loopPoint
    
    ; ... (handle other commands)
    
.noteOn:
    ; Play note on channel
    jsr PlayNoteOnChannel
    
.nextChannel:
    inx
    cpx #$06                ; Music uses channels 0-5
    bcc .channelLoop
    
.done:
    rts
```

## Sound Channels

### Channel Configuration

Each of 8 channels can be configured:

```
Channel Registers (per voice):
  $x0: Volume L (0-127)
  $x1: Volume R (0-127)
  $x2: Pitch low byte
  $x3: Pitch high byte
  $x4: Sample source number
  $x5: ADSR 1 (Attack, Decay)
  $x6: ADSR 2 (Sustain, Release)
  $x7: Gain (alternative to ADSR)
```

### ADSR Envelope

```
ADSR (Attack-Decay-Sustain-Release):

   Volume
     |
 127 |    /\
     |   /  \___________
     |  /               \
     | /                 \
   0 |/                   \__
     +----+----+----+----+-----> Time
       A   D   S    R
       
A = Attack:  How fast note reaches peak (0-15)
D = Decay:   How fast it falls to sustain (0-7)
S = Sustain: Volume level to hold (0-7)
R = Release: How fast it fades out (0-31)

ADSR1 byte: aaaa ddds
  aaaa = Attack rate
  ddd = Decay rate
  s = Sustain level bit 3

ADSR2 byte: sss rrrrr
  sss = Sustain level bits 0-2
  rrrrr = Release rate
```

### Sample Playback

```asm
; ==============================================================================
; PlaySampleOnChannel - Start sample playback
; ==============================================================================
; Inputs:
;   A = Channel number (0-7)
;   X = Sample number
;   Y = Pitch (note)
; ==============================================================================
PlaySampleOnChannel:
    ; Calculate DSP register offset
    asl a                   ; × 16 (channel spacing)
    asl a
    asl a
    asl a
    sta $00                 ; Save offset
    
    ; Set sample source
    lda $00
    ora #$04                ; +$x4 (source register)
    sta DspAddress
    stx DspData             ; Sample number
    
    ; Set pitch
    lda PitchTable,y        ; Get pitch value
    sta $10
    lda PitchTable+1,y
    sta $11
    
    lda $00
    ora #$02                ; +$x2 (pitch low)
    sta DspAddress
    lda $10
    sta DspData
    
    lda $00
    ora #$03                ; +$x3 (pitch high)
    sta DspAddress
    lda $11
    sta DspData
    
    ; Key on
    lda ChannelMask,x       ; Get channel bit
    sta DspAddress          ; Register $4C (key on)
    sta DspData
    
    rts
```

## Instrument System

### Instrument Definition

```
Instrument Structure (8 bytes):
  Byte 0: Sample number
  Byte 1: ADSR 1 (Attack/Decay)
  Byte 2: ADSR 2 (Sustain/Release)
  Byte 3: Base volume
  Byte 4: Base pan
  Byte 5: Pitch adjustment
  Byte 6: Flags (loop, noise, etc.)
  Byte 7: Reserved

Flags:
  Bit 0: Loop sample
  Bit 1: Use noise generator
  Bit 2: Vibrato enabled
  Bit 3: Tremolo enabled
  Bit 4-7: Reserved
```

### Sample Format (BRR)

SNES uses BRR (Bit Rate Reduction) compressed samples:

```
BRR Block (9 bytes):
  Byte 0: Header
    Bits 0-1: Loop flags
      00 = Continue
      01 = Loop end
      10 = Loop start
      11 = Loop both
    Bits 2-3: Filter type (0-3)
    Bits 4-7: Shift amount (0-12)
  
  Bytes 1-8: 16 4-bit samples (compressed)
  
Compression ratio: ~3.6:1
Sample rate: 32kHz maximum
```

### Instrument Table

```
Built-in Instruments:
  00: Piano
  01: Strings
  02: Brass
  03: Flute
  04: Synth Lead
  05: Synth Pad
  06: Electric Guitar
  07: Acoustic Guitar
  08: Bass Guitar
  09: Slap Bass
  0A: Timpani
  0B: Snare Drum
  0C: Bass Drum
  0D: Hi-Hat
  0E: Crash Cymbal
  0F: Sound Effect samples
  ... (total 128 instruments)
```

## Music Data Organization

### Music Bank Structure

```
ROM Bank $08 (Music Data):
  $08:0000-$08:1FFF: Music pointers (256 entries)
  $08:2000-$08:3FFF: Music 0-15 data
  $08:4000-$08:5FFF: Music 16-31 data
  $08:6000-$08:7FFF: Music 32-47 data
  $08:8000-$08:FFFF: Instrument samples

Music IDs:
  $00: Title Screen
  $01: World Map
  $02: Town Theme
  $03: Dungeon Theme
  $04: Battle Theme
  $05: Boss Battle
  $06: Victory Fanfare
  $07: Game Over
  ... (total 64 tracks)
```

### Loading Music

```asm
; ==============================================================================
; LoadMusic - Load music into SPC700 RAM
; ==============================================================================
; Inputs:
;   A = Music ID
; ==============================================================================
LoadMusic:
    ; Get music pointer
    asl a                   ; × 2 (word table)
    tax
    lda MusicPointerTable,x
    sta $00
    lda MusicPointerTable+1,x
    sta $01
    
    ; Get music size
    ldy #$00
    lda ($00),y             ; Size low
    sta $10
    iny
    lda ($00),y             ; Size high
    sta $11
    
    ; Send load command to SPC700
    lda #$02                ; Load music command
    sta $2140
    lda $10                 ; Size low
    sta $2141
    lda $11                 ; Size high
    sta $2142
    
    ; Transfer music data
    ldy #$02                ; Skip size header
.transferLoop:
    lda ($00),y
    sta $2141               ; Send byte
    
    ; Wait for SPC acknowledgment
.waitAck:
    lda $2140
    cmp #$AA
    bne .waitAck
    
    iny
    cpy $11
    bcc .transferLoop
    
    ; Start playback
    lda #$03                ; Play command
    sta $2140
    
    rts
```

## Code Locations

### Main CPU Side

**File**: `src/asm/bank_01_documented.asm`

```asm
InitializeAudio:            ; Setup audio system
    ; Located at $01:C000
    
LoadMusic:                  ; Load music to SPC700
    ; Located at $01:C123
    
PlaySoundEffect:            ; Trigger SFX
    ; Located at $01:C234
    
StopMusic:                  ; Halt music playback
    ; Located at $01:C345
    
SetMusicVolume:             ; Adjust music volume
    ; Located at $01:C456
```

### SPC700 Driver

**File**: `src/spc700/audio_driver.s` (separate SPC700 assembly)

```asm
DriverMain:                 ; Main driver loop
    ; SPC RAM at $0300
    
ProcessCommand:             ; Handle CPU commands
    ; SPC RAM at $0350
    
UpdateSequencer:            ; Music sequencer
    ; SPC RAM at $0400
    
MixChannels:                ; Mix 8 channels
    ; SPC RAM at $0500
    
ProcessEcho:                ; Echo/reverb effect
    ; SPC RAM at $0600
```

### Music Data

**File**: `assets/music/*.bin` (binary music data)

**File**: `src/asm/bank_08_documented.asm` (music pointers)

```asm
MusicPointerTable:          ; Music pointer table
    ; Located at $08:0000
    
MusicData_Title:            ; Title screen music
    ; Located at $08:2000
    
MusicData_WorldMap:         ; World map theme
    ; Located at $08:2800
    
; ... (all music tracks)
```

## Performance Considerations

### SPC700 CPU Load

```
Available CPU time: ~2.048 MHz
Typical driver load: ~30-40% CPU
Remaining: 60-70% for music/SFX

Optimization strategies:
- Use lookup tables for pitch
- Precalculate ADSR values
- Limit simultaneous channels
- Simple mixing algorithm
```

### Memory Management

```
64KB Audio RAM allocation:
- Driver code: ~8KB
- Sample data: ~40KB
- Echo buffer: ~12KB
- Working RAM: ~4KB

Sample optimization:
- Loop samples when possible
- Use BRR compression
- Share samples between instruments
- Limit sample size to essentials
```

## Debug Tools

### Audio Debugging (Mesen-S)

- **SPC Player**: Listen to isolated tracks
- **Channel Viewer**: See individual channels
- **Sample Viewer**: Inspect BRR samples
- **Memory Viewer**: Check SPC RAM
- **Debugger**: Breakpoint on SPC code

### Testing Commands

```asm
; Mute specific channel
DebugMuteChannel:
    lda #$07                ; Channel 7
    sta $2140
    lda #$FF                ; Mute command
    sta $2141
    rts

; Force music ID
DebugPlayMusic:
    lda #$04                ; Battle theme
    jsr LoadMusic
    rts
```

## See Also

- **[MODDING_GUIDE.md](MODDING_GUIDE.md)** - How to modify music/sound
- **[data_formats.md](data_formats.md)** - Music data structures
- **[GRAPHICS_SYSTEM.md](GRAPHICS_SYSTEM.md)** - Related to audio sync

---

**For modding music**, see [MODDING_GUIDE.md](MODDING_GUIDE.md).

**For music data format**, see [data_formats.md](data_formats.md).
