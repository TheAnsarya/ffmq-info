# Mesen Emulator Integration Research

**Purpose:** Investigate Mesen-S emulator API for live VRAM inspection and debugging  
**Target Use Case:** Real-time graphics verification during ROM hacking  
**Last Updated:** November 17, 2025

---

## Mesen-S Overview

**Mesen-S** is a high-accuracy SNES emulator with extensive debugging capabilities.

**Official Repository:** https://github.com/SourMesen/Mesen-S  
**Documentation:** https://www.mesen.ca/docs/  
**License:** GPLv3

**Key Features for ROM Hacking:**
- Comprehensive debugger with breakpoints
- Real-time VRAM viewer
- Tile and sprite viewers
- Memory viewer and hex editor
- Trace logger
- Event viewer (PPU, APU, CPU events)
- Script debugging support (Lua)

---

## API and Integration Capabilities

### 1. Lua Scripting API

Mesen-S supports **Lua scripting** for custom debugging and automation.

**Capabilities:**
- Read/write memory during emulation
- Set breakpoints programmatically
- Hook into CPU/PPU/APU events
- Capture screenshots and VRAM dumps
- Automate testing scenarios

**Lua API Documentation:** https://www.mesen.ca/docs/debugging/luaapi.html

**Example Lua Script - VRAM Monitor:**
```lua
-- Monitor VRAM writes and log graphics uploads
function onVramWrite(address, value)
    -- Address: VRAM address being written
    -- Value: Data being written
    
    if address >= 0x0000 and address <= 0x1FFF then
        emu.log("Character sprite VRAM write: $" .. string.format("%04X", address) .. " = $" .. string.format("%02X", value))
        
        -- Optionally export VRAM region
        if address == 0x01FF then  -- End of character sprite region
            emu.debug().exportVram("char_sprites_" .. emu.frameCount() .. ".png", 0x0000, 0x2000)
        end
    end
end

-- Register callback
emu.addMemoryCallback(onVramWrite, emu.memCallbackType.cpuWrite, 0x2100, 0x213F)
```

**Example Lua Script - Automated Screenshot Capture:**
```lua
-- Capture screenshots at specific game events

local captureCounter = 0

function captureGameplayScreenshot(eventName)
    captureCounter = captureCounter + 1
    local filename = string.format("screenshots/%s_%04d.png", eventName, captureCounter)
    emu.takeScreenshot(filename)
    emu.log("Screenshot saved: " .. filename)
end

-- Monitor specific memory addresses for events
function checkGameEvents()
    local mapId = emu.read(0x7E0048, emu.memType.snesMemory)  -- Current map ID
    local battleState = emu.read(0x7E0090, emu.memType.snesMemory)  -- Battle state
    
    -- Capture when entering new map
    if mapId ~= lastMapId then
        captureGameplayScreenshot("map_" .. mapId)
        lastMapId = mapId
    end
    
    -- Capture during battle transitions
    if battleState == 0x01 and lastBattleState == 0x00 then
        captureGameplayScreenshot("battle_start")
    end
    lastBattleState = battleState
end

-- Run every frame
emu.addEventCallback(checkGameEvents, emu.eventType.endFrame)
```

---

### 2. Command-Line Interface

Mesen-S can be controlled via command-line for automated workflows.

**Command-Line Options:**
```bash
# Launch with ROM
Mesen-S.exe ffmq.smc

# Launch with Lua script
Mesen-S.exe ffmq.smc --lua-script vram_monitor.lua

# Record gameplay to video
Mesen-S.exe ffmq.smc --record output.avi

# Run until specific frame and exit
Mesen-S.exe ffmq.smc --test-runner --frames 3600

# Load save state and capture screenshot
Mesen-S.exe ffmq.smc --load-state ffmq_foresta.mss --screenshot output.png
```

---

### 3. Debug API (Programmatic Control)

Mesen-S exposes a **debug API** through its Lua interface.

**Available Functions:**

