# Modern SNES Development Toolchain (2025)

## Current Status: ✅ asar 1.91 Installed

## Toolchain Comparison

### 1. **asar** (CURRENT - ✅ RECOMMENDED)
- **Version**: 1.91 (actively maintained)
- **Speed**: ⚡ FASTEST (designed for ROM hacking)
- **Pros**:
  - Lightning-fast assembly (critical for iterative development)
  - Excellent for patching existing ROMs
  - Simple syntax, easy to learn
  - Active community (SMW hacking scene)
  - Great macro support
  - Patch distribution (`.asm` patches)
  
- **Cons**:
  - Less debugging info than ca65
  - ROM hacking focused (not from-scratch development)
  
- **Best For**: ROM modifications, fast iteration, FFMQ disassembly rebuild

### 2. **ca65/ld65** (WLA-DX alternative)
- **Part of**: cc65 toolchain
- **Pros**:
  - Professional-grade debugging symbols
  - Linker for complex projects
  - C integration possible
  - Excellent for from-scratch projects
  
- **Cons**:
  - Slower than asar
  - More complex setup
  - Syntax conversion needed
  - Overkill for ROM modifications

- **Best For**: New SNES games from scratch, C integration

### 3. **bass** (byuu's assembler)
- **Status**: Unmaintained (byuu passed away 2021)
- **Pros**:
  - Clean syntax
  - Multi-platform (65816, ARM, etc.)
  
- **Cons**:
  - No longer maintained
  - Community moved to other tools
  
- **Best For**: Legacy projects only

### 4. **WLA-DX**
- **Status**: Actively maintained
- **Pros**:
  - Multi-platform (GB, NES, SNES, etc.)
  - Good linker
  
- **Cons**:
  - More complex than asar
  - Slower assembly
  
- **Best For**: Multi-console projects

## 🏆 RECOMMENDATION: Modern Hybrid Approach

### Primary: **asar** for fast development
- Use for daily development, quick iterations
- ROM patching and modifications
- Keep current syntax (no conversion needed!)

### Secondary: **ca65** for debugging builds
- Generate debug symbols when needed
- Use Mesen-S debug features
- Only when deep debugging required

### Why This Works:
1. **Speed**: asar assembles in <1 second
2. **Compatibility**: Works with existing Diztinguish output
3. **Modern**: asar 1.91 (2023) is current
4. **Community**: Large active ROM hacking scene
5. **Flexibility**: Can output ca65 debug info when needed

## Modern Build Stack Components

### ✅ Assembly: asar 1.91
- Fast iteration (< 1s builds)
- ROM patching support
- Active development

### ✅ Emulation: Mesen-S (or bsnes-plus)
- **Mesen-S**: Best debugger, trace logging, breakpoints
- **bsnes-plus**: Cycle-accurate, excellent debugging
- Auto-launch from build system

### ✅ Graphics: Custom Python Pipeline
- PNG ↔ SNES tile conversion
- Palette management
- Modern asset workflow

### ✅ Testing: Automated ROM Comparison
- Byte-perfect rebuild verification
- Regression testing
- Hash verification

### ✅ Version Control: Git + LFS
- Track source code
- Large binary files (ROMs, graphics) in LFS
- GitHub Actions for CI/CD

### ✅ Build System: Make + PowerShell
- Cross-platform support
- Automated workflows
- Hot-reload development

## Modern Features We'll Add

### 1. **Watch Mode** (Hot Reload)
```powershell
# Watches .asm files, rebuilds + launches emulator on change
make watch
```

### 2. **Debug Build**
```powershell
# Generates debug symbols, launches with Mesen-S debugger
make debug
```

### 3. **Test Suite**
```powershell
# Automated testing, ROM comparison, validation
make test
```

### 4. **CI/CD Pipeline**
```yaml
# GitHub Actions: Build + test on every commit
- Build ROM
- Verify byte-perfect rebuild
- Run automated tests
- Generate reports
```

### 5. **Asset Pipeline**
```powershell
# Auto-converts PNG → SNES on build
make graphics     # Convert all graphics
make text         # Rebuild text tables
make data         # Rebuild data tables
```

### 6. **Development Server**
```powershell
# Live development environment
make dev
# - Watches for file changes
# - Rebuilds automatically
# - Reloads emulator
# - Shows build errors in real-time
```

## Comparison with Other ROM Hacking Projects (2024-2025)

### Pokemon ROM Hacking
- **Tool**: pokeemerald (decomp project) uses `agbcc` (GBA)
- **Approach**: Full decompilation to C, then recompile
- **Our advantage**: Faster iteration with direct assembly

### Super Mario World
- **Tool**: asar (same!)
- **Approach**: ROM patches, custom blocks
- **Our advantage**: We're doing both patches + full rebuild

### Chrono Trigger
- **Tool**: Custom toolchain with ca65
- **Approach**: Full disassembly + rebuild
- **Similar to us**: But we're faster with asar

## Implementation Plan

### Phase 1: Optimize Current asar Build ✅ (NOW)
- [x] Verify asar installation
- [ ] Create fast build script
- [ ] Set up ROM comparison
- [ ] Establish baseline

### Phase 2: Modern Development Workflow
- [ ] Watch mode with auto-rebuild
- [ ] Emulator integration (Mesen-S)
- [ ] Debug build target
- [ ] Asset pipeline automation

### Phase 3: Testing & CI/CD
- [ ] Automated test suite
- [ ] GitHub Actions workflow
- [ ] Byte-perfect rebuild verification
- [ ] Regression testing

### Phase 4: Advanced Features
- [ ] Live debugging integration
- [ ] Performance profiling
- [ ] Optimization tools
- [ ] Documentation generator

## Conclusion

**asar IS the modern solution for SNES ROM hacking in 2025.**

It's:
- ✅ Actively maintained
- ✅ Fast (< 1s builds)
- ✅ Modern features
- ✅ Large community
- ✅ Perfect for our use case

We don't need to switch tools - we need to **level up our build system** around asar!

Next: Implement watch mode, emulator integration, and automated testing.
