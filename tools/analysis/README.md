# Analysis Tools

This directory contains tools for analyzing ROM data, project status, code coverage, and various game mechanics.

## ⭐ Event System Analysis (NEW)

### **event_system_analyzer.py** - Comprehensive Event System Analyzer
**STATUS**: ✅ Production-ready  
**DOCUMENTATION**: See `docs/EVENT_SYSTEM_QUICK_START.md` and `docs/EVENT_SYSTEM_ARCHITECTURE.md`

**Purpose**: Analyzes FFMQ's dialog system as a complete event scripting system, treating dialogs as event scripts with embedded text functionality.

**Key Features**:
- Analyzes all 256 dialogs as event scripts (not just text)
- Extracts 48 different event commands with parameters
- Builds subroutine call graphs (command 0x08 - 500+ uses)
- Tracks memory modifications (command 0x0E - 100+ uses)
- Recognizes parameter patterns across all commands
- Generates 6 comprehensive output files

**Quick Start**:
```bash
# From project root
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl

# Analyze first 100 dialogs only
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl --count 100

# Custom output directory
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl --output analysis/events
```

**Outputs** (6 files generated):
1. **event_system_statistics.json** - Overall statistics, command usage, category breakdowns
2. **event_scripts.json** - Detailed per-dialog analysis with all commands and parameters
3. **EVENT_COMMAND_REFERENCE.md** - Auto-generated command documentation
4. **subroutine_call_graph.csv** - Subroutine call mapping (identify reusable components)
5. **memory_modification_map.csv** - Memory write tracking (quest progression analysis)
6. **parameter_patterns.csv** - Parameter pattern analysis (identify unknown commands)

**Use Cases**:
- **Unknown Command Identification**: Analyze parameter patterns to determine command purpose
- **Subroutine Mapping**: Find commonly called dialog components (greetings, shop menus, etc.)
- **Quest System Analysis**: Track game state modifications to map quest progression
- **Parameter Type Database**: Build comprehensive parameter type reference
- **Event Editor Support**: Generate specifications for dialog/event editor development

**Documentation**:
- **Quick Start Guide**: `docs/EVENT_SYSTEM_QUICK_START.md` (step-by-step workflows)
- **Architecture Docs**: `docs/EVENT_SYSTEM_ARCHITECTURE.md` (comprehensive system design)
- **Control Code Reference**: `docs/CONTROL_CODE_IDENTIFICATION.md` (48 command catalog)

---

## Project Analysis

### Documentation Analysis
- **analyze_doc_coverage.py** - Analyze documentation coverage
  - Scans codebase for documented vs undocumented code
  - Generates coverage reports
  - Identifies documentation gaps
  - Tracks documentation progress over time
  - Usage: `python tools/analysis/analyze_doc_coverage.py --output coverage_report.md`

- **doc_coverage_analyzer.py** - Advanced documentation analyzer
  - Detailed function/label documentation analysis
  - Cross-reference checking
  - Documentation quality metrics
  - Generates improvement recommendations
  - Usage: `python tools/analysis/doc_coverage_analyzer.py --detail`

### Project Status
- **project_status.py** - Generate project status report
  - Overall project completion percentage
  - Bank-by-bank progress
  - Documentation statistics
  - Test coverage metrics
  - Recent activity summary
  - Usage: `python tools/analysis/project_status.py --output STATUS.md`

- **analyze_project_priorities.py** - Analyze project priorities
  - Identifies high-priority work items
  - Categorizes tasks by importance
  - Estimates work remaining
  - Generates priority-ordered task list
  - Usage: `python tools/analysis/analyze_project_priorities.py --output PRIORITIES.md`

### Code Analysis
- **code_label_analyzer.py** - Analyze code labels and symbols
  - Scans assembly for label usage
  - Identifies unused labels
  - Finds label conflicts
  - Tracks label naming patterns
  - Generates label statistics
  - Usage: `python tools/analysis/code_label_analyzer.py --source src/ --output label_report.txt`

## Common Workflows