**Memory Access:**
```lua
-- Read memory
value = emu.read(address, memType)
value16 = emu.readWord(address, memType)

-- Write memory
emu.write(address, value, memType)
emu.writeWord(address, value, memType)

-- Memory types:
-- emu.memType.cpu (CPU bus, $00-$FFFFFF)
-- emu.memType.snesMemory (SNES memory map)
-- emu.memType.prgRom (PRG ROM)
-- emu.memType.workRam (WRAM $7E0000-$7FFFFF)
-- emu.memType.saveRam (SRAM)
-- emu.memType.videoRam (VRAM)
-- emu.memType.cgRam (Palette/CGRAM)
-- emu.memType.oamRam (OAM sprite memory)
-- emu.memType.spriteRam (SPR-RAM)
```

**Breakpoints:**
```lua
-- Add execution breakpoint
emu.addBreakpoint(address, type)

-- Breakpoint types:
-- emu.breakpointType.exec (execute)
-- emu.breakpointType.read (read)
-- emu.breakpointType.write (write)

-- Example: Break when writing to VRAM
emu.addBreakpoint(0x2118, emu.breakpointType.write)
```

**VRAM Export:**
```lua
-- Export VRAM to PNG
emu.debug().exportVram(filename, startAddr, length)

-- Example: Export character sprites
emu.debug().exportVram("char_sprites.png", 0x0000, 0x2000)

-- Export with palette
emu.debug().exportVram("enemy_sprites.png", 0x2000, 0x2000, paletteIndex)
```

**Screenshot Capture:**
```lua
-- Take screenshot of current frame
emu.takeScreenshot(filename)

-- Example with frame number
local frame = emu.frameCount()
emu.takeScreenshot(string.format("frame_%06d.png", frame))
```

**State Management:**
```lua
-- Save state
emu.saveState(filename)

-- Load state
emu.loadState(filename)

-- Get state slot
emu.saveStateSlot(slot)  -- slot: 1-10
emu.loadStateSlot(slot)
```

---

### 4. Real-Time VRAM Monitoring

**Approach:** Use Lua callbacks to monitor VRAM changes in real-time.

**Implementation:**
```lua
-- vram_realtime_monitor.lua

local vramSnapshot = {}
local vramDirtyRegions = {}

function initializeVramSnapshot()
    -- Read entire VRAM (64KB)
    for addr = 0x0000, 0xFFFF do
        vramSnapshot[addr] = emu.read(addr, emu.memType.videoRam)
    end
    emu.log("VRAM snapshot initialized")
end

function onVramWrite(address, value, type)
    -- Mark region as dirty
    local region = math.floor(address / 0x0400)  -- 1KB regions
    vramDirtyRegions[region] = true
    
    -- Log significant changes
    local oldValue = vramSnapshot[address]
    if oldValue ~= value then
        emu.log(string.format("VRAM[$%04X]: $%02X -> $%02X", address, oldValue, value))
        vramSnapshot[address] = value
    end
end

function exportDirtyRegions()
    for region, dirty in pairs(vramDirtyRegions) do
        if dirty then
            local startAddr = region * 0x0400
            local filename = string.format("vram_region_%02X_frame_%06d.png", 
                region, emu.frameCount())
            emu.debug().exportVram(filename, startAddr, 0x0400)
            emu.log("Exported VRAM region: " .. filename)
            vramDirtyRegions[region] = false
        end
    end
end

-- Initialize on start
emu.addEventCallback(initializeVramSnapshot, emu.eventType.reset)

-- Monitor VRAM writes
emu.addMemoryCallback(onVramWrite, emu.memCallbackType.write, 0x0000, 0xFFFF, emu.memType.videoRam)

-- Export dirty regions every 60 frames (1 second at 60 FPS)
local frameCounter = 0
emu.addEventCallback(function()
    frameCounter = frameCounter + 1
    if frameCounter >= 60 then
        exportDirtyRegions()
        frameCounter = 0
    end
end, emu.eventType.endFrame)
```

---

### 5. Graphics Extraction Automation

