# Automatic Activity Tracker - Set It and Forget It!

**TL;DR:** Run `.\start-tracking.ps1` once and everything is logged automatically. That's it!

## How It Works

The automatic tracker monitors all your source files and automatically logs changes to the chat log. No manual intervention required!

### What Gets Tracked Automatically

✅ **All File Changes:**
- Modified files (with hash-based change detection)
- New files added
- Deleted files
- Real changes only (not just timestamp updates)

✅ **File Types Monitored:**
- Python (`.py`)
- Assembly (`.s`, `.asm`, `.inc`)
- Documentation (`.md`, `.txt`)
- Scripts (`.ps1`, `.bat`, `.sh`)
- Code (`.c`, `.cpp`, `.h`)
- Config (`.json`)

✅ **Automatic Logging:**
- Changes logged every 30 seconds (configurable)
- Groups changes into meaningful entries
- Tracks which files were modified/added/deleted
- No manual commands needed!

## Quick Start

### 1. Start Tracking (Once)

```powershell
.\start-tracking.ps1
```

This starts the tracker in the background. You can close the window - it keeps running!

### 2. Work Normally

Just code! The tracker monitors everything automatically.

### 3. Check Status Anytime

```powershell
.\track.ps1 status
```

Shows if tracker is running and when last activity was logged.

## Commands

```powershell
# Start tracking in background
.\start-tracking.ps1

# Check if running
.\track.ps1 status

# Stop tracking
.\track.ps1 stop

# Start tracking (manual)
.\track.ps1 start

# Start with custom interval (60 seconds)
.\track.ps1 start -Interval 60
```

## How It's Different from Manual Logging

### Manual Logging (.\update.ps1)
- You run command when you want to log
- You describe what you did
- You choose when to log
- Good for questions, notes, decisions

### Automatic Tracking (.\track.ps1)
- Runs continuously in background
- Detects file changes automatically
- Logs changes without your input
- Good for tracking all code modifications

### Best Approach: Use Both!

```powershell
# Start automatic tracker once
.\start-tracking.ps1

# Let it track file changes automatically
# (Your code edits are logged automatically)

# Manual log for questions/decisions
.\update.ps1 -Type question -Message "How does SNES DMA work?"

# Manual log for important notes
.\update.ps1 -Type note -Message "Decided to use ca65 for better debugging"
```

## Technical Details

### File Monitoring
- Uses MD5 hashing to detect real content changes
- Ignores timestamp-only changes
- Scans every 30 seconds by default (configurable)
- Monitors: `src/`, `tools/`, `docs/`, `.vscode/`

### State Management
- Stores file hashes in `.auto_tracker_state.json`
- Tracks last activity time
- Persists across runs
- Automatically saves state

### Background Execution
- Runs as separate process
- PID stored in `.auto_tracker.pid`
- Can be stopped with `.\track.ps1 stop`
- Automatic cleanup on exit

### Chat Log Integration
- Uses same logging system as manual updates
- Entries marked as "Auto-tracked"
- Groups multiple changes together
- Limits to 10 files per entry for readability

## Examples

### Starting Tracking
```powershell
PS> .\start-tracking.ps1

╔═══════════════════════════════════════════════════╗
║   FFMQ Development - Automatic Logging Enabled   ║
╚═══════════════════════════════════════════════════╝

Starting automatic activity tracker...
✓ Automatic logging is now active!

All your file changes will be logged automatically.
No need to run .\update.ps1 manually anymore!

Commands:
  .\track.ps1 status  - Check tracking status
  .\track.ps1 stop    - Stop automatic tracking
  .\track.ps1 start   - Start automatic tracking

💡 Tracker runs in background, no need to keep window open!
```

### Checking Status
```powershell
PS> .\track.ps1 status

✓ Tracker is running
Last activity: 2025-10-24T22:15:30.123456
Tracking 247 files
```

### Automatic Logging in Action
```
[You edit src/asm/main.s and tools/extract_graphics.py]

[After 30 seconds, automatically logged:]
✓ Auto-logged 2 changes

[Chat log entry created:]
### [22:15:30] Change Made

**Description:** Auto-tracked: Modified 2 file(s)

**Files Affected:**
- `src/asm/main.s`
- `tools/extract_graphics.py`
```

## Troubleshooting

