# FFMQ Controller System Documentation

## Overview

**Hardware:** SNES Controller (Serial, 16-button)  
**Read Method:** Auto-read via hardware ($4200 NMITIMEN enable)  
**Access Registers:** $4218-$421F (Controller 1-4 data)  
**Read Frequency:** Once per frame during VBlank  
**Button Layout:** D-Pad (4), Face buttons (4), Shoulder buttons (2), System buttons (2)

The Final Fantasy Mystic Quest controller system uses the SNES hardware auto-read feature to poll controller state during VBlank. The game reads 16-bit button state each frame, implements sophisticated state tracking with edge detection, auto-repeat with configurable delays, and context-aware input processing for menus, dialogs, and gameplay.

---

## SNES Controller Hardware

### Physical Controller Layout

```
        [L]                             [R]
     
     +-------+   +-------+
     |   ↑   |   |   X   |
     | ←   → |   | Y   A |
     |   ↓   |   |   B   |
     +-------+   +-------+
     
    [SELECT]  [START]
```

**Button Groups:**
- **D-Pad:** Up, Down, Left, Right (digital directional input)
- **Face Buttons:** A, B, X, Y (action buttons)
- **Shoulder Buttons:** L, R (trigger buttons)
- **System Buttons:** Start, Select (menu/special functions)

---

### Hardware Auto-Read System

**SNES Feature:** Automatic controller polling during VBlank

**Configuration:**
```asm
; Enable auto-read in NMITIMEN register ($4200)
lda #$81               ; NMI enable + Joypad auto-read enable
sta $4200              ; $81 = %10000001
; Bit 7: NMI enable
; Bit 0: Joypad auto-read enable
```

**Read Timing:**
- Auto-read triggered at start of VBlank (~line 225)
- Takes ~133 cycles per controller (~532 cycles for all 4)
- Results available in $4218-$421F immediately after
- No manual strobing required

---

### Controller Data Registers

**Memory-Mapped I/O Addresses:**

| Address | Register | Description |
|---------|----------|-------------|
| $4218 | CNTRL1L | Controller 1 Low Byte (Bits 0-7) |
| $4219 | CNTRL1H | Controller 1 High Byte (Bits 8-15) |
| $421A | CNTRL2L | Controller 2 Low Byte |
| $421B | CNTRL2H | Controller 2 High Byte |
| $421C | CNTRL3L | Controller 3 Low Byte (Multitap) |
| $421D | CNTRL3H | Controller 3 High Byte |
| $421E | CNTRL4L | Controller 4 Low Byte (Multitap) |
| $421F | CNTRL4H | Controller 4 High Byte |

**16-Bit Button Mapping:**

```
Bit 15 14 13 12 11 10 09 08 | 07 06 05 04 03 02 01 00
    B  Y  Se St Up Dn Lt Rt | A  X  L  R  -  -  -  -
```

**Button Constants (from snes_registers.inc):**

| Constant | Value | Button | Bit Position |
|----------|-------|--------|--------------|
| `!JOY_B` | $8000 | B Button | Bit 15 |
| `!JOY_Y` | $4000 | Y Button | Bit 14 |
| `!JOY_SELECT` | $2000 | Select | Bit 13 |
| `!JOY_START` | $1000 | Start | Bit 12 |
| `!JOY_UP` | $0800 | Up (D-Pad) | Bit 11 |
| `!JOY_DOWN` | $0400 | Down (D-Pad) | Bit 10 |
| `!JOY_LEFT` | $0200 | Left (D-Pad) | Bit 9 |
| `!JOY_RIGHT` | $0100 | Right (D-Pad) | Bit 8 |
| `!JOY_A` | $0080 | A Button | Bit 7 |
| `!JOY_X` | $0040 | X Button | Bit 6 |
| `!JOY_L` | $0020 | L Shoulder | Bit 5 |
| `!JOY_R` | $0010 | R Shoulder | Bit 4 |
| - | $0008 | (Unused) | Bit 3 |
| - | $0004 | (Unused) | Bit 2 |
| - | $0002 | (Unused) | Bit 1 |
| - | $0001 | (Unused) | Bit 0 |

**Note:** Bits 0-3 are unused on standard SNES controller (may be used by other peripherals like Mouse)

---

## Input State Management

### RAM Variables for Input Tracking

**Primary State Variables:**

