# FFMQ Audio System Architecture

## Table of Contents

1. [Overview](#overview)
2. [SPC700 Architecture](#spc700-architecture)
3. [Audio Memory Map](#audio-memory-map)
4. [Channel Management](#channel-management)
5. [Music System](#music-system)
6. [Sound Effects](#sound-effects)
7. [Communication Protocol](#communication-protocol)
8. [Performance Considerations](#performance-considerations)
9. [Code Examples](#code-examples)

---

## Overview

The Final Fantasy Mystic Quest audio system uses the SNES SPC700 sound processor for all audio playback. The system manages 8 independent audio channels, handles both background music and sound effects, and communicates with the main CPU through a sophisticated protocol.

### Key Features

- **8-channel audio:** Full utilization of SPC700 capabilities
- **Dynamic channel allocation:** Music and SFX share channels intelligently
- **Streaming support:** Background music streams from ROM
- **Priority system:** SFX can override music channels based on priority
- **Memory efficient:** Compressed audio data, shared patterns

### System Components

```
┌─────────────────────────────────────────────────────┐
│                    Main CPU (65816)                  │
│  ┌──────────────────────────────────────────────┐  │
│  │         Audio Command Queue ($0200-$0627)     │  │
│  └───────────────────┬──────────────────────────┘  │
└────────────────────│─────────────────────────────────┘
                     │ Communication Ports
                     ↓
┌─────────────────────────────────────────────────────┐
│                 SPC700 Sound Processor               │
│  ┌──────────────────────────────────────────────┐  │
│  │  Audio RAM (64 KB)                             │  │
│  │  - Sample Data ($0000-$DFFF)                   │  │
│  │  - Pattern Data ($E000-$EFFF)                  │  │
│  │  - Channel State ($F000-$F7FF)                 │  │
│  │  - System Variables ($F800-$FFFF)              │  │
│  └──────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────┐  │
│  │  8 Audio Channels                              │  │
│  │  - Ch 0-3: Music (melody, harmony)             │  │
│  │  - Ch 4-5: Music (bass, percussion)            │  │
│  │  - Ch 6-7: Sound Effects (high priority)       │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                     │
                     ↓
              Digital-to-Analog
                     │
                     ↓
                Audio Output
```

---

## SPC700 Architecture

### Processor Overview

The SPC700 is a custom Sony audio processor:
- **CPU:** 8-bit processor at 1.024 MHz
- **Memory:** 64 KB audio RAM
- **Channels:** 8 independent voices
- **DSP:** Hardware sample playback, ADSR envelopes, echo effects

### Audio RAM Organization

| Address Range | Size    | Purpose                    | FFMQ Usage                      |
|--------------|---------|----------------------------|---------------------------------|
| $0000-$3FFF  | 16 KB   | Sample data region 1       | Instrument samples (percussion) |
| $4000-$7FFF  | 16 KB   | Sample data region 2       | Instrument samples (melodic)    |
| $8000-$BFFF  | 16 KB   | Sample data region 3       | Sound effect samples            |
| $C000-$DFFF  | 8 KB    | Sample data region 4       | Voice samples (rare)            |
| $E000-$EFFF  | 4 KB    | Pattern/sequence data      | Music patterns, loops           |
| $F000-$F7FF  | 2 KB    | Channel state buffers      | Real-time channel data          |
| $F800-$FFFF  | 2 KB    | System variables           | SPC700 internal state           |

### DSP Registers

The SPC700's DSP provides per-channel control:

| Register | Name           | Function                           |
|----------|----------------|------------------------------------|
| V0VOL    | Volume L       | Left channel volume (0-127)        |
| V0VOLA   | Volume R       | Right channel volume (0-127)       |
| V0PITCHL | Pitch Low      | Sample pitch (low byte)            |
| V0PITCHH | Pitch High     | Sample pitch (high byte)           |
| V0SRCN   | Source Number  | Sample number in directory         |
| V0ADSR1  | ADSR 1         | Attack/Decay envelope              |
| V0ADSR2  | ADSR 2         | Sustain/Release envelope           |
| V0GAIN   | Gain           | Direct gain control                |

---

## Audio Memory Map

### Main CPU Side ($0200-$0688)

These are the CPU-side variables used to manage audio:

#### Channel Assignment ($0628)

```assembly
!audio_channel_assign = $0628     ; 8 channels worth of data
```

**Purpose:** Tracks which sound effect or music pattern is assigned to each channel.

**Data Structure:**
```
Offset  Channel  Purpose
+$00    0        Music: Lead melody
+$01    1        Music: Harmony 1
+$02    2        Music: Harmony 2
+$03    3        Music: Arpeggio/ornament
+$04    4        Music: Bass line
+$05    5        Music: Percussion/rhythm
+$06    6        SFX: High priority effects
+$07    7        SFX: Medium priority effects
```

#### SPC700 RAM Addresses ($0648, $064A)

```assembly
!audio_ram_addr_start = $0648     ; SPC700 RAM start addresses
!audio_ram_addr_end   = $064a     ; SPC700 RAM end addresses
```

**Purpose:** Define transfer regions when uploading data to SPC700 audio RAM.

**Usage:**
- Start address: Where to begin writing in SPC700 RAM
- End address: Where to stop writing
- Size is calculated as (end - start)

#### Pattern Data ($0668, $0688)

```assembly
!audio_pattern_size   = $0668     ; Pattern data sizes (per channel)
!audio_pattern_buffer = $0688     ; Pattern buffer slots (8 channels)
```

**Purpose:** 
- `audio_pattern_size`: Size of music pattern data for each channel
- `audio_pattern_buffer`: Temporary buffer for pattern data before upload to SPC700

---

## Channel Management

### Channel Allocation Strategy

FFMQ uses a hybrid allocation system:

1. **Static Allocation (Channels 0-5):** Reserved for background music
2. **Dynamic Allocation (Channels 6-7):** Shared by sound effects

### Channel Priority System

| Channel | Priority | Typical Use                  | Can Override? |
|---------|----------|------------------------------|---------------|
| 0       | 5        | Lead melody                  | No            |
| 1       | 4        | Harmony 1                    | No            |
| 2       | 4        | Harmony 2                    | No            |
| 3       | 3        | Ornament/arpeggio            | Rare          |
| 4       | 3        | Bass line                    | Rare          |
| 5       | 2        | Percussion/drums             | Yes (by SFX)  |
| 6       | 8        | High priority SFX            | Yes           |
| 7       | 6        | Medium priority SFX          | Yes           |

**Priority Rules:**
- Lower priority channels can be interrupted by higher priority sounds
- Music channels (0-5) have fixed priority
- SFX channels (6-7) have dynamic priority based on effect type

### Channel State Machine

Each channel operates in one of several states:

```
┌──────────┐
│   IDLE   │ ← Channel not playing
└─────┬────┘
      │ Start playback
      ↓
┌──────────┐
│ STARTING │ ← Initialize sample, ADSR
└─────┬────┘
      │
      ↓
┌──────────┐
│ PLAYING  │ ← Active playback
└─────┬────┘
      │ Pattern end / SFX complete
      ↓
┌──────────┐
│ RELEASE  │ ← ADSR release phase
└─────┬────┘
      │ Release complete
      ↓
┌──────────┐
│   IDLE   │
└──────────┘
```

---

## Music System

### Music Data Format

FFMQ music is stored in a compact pattern-based format:

#### Pattern Structure

```
Byte    Purpose
----    -------
0       Pattern ID (0-255)
1       Pattern length (in ticks)
2       Tempo modifier
3       Channel mask (which channels play this pattern)
4-N     Note data (compressed)
```

#### Note Data Format

Each note is encoded in 2-3 bytes:

```
Byte 0: PPPPPPPP (Pitch: 0-127)
Byte 1: LLDDDVVV (Length:2, Duration:3, Volume:3)
Byte 2: EEEEFFFF (Effect:4, Effect param:4) [optional]
```

**Pitch encoding:**
- 0-11: Octave 1 (C-B)
- 12-23: Octave 2 (C-B)
- ...
- 108-119: Octave 10 (C-B)
- 127: Rest

**Length encoding:**
- 00: Whole note (96 ticks)
- 01: Half note (48 ticks)
- 10: Quarter note (24 ticks)
- 11: Eighth note (12 ticks)

**Volume encoding:**
- 000: pp (pianissimo, vol 32)
- 001: p (piano, vol 48)
- 010: mp (mezzo-piano, vol 64)
- 011: mf (mezzo-forte, vol 80)
- 100: f (forte, vol 96)
- 101: ff (fortissimo, vol 112)
- 110: fff (forte-fortissimo, vol 127)

### Music Playback Pipeline

```
┌────────────────────────────────────────────────────────┐
│ 1. Load Music Track                                    │
│    - Read pattern table from ROM                       │
│    - Parse channel assignments                         │
│    - Load initial samples to SPC700                    │
└──────────────────┬─────────────────────────────────────┘
                   ↓
┌────────────────────────────────────────────────────────┐
│ 2. Initialize Channels                                 │
│    - Set channel volumes                               │
│    - Configure ADSR envelopes                          │
│    - Load first patterns to buffers                    │
└──────────────────┬─────────────────────────────────────┘
                   ↓
┌────────────────────────────────────────────────────────┐
│ 3. Start Playback (Main Loop)                          │
│    ┌──────────────────────────────────────────────┐   │
│    │ For each channel (0-5):                       │   │
│    │   - Read next note from pattern               │   │
│    │   - Set pitch, volume, ADSR                   │   │
│    │   - Trigger sample playback                   │   │
│    │   - Wait for note duration                    │   │
│    │   - Check for pattern end                     │   │
│    │   - Load next pattern if needed               │   │
│    └──────────────────────────────────────────────┘   │
│    │ Loop until track ends                             │
└────┴───────────────────────────────────────────────────┘
                   ↓
┌────────────────────────────────────────────────────────┐
│ 4. Handle Loop Points                                  │
│    - Check if loop point reached                       │
│    - Jump to loop start pattern                        │
│    - Or advance to next track                          │
└────────────────────────────────────────────────────────┘
```

### Tempo & Timing

FFMQ music uses a tick-based timing system:

- **Base tempo:** 120 BPM (typical)
- **Tick rate:** 60 Hz (NTSC) or 50 Hz (PAL)
- **Ticks per beat:** 24 ticks
- **Time per tick:** 16.67 ms (NTSC) or 20 ms (PAL)

**Tempo calculation:**
```
BPM = (tick_rate × 60) / ticks_per_beat
BPM = (60 × 60) / 24 = 150 BPM (at standard speed)
```

**Tempo modifiers:**
- Stored in pattern header (byte 2)
- Range: 50% - 200% of base tempo
- Applied per-pattern for tempo changes

---

## Sound Effects

### SFX Data Format

Sound effects are stored separately from music:

#### SFX Structure

```
Byte    Purpose
----    -------
0       SFX ID (0-255)
1       Priority (0-15, higher = more important)
2       Channel preference (6 or 7)
3       Sample number
4       Pitch (0-255)
5       Volume (0-127)
6       ADSR attack/decay
7       ADSR sustain/release
8       Duration (in frames, 0 = until complete)
```

### SFX Playback Strategy

```
┌────────────────────────────────────────────────────────┐
│ 1. SFX Trigger Request                                 │
│    - Game event triggers SFX (e.g., menu select)       │
│    - Pass SFX ID to audio system                       │
└──────────────────┬─────────────────────────────────────┘
                   ↓
┌────────────────────────────────────────────────────────┐
│ 2. Channel Selection                                   │
│    - Check SFX priority                                │
│    - Find available SFX channel (6 or 7)               │
│    - If both busy, compare priorities                  │
│    - Override lower priority if needed                 │
└──────────────────┬─────────────────────────────────────┘
                   ↓
┌────────────────────────────────────────────────────────┐
│ 3. Sample Upload (if needed)                           │
│    - Check if sample already in SPC700 RAM             │
│    - If not, upload sample data                        │
│    - Update sample directory                           │
└──────────────────┬─────────────────────────────────────┘
                   ↓
┌────────────────────────────────────────────────────────┐
│ 4. Channel Configuration                               │
│    - Set sample number                                 │
│    - Set pitch, volume                                 │
│    - Configure ADSR envelope                           │
│    - Enable channel (KON register)                     │
└──────────────────┬─────────────────────────────────────┘
                   ↓
┌────────────────────────────────────────────────────────┐
│ 5. Playback                                            │
│    - SPC700 plays sample                               │
│    - CPU counts duration frames                        │
│    - Mark channel idle when complete                   │
└────────────────────────────────────────────────────────┘
```

### Common Sound Effects

| ID   | Effect                  | Priority | Channel | Duration    |
|------|-------------------------|----------|---------|-------------|
| $00  | Menu cursor move        | 5        | 6       | 8 frames    |
| $01  | Menu select             | 6        | 6       | 15 frames   |
| $02  | Menu cancel             | 6        | 6       | 12 frames   |
| $03  | Cannot select           | 7        | 6       | 20 frames   |
| $10  | Sword swing             | 8        | 7       | 25 frames   |
| $11  | Sword hit               | 9        | 7       | 18 frames   |
| $12  | Enemy hit               | 8        | 7       | 20 frames   |
| $20  | Spell cast              | 10       | 6/7     | 45 frames   |
| $21  | Healing spell           | 9        | 6       | 40 frames   |
| $30  | Item get (small)        | 7        | 6       | 30 frames   |
| $31  | Item get (major)        | 10       | 6       | 60 frames   |
| $40  | Door open               | 6        | 7       | 35 frames   |
| $41  | Chest open              | 8        | 6       | 50 frames   |
| $50  | Battle victory fanfare  | 15       | All     | Until end   |

---

## Communication Protocol

### CPU ↔ SPC700 Communication Ports

The SNES provides 4 communication ports for CPU-SPC700 data transfer:

| Port    | Address (CPU) | Address (SPC) | Direction    |
|---------|---------------|---------------|--------------|
| PORT 0  | $2140         | $F4           | Bidirectional|
| PORT 1  | $2141         | $F5           | Bidirectional|
| PORT 2  | $2142         | $F6           | Bidirectional|
| PORT 3  | $2143         | $F7           | Bidirectional|

### Command Protocol

FFMQ uses a handshake protocol for reliable communication:

#### Protocol Flow

```
CPU:                                SPC700:
┌────────────────┐                 ┌────────────────┐
│ Write command  │                 │                │
│ to PORT 0      │────────────────→│ Read PORT 0    │
│ (e.g., $01)    │                 │ Detect command │
└────────────────┘                 └────────────────┘
        │                                   │
        │ Wait for ACK                      │ Process command
        │                                   │
        ↓                                   ↓
┌────────────────┐                 ┌────────────────┐
│ Read PORT 0    │                 │ Write ACK      │
│ Check for ACK  │←────────────────│ to PORT 0      │
│ (command | $80)│                 │ (command | $80)│
└────────────────┘                 └────────────────┘
        │                                   │
        │ ACK received                      │
        ↓                                   ↓
┌────────────────┐                 ┌────────────────┐
│ Send parameters│                 │ Wait for more  │
│ via PORT 1-3   │────────────────→│ data if needed │
└────────────────┘                 └────────────────┘
```

### Command Set

| Command | PORT 0 | PORT 1      | PORT 2      | PORT 3      | Function                    |
|---------|--------|-------------|-------------|-------------|-----------------------------|
| $00     | $00    | -           | -           | -           | NOP / Idle                  |
| $01     | $01    | Track ID    | Variation   | -           | Play music track            |
| $02     | $02    | -           | -           | -           | Stop music                  |
| $03     | $03    | SFX ID      | Priority    | -           | Play sound effect           |
| $04     | $04    | Addr Low    | Addr High   | Bank        | Set SPC RAM write addr      |
| $05     | $05    | Size Low    | Size High   | -           | Set transfer size           |
| $06     | $06    | Data byte   | -           | -           | Write byte to SPC RAM       |
| $07     | $07    | Volume      | Fade frames | -           | Fade music volume           |
| $08     | $08    | Channel     | Volume      | -           | Set channel volume          |
| $09     | $09    | -           | -           | -           | Pause music                 |
| $0A     | $0A    | -           | -           | -           | Resume music                |
| $0B     | $0B    | Effect type | Param 1     | Param 2     | Apply audio effect          |
| $0C     | $0C    | -           | -           | -           | Reset SPC700                |

### Data Transfer Protocol

For bulk data transfer (samples, patterns):

```
1. CPU: Send $04 command (set write address)
   - PORT 1: Low byte of SPC RAM address
   - PORT 2: High byte of SPC RAM address
   - Wait for ACK ($84)

2. CPU: Send $05 command (set transfer size)
   - PORT 1: Low byte of size
   - PORT 2: High byte of size
   - Wait for ACK ($85)

3. CPU: Loop for each byte:
   - Send $06 command (write byte)
   - PORT 1: Data byte
   - Wait for ACK ($86)
   - Repeat until all bytes transferred

4. CPU: Send $00 command (complete)
   - SPC700 now has data in RAM
```

**Optimization:** FFMQ batches small transfers (< 256 bytes) by sending multiple bytes per command cycle.

---

## Performance Considerations

### CPU Time Budget

Audio system must not consume too much CPU time:

- **Target:** < 5% of frame time (1.4 ms per 16.67 ms frame)
- **Actual usage:**
  - Music update: ~0.3 ms per frame (1.8%)
  - SFX trigger: ~0.2 ms per event
  - Sample upload: ~5 ms (blocks frame, done during transitions)

### SPC700 CPU Usage

The SPC700 runs at 1.024 MHz (slower than main CPU):

- **Music processing:** ~40% CPU (6 active channels)
- **SFX processing:** ~10% CPU (2 active channels)
- **Echo/reverb:** ~15% CPU (if enabled)
- **Total:** ~65% CPU during intense scenes
- **Headroom:** 35% for additional effects

### Memory Management

Audio RAM is limited (64 KB total):

**Sample compression:**
- BRR (Bit Rate Reduction) compression used
- 9:16 compression ratio (typical)
- 16 KB of samples = ~28 KB uncompressed

**Dynamic sample loading:**
- Only load samples needed for current area
- Swap sample banks during screen transitions
- Common samples (menu sounds) always resident

**Pattern streaming:**
- Store only 4-8 KB of patterns in SPC RAM
- Stream next patterns from ROM as needed
- Loop points allow pattern reuse

### Latency Considerations

Audio latency affects user experience:

| Action                  | Latency    | Acceptable? |
|-------------------------|------------|-------------|
| Menu cursor move SFX    | 1 frame    | Excellent   |
| Menu select SFX         | 1-2 frames | Excellent   |
| Battle attack SFX       | 2-3 frames | Good        |
| Music track change      | 8-16 frames| Acceptable  |
| Sample upload (large)   | 60+ frames | During fade |

**Latency sources:**
1. Command processing: 1 frame (communication protocol)
2. Sample upload: Variable (0 if cached, 10-60 frames if new)
3. SPC700 processing: 1-2 frames (pattern parsing)

**Optimization strategies:**
- Pre-cache common samples
- Initiate music changes early (during fade-out)
- Use SFX channels for instant-response sounds

---

## Code Examples

### Example 1: Play Music Track

```assembly
; Play music track $05 (e.g., overworld theme)
PlayMusicTrack:
    lda #$05                      ; Track ID
    sta music_track_id            ; Save for reference
    
    ; Send command to SPC700
    lda #$01                      ; Command: Play music
    sta $2140                     ; PORT 0
    lda #$05                      ; Track ID
    sta $2141                     ; PORT 1
    lda #$00                      ; Variation 0
    sta $2142                     ; PORT 2
    
    ; Wait for acknowledgment
.wait_ack:
    lda $2140                     ; Read PORT 0
    cmp #$81                      ; ACK = command | $80
    bne .wait_ack                 ; Loop until ACK
    
    rts
```

### Example 2: Trigger Sound Effect

```assembly
; Play sound effect (menu select)
PlayMenuSelectSFX:
    lda #$03                      ; Command: Play SFX
    sta $2140                     ; PORT 0
    lda #$01                      ; SFX ID $01 (menu select)
    sta $2141                     ; PORT 1
    lda #$06                      ; Priority 6
    sta $2142                     ; PORT 2
    
.wait_ack:
    lda $2140
    cmp #$83                      ; ACK for command $03
    bne .wait_ack
    
    rts
```

### Example 3: Channel Volume Control

```assembly
; Fade out channel 0 (lead melody)
FadeOutChannel0:
    lda #$3c                      ; 60 frames (1 second)
    sta fade_timer                ; Store timer
    
.fade_loop:
    lda #$08                      ; Command: Set channel volume
    sta $2140                     ; PORT 0
    lda #$00                      ; Channel 0
    sta $2141                     ; PORT 1
    
    ; Calculate volume (linear fade)
    lda fade_timer
    asl a                         ; × 2 (0-120 range)
    sta $2142                     ; PORT 2 (volume)
    
.wait_ack:
    lda $2140
    cmp #$88                      ; ACK
    bne .wait_ack
    
    ; Wait 1 frame
    jsr WaitOneFrame
    
    dec fade_timer
    bne .fade_loop
    
    rts
```

### Example 4: Upload Sample to SPC700

```assembly
; Upload 512-byte sample to SPC700 RAM
UploadSample:
    ; Set destination address ($4000 in SPC RAM)
    lda #$04                      ; Command: Set write address
    sta $2140                     ; PORT 0
    lda #$00                      ; Low byte
    sta $2141                     ; PORT 1
    lda #$40                      ; High byte ($4000)
    sta $2142                     ; PORT 2
    
.wait_addr_ack:
    lda $2140
    cmp #$84
    bne .wait_addr_ack
    
    ; Set transfer size (512 bytes)
    lda #$05                      ; Command: Set size
    sta $2140                     ; PORT 0
    lda #$00                      ; Low byte (256)
    sta $2141                     ; PORT 1
    lda #$02                      ; High byte (512)
    sta $2142                     ; PORT 2
    
.wait_size_ack:
    lda $2140
    cmp #$85
    bne .wait_size_ack
    
    ; Transfer data
    ldx #$0000                    ; Byte counter
.transfer_loop:
    lda #$06                      ; Command: Write byte
    sta $2140                     ; PORT 0
    lda sample_data,x             ; Load byte from ROM
    sta $2141                     ; PORT 1
    
.wait_byte_ack:
    lda $2140
    cmp #$86
    bne .wait_byte_ack
    
    inx
    cpx #$0200                    ; 512 bytes
    bcc .transfer_loop
    
    ; Complete
    lda #$00                      ; Command: Complete
    sta $2140
    
    rts
```

### Example 5: Dynamic Channel Assignment

```assembly
; Assign sound effect to best available channel
AssignSFXToChannel:
    ; Check channel 6
    lda.w !audio_channel_assign+6 ; Read channel 6 assignment
    beq .use_channel_6             ; If 0, channel is idle
    
    ; Check channel 7
    lda.w !audio_channel_assign+7 ; Read channel 7 assignment
    beq .use_channel_7             ; If 0, channel is idle
    
    ; Both channels busy, check priorities
    lda channel_6_priority
    cmp sfx_priority               ; Compare with new SFX priority
    bcs .override_channel_6        ; Override if new is higher priority
    
    lda channel_7_priority
    cmp sfx_priority
    bcs .override_channel_7
    
    ; Cannot play (both channels higher priority)
    rts
    
.use_channel_6:
.override_channel_6:
    lda #$06
    sta selected_channel
    bra .assign
    
.use_channel_7:
.override_channel_7:
    lda #$07
    sta selected_channel
    
.assign:
    ; Assign SFX to selected channel
    lda sfx_id
    ldx selected_channel
    sta.w !audio_channel_assign,x ; Store assignment
    lda sfx_priority
    sta channel_priority,x         ; Store priority
    
    ; Trigger SFX playback
    jsr PlaySoundEffect
    
    rts
```

### Example 6: Music Pattern Processing

```assembly
; Process next note from music pattern
ProcessMusicNote:
    ldx current_channel            ; Get current channel (0-5)
    
    ; Load pattern data pointer
    lda.w !audio_pattern_buffer,x  ; Get pattern buffer offset
    tay                             ; Y = pattern data offset
    
    ; Read note data
    lda pattern_data,y              ; Byte 0: Pitch
    cmp #127                        ; Check for rest
    beq .play_rest
    
    sta note_pitch                  ; Store pitch
    
    iny
    lda pattern_data,y              ; Byte 1: Length/Duration/Volume
    and #$c0                        ; Mask length bits
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    sta note_length                 ; Store length (0-3)
    
    lda pattern_data,y
    and #$38                        ; Mask duration bits
    lsr a
    lsr a
    lsr a
    sta note_duration               ; Store duration (0-7)
    
    lda pattern_data,y
    and #$07                        ; Mask volume bits
    sta note_volume                 ; Store volume (0-7)
    
    ; Convert volume level to actual volume
    tax
    lda volume_table,x              ; Look up actual volume
    sta note_volume_actual
    
    ; Send note to SPC700
    jsr SendNoteToChannel
    
    ; Update pattern pointer
    iny
    iny                             ; Skip 2 bytes
    sty temp_offset
    ldx current_channel
    lda temp_offset
    sta.w !audio_pattern_buffer,x  ; Update pointer
    
    rts
    
.play_rest:
    ; Rest: Don't trigger note, just advance
    iny
    iny
    sty temp_offset
    ldx current_channel
    lda temp_offset
    sta.w !audio_pattern_buffer,x
    rts

; Volume conversion table
volume_table:
    .db $20, $30, $40, $50, $60, $70, $7f, $7f  ; pp, p, mp, mf, f, ff, fff
```

### Example 7: Audio RAM Management

```assembly
; Load instrument samples for current area
LoadAreaSamples:
    ; Get area ID
    lda current_area_id
    asl a                          ; × 2 (word index)
    tax
    
    ; Load sample bank info
    lda sample_bank_table,x        ; Low byte
    sta sample_bank_addr
    inx
    lda sample_bank_table,x        ; High byte
    sta sample_bank_addr+1
    
    ; Set SPC700 destination ($4000)
    lda #$00
    sta.w !audio_ram_addr_start    ; Low byte
    lda #$40
    sta.w !audio_ram_addr_start+1  ; High byte
    
    ; Get sample bank size
    lda sample_bank_sizes,x
    sta transfer_size
    
    ; Upload samples
    jsr UploadDataToSPC
    
    ; Update sample directory in SPC RAM
    jsr UpdateSampleDirectory
    
    rts

; Sample bank table (ROM addresses)
sample_bank_table:
    .dw samples_overworld          ; Area 0
    .dw samples_forest             ; Area 1
    .dw samples_cave               ; Area 2
    .dw samples_town               ; Area 3
    .dw samples_dungeon            ; Area 4
    .dw samples_boss               ; Area 5
    ; ... more areas

; Sample bank sizes
sample_bank_sizes:
    .dw $2000                      ; Overworld: 8 KB
    .dw $1800                      ; Forest: 6 KB
    .dw $1000                      ; Cave: 4 KB
    .dw $1000                      ; Town: 4 KB
    .dw $2800                      ; Dungeon: 10 KB
    .dw $3000                      ; Boss: 12 KB
    ; ... more sizes
```

---

## Document Info

**Version:** 1.0  
**Last Updated:** December 2024  
**Audio Channels:** 8 (SPC700)  
**Memory Usage:** 64 KB SPC700 RAM  
**Communication Ports:** 4 bidirectional

**See Also:**
- `MEMORY_MAP.md` - Audio memory variables ($0200-$0688)
- `LABEL_USAGE_GUIDE.md` - Audio label usage examples
- SNES Development Manual - SPC700 architecture
- SPC700 Reference - Instruction set and DSP
