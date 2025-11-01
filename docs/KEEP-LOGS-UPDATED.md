# Keep Chat Logs Updated - Always!

**Important:** Chat logs should be updated **ALL THE TIME**, not just on commits!

## When to Log

### ✅ Always Log These:
- **Every git commit** → Automatic via git hook
- **Before switching tasks** → Use `.\update.ps1`
- **After fixing a bug** → Log what was wrong and how you fixed it
- **When answering a question** → Log the Q&A for future reference
- **Making a design decision** → Log why you chose this approach
- **Refactoring code** → Log what and why before committing
- **Researching a topic** → Log findings and references
- **Working on something complex** → Log progress every 30 minutes
- **End of work session** → Log what you accomplished

### ❌ Don't Wait to Log:
- ~~"I'll log it when I commit"~~ → Log it NOW
- ~~"I'll remember what I did"~~ → You won't, log it NOW
- ~~"This change is too small"~~ → If you made it, log it
- ~~"I'm just experimenting"~~ → Especially log experiments!

## How to Log (Multiple Ways!)

### Method 1: Interactive Menu (Easiest!)
```powershell
.\update.ps1
```
Shows menu with all your current changes and lets you log interactively.

### Method 2: Quick Commands
```powershell
# Log a change
.\update.ps1 -Type change -Message "Fixed tile decoding bug in 4BPP converter"

# Log a question
.\update.ps1 -Type question -Message "How does SNES DMA work?"

# Log a note
.\update.ps1 -Type note -Message "Decided to use ca65 over asar for better debugging"

# View summary
.\update.ps1 -Type summary
```

### Method 3: Direct Python
```bash
python tools/update_chat_log.py --change "description"
python tools/update_chat_log.py --question "question" --answer "answer"
python tools/update_chat_log.py --note "thought or decision"
python tools/update_chat_log.py --summary
```

### Method 4: VS Code Tasks
Press `Ctrl+Shift+P`, type "Tasks: Run Task", then choose:
- 📝 Log Changes
- 🔄 Quick Log Change
- ❓ Quick Log Question
- 💭 Quick Log Note
- 📊 View Chat Log Summary

### Method 5: Keyboard Shortcut (Set this up!)
1. `Ctrl+K Ctrl+S` → Open keyboard shortcuts
2. Search for "Run Task"
3. Assign `Ctrl+Shift+L` to "Log Changes" task
4. Now just press `Ctrl+Shift+L` anytime!

## Best Practices

### Log Often!
```
Good: Log every 15-30 minutes when actively working
Better: Log after each meaningful change
Best: Log immediately when you think "I should remember this"
```

### Log Before Switching
```powershell
# Before switching to a different task
.\update.ps1

# Example:
# "Working on graphics tools" → Log it
# Switch to "fixing text encoding" → Log that too
```

### Log Your Thought Process
```
Good: "Fixed bug in tile decoder"
Better: "Fixed bug in tile decoder - was using wrong offset"
Best: "Fixed bug in tile decoder - was using row*2 instead of (row*2 + 16) for bitplanes 2-3. Found by testing with tile $0100 from bank $07."
```

### Log Questions Immediately
```powershell
# When you wonder something
.\update.ps1 -Type question -Message "What's the difference between LoROM and HiROM?"

# When you find the answer (even 5 minutes later)
.\update.ps1 -Type question -Message "What's the difference between LoROM and HiROM?" -Answer "LoROM maps banks to $8000-$ffff with mirrors, HiROM to $0000-$ffff. FFMQ uses LoROM."
```

## Logging Workflow Examples

### Example 1: Bug Fix Session
```powershell
# Start work
.\update.ps1 -Type note -Message "Starting work on graphics extraction bug reports"

# Reproduce bug
.\update.ps1 -Type change -Message "Reproduced tile corruption bug - happens with tiles > $0200"

# Debug
.\update.ps1 -Type note -Message "Bug seems to be in palette offset calculation"

# Fix
.\update.ps1 -Type change -Message "Fixed palette offset bug - was missing bank boundary check"

# Test
.\update.ps1 -Type change -Message "Verified fix with all tiles in banks $07-$0a, no more corruption"

# Commit (auto-logged)
git commit -m "Fix palette offset bug causing tile corruption"

# Summary
.\update.ps1 -Type summary
```