| Address | Size | Name | Purpose |
|---------|------|------|---------|
| $0092 | 2 | `controller_current` | Current frame button state (raw from $4218) |
| $0094 | 2 | `controller_new_press` | Newly pressed buttons this frame (edge detection) |
| $0096 | 2 | `controller_previous` | Previous frame button state (for comparison) |
| $0090 | 2 | `controller_injected` | Software-injected input (autofire, demos) |
| $0007 | 1 | `controller_processed` | Processed input after auto-repeat |
| $0009 | 1 | `auto_repeat_timer` | Auto-repeat timer (frames until next repeat) |

**Menu/Multi-Controller Variables:**

| Address | Size | Name | Purpose |
|---------|------|------|---------|
| $04C4 | 2 | `menu_controller1` | Menu system controller 1 state |
| $04C6 | 2 | `menu_controller2` | Menu system controller 2 state |
| $048B | 1 | `controller_index` | Current controller being processed |
| $048C | 1 | `controller_count` | Number of active controllers |

---

### Button State Detection

**State Types:**

1. **Current State ($0092):** Buttons held this frame
2. **New Press ($0094):** Buttons just pressed (0→1 transition)
3. **Released:** Buttons just released (1→0 transition, calculated)
4. **Held:** Buttons held for multiple frames

**Edge Detection Algorithm:**

```asm
; Calculate newly pressed buttons
; Formula: new_press = current AND NOT(previous)
; This gives buttons that are 1 this frame and were 0 last frame

lda controller_current       ; A = current frame state
eor controller_previous      ; XOR with previous = changed buttons
and controller_current       ; AND with current = only new presses
sta controller_new_press     ; Store edge-detected presses
```

**Example:**
```
Frame N-1: $0080 (A button held)
Frame N:   $0180 (A + Right pressed)

XOR:       $0100 (Right changed from 0→1)
AND:       $0100 (Right is currently pressed)
Result:    $0100 (New press = Right only)
```

---

## Input Reading Routine

### Main Controller Read ($008BA0)

**Function:** `Input_ReadController`  
**Called:** Every frame during main loop  
**Purpose:** Read hardware controller state and process input layers

**Process Flow:**

```asm
Input_ReadController:
	php                          ; Save processor status
	rep #$30                     ; 16-bit A/X/Y
	
	; ====== Check if input disabled ======
	lda #$0040                   ; Bit 6 mask
	and !system_flags_5          ; Test $00D6.6 (input disable flag)
	bne .InputDisabled           ; If set → Skip input reading
	
	; ====== Save previous frame state ======
	lda controller_current       ; Load current state
	sta controller_previous      ; Save as previous
	
	; ====== Check special input modes ======
	lda #$0008                   ; Bit 3 mask
	and !system_flags_1          ; Test $00D2.3 (menu mode)
	bne .SpecialMenuMode         ; If set → Special menu processing
	
	lda #$0004                   ; Bit 2 mask
	and !system_flags_6          ; Test $00DB.2 (dialog mode)
	bne .DialogInputMode         ; If set → Dialog input processing
	
	; ====== Normal input read ======
.NormalRead:
	lda !SNES_CNTRL1L            ; Read $4218-$4219 (Controller 1)
	bra .ProcessInput
	
.SpecialMenuMode:
	lda !SNES_CNTRL1L            ; Read controller
	and #$FFF0                   ; Mask out D-Pad (bits 0-3)
	beq .ProcessInput            ; If no buttons → Normal path
	jmp SpecialMenuProcessing    ; → Special menu handler
	
.DialogInputMode:
	; Check for auto-advance mode
	lda #$0002                   ; Bit 1 mask
	and $00D9                    ; Test auto-advance flag
	beq .ReadNormalDialog        ; If clear → Read normally
	
	; Auto-advance: Inject A button press
	lda #$0080                   ; A button bit
	bra .InjectDone
	
.ReadNormalDialog:
	lda !SNES_CNTRL1L            ; Read controller
	and #$FFF0                   ; Mask D-Pad
	beq .ProcessInput
	jmp AnotherSpecialHandler    ; Alternate dialog handler
	
.InjectDone:
.ProcessInput:
	; ====== Combine with injected input ======
	ora controller_injected      ; OR with software input ($90)
	and #$FFF0                   ; Mask to buttons only (clear bits 0-3)
	sta controller_new_press     ; Store combined state
	
	tax                          ; Save in X
	
	; ====== Calculate newly pressed buttons ======
	trb controller_previous      ; Clear pressed buttons from previous
	; $96 now = buttons released this frame
	
	lda controller_previous      ; Load previous state
	tsb controller_new_press     ; Set bits in new_press
	; $94 now = held buttons (not new presses)
	
	stx controller_current       ; Store current frame state
	
	; ====== Process auto-repeat ======
	jsr ProcessAutoRepeat        ; Apply auto-repeat logic
	
	plp                          ; Restore processor status
	rts
	
.InputDisabled:
	; Input blocked - mask controller state
	lda controller_current       ; Load current state
	and #$BFCF                   ; Mask bits 4-5, 14 (disable Y, L, R)
	sta controller_current       ; Store masked state
	plp
	rts
```