### Tracker Not Starting
```powershell
# Check if Python is available
python --version

# Check if another instance is running
.\track.ps1 status

# Stop existing instance
.\track.ps1 stop

# Try starting again
.\start-tracking.ps1
```

### Changes Not Being Logged
```powershell
# Check if tracker is running
.\track.ps1 status

# Verify you're editing tracked file types
# (Must be .py, .s, .asm, .inc, .md, .txt, .ps1, etc.)

# Check if files are in watched directories
# (src/, tools/, docs/, .vscode/)
```

### Stop Tracking
```powershell
# Simple stop command
.\track.ps1 stop

# If that doesn't work, find and kill process
Get-Process python | Where-Object {$_.CommandLine -like '*auto_tracker*'} | Stop-Process
```

## Configuration

### Change Check Interval

Default is 30 seconds. To change:

```powershell
# Check every 60 seconds instead
.\track.ps1 start -Interval 60

# Check every 10 seconds (more responsive)
.\track.ps1 start -Interval 10
```

### Add More File Types

Edit `tools/auto_tracker.py`:

```python
# Line ~33
self.track_extensions = {
	'.py', '.s', '.asm', '.inc', '.md', '.txt',
	'.json', '.ps1', '.bat', '.sh', '.c', '.cpp', '.h',
	'.js',  # Add JavaScript
	'.ts',  # Add TypeScript
	# ... add more as needed
}
```

### Add More Directories

Edit `tools/auto_tracker.py`:

```python
# Line ~25
self.watch_dirs = [
	self.project_root / "src",
	self.project_root / "tools",
	self.project_root / "docs",
	self.project_root / ".vscode",
	self.project_root / "assets",  # Add assets directory
	# ... add more as needed
]
```

## Integration with Git

The automatic tracker works alongside the git commit hooks:

1. **File changes** → Tracked automatically (every 30 seconds)
2. **Git commit** → Logged automatically (via post-commit hook)
3. **Result:** Complete history of ALL work!

## Performance

### Resource Usage
- Minimal CPU usage (scans every 30 seconds)
- Low memory footprint (stores file hashes only)
- No impact on your development workflow

### File Scanning
- Only scans watched directories
- Only tracks specific file extensions
- Hash-based change detection is fast
- Skips binary files and large files

## Best Practices

### Just Start It!
```powershell
# When you begin working on the project
.\start-tracking.ps1
```

### Let It Run
- Don't stop/start repeatedly
- Let it run throughout your session
- It won't interfere with your work

### Combine with Manual Logging
```powershell
# Automatic tracker handles file changes
# You handle questions and decisions
.\update.ps1 -Type question -Message "Research question"
.\update.ps1 -Type note -Message "Important decision"
```

### Check Status Occasionally
```powershell
# Make sure it's still running
.\track.ps1 status
```

## Why Use Automatic Tracking?

### Benefits

✅ **Never Forget to Log:**
- All file changes tracked automatically
- No manual command needed
- Complete history guaranteed

✅ **Focus on Coding:**
- No interruptions to log changes
- No mental overhead
- Just code normally

✅ **Detailed History:**
- Exact files changed tracked
- Timestamps automatic
- Nothing falls through cracks

✅ **Easy to Use:**
- One command to start
- Runs in background
- Set it and forget it!

### Limitations

⚠️ **No Context:**
- Doesn't know WHY you changed files
- Can't describe WHAT you did
- Use manual logging for context

⚠️ **File-Based Only:**
- Only tracks file changes
- Doesn't track thoughts or questions
- Use manual logging for those

⚠️ **Delayed Logging:**
- Changes logged after 30 seconds (or configured interval)
- Not instant like manual logging
- Good enough for historical tracking

## Recommendation

**Best Setup:**

1. Start automatic tracker: `.\start-tracking.ps1`
2. Let it run and track file changes
3. Use manual logging for:
   - Questions you have
   - Decisions you make
   - Important milestones
   - Context for complex changes

This gives you the best of both worlds:
- Automatic tracking of ALL file changes
- Manual logging of important context

## Summary

```powershell
# One-time setup each session
.\start-tracking.ps1

# Everything is now logged automatically!
# Just code normally and forget about logging.

# Optional: Manual log for context
.\update.ps1 -Type note -Message "Starting work on graphics tools"
```

---

**The bottom line:** Run `.\start-tracking.ps1` and never worry about logging again! 🎉
