# Chat Log Auto-Update System - Complete Guide

This system automatically maintains chat logs and documentation for the FFMQ SNES development project.

## Overview

**Automatic Logging:**
- Git commits → Logged automatically via post-commit hook
- Changed files → Tracked with each commit
- Timestamps → Added to every entry

**Manual Logging:**
- Changes → `.\log.ps1 -Type change -Message "description"`
- Questions → `.\log.ps1 -Type question -Message "question"`
- Summary → `.\log.ps1 -Type summary`

## Quick Reference

### Log a Change
```powershell
.\log.ps1 -Type change -Message "Refactored graphics decoder"
```

### Log with Files
```powershell
.\log.ps1 -Type change -Message "Fixed bug" -Files file1.py,file2.s
```

### Log Question
```powershell
.\log.ps1 -Type question -Message "How does SNES DMA work?"
```

### Log Question + Answer
```powershell
.\log.ps1 -Type question -Message "SNES color format?" -Answer "15-bit BGR"
```

### View Summary
```powershell
.\log.ps1 -Type summary
```

## File Structure

```
~docs/copilot-chats/
├── README.md							# Quick overview (this file)
├── 2025-01-24-project-reorganization.md	# Main project log
├── 2025-01-24-session.md				# Daily session (auto-created)
├── 2025-01-25-session.md				# Next day
└── ...
```

## How It Works

1. **Make changes** to code
2. **Commit** → Hook automatically logs it
3. **Manual log** for non-commit changes
4. **Daily session** tracks everything

## Session Log Format

```markdown
### [14:30:15] Git Commit: abc1234

**Message:** Add graphics decoder

**Files Changed:**
- `tools/graphics/decoder.py`
- `src/include/graphics.inc`
```

## Best Practices

✅ **DO:**
- Commit with descriptive messages (they're auto-logged)
- Log significant changes manually
- Log important questions and answers
- Review daily summary

❌ **DON'T:**
- Log trivial changes
- Duplicate commit logs manually
- Write vague log messages

## Troubleshooting

**Hook not running?**
```bash
chmod +x .git/hooks/post-commit  # Unix/Linux/Mac
```

**Can't run log.ps1?**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**See full logs?**
```powershell
cat ~docs/copilot-chats/2025-01-24-session.md
```

## Tools

- **update_chat_log.py** - Core logging tool
- **log.ps1** - PowerShell helper script
- **.git/hooks/post-commit** - Automatic hook
- **.git/hooks/post-commit.ps1** - PowerShell hook

---

For complete documentation with examples and advanced usage, see inline comments in `tools/update_chat_log.py`.