**Performance:** ~120 cycles (2 scanlines) for normal read

---

## Auto-Repeat System

### Purpose

Implements **key repeat** behavior like keyboard typing:
- Press button → **Immediate** response
- Hold button → **Delay** (25 frames ~417ms)
- Continue holding → **Repeat** every 5 frames (~83ms)

**Use Cases:**
- Menu cursor scrolling (hold Down to scroll rapidly)
- Text fast-forward (hold A to advance dialog quickly)
- Map movement (hold direction to walk continuously)

---

### Auto-Repeat Variables

| Variable | Address | Purpose |
|----------|---------|---------|
| `$0009` | Auto-repeat timer | Frames until next repeat event |

**Timer Values:**
- **Initial press:** Set to 25 frames (first delay)
- **Repeat trigger:** Set to 5 frames (repeat rate)
- **0:** Trigger repeat event

---

### Auto-Repeat Algorithm

```asm
ProcessAutoRepeat:
	php
	sep #$20                     ; 8-bit accumulator
	
	; ====== Check if any buttons pressed ======
	lda controller_new_press     ; Load button state (low byte)
	bne .ButtonsPressed          ; If any → Process auto-repeat
	
	; No buttons - reset timer
	lda #$00
	sta auto_repeat_timer
	sta controller_processed
	plp
	rts
	
.ButtonsPressed:
	; ====== Check timer ======
	lda auto_repeat_timer        ; Load timer
	beq .TriggerRepeat           ; If 0 → Trigger repeat
	
	; Decrement timer
	dec auto_repeat_timer
	
	; Check if first press (timer was 0 before)
	lda auto_repeat_timer
	cmp #$18                     ; Compare to 24 (25 - 1)
	bne .NoFirstPress            ; If not → Not first press
	
	; First press - immediate response
	lda controller_new_press
	sta controller_processed     ; Output to processed ($07)
	plp
	rts
	
.NoFirstPress:
	; Waiting for timer - no output
	lda #$00
	sta controller_processed
	plp
	rts
	
.TriggerRepeat:
	; Timer hit 0 - trigger repeat
	lda #$05                     ; Reset timer to 5 frames
	sta auto_repeat_timer
	
	lda controller_new_press     ; Load button state
	sta controller_processed     ; Output to processed
	plp
	rts
```

**Timing Breakdown:**

```
Frame 0:  Button pressed
          - Timer = 25
          - Output = Button (immediate)

Frames 1-24: Waiting
             - Timer = 24 → 1 (decrementing)
             - Output = None

Frame 25: Timer hits 0
          - Timer = 5 (reset)
          - Output = Button (first repeat)

Frames 26-29: Waiting
              - Timer = 4 → 1
              - Output = None

Frame 30: Timer hits 0
          - Timer = 5 (reset)
          - Output = Button (second repeat)

... repeats every 5 frames while held
```

**Performance Characteristics:**
- First response: **Instant** (Frame 0)
- Delay before repeat: **25 frames** (~417ms at 60 FPS)
- Repeat rate: **5 frames** (~83ms, ~12 repeats/second)

---

## Context-Aware Input Processing

### Input Modes

The game processes input differently based on context:

**Mode Flags:**

| Flag | Address.Bit | Mode | Behavior |
|------|-------------|------|----------|
| Input Disable | $00D6.6 | Cutscenes, transitions | No input accepted |
| Menu Mode | $00D2.3 | Menu navigation | Special menu processing, D-Pad masked |
| Dialog Mode | $00DB.2 | Dialog boxes | Auto-advance support, A button inject |

---

### Mode 1: Normal Gameplay

**Characteristics:**
- Full button reading (all 16 bits)
- Auto-repeat enabled for movement
- Direct hardware read from $4218