### Generate Comprehensive Project Report
```bash
# 1. Analyze documentation coverage
python tools/analysis/analyze_doc_coverage.py --output reports/doc_coverage.md

# 2. Generate project status
python tools/analysis/project_status.py --output STATUS.md

# 3. Analyze priorities
python tools/analysis/analyze_project_priorities.py --output PRIORITIES.md

# 4. Analyze code labels
python tools/analysis/code_label_analyzer.py --source src/ --output reports/labels.txt

# All reports now in reports/ directory
```

### Track Documentation Progress
```bash
# Generate baseline coverage
python tools/analysis/analyze_doc_coverage.py --output reports/coverage_baseline.md

# ... work on documentation ...

# Generate current coverage
python tools/analysis/analyze_doc_coverage.py --output reports/coverage_current.md

# Compare coverage
diff reports/coverage_baseline.md reports/coverage_current.md
```

### Identify High-Priority Work
```bash
# Analyze what needs attention
python tools/analysis/analyze_project_priorities.py --output PRIORITIES.md

# Review PRIORITIES.md to see:
# - Undocumented critical functions
# - Incomplete banks
# - Missing tests
# - Documentation gaps
```

### Audit Code Labels
```bash
# Full label analysis
python tools/analysis/code_label_analyzer.py --source src/ --output label_audit.txt

# Find unused labels
python tools/analysis/code_label_analyzer.py --source src/ --unused-only

# Check for naming conflicts
python tools/analysis/code_label_analyzer.py --source src/ --conflicts

# Generate label statistics
python tools/analysis/code_label_analyzer.py --source src/ --stats
```

## Analysis Reports

### Documentation Coverage Report
```markdown
# Documentation Coverage Report
Generated: 2025-11-07

## Overall Statistics
- Total Functions: 2,486
- Documented: 758 (30.5%)
- Undocumented: 1,728 (69.5%)
- Documentation Lines: 18,342

## Bank Breakdown
- Bank $00: 15/150 (10.0%)
- Bank $01: 42/280 (15.0%)
- Bank $02: 183/420 (43.6%) ⭐
...

## Priority Gaps
1. Bank $01 - Graphics/DMA (critical, 15% done)
2. Bank $00 - Core engine (critical, 10% done)
...
```

### Project Status Report
```markdown
# Project Status
Last Updated: 2025-11-07

## Completion
- Overall: 30.5% (758/2,486 functions)
- Documentation: 18,342 lines
- Tests: 142 passing
- Build: Byte-perfect ✅

## Recent Progress
- Added 183 Bank $02 functions (Update #37)
- Reorganized project structure
- Created comprehensive documentation
...
```

### Priority Analysis
```markdown
# Project Priorities
Generated: 2025-11-07

## High Priority
1. Bank $01 Graphics/DMA (15% done, critical)
   - 238 undocumented functions
   - Core game functionality
   - Estimated: 40 hours

2. Bank $00 Core Engine (10% done, critical)
   - 135 undocumented functions
   - System initialization
   - Estimated: 25 hours
...
```

### Label Analysis Report
```
Label Analysis Report
Generated: 2025-11-07

Total Labels: 1,842
Used: 1,756 (95.3%)
Unused: 86 (4.7%)

Label Categories:
- Functions: 1,024 (55.6%)
- Data: 512 (27.8%)
- Jumps: 306 (16.6%)

Naming Patterns:
- Func_*: 456 labels
- Data_*: 298 labels
- Jump_*: 124 labels
- Custom: 964 labels

Potential Conflicts: 3
- Label_8000 (Bank 00, Bank 01)
- InitData (Bank 02, Bank 03)
- TempBuffer (Bank 00, Bank 04)

Unused Labels:
1. OldTestFunction (src/bank00.asm:1234)
2. UnusedDataTable (src/bank01.asm:567)
...
```

## Analysis Configuration