**Automated Character Sprite Extraction:**
```lua
-- extract_character_sprites.lua

-- Character sprite VRAM locations
local characterSprites = {
    {name = "benjamin_walk_north", vram = 0x0000, size = 0x0040, frames = 4},
    {name = "benjamin_walk_south", vram = 0x0100, size = 0x0040, frames = 4},
    {name = "benjamin_walk_east", vram = 0x0200, size = 0x0040, frames = 4},
    {name = "benjamin_walk_west", vram = 0x0300, size = 0x0040, frames = 4},
    {name = "benjamin_attack", vram = 0x0400, size = 0x0080, frames = 8},
}

function extractCharacterSprites()
    emu.log("Extracting character sprites...")
    
    for _, sprite in ipairs(characterSprites) do
        for frame = 1, sprite.frames do
            local vramAddr = sprite.vram + ((frame - 1) * (sprite.size / sprite.frames))
            local filename = string.format("assets/screenshots/vram_dumps/character_sprites/%s_frame_%02d_vram_%04X-%04X.png",
                sprite.name, frame, vramAddr, vramAddr + (sprite.size / sprite.frames) - 1)
            
            emu.debug().exportVram(filename, vramAddr, sprite.size / sprite.frames, 0)  -- Palette 0
            emu.log("Extracted: " .. filename)
        end
    end
    
    emu.log("Character sprite extraction complete!")
end

-- Extract sprites when pressing F9
emu.addEventCallback(function(key)
    if key == 0x78 then  -- F9 key
        extractCharacterSprites()
    end
end, emu.eventType.inputPolled)
```

---

### 6. Code Verification During Emulation

**Approach:** Use breakpoints to verify code execution paths.

**Implementation:**
```lua
-- verify_bank02_functions.lua

-- Functions to verify in Bank $02
local functionsToVerify = {
    {name = "Bank02_Init", address = 0x028000},
    {name = "validate_entity_system", address = 0x02806B},
    {name = "Entity_InitWithGraphics", address = 0x0293D7},
    {name = "Entity_ProcessMainLoop", address = 0x0293E7},
    {name = "Graphics_CoordScale", address = 0x0290E3},
    {name = "Math_Negate16Bit", address = 0x02909C},
}

local verificationLog = {}

function onFunctionExecute(address)
    -- Find function name
    for _, func in ipairs(functionsToVerify) do
        if func.address == address then
            local frame = emu.frameCount()
            local pc = emu.getState().cpu.pc
            local a = emu.getState().cpu.a
            local x = emu.getState().cpu.x
            local y = emu.getState().cpu.y
            
            local logEntry = string.format("[Frame %06d] %s called at PC=$%06X (A=$%04X X=$%04X Y=$%04X)",
                frame, func.name, pc, a, x, y)
            
            emu.log(logEntry)
            table.insert(verificationLog, logEntry)
            break
        end
    end
end

-- Add breakpoints for all functions
for _, func in ipairs(functionsToVerify) do
    emu.addBreakpoint(func.address, emu.breakpointType.exec)
    emu.log("Added breakpoint: " .. func.name .. " at $" .. string.format("%06X", func.address))
end

-- Export log on F10
emu.addEventCallback(function(key)
    if key == 0x79 then  -- F10 key
        local file = io.open("verification_log.txt", "w")
        for _, entry in ipairs(verificationLog) do
            file:write(entry .. "\n")
        end
        file:close()
        emu.log("Verification log exported to verification_log.txt")
    end
end, emu.eventType.inputPolled)
```

---

## Integration Workflow

### Step 1: Setup Mesen-S with Lua Scripts

1. Download Mesen-S from https://github.com/SourMesen/Mesen-S/releases
2. Create `scripts/` directory in project root
3. Place Lua scripts in `scripts/` directory
4. Configure Mesen-S to auto-load scripts

**Auto-load Configuration:**
```
File: Mesen-S/LuaScripts/autoload.lua

-- Auto-load project scripts
dofile("C:/Users/me/source/repos/ffmq-info/scripts/vram_monitor.lua")
dofile("C:/Users/me/source/repos/ffmq-info/scripts/extract_sprites.lua")
dofile("C:/Users/me/source/repos/ffmq-info/scripts/verify_code.lua")
```

---

### Step 2: Automated Graphics Extraction

**PowerShell Wrapper Script:**
```powershell
# extract_all_graphics.ps1

param(
    [string]$RomPath = "roms/ffmq.smc",
    [string]$MesenPath = "C:/Program Files/Mesen-S/Mesen-S.exe",
    [string]$OutputDir = "assets/screenshots/vram_dumps/"
)

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputDir

# Launch Mesen with extraction script
& $MesenPath $RomPath --lua-script scripts/extract_sprites.lua --test-runner --frames 600

Write-Host "Graphics extraction complete! Check $OutputDir"
```