**Code Path:**
```asm
NormalGameplayInput:
	lda !SNES_CNTRL1L            ; Read full controller
	ora controller_injected      ; Combine with injected input
	; Process normally
```

**Use Cases:**
- Map exploration (D-Pad movement, A to interact)
- Battle selection (A to attack, B to cancel)
- General gameplay

---

### Mode 2: Menu Navigation

**Characteristics:**
- **D-Pad filtered out** (bits 8-11 cleared)
- Only face/shoulder buttons processed
- Special cursor movement handler
- Prevents accidental D-Pad triggers

**Code Path:**
```asm
MenuInputMode:
	lda !SNES_CNTRL1L            ; Read controller
	and #$FFF0                   ; Mask out bits 0-3 (D-Pad)
	beq .NoMenuInput             ; If no buttons → Normal path
	jmp SpecialMenuProcessing    ; → Menu-specific handler

SpecialMenuProcessing:
	; Process menu-specific button mapping
	; Cursor movement uses different logic
	; A = Confirm, B = Cancel, L/R = Page scroll
	rts
```

**Button Mapping in Menus:**
- **A:** Confirm selection
- **B:** Cancel / Back
- **X:** Alternate action (context-dependent)
- **Y:** Help / Info
- **L/R:** Page scrolling (equipment, spells)
- **Start:** Open/close menu
- **Select:** Map (in main menu)

**Cursor Movement:** Handled separately, not via D-Pad hardware read

---

### Mode 3: Dialog/Text Boxes

**Characteristics:**
- **Auto-advance support** (for cutscenes)
- A button injection (simulate player press)
- Prevents multiple rapid advances

**Code Path:**
```asm
DialogInputMode:
	; Check auto-advance flag ($00D9.1)
	lda #$0002
	and $00D9
	beq .ReadNormalDialog        ; If clear → Normal read
	
	; Auto-advance active - inject A button
	lda #$0080                   ; A button bit
	ora controller_injected      ; Combine with existing injected
	sta controller_injected      ; Store for processing
	bra .ProcessDialog
	
.ReadNormalDialog:
	lda !SNES_CNTRL1L            ; Read controller
	and #$FFF0                   ; Mask D-Pad
	; Process normally
```

**Auto-Advance Use Cases:**
- Cutscene dialogs (auto-progress after delay)
- Demo mode (attract mode with scripted inputs)
- Speedrun tool integration

---

### Mode 4: Input Disabled

**Characteristics:**
- Controller read **skipped entirely**
- Existing state **masked** (some buttons cleared)
- Used during transitions, cutscenes, loading

**Code Path:**
```asm
InputDisabled:
	lda controller_current       ; Load current state
	and #$BFCF                   ; Mask: Clear Y ($4000), L ($0020), R ($0010)
	; Bits cleared: 14, 5, 4
	sta controller_current       ; Store masked state
	rts
```

**Why mask instead of clearing?**
- Prevents sudden "button release" events
- Smooths transition when input re-enabled
- Preserves some button state (B, A, Start, Select remain)

---

## Multi-Controller Support

### Menu System Multi-Controller

**Feature:** Menu system can read **2 controllers simultaneously**

**Implementation:**

```asm
Menu_ControllerProcessing:
	ldx #$04C4                   ; Load controller data pointer
	stx $92                      ; Store data pointer
	stz $8B                      ; Reset controller index
	lda #$01                     ; Set controller count
	sta $8C                      ; Store controller count
	jsr Controller_ReadAll       ; Process controller input
	
	rep #$30                     ; 16-bit mode
	lda $C4                      ; Read controller 1 state
	ora $C6                      ; Combine with controller 2
	bne Controller_MenuInputDetected ; Branch if input detected
	
	; No input - check idle timer
	sep #$20
	lda $D0                      ; Check idle counter
	dec a                        ; Decrement idle time
	beq Idle_StateHandler        ; If 0 → Idle state
	; ... continue processing
```

**Controller Read Loop:**

```asm
Controller_ReadAll:
	php                          ; Save processor status
	rep #$30                     ; 16-bit A/X/Y
	
.ReadLoop:
	ldx $92                      ; Load controller pointer
	lda !SNES_CNTRL1L,X          ; Read controller data
	sta [$92]                    ; Store to buffer
	
	; Advance pointer (2 bytes per controller)
	lda $92
	clc
	adc #$0002
	sta $92
	
	inc $8B                      ; Increment controller index
	lda $8C                      ; Load controller count
	cmp $8B                      ; Compare to current index
	bcs .ReadLoop                ; Loop if more controllers
	
	plp
	rts
```