### analysis_config.json
```json
{
    "source_dirs": ["src/", "data/"],
    "doc_file": "docs/technical/FUNCTION_REFERENCE.md",
    "output_dir": "reports/",
    "exclude_patterns": ["*.bak", "*_old.*"],
    "coverage_thresholds": {
        "excellent": 90,
        "good": 70,
        "acceptable": 50,
        "poor": 30
    },
    "priority_weights": {
        "criticality": 0.5,
        "completeness": 0.3,
        "effort": 0.2
    }
}
```

## Metrics Tracked

### Documentation Metrics
- Total functions/labels
- Documented vs undocumented
- Documentation lines
- Average description length
- Cross-reference count
- Documentation age

### Code Metrics
- Total assembly lines
- Code vs data vs comments
- Label count and types
- Include/import usage
- Bank sizes
- Free space analysis

### Project Metrics
- Completion percentage
- Work velocity (functions/day)
- Estimated completion time
- Test coverage
- Build success rate
- Issue count

## Dependencies

- Python 3.7+
- Standard library only (no pip packages required)
- Access to source files
- Access to documentation files

## See Also

- **tools/tracking/** - For tracking progress over time
- **tools/testing/** - For test coverage analysis
- **docs/status/** - For project status documentation
- **docs/technical/FUNCTION_REFERENCE.md** - Main documentation file

## Tips and Best Practices

### Regular Analysis
- Run coverage analysis weekly
- Update project status after each major update
- Track priorities monthly
- Audit labels before major refactoring

### Using Reports
- Share status reports with team
- Use coverage reports to guide documentation work
- Prioritize based on priority analysis
- Address label conflicts immediately

### Automation
- Add analysis to CI/CD pipeline
- Schedule nightly status reports
- Alert on coverage regression
- Track trends over time

## Advanced Usage

### Custom Metrics
Add custom metrics to analysis:
```python
from tools.analysis.project_status import ProjectAnalyzer

analyzer = ProjectAnalyzer()
analyzer.add_metric('custom_metric', calculate_custom)
report = analyzer.generate_report()
```

### Trend Analysis
Track metrics over time:
```bash
# Daily status generation
python tools/analysis/project_status.py --output reports/status_$(date +%Y%m%d).md

# Generate trend chart
python tools/analysis/generate_trends.py --input reports/status_*.md --output trends.png
```

### Integration with Git
Track documentation coverage per commit:
```bash
git log --oneline | while read commit; do
    git checkout $commit
    python tools/analysis/analyze_doc_coverage.py --brief >> coverage_history.csv
done
```

## Output Formats

### Supported Output Formats
- **Markdown** - `.md` files (default)
- **JSON** - `.json` for programmatic access
- **HTML** - `.html` for web viewing
- **CSV** - `.csv` for spreadsheet analysis
- **Plain Text** - `.txt` for simple viewing

### Format Examples

**JSON Output:**
```json
{
    "generated": "2025-11-07T10:30:00",
    "total_functions": 2486,
    "documented": 758,
    "coverage": 30.5,
    "banks": [
        {"id": "00", "functions": 150, "documented": 15, "coverage": 10.0},
        ...
    ]
}
```

**CSV Output:**
```csv
Bank,Total,Documented,Coverage
00,150,15,10.0
01,280,42,15.0
02,420,183,43.6
...
```

## Troubleshooting

**Issue: Coverage report shows 0%**
- Solution: Check documentation file path in config

**Issue: Label analyzer crashes**
- Solution: Ensure source files have valid assembly syntax

**Issue: Priority analysis incomplete**
- Solution: Verify all required data files exist

**Issue: Outdated statistics**
- Solution: Ensure you're analyzing latest source/docs

## Contributing

When adding analysis tools:
1. Follow naming convention: `analyze_*.py`
2. Support multiple output formats
3. Include progress indicators
4. Add configuration options
5. Document metrics clearly
6. Create visualization where helpful
7. Update this README

## Future Development

Planned additions:
- [ ] Real-time analysis dashboard
- [ ] Automated trend detection
- [ ] Machine learning predictions
- [ ] Integration with project management tools
- [ ] Visual code complexity analysis
- [ ] Automated priority recommendations
- [ ] Natural language report generation