---

### Step 3: Real-Time VRAM Verification

**Usage:**
1. Launch Mesen-S with ROM
2. Load Lua script: `Tools → Lua Script Window → Load Script → vram_realtime_monitor.lua`
3. Play game normally
4. Script automatically exports VRAM changes every second
5. Compare exported images with expected graphics

**Verification Process:**
```powershell
# verify_extracted_graphics.ps1

# Compare extracted VRAM dumps with reference screenshots
$extracted = Get-ChildItem "assets/screenshots/vram_dumps/" -Recurse -Filter "*.png"
$reference = Get-ChildItem "assets/reference_screenshots/" -Recurse -Filter "*.png"

foreach ($extractedFile in $extracted) {
    $referenceName = $extractedFile.Name
    $referenceFile = $reference | Where-Object { $_.Name -eq $referenceName }
    
    if ($referenceFile) {
        # Use ImageMagick to compare
        $result = & magick compare -metric RMSE $extractedFile.FullName $referenceFile.FullName null: 2>&1
        
        if ($result -match "0 \(0\)") {
            Write-Host "✓ MATCH: $referenceName" -ForegroundColor Green
        } else {
            Write-Host "✗ DIFF: $referenceName - $result" -ForegroundColor Red
        }
    } else {
        Write-Host "? NO REFERENCE: $referenceName" -ForegroundColor Yellow
    }
}
```

---

## Limitations and Alternatives

### Mesen-S Limitations

**Limitation 1: No Direct Python API**
- Mesen-S only supports Lua scripting
- No native Python, C#, or JavaScript API
- **Workaround:** Use Lua to export data, then process with Python

**Limitation 2: Limited Remote Control**
- No network API for external control
- Cannot control emulator from separate process
- **Workaround:** Use command-line interface + file-based communication

**Limitation 3: Export Format Constraints**
- VRAM exports are PNG only
- No raw binary export option
- **Workaround:** Convert PNG back to raw data if needed

---

### Alternative: BSNES-Plus

BSNES-Plus offers different debugging capabilities:

**Advantages:**
- More detailed memory viewer
- Better trace logging
- Export raw binary data
- Command-line automation support

**Disadvantages:**
- No Lua scripting
- Less user-friendly interface
- Slower emulation

---

### Alternative: Custom Emulator Integration

**For maximum control, consider:**

1. **RetroArch + Custom Core:**
   - Use RetroArch with libretro API
   - Write custom frontend in Python/C++
   - Full programmatic control

2. **Headless Emulation:**
   - Use emulator core library (e.g., SNES9x core)
   - Integrate into custom testing framework
   - Automate all graphics extraction

---

## Recommended Approach

**For FFMQ ROM Hacking Project:**

**Phase 1: Manual Capture (Current)**
- Use Mesen-S GUI for manual VRAM captures
- Organize screenshots per directory structure
- Build reference library

**Phase 2: Lua Automation**
- Implement Lua scripts for automated extraction
- Run extraction scripts on save states at key points
- Verify extracted graphics programmatically

**Phase 3: CI/CD Integration**
- Integrate Mesen-S into build pipeline
- Automated testing: ROM → Emulate → Extract → Verify
- Detect graphics regressions automatically

---

## Next Steps

1. **Install Mesen-S:**
   ```powershell
   # Download latest release
   Invoke-WebRequest -Uri "https://github.com/SourMesen/Mesen-S/releases/latest/download/Mesen-S.zip" -OutFile "mesen-s.zip"
   Expand-Archive -Path "mesen-s.zip" -DestinationPath "C:/Program Files/Mesen-S"
   ```

2. **Create Initial Lua Scripts:**
   - `scripts/vram_monitor.lua` - Real-time VRAM monitoring
   - `scripts/extract_sprites.lua` - Automated sprite extraction
   - `scripts/verify_code.lua` - Code execution verification

3. **Test Integration:**
   - Load ROM in Mesen-S
   - Run Lua scripts
   - Verify exported files

4. **Document Workflow:**
   - Update README with Mesen-S instructions
   - Create tutorial for graphics extraction
   - Add verification guidelines

---

*For implementation help, see scripts/ directory and CONTRIBUTING.md*