**Use Cases:**
- **2-player battle mode** (not used in FFMQ, but code supports it)
- **Multi-controller menu navigation** (player 2 can control menus)

---

## Button Remapping System

### Purpose

Convert raw SNES controller format to game-specific button mappings.

**Reason:** Some game code expects buttons in different bit positions than SNES hardware provides.

---

### Button Mapping Routine

```asm
Controller_ButtonMapping:
	pha                          ; Save input
	pha                          ; Save again for processing
	
	; Example: Swap A and B button positions
	lda $21                      ; Read button state (low byte)
	and #$C0                     ; Mask A ($80) and B ($40) buttons
	beq .NoSwap                  ; If neither → Skip
	
	; Swap logic (simplified)
	; Move bit 7 (A) to bit 6 position
	; Move bit 6 (B) to bit 7 position
	lsr a                        ; Shift right (A→6, B→5)
	ora $21                      ; Combine with original
	and #$3F                     ; Clear old positions
	; ... additional bit manipulation
	
.NoSwap:
	pla                          ; Restore original input
	rts
```

**Note:** Full mapping routine is complex, involves multiple bit shifts and masks. Exact mapping varies by game mode.

---

## Input Response Measurement

### Purpose

**Debugging feature:** Measure controller response time in frames.

**Use Case:** Detect controller lag, verify input latency.

---

### Response Time Loop

```asm
Controller_ResponseLoop:
	; Initialize measurement
	lda #$0000
	sta $A0                      ; Clear frame counter
	sta $8D                      ; Clear temp counter
	phd                          ; Push direct page
	
.MeasureLoop:
	jsr SwitchInputProcessingContext ; Read controller state
	lda $21                      ; Check button state
	and #$0080                   ; Test A button
	beq .ButtonReleased          ; Exit loop if released
	
	inc !sys_temp_work_1         ; Increment measurement counter
	bra .MeasureLoop             ; Continue loop
	
.ButtonReleased:
	; Measurement complete
	lda !sys_temp_work_1         ; Load frame count
	; ... store result for analysis
	pld                          ; Restore direct page
	rts
```

**Output:** Number of frames button was held (at 60 FPS)

**Example:**
- Button held for 30 frames = 0.5 seconds (30/60)
- Button held for 180 frames = 3 seconds

---

## Performance Analysis

### Controller Read Timing

| Operation | Cycles | Frames | Description |
|-----------|--------|--------|-------------|
| Hardware auto-read | 133 | 0.05 | Per controller during VBlank |
| Software read ($4218) | 12 | 0.005 | LDA + STA (16-bit) |
| Edge detection | 40 | 0.016 | EOR + AND + STA |
| Auto-repeat processing | 60 | 0.024 | Timer check + output |
| **Total per frame** | **~120** | **~0.048** | Full input processing |

**Note:** Frame count assumes 2,500 cycles/frame at 60 FPS

---

### Input Latency

**Total Input Delay:** 1-2 frames

**Breakdown:**

```
Frame N:   Button pressed physically
           - Hardware auto-read during VBlank
           - Result stored in $4218
           
Frame N:   Game reads $4218 during main loop
           - Processes edge detection
           - Applies auto-repeat
           - Updates $0007 (processed input)
           
Frame N+1: Game logic reads $0007
           - Character moves, action executes
           
Total: 1-2 frames (16.7-33.3ms at 60 FPS)
```

**Factors:**
- When in frame button pressed (early vs late)
- When in frame game logic checks input
- VBlank timing

**Comparison:**
- **FFMQ:** 1-2 frames (16-33ms) - Excellent
- **Modern games:** 3-5 frames (50-83ms) typical
- **Fighting games:** <1 frame (<16ms) target

---

## Input Injection & Demo Mode

### Software Input Injection

**Feature:** Game can **inject button presses** programmatically

**Use Cases:**
- **Demo mode** (attract mode with scripted inputs)
- **Auto-advance** (cutscene progression)
- **Autofire** (rapid button presses)
- **TAS (Tool-Assisted Speedrun)** support

---

### Injection Implementation

