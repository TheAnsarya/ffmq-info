# Tracking Tools

This directory contains tools for tracking project progress, changes, and development activity.

## Progress Tracking

### Automated Tracking
- **auto_tracker.py** - Automatic progress tracking
  - Monitors code changes automatically
  - Tracks documentation additions
  - Updates progress metrics
  - Generates timeline
  - Usage: `python tools/tracking/auto_tracker.py [--daemon]`

### Disassembly Progress
- **disassembly_tracker.py** - Track disassembly completion
  - Monitors disassembled code coverage
  - Tracks labeled vs unlabeled code
  - Reports progress by bank
  - Identifies priority areas
  - Usage: `python tools/tracking/disassembly_tracker.py --output disassembly_progress.md`

### Extraction Progress
- **track_extraction.py** - Track data extraction progress
  - Monitors extracted assets
  - Tracks extraction completeness
  - Identifies missing data
  - Reports extraction statistics
  - Usage: `python tools/tracking/track_extraction.py --output extraction_status.md`

### Session Logging
- **update_chat_log.py** ⭐ - Update development session logs
  - Log changes, questions, notes
  - Maintain session history
  - Track development timeline
  - Generate session summaries
  - Usage: `python tools/tracking/update_chat_log.py --change "Description" | --question "Q" | --note "N" | --summary`

## Common Workflows

### Daily Progress Logging
```bash
# Log a change made today
python tools/tracking/update_chat_log.py --change "Documented 42 functions in Bank $03"

# Log a question for later
python tools/tracking/update_chat_log.py --question "What does byte 0x05 in spell data do?"

# Log a general note
python tools/tracking/update_chat_log.py --note "Enemy AI seems to use pattern table at $1A8000"

# View today's summary
python tools/tracking/update_chat_log.py --summary
```

### Track Overall Project Progress
```bash
# Update all progress metrics
python tools/tracking/auto_tracker.py --update

# Generate progress report
python tools/tracking/auto_tracker.py --report --output PROGRESS.md

# View progress statistics
python tools/tracking/auto_tracker.py --stats
```

### Monitor Disassembly Progress
```bash
# Check disassembly status
python tools/tracking/disassembly_tracker.py

# Generate detailed report
python tools/tracking/disassembly_tracker.py --output reports/disassembly.md --detail

# Check specific bank
python tools/tracking/disassembly_tracker.py --bank 02

# Track progress over time
python tools/tracking/disassembly_tracker.py --history --output progress_history.csv
```

### Track Data Extraction
```bash
# Check extraction status
python tools/tracking/track_extraction.py

# Generate extraction report
python tools/tracking/track_extraction.py --output EXTRACTION_STATUS.md

# Check what's missing
python tools/tracking/track_extraction.py --missing-only

# Track by data type
python tools/tracking/track_extraction.py --type enemies
```

### Automated Continuous Tracking
```bash
# Start tracking daemon (runs in background)
python tools/tracking/auto_tracker.py --daemon

# Monitor changes and auto-update progress
# Daemon watches for:
# - New commits
# - Documentation changes
# - Data extractions
# - Test additions

# Stop daemon
python tools/tracking/auto_tracker.py --stop-daemon
```

## Session Log Format

### Daily Session Log
```markdown
# Development Session - 2025-11-07

## Changes
- [10:30] Documented 42 Bank $03 functions
- [14:15] Reorganized tools/ directory structure
- [16:45] Created comprehensive README files

## Questions
- [11:00] What does byte 0x05 in spell data control?
- [15:30] How are metatiles compressed in Bank $06?

## Notes
- [12:00] Enemy AI patterns stored at $1A8000-$1A8FFF
- [17:00] Graphics pipeline working perfectly for 4bpp sprites

## Statistics
- Functions documented: +42
- Files reorganized: 85
- Tests added: 3
- Lines of code: +1,240
```

### Progress Report Format
```markdown
# Project Progress Report
Generated: 2025-11-07 18:00

## Overall Progress
- Total Functions: 2,486
- Documented: 800 (32.2%) [+42 today]
- ROM Coverage: 78.5%
- Test Coverage: 65.3%

## Recent Activity (Last 7 Days)
- Functions documented: 183
- Code commits: 13
- Tests added: 8
- Issues closed: 5

## Bank Progress
| Bank | Total | Done | % | Priority |
|------|-------|------|---|----------|
| $00  | 150   | 15   | 10.0% | High |
| $01  | 280   | 42   | 15.0% | High |
| $02  | 420   | 183  | 43.6% | Med  |
| $03  | 350   | 42   | 12.0% | Med  |
...

## Velocity
- Functions/day: 26.1 (7-day avg)
- ETA to 80%: ~45 days
- ETA to 100%: ~65 days
```

## Tracking Configuration

### tracking_config.json
```json
{
    "session_log_dir": "docs/historical/sessions/",
    "progress_report": "PROGRESS_REPORT.md",
    "auto_track_interval": 300,
    "track_metrics": [
        "functions_documented",
        "code_coverage",
        "test_coverage",
        "extraction_progress",
        "build_success_rate"
    ],
    "notify_milestones": true,
    "milestone_percentages": [25, 50, 75, 90, 95, 100]
}
```

## Tracked Metrics

### Documentation Metrics
- Functions documented (total and by bank)
- Documentation completeness percentage
- Average documentation length
- Documentation quality score

### Code Metrics
- Lines of assembly code
- Code labeled vs unlabeled
- Cross-reference completeness
- Code organization score

### Extraction Metrics
- Assets extracted (graphics, text, music, data)
- Extraction completeness percentage
- Data validation status
- Format conversion success rate

