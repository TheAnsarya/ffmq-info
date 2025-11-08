# Developer Onboarding Guide

> **Target Audience:** New developers joining the project  
> **Time Required:** 30-60 minutes for complete setup  
> **Prerequisites:** Basic Git, Python, and assembly knowledge

Welcome to the FFMQ disassembly project! This guide will get you from zero to productive contributor in under an hour.

## 🎯 Your First Hour

### Minute 0-10: Initial Setup

**1. Clone the repository:**
```bash
git clone https://github.com/TheAnsarya/ffmq-info.git
cd ffmq-info
```

**2. Install requirements:**
```powershell
# Run setup script (Windows)
.\setup.ps1

# Or manual setup
pip install -r requirements.txt
```

**3. Get the ROM:**
- Place `Final Fantasy - Mystic Quest (U) (V1.1).sfc` in `roms/` directory
- **Do not commit ROM files** (they're in .gitignore)

### Minute 10-20: Understand the Structure

**Read these files in order:**
1. **[README.md](../README.md)** (5 min) - Project overview
2. **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** (5 min) - Comprehensive guide
3. **[CONTRIBUTING.md](../CONTRIBUTING.md)** (5 min) - Standards and workflow
4. **[docs/INDEX.md](INDEX.md)** (5 min) - Documentation roadmap

**Key takeaway:** You now understand:
- What the project does
- How it's organized
- How to contribute
- Where to find information

### Minute 20-30: Build Your First ROM

```powershell
# Build ROM
.\build.ps1

# Expected output: build/ffmq-rebuilt.sfc (1,048,576 bytes)

# Verify it matches original
.\test-roundtrip.ps1

# Expected: "FC: no differences encountered"
```

**If build fails:** Check [Troubleshooting](#troubleshooting) section below.

### Minute 30-40: Make a Trivial Change

**Edit an enemy:**
```bash
# 1. Open enemy editor
python tools/enemy_editor_gui.py

# 2. Select "Brownie" (first enemy)
# 3. Change HP from 50 to 100
# 4. Click "Save Enemy"
# 5. Click "Export JSON" (Ctrl+E)
```

**Rebuild ROM:**
```powershell
.\build.ps1
```

**Test in emulator:**
```bash
# If you have MesenS
mesen build/ffmq-rebuilt.sfc
```

**Congratulations!** You've modified the game!

### Minute 40-50: Explore the Code

**Open these files in your editor:**

**1. docs/FUNCTION_REFERENCE.md**
- Search for "Brownie" or "Enemy"
- See how code is documented
- Note the format and style

**2. src/asm/bank_00_documented.asm**
- Open and scroll through
- See assembly code structure
- Note the commenting style

**3. tools/enemy_editor_gui.py**
- See how the GUI works
- Note Python code style
- Check docstrings

### Minute 50-60: Pick Your First Issue

**1. Visit [GitHub Project #3](https://github.com/users/TheAnsarya/projects/3)**

**2. Look for "good first issue" label**

**3. Common first contributions:**
- Document 5-10 functions in any bank
- Add docstrings to a Python tool
- Fix typos in documentation
- Add test cases
- Improve error messages

**4. Create a branch:**
```bash
git checkout -b feature/your-first-contribution
```

## 📚 Development Workflow

### Daily Workflow

```bash
# 1. Update from main
git checkout master
git pull origin master

# 2. Create feature branch
git checkout -b feature/descriptive-name

# 3. Make changes
# (edit files)

# 4. Format code (for ASM files)
.\tools\format_asm.ps1 -Path src\asm\bank_XX.asm

# 5. Test changes
python tools/run_all_tests.py

# 6. Build ROM
.\build.ps1

# 7. Commit with descriptive message
git add .
git commit -m "Descriptive message"

# 8. Push to your fork
git push origin feature/descriptive-name

# 9. Create pull request on GitHub
```

### Code Review Checklist

Before submitting PR, verify:
- ✅ Code follows project standards
- ✅ All tests pass
- ✅ ASM files formatted (format_asm.ps1)
- ✅ Documentation updated
- ✅ ROM builds successfully
- ✅ Commit messages are clear

## 🎨 Coding Standards

### Assembly Code

**Format:**
```asm
; ==============================================================================
; FunctionName - Brief description
; ==============================================================================
; Inputs:
;   A = Input parameter
;   X = Another parameter
; Outputs:
;   A = Return value
;   Carry = Set on error
; ==============================================================================
FunctionName:
	lda	Parameter	; Load value
	sta	Destination	; Store result
	rts			; Return
```

**Column alignment:**
- Labels: Column 0
- Opcodes: Column 23
- Operands: Column 47
- Comments: Column 57

**Auto-format:**
```powershell
.\tools\format_asm.ps1 -Path file.asm
```

### Python Code

**Style:** PEP 8 compliance
```python
"""Module docstring describing purpose."""

def function_name(param1: str, param2: int) -> bool:
    """
    Brief description of function.
    
    Args:
        param1: Description of param1
        param2: Description of param2
        
    Returns:
        Description of return value
        
    Raises:
        ValueError: When condition occurs
    """
    # Implementation
    return True
```

**Run formatter:**
```bash
# Install black (if needed)
pip install black

# Format file
black tools/your_script.py
```

### Documentation

**Markdown style:**
- Use proper headers (`#`, `##`, `###`)
- Code blocks with language tags
- Tables for structured data
- Links to related docs

**Update INDEX.md** when adding new docs.

## 🔧 Essential Tools

### Required

**1. Asar** - SNES assembler
- Download: https://github.com/RPGHacker/asar/releases
- Place `asar.exe` in project root or PATH

**2. Python 3.8+**
- Download: https://python.org/
- Ensure `pip` is available

**3. Git**
- Download: https://git-scm.com/
- Configure name/email

### Recommended

**4. VS Code** - Code editor
- Download: https://code.visualstudio.com/
- Extensions:
  - Python
  - PowerShell
  - EditorConfig
  - Markdown All in One

**5. MesenS** - SNES emulator
- Download: https://github.com/SourMesen/Mesen-S/releases
- Best for testing changes

**6. YY-CHR** - Graphics editor
- Download: https://www.romhacking.net/utilities/958/
- For editing SNES graphics

## 📖 Key Documentation

### Must-Read (Before Contributing)

1. **[README.md](../README.md)** - Project overview
2. **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Contribution guidelines
3. **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** - Complete project guide

### Reference (Keep Handy)

1. **[FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md)** - All documented functions
2. **[TOOLS_REFERENCE.md](TOOLS_REFERENCE.md)** - Python tools guide
3. **[POWERSHELL_REFERENCE.md](POWERSHELL_REFERENCE.md)** - Script reference

### Technical (For Deep Work)

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Project architecture
2. **[Bank Classification](technical/BANK_CLASSIFICATION.md)** - ROM structure
3. **[Battle System](BATTLE_SYSTEM.md)** - Game mechanics

## 🎓 Learning Path

### Week 1: Familiarization
- ✅ Set up environment
- ✅ Build ROM successfully
- ✅ Make trivial change
- ✅ Read core documentation
- 🎯 Document 10 simple functions

### Week 2: First Contribution
- Document a small system (20-30 functions)
- Add Python tool docstrings
- Fix documentation issues
- Add test cases

### Week 3: Deeper Work
- Document complex system (battle, graphics, etc.)
- Create new analysis tool
- Improve existing tools
- Write tutorial

### Month 2+: Advanced
- Own a subsystem (Bank $01, Battle System, etc.)
- Mentor new contributors
- Design new features
- Lead research efforts

## 🚨 Troubleshooting

### "Asar not found"

**Problem:** Build script can't find asar.exe

**Solution:**
```powershell
# Option 1: Add to PATH
$env:PATH += ";C:\path\to\asar"

# Option 2: Copy to project root
Copy-Item "C:\path\to\asar.exe" -Destination "."

# Option 3: Use full path in build.ps1
# (edit build.ps1 to use full path)
```

### "Python not found"

**Problem:** Python not in PATH

**Solution:**
```powershell
# Check Python installation
python --version

# If not found, add to PATH or reinstall Python with "Add to PATH" checked
```

### "Build doesn't match original"

**Problem:** Byte-perfect rebuild fails

**Solution:**
```powershell
# 1. Verify ROM is correct version
# CRC32 should be: 2c52c792

# 2. Check for uncommitted changes
git status

# 3. Review build log
Get-Content logs\build-latest.log

# 4. Run roundtrip test with verbose
.\test-roundtrip.ps1 -Verbose

# 5. Compare with original
fc /b roms\original.sfc build\ffmq-rebuilt.sfc
```

### "Tests failing"

**Problem:** Test suite shows errors

**Solution:**
```bash
# Run tests with verbose output
python tools/run_all_tests.py --verbose

# Run specific failing test
python tools/run_tests.py tests/test_enemies.py

# Check test output for specifics
# Usually indicates data mismatch or missing files
```

### "Git conflicts"

**Problem:** Merge conflicts when pulling

**Solution:**
```bash
# 1. Stash your changes
git stash

# 2. Pull latest
git pull origin master

# 3. Apply stash
git stash pop

# 4. Resolve conflicts manually
# (edit conflicted files)

# 5. Add resolved files
git add .

# 6. Continue with commit
git commit
```

## 💡 Pro Tips

### Productivity Tips

1. **Use VS Code tasks**
   - Ctrl+Shift+P → "Tasks: Run Task"
   - Quick build, format, verify

2. **Enable automatic tracking**
   ```powershell
   .\start-tracking.ps1
   ```
   Your changes are logged automatically!

3. **Set up aliases** (PowerShell profile)
   ```powershell
   function Build { .\build.ps1 }
   function Test { python tools/run_all_tests.py }
   function Format { .\tools\format_asm.ps1 -Path $args[0] }
   ```

4. **Use grep for searching**
   ```bash
   # Find all references to a label
   grep -r "LabelName" src/asm/

   # Find all TODOs
   grep -r "TODO" .
   ```

### Code Navigation

1. **Function Reference is searchable**
   - Ctrl+F in FUNCTION_REFERENCE.md
   - Search by function name, address, or description

2. **Use git blame**
   ```bash
   git blame src/asm/bank_00_documented.asm
   ```
   See who wrote what and when

3. **Use git log**
   ```bash
   git log --oneline --graph --all
   ```
   Visual commit history

### Testing Strategies

1. **Test incrementally**
   - Don't write 100 lines then test
   - Test after every 10-20 lines

2. **Use emulator debugger**
   - MesenS has excellent debugger
   - Set breakpoints in your code

3. **Compare with original**
   - Always verify changes don't break game
   - Test same scenario in original vs modified ROM

## 📞 Getting Help

### Before Asking

1. Check documentation (docs/INDEX.md)
2. Search existing issues on GitHub
3. Read error messages carefully
4. Try troubleshooting steps above

### How to Ask

**Good question:**
> "I'm trying to document the function at $80:8234 (bank_00.asm line 150). It appears to write to $2121 (CGADD) and $2122 (CGDATA). I think it's setting color palettes, but I'm not sure about the loop structure. Can someone explain the purpose of the X register in this context?"

**Bad question:**
> "Code doesn't work. Help?"

### Where to Ask

1. **GitHub Issues** - Technical problems, bugs
2. **GitHub Discussions** - Questions, ideas
3. **Pull Request Comments** - Code review questions

## 🎉 Your First Pull Request

### Checklist

Before submitting PR:
- ✅ Tests pass locally
- ✅ Code formatted (ASM, Python)
- ✅ Documentation updated
- ✅ Commit messages descriptive
- ✅ No merge conflicts
- ✅ PR description explains changes

### PR Template

```markdown
## Description
Brief description of what this PR does

## Changes
- List of specific changes
- Another change
- Etc.

## Testing
How you tested these changes

## Related Issues
Fixes #123
Related to #456

## Checklist
- [x] Tests pass
- [x] Code formatted
- [x] Docs updated
- [x] No conflicts
```

### Review Process

1. **Submit PR** - GitHub web interface
2. **Wait for review** - Usually within 24-48 hours
3. **Address feedback** - Make requested changes
4. **Approval** - Maintainer approves
5. **Merge** - PR merged into master

## 🚀 Next Steps

Now that you're set up:

1. **Pick an issue** from GitHub Project #3
2. **Start small** - Document 5-10 functions
3. **Ask questions** - No question is too basic
4. **Have fun!** - This is a learning project

**Welcome to the team!** 🎮

---

## 📚 Additional Resources

### External
- [SNES Dev Manual](https://problemkaputt.de/fullsnes.htm)
- [65816 Reference](https://softpixel.com/~cwright/sianse/docs/65816NFO.HTM)
- [ROMhacking.net](https://www.romhacking.net/)

### Internal
- [Function Reference](FUNCTION_REFERENCE.md)
- [ROM Data Map](ROM_DATA_MAP.md)
- [Battle System](BATTLE_SYSTEM.md)

---

*Last updated: 2025-11-07 | For questions: Create a GitHub issue*