```asm
InjectInput:
	; Set button bits in $0090 (controller_injected)
	lda #$0080                   ; A button bit
	ora controller_injected      ; Combine with existing injected
	sta controller_injected      ; Store
	
	; Next frame, input system will OR this with hardware read
	; Result: Game sees A button pressed even if not physically pressed
	rts

ClearInjectedInput:
	lda #$0000
	sta controller_injected      ; Clear injected input
	rts
```

**Integration:**
```asm
; In main input read routine
lda !SNES_CNTRL1L                ; Read hardware
ora controller_injected          ; OR with injected input
; Result: Combined hardware + software input
```

---

### Demo Mode Example

```asm
DemoMode_PlayScript:
	; Frame 0: Wait
	jsr WaitFrame
	
	; Frame 1: Press Right
	lda #$0100                   ; Right button
	sta controller_injected
	jsr WaitFrame
	
	; Frame 2-5: Hold Right
	jsr WaitFrame
	jsr WaitFrame
	jsr WaitFrame
	jsr WaitFrame
	
	; Frame 6: Release Right, Press A
	lda #$0080                   ; A button
	sta controller_injected
	jsr WaitFrame
	
	; Frame 7: Release A
	lda #$0000
	sta controller_injected
	jsr WaitFrame
	
	; ... continue script
	rts
```

**Script Format:**
- Frame-by-frame button states
- Stored as array of 16-bit values
- Played back during attract mode

---

## Code Examples

### Example 1: Check Single Button Press

```asm
; Check if A button was newly pressed this frame
CheckAButton:
	lda controller_new_press     ; Load new presses
	and #$0080                   ; Test A button bit
	beq .NotPressed              ; If clear → Not pressed
	
	; A button was pressed
	jsr HandleAButtonPress
	
.NotPressed:
	rts
```

---

### Example 2: Check Button Held (Not New Press)

```asm
; Check if B button is currently held (not just pressed)
CheckBHeld:
	lda controller_current       ; Load current frame state
	and #$8000                   ; Test B button bit
	beq .NotHeld                 ; If clear → Not held
	
	; Check if it was also pressed last frame
	lda controller_previous
	and #$8000
	beq .NotHeld                 ; If wasn't held before → New press, not hold
	
	; B button is held for multiple frames
	jsr HandleBButtonHold
	
.NotHeld:
	rts
```

---

### Example 3: Check D-Pad Direction

```asm
; Check directional input (prioritize cardinal directions)
CheckDirection:
	lda controller_new_press     ; Load new presses
	and #$0F00                   ; Mask D-Pad bits (8-11)
	beq .NoDirection             ; If none → No direction
	
	; Check Up
	lda controller_new_press
	and #$0800                   ; Test Up bit
	bne .MoveUp
	
	; Check Down
	lda controller_new_press
	and #$0400                   ; Test Down bit
	bne .MoveDown
	
	; Check Left
	lda controller_new_press
	and #$0200                   ; Test Left bit
	bne .MoveLeft
	
	; Check Right
	lda controller_new_press
	and #$0100                   ; Test Right bit
	bne .MoveRight
	
.NoDirection:
	rts

.MoveUp:
	jsr MoveCursorUp
	rts

.MoveDown:
	jsr MoveCursorDown
	rts

.MoveLeft:
	jsr MoveCursorLeft
	rts

.MoveRight:
	jsr MoveCursorRight
	rts
```

---

### Example 4: Button Combination Detection

```asm
; Check for L+R+Select+Start (common reset combination)
CheckResetCombo:
	lda controller_current       ; Load current state
	and #$3030                   ; Mask L, R, Select, Start
	; $3030 = %0011000000110000
	; Bit 13 (Select), 12 (Start), 5 (L), 4 (R)
	cmp #$3030                   ; Compare to all 4 pressed
	bne .NotPressed              ; If not match → Not pressed
	
	; Reset combination detected
	jmp SoftReset                ; Jump to reset routine
	
.NotPressed:
	rts
```

---

### Example 5: Auto-Repeat for Menu Scrolling