### Development Metrics
- Commits per day/week
- Active development time
- Issues opened/closed
- Pull requests merged

### Quality Metrics
- Build success rate
- Test pass rate
- Test coverage percentage
- Code review completion

## Progress Visualization

### Terminal Output
```
Project Progress: 32.2% ████████░░░░░░░░░░░░░░░░░ 800/2,486

Bank Progress:
$00 [███░░░░░░░]  10.0%  (15/150)   Priority: High
$01 [████░░░░░░]  15.0%  (42/280)   Priority: High
$02 [████████░░]  43.6%  (183/420)  Priority: Med
$03 [███░░░░░░░]  12.0%  (42/350)   Priority: Med

Recent Velocity: 26.1 functions/day (7-day average)
ETA to 80%: 45 days | ETA to 100%: 65 days
```

### Chart Generation
```bash
# Generate progress chart
python tools/tracking/auto_tracker.py --chart --output progress_chart.png

# Generate velocity chart
python tools/tracking/auto_tracker.py --chart velocity --output velocity_chart.png

# Generate burndown chart
python tools/tracking/auto_tracker.py --chart burndown --output burndown.png
```

## Integration with Git

### Git Hooks
```bash
# Post-commit hook to auto-update progress
# .git/hooks/post-commit

#!/bin/bash
python tools/tracking/auto_tracker.py --update
python tools/tracking/update_chat_log.py --change "$(git log -1 --pretty=%B)"
```

### Commit Statistics
```bash
# Track commits by date
python tools/tracking/auto_tracker.py --git-stats --since "1 week ago"

# Author statistics
python tools/tracking/auto_tracker.py --git-stats --by-author

# File change frequency
python tools/tracking/auto_tracker.py --git-stats --file-frequency
```

## Dependencies

- Python 3.7+
- **gitpython** - `pip install gitpython` (for git integration)
- **matplotlib** - `pip install matplotlib` (for charts)
- Standard library modules

## See Also

- **tools/analysis/** - For detailed project analysis
- **docs/status/** - For status documentation
- **docs/historical/** - For historical session logs
- **.github/workflows/** - For CI/CD integration

## Tips and Best Practices

### Daily Tracking
- Log changes as you make them
- Record questions immediately
- Note discoveries right away
- Review session log at end of day

### Progress Monitoring
- Run progress update daily
- Generate reports weekly
- Review velocity trends monthly
- Adjust estimates based on actual velocity

### Session Logging
- Be specific in change descriptions
- Include context for questions
- Tag notes with relevant topics
- Link to commits/issues when relevant

### Automated Tracking
- Set up git hooks for automatic logging
- Run tracking daemon during development
- Generate reports before standups
- Archive old logs monthly

## Troubleshooting

**Issue: Session log not updating**
- Solution: Check file permissions, verify path in config

**Issue: Progress calculation incorrect**
- Solution: Run full analysis update, clear cache

**Issue: Git integration fails**
- Solution: Ensure gitpython installed, repo initialized

**Issue: Chart generation errors**
- Solution: Install matplotlib, check data file format

## Advanced Features

### Custom Metrics
Add custom tracking metrics:
```python
from tools.tracking.auto_tracker import ProgressTracker

tracker = ProgressTracker()
tracker.add_metric('custom_metric', calculate_custom_metric)
tracker.update()
```

### Webhooks
Send progress updates to external services:
```python
# Slack webhook example
from tools.tracking.auto_tracker import ProgressTracker

tracker = ProgressTracker()
tracker.add_webhook('slack', 'https://hooks.slack.com/...')
tracker.update()  # Sends update to Slack
```

### Data Export
Export tracking data for analysis:
```bash
# Export as JSON
python tools/tracking/auto_tracker.py --export json --output tracking_data.json

# Export as CSV
python tools/tracking/auto_tracker.py --export csv --output tracking_data.csv

# Export for spreadsheet
python tools/tracking/auto_tracker.py --export xlsx --output tracking_data.xlsx
```

## Milestone Notifications

Configure milestone notifications:
```json
{
    "milestones": [
        {"percent": 25, "notify": "slack", "message": "Quarter done!"},
        {"percent": 50, "notify": "email", "message": "Halfway there!"},
        {"percent": 75, "notify": "slack", "message": "Three quarters!"},
        {"percent": 100, "notify": "all", "message": "Complete! 🎉"}
    ]
}
```

## Historical Analysis

### Trend Analysis
```bash
# Analyze progress trends
python tools/tracking/auto_tracker.py --trends --period 30d

# Compare velocity across time periods
python tools/tracking/auto_tracker.py --compare-velocity --periods "last week" "this week"

# Identify bottlenecks
python tools/tracking/auto_tracker.py --bottlenecks
```

### Prediction Models
```bash
# Predict completion date
python tools/tracking/auto_tracker.py --predict-completion

# Estimate effort for remaining work
python tools/tracking/auto_tracker.py --estimate-remaining

# Forecast with different scenarios
python tools/tracking/auto_tracker.py --forecast --scenarios optimistic,realistic,pessimistic
```

## Contributing

When adding tracking tools:
1. Integrate with existing metrics
2. Maintain backwards compatibility
3. Document tracked data format
4. Add visualization if appropriate
5. Update configuration schema
6. Add tests for tracking logic
7. Update this README

## Future Development

Planned additions:
- [ ] Real-time dashboard
- [ ] Machine learning predictions
- [ ] Integration with project management tools
- [ ] Automated milestone detection
- [ ] Team collaboration features
- [ ] Mobile progress app
- [ ] Voice logging support