### Example 2: Research Session
```powershell
# Question
.\update.ps1 -Type question -Message "How does SNES BRR audio compression work?"

# Research findings
.\update.ps1 -Type note -Message "BRR uses 4-bit ADPCM with prediction filters. Each block is 9 bytes."

# More findings
.\update.ps1 -Type note -Message "BRR samples must be aligned to 9-byte boundaries. Sample rate encoded separately."

# Answer the question
.\update.ps1 -Type question -Message "How does SNES BRR audio compression work?" -Answer "4-bit ADPCM with prediction filters, 9-byte blocks, requires 9-byte alignment. See: https://problemkaputt.de/fullsnes.htm#snesaudioprocessingunit"

# Implement
.\update.ps1 -Type change -Message "Started BRR decoder implementation based on research"

# Commit
git commit -m "Add initial BRR audio decoder"
```

### Example 3: Refactoring
```powershell
# Before refactoring
.\update.ps1 -Type note -Message "Planning to refactor tile decoder - current code is 300 lines in one function"

# During refactoring
.\update.ps1 -Type change -Message "Split decode_4bpp_tile into smaller functions: decode_bitplane, combine_bitplanes"

# More refactoring
.\update.ps1 -Type change -Message "Extracted palette handling into separate PaletteManager class"

# Testing
.\update.ps1 -Type change -Message "All tests passing after refactor, code is much cleaner"

# Commit
git commit -m "Refactor tile decoder for better maintainability"
```

## Reminders

### Set Up Periodic Reminders
Add to your workflow:
```powershell
# Add to your PowerShell profile
# Every time you open a terminal, it reminds you
if (Test-Path ".\update.ps1") {
    Write-Host "💡 Remember to log your changes with: .\update.ps1" -ForegroundColor Yellow
}
```

### Monitor Mode (Optional)
```powershell
# Start monitor that checks for changes every 5 minutes
.\update.ps1 -Monitor
```

### Daily Review
```powershell
# End of each day
.\update.ps1 -Type summary

# Review what you accomplished
cat ~docs/copilot-chats/2025-10-24-session.md
```

## What Gets Logged

### Automatic (No Effort)
- ✅ Git commits → Hash, message, files changed
- ✅ Timestamps → On every entry

### Manual (You Control)
- 📝 Changes → What you modified and why
- ❓ Questions → What you're researching
- 💭 Notes → Thoughts, decisions, observations
- 🔍 Progress → Where you are on a task

## Benefits of Continuous Logging

### Short-term:
- Don't forget what you were doing
- Easy context switching
- Track progress on complex tasks

### Medium-term:
- Debug issues with historical context
- Remember why decisions were made
- Onboard team members quickly

### Long-term:
- Complete project history
- Generate documentation from logs
- Learn from past work
- Create progress reports

## Integration Points

### With Git:
```bash
# Before commit, log what you're committing
.\update.ps1

# Commit (auto-logged)
git commit -m "message"

# Result: Complete history
```

### With VS Code:
- Use tasks for quick logging
- Status bar reminder (configure)
- Keyboard shortcuts (configure)

### With Your Workflow:
```
1. Start task → Log it
2. Work on code → Log changes as you go
3. Research something → Log findings
4. Switch tasks → Log completion
5. End session → Review summary
```

## Tips for Success

### Make It a Habit
- Log at least once per hour
- Set keyboard shortcut
- Use interactive menu
- Review summary daily

### Keep It Simple
```
Don't overthink it:
- "Fixed bug" is better than nothing
- "Fixed palette bug" is better
- "Fixed palette offset calculation in decode_4bpp_tile" is best
```

### Use Templates
```powershell
# Create shortcuts
function Log-Change { .\update.ps1 -Type change -Message $args[0] }
function Log-Question { .\update.ps1 -Type question -Message $args[0] }
function Log-Note { .\update.ps1 -Type note -Message $args[0] }

# Usage
Log-Change "Fixed tile decoding"
Log-Question "How does PPU work?"
Log-Note "Switching to text extraction next"
```

## Troubleshooting

### "I keep forgetting to log"
→ Set up keyboard shortcut: `Ctrl+Shift+L`
→ Run monitor mode: `.\update.ps1 -Monitor`
→ Add reminder to PowerShell profile

### "Logging takes too long"
→ Use quick commands instead of interactive menu
→ Set up VS Code tasks
→ Create PowerShell aliases

### "I don't know what to log"
→ Log EVERYTHING you do
→ When in doubt, log it
→ More is better than less

## The Rule

**If you spent more than 5 minutes on it, LOG IT!**

Even better:
**If you thought it, LOG IT!**

---

Remember: **The best time to log is NOW!**
The second best time is after finishing this sentence. Go log what you're working on! 😊