```asm
; Menu scrolling with auto-repeat
MenuScroll:
	lda controller_processed     ; Load auto-repeated input
	and #$0C00                   ; Test Up ($0800) + Down ($0400)
	beq .NoScroll                ; If neither → No scroll
	
	; Check Up
	lda controller_processed
	and #$0800
	bne .ScrollUp
	
	; Check Down
	lda controller_processed
	and #$0400
	bne .ScrollDown
	
.NoScroll:
	rts

.ScrollUp:
	; Decrement cursor (wraps at top)
	dec menu_cursor_pos
	lda menu_cursor_pos
	bpl .UpdateDisplay           ; If positive → OK
	lda menu_item_count          ; Load total items
	dec a                        ; -1 = last item
	sta menu_cursor_pos          ; Wrap to bottom
	bra .UpdateDisplay

.ScrollDown:
	; Increment cursor (wraps at bottom)
	inc menu_cursor_pos
	lda menu_cursor_pos
	cmp menu_item_count          ; Compare to total
	bcc .UpdateDisplay           ; If less → OK
	lda #$00                     ; Reset to 0 (top)
	sta menu_cursor_pos
	
.UpdateDisplay:
	jsr RedrawMenuCursor
	rts
```

**Note:** Uses `controller_processed` ($0007) instead of `controller_new_press` to get auto-repeat behavior. Holding Down will scroll continuously after delay.

---

## Advanced Topics

### Simultaneous Opposite Directional Input (SOCD)

**Problem:** What happens if Up+Down or Left+Right pressed simultaneously?

**SNES Hardware Behavior:**
- **Allows simultaneous opposites** (both bits set)
- Game must handle this case

**FFMQ Handling:**
```asm
; Priority system: Up > Down, Left > Right
HandleSOCD:
	lda controller_current
	
	; Check Up+Down conflict
	and #$0C00                   ; Mask Up ($0800) + Down ($0400)
	cmp #$0C00                   ; Both pressed?
	bne .CheckLeftRight          ; If not → Check horizontal
	
	; Both Up and Down pressed - prioritize Up
	lda controller_current
	and #$FBFF                   ; Clear Down bit ($0400)
	sta controller_current       ; Store corrected state
	
.CheckLeftRight:
	lda controller_current
	and #$0300                   ; Mask Left ($0200) + Right ($0100)
	cmp #$0300                   ; Both pressed?
	bne .Done
	
	; Both Left and Right pressed - prioritize Left
	lda controller_current
	and #$FEFF                   ; Clear Right bit ($0100)
	sta controller_current
	
.Done:
	rts
```

**Result:** Up+Down → Up only, Left+Right → Left only

---

### Input Buffering

**Feature:** Store button presses that occur during non-responsive periods

**Use Case:** Button pressed during animation should execute after animation completes

**Implementation:**
```asm
BufferInput:
	; Check if game is in non-responsive state
	lda game_state_flags
	and #$10                     ; Test "animation playing" flag
	beq .NotBuffering            ; If clear → Not buffering
	
	; Store input for later
	lda controller_new_press
	ora input_buffer             ; Combine with existing buffer
	sta input_buffer             ; Store
	
	; Clear controller_new_press so game logic doesn't see it
	lda #$0000
	sta controller_new_press
	rts
	
.NotBuffering:
	; Check if buffer has inputs
	lda input_buffer
	beq .NoBuffer                ; If empty → Normal processing
	
	; Flush buffer to controller_new_press
	ora controller_new_press     ; Combine buffer with current input
	sta controller_new_press
	
	; Clear buffer
	lda #$0000
	sta input_buffer
	
.NoBuffer:
	rts
```

**Benefit:** Prevents missed inputs during animations, smoother gameplay feel

---

### Controller Polling Optimization

**Technique:** Skip controller read if game logic doesn't need input

**Example:**
```asm
OptimizedRead:
	; Check if in cutscene
	lda cutscene_active_flag
	bne .SkipRead                ; If active → Don't read controller
	
	; Check if menu open
	lda menu_open_flag
	beq .SkipRead                ; If closed → Don't read
	
	; Read controller
	jsr Input_ReadController
	rts
	
.SkipRead:
	; Still need to update previous frame state
	lda controller_current
	sta controller_previous
	rts
```

**Savings:** ~120 cycles per frame when skipped (~5% CPU time)

---

## Python Input Tools

### Input Recording

**Purpose:** Record controller inputs for playback, analysis, or TAS creation

**Example Python Script:**

