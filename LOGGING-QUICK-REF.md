# 📝 Chat Log Quick Reference Card

**🤖 AUTOMATIC TRACKING AVAILABLE!**

## Easiest Way: Fully Automatic

```powershell
# Start once, forget about it!
.\start-tracking.ps1

# Everything is logged automatically in the background
# No manual logging needed!
```

**Status commands:**
```powershell
.\track.ps1 status  # Check if running
.\track.ps1 stop    # Stop tracking
.\track.ps1 start   # Start tracking
```

---

## Manual Logging (If You Prefer)

### Always
- ✅ Before switching tasks
- ✅ After fixing bugs
- ✅ When asking questions
- ✅ Making decisions
- ✅ Every 15-30 minutes

### Never Wait
- ❌ "I'll log it later" → Log NOW
- ❌ "Too small to log" → Log it anyway
- ❌ "Just experimenting" → Log experiments!

## Quick Commands

```powershell
# Interactive menu (easiest!)
.\update.ps1

# Quick change
.\update.ps1 -Type change -Message "description"

# Quick question
.\update.ps1 -Type question -Message "question"

# Quick note
.\update.ps1 -Type note -Message "decision"

# View summary
.\update.ps1 -Type summary
```

## VS Code

**Press:** `Ctrl+Shift+P`  
**Type:** `Tasks: Run Task`  
**Choose:** 📝 Log Changes

## Keyboard Shortcut (Set This Up!)

1. `Ctrl+K Ctrl+S`
2. Search "Run Task"
3. Assign `Ctrl+Shift+L`
4. Press `Ctrl+Shift+L` anytime to log!

## The Rule

**If you spent 5 minutes on it → LOG IT!**

## Examples

```powershell
# Bug fix
.\update.ps1 -Type change -Message "Fixed offset bug in tile decoder"

# Question
.\update.ps1 -Type question -Message "How does SNES DMA work?"

# Decision
.\update.ps1 -Type note -Message "Chose ca65 over asar for debugging"

# Progress
.\update.ps1 -Type note -Message "Completed 4BPP decoder, starting 2BPP next"
```

## Remember

**The best time to log is NOW!** 🎯

---

See `docs/KEEP-LOGS-UPDATED.md` for complete guide