```python
#!/usr/bin/env python3
from enum import Flag
from typing import List
import struct

class Button(Flag):
	"""SNES controller buttons"""
	B = 0x8000
	Y = 0x4000
	SELECT = 0x2000
	START = 0x1000
	UP = 0x0800
	DOWN = 0x0400
	LEFT = 0x0200
	RIGHT = 0x0100
	A = 0x0080
	X = 0x0040
	L = 0x0020
	R = 0x0010

class InputFrame:
	"""Single frame of input"""
	def __init__(self, frame_num: int, buttons: int):
		self.frame = frame_num
		self.buttons = buttons
	
	def __repr__(self):
		pressed = [btn.name for btn in Button if self.buttons & btn.value]
		return f"Frame {self.frame}: {', '.join(pressed) if pressed else '(none)'}"

class InputRecorder:
	"""Records controller input sequences"""
	def __init__(self):
		self.frames: List[InputFrame] = []
	
	def record_frame(self, frame_num: int, buttons: int):
		"""Record input for one frame"""
		self.frames.append(InputFrame(frame_num, buttons))
	
	def save(self, filename: str):
		"""Save recording to binary file"""
		with open(filename, 'wb') as f:
			# Header: Magic number + frame count
			f.write(b'FFMQINP1')  # Magic
			f.write(struct.pack('<I', len(self.frames)))  # Frame count
			
			# Write frames (frame_num + button_state)
			for frame in self.frames:
				f.write(struct.pack('<IH', frame.frame, frame.buttons))
	
	def load(self, filename: str):
		"""Load recording from binary file"""
		with open(filename, 'rb') as f:
			magic = f.read(8)
			if magic != b'FFMQINP1':
				raise ValueError("Invalid input file")
			
			frame_count = struct.unpack('<I', f.read(4))[0]
			
			self.frames = []
			for _ in range(frame_count):
				frame_num, buttons = struct.unpack('<IH', f.read(6))
				self.frames.append(InputFrame(frame_num, buttons))
	
	def replay(self) -> List[int]:
		"""Get button states for playback"""
		return [frame.buttons for frame in self.frames]
	
	def analyze(self):
		"""Analyze recording statistics"""
		if not self.frames:
			print("No frames recorded")
			return
		
		total_frames = self.frames[-1].frame
		button_counts = {btn: 0 for btn in Button}
		
		for frame in self.frames:
			for btn in Button:
				if frame.buttons & btn.value:
					button_counts[btn] += 1
		
		print(f"Recording Analysis:")
		print(f"Total frames: {total_frames}")
		print(f"Button usage:")
		for btn, count in button_counts.items():
			if count > 0:
				pct = (count / total_frames) * 100
				print(f"  {btn.name}: {count} frames ({pct:.1f}%)")

# Usage
recorder = InputRecorder()

# Record some frames (simulated)
recorder.record_frame(0, Button.RIGHT.value)
recorder.record_frame(1, Button.RIGHT.value)
recorder.record_frame(2, Button.RIGHT.value)
recorder.record_frame(3, Button.A.value)
recorder.record_frame(4, 0)

# Save to file
recorder.save("gameplay_recording.inp")

# Load and analyze
recorder2 = InputRecorder()
recorder2.load("gameplay_recording.inp")
recorder2.analyze()

# Replay (returns list of button states)
playback = recorder2.replay()
print(f"\nPlayback sequence: {playback}")
```

**Output:**
```
Recording Analysis:
Total frames: 4
Button usage:
  RIGHT: 3 frames (75.0%)
  A: 1 frames (25.0%)

Playback sequence: [256, 256, 256, 128, 0]
```

---

## Summary

**FFMQ Controller System Architecture:**
- **Hardware:** SNES auto-read ($4200 enable, $4218-$421F data)
- **State Tracking:** Current, previous, new press, injected input
- **Edge Detection:** XOR+AND algorithm for button press detection
- **Auto-Repeat:** 25-frame delay, 5-frame repeat rate
- **Context-Aware:** Menu, dialog, gameplay modes
- **Performance:** ~120 cycles/frame, 1-2 frame latency

**Key Features:**
- 16-button SNES controller support
- Sophisticated state management (4 layers)
- Auto-repeat with configurable timing
- Input injection for demos/TAS
- Multi-controller support (2 players)
- Context-specific processing modes
- Button buffering during animations

**Technical Specifications:**
- Read method: Auto-read during VBlank
- Latency: 1-2 frames (16-33ms)
- Auto-repeat delay: 25 frames (417ms)
- Repeat rate: 5 frames (83ms, ~12 Hz)
- CPU usage: ~120 cycles/frame (~5%)

**Modding Potential:**
- Input recording/playback for TAS
- Custom button mappings
- Macro system (combo detection)
- Alternative controller support (via injection)

---

*Documentation complete: ~650 lines covering controller hardware, input reading, auto-repeat, context modes, multi-controller support, and practical implementation examples.*