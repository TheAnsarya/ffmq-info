# GitHub Integration Tools

This directory contains PowerShell scripts for integrating with GitHub, managing issues, and automating project management tasks.

## Issue Creation

### Granular Issue Creation
- **create_github_granular_issues.ps1** - Create detailed, granular issues
  - Creates fine-grained issues for specific tasks
  - One issue per feature/function/component
  - Automatically labels and categorizes
  - Links related issues
  - Usage: `.\tools\github\create_github_granular_issues.ps1 -Category <category> -Items <items.json>`

### Bulk Issue Creation
- **create_github_issues.ps1** - Create issues in bulk
  - Batch create multiple issues from template
  - Supports CSV/JSON input
  - Applies labels and milestones
  - Assigns to team members
  - Usage: `.\tools\github\create_github_issues.ps1 -InputFile <issues.csv>`

### Sub-Issue Creation
- **create_github_sub_issues.ps1** - Create sub-issues for epics
  - Breaks down epics into smaller tasks
  - Creates hierarchical issue structure
  - Links child issues to parent
  - Tracks completion automatically
  - Usage: `.\tools\github\create_github_sub_issues.ps1 -ParentIssue <number> -SubIssues <tasks.json>`

## Issue Management

### Parent-Child Relationships
- **add_children_to_parent_checklists.ps1** - Add child issues to parent checklists
  - Maintains parent issue checklist
  - Auto-checks completed children
  - Updates parent progress
  - Usage: `.\tools\github\add_children_to_parent_checklists.ps1 -ParentIssue <number>`

- **link_child_issues_to_parents.ps1** - Link child issues to parents
  - Creates bidirectional links
  - Updates issue descriptions
  - Maintains relationship metadata
  - Usage: `.\tools\github\link_child_issues_to_parents.ps1 -Relationships <links.json>`

### Task Management
- **add_tasks_to_child_issues.ps1** - Add tasks to child issues
  - Breaks down child issues into tasks
  - Creates checklists in issue body
  - Tracks task completion
  - Updates status automatically
  - Usage: `.\tools\github\add_tasks_to_child_issues.ps1 -ChildIssue <number> -Tasks <tasks.json>`

## Project Board Management

- **setup_project_board.ps1** - Set up GitHub project board
  - Creates project board with columns
  - Configures automation rules
  - Sets up labels and milestones
  - Populates initial issues
  - Usage: `.\tools\github\setup_project_board.ps1 -BoardName <name> -Config <config.json>`

## Common Workflows

### Create Epic with Sub-Issues
```powershell
# 1. Create parent epic issue
.\tools\github\create_github_issues.ps1 -InputFile epic.json

# 2. Create sub-issues for epic (assuming epic is #100)
.\tools\github\create_github_sub_issues.ps1 -ParentIssue 100 -SubIssues subtasks.json

# 3. Add sub-issues to parent checklist
.\tools\github\add_children_to_parent_checklists.ps1 -ParentIssue 100

# 4. Link everything together
.\tools\github\link_child_issues_to_parents.ps1 -ParentIssue 100
```

### Bulk Issue Creation from Documentation
```powershell
# 1. Generate issue list from undocumented functions
python tools/analysis/analyze_doc_coverage.py --export-issues issues.csv

# 2. Create GitHub issues
.\tools\github\create_github_issues.ps1 -InputFile issues.csv

# 3. Set up on project board
.\tools\github\setup_project_board.ps1 -BoardName "Documentation" -AutoPopulate
```

### Create Bank-Specific Issue Hierarchy
```powershell
# Create epic for Bank $03 documentation
$epic = @{
    title = "Document Bank $03 Functions"
    body = "Complete documentation for all Bank $03 functions"
    labels = @("documentation", "bank-03")
}
$epic | ConvertTo-Json | .\tools\github\create_github_issues.ps1 -Json

# Create sub-issues for each function group
.\tools\github\create_github_granular_issues.ps1 -Category "bank-03" -Granularity function
```

### Set Up New Project Board
```powershell
# Create project board configuration
$config = @{
    name = "FFMQ Disassembly"
    columns = @("To Do", "In Progress", "Review", "Done")
    automation = @{
        "To Do" = "newly_added"
        "In Progress" = "reopened"
        "Done" = "closed"
    }
    labels = @(
        @{name="documentation"; color="0075ca"},
        @{name="bug"; color="d73a4a"},
        @{name="enhancement"; color="a2eeef"}
    )
}
$config | ConvertTo-Json | Out-File project_config.json

# Set up board
.\tools\github\setup_project_board.ps1 -Config project_config.json
```

## Input File Formats

### Issues CSV Format
```csv
Title,Body,Labels,Milestone,Assignee
"Document Bank $00 Functions","Document all functions in Bank $00","documentation,priority-high",v1.0,username
"Fix label conflict","Resolve duplicate label in bank01.asm","bug",v1.0,username
```

### Issues JSON Format
```json
{
    "issues": [
        {
            "title": "Document Bank $00 Functions",
            "body": "Document all functions in Bank $00\n\n## Functions\n- Func_8000\n- Func_8100\n- ...",
            "labels": ["documentation", "priority-high"],
            "milestone": "v1.0",
            "assignees": ["username"]
        }
    ]
}
```

### Sub-Issues JSON Format
```json
{
    "parent": 100,
    "children": [
        {
            "title": "Document Func_8000-Func_80FF",
            "body": "Document functions in range $8000-$80FF",
            "labels": ["documentation"],
            "tasks": [
                "Func_8000 - Main initialization",
                "Func_8020 - System setup",
                "Func_8040 - DMA configuration"
            ]
        }
    ]
}
```

### Project Board Config Format
```json
{
    "name": "FFMQ Disassembly",
    "description": "Track disassembly progress",
    "columns": [
        {"name": "To Do", "automation": "newly_added"},
        {"name": "In Progress", "automation": "reopened"},
        {"name": "Review", "automation": null},
        {"name": "Done", "automation": "closed"}
    ],
    "labels": [
        {"name": "documentation", "color": "0075ca", "description": "Documentation improvements"},
        {"name": "bug", "color": "d73a4a", "description": "Something isn't working"},
        {"name": "enhancement", "color": "a2eeef", "description": "New feature or request"}
    ],
    "milestones": [
        {"title": "v1.0", "description": "First complete disassembly", "due_on": "2025-12-31"}
    ]
}
```

## GitHub API Configuration

### Authentication
Set up GitHub Personal Access Token:
```powershell
# Set environment variable
$env:GITHUB_TOKEN = "ghp_your_token_here"

# Or store in config
$config = @{
    token = "ghp_your_token_here"
    repo = "owner/repo"
}
$config | ConvertTo-Json | Out-File ~/.github_config.json
```

### Rate Limiting
Scripts automatically handle GitHub API rate limits:
- Monitors remaining API calls
- Waits when limit approached
- Batches requests when possible
- Logs rate limit status

## Dependencies

- PowerShell 5.1+
- **PowerShellForGitHub** module - `Install-Module -Name PowerShellForGitHub`
- GitHub Personal Access Token with `repo` scope
- Internet connection

## See Also

- **GitHub API Documentation** - https://docs.github.com/en/rest
- **PowerShellForGitHub** - https://github.com/microsoft/PowerShellForGitHub
- **docs/project-management/** - For project management workflows
- **.github/** - For GitHub Actions workflows

## Tips and Best Practices

### Issue Creation
- Use descriptive titles (50 chars max)
- Include context in issue body
- Apply appropriate labels
- Link related issues
- Assign to team members when known

### Issue Hierarchy
- Use epics for large features
- Break down into manageable sub-issues
- Keep hierarchy depth reasonable (2-3 levels max)
- Update parent checklist as children complete

### Labels
- Use consistent labeling scheme
- Create labels for: type, priority, component, bank
- Color-code by category
- Document label meanings

### Milestones
- Create milestones for versions/sprints
- Set realistic due dates
- Assign issues to milestones
- Track milestone progress

### Automation
- Set up automation rules for common workflows
- Use GitHub Actions for CI/CD integration
- Automate issue labeling where possible
- Create templates for common issue types

## Troubleshooting

**Issue: "Authentication failed"**
- Solution: Check GITHUB_TOKEN is set and valid

**Issue: "Rate limit exceeded"**
- Solution: Wait for rate limit reset, or use authenticated requests

**Issue: "Repository not found"**
- Solution: Verify repo name format (owner/repo), check token permissions

**Issue: "Issue creation fails"**
- Solution: Check JSON/CSV format, verify required fields

## Advanced Features

### Custom Issue Templates
Create reusable issue templates:
```powershell
# Define template
$template = @{
    title = "Document {{bank}} Functions"
    body = @"
## Bank: {{bank}}
## Status: Not Started

### Functions to Document:
{{functions}}

### Completion Checklist:
- [ ] All functions documented
- [ ] Cross-references added
- [ ] Examples provided
- [ ] Tests created
"@
    labels = @("documentation", "{{bank}}")
}

# Use template
$params = @{
    bank = "Bank $03"
    functions = "- Func_8000\n- Func_8100"
}
$issue = Expand-Template $template $params
Create-GitHubIssue $issue
```

### Batch Operations
```powershell
# Close multiple issues
@(101, 102, 103, 104) | ForEach-Object {
    Close-GitHubIssue -IssueNumber $_ -Comment "Fixed in commit abc123"
}

# Add label to multiple issues
@(105, 106, 107) | ForEach-Object {
    Add-GitHubIssueLabel -IssueNumber $_ -Label "priority-high"
}

# Bulk comment
Get-GitHubIssue -State Open -Label "documentation" | ForEach-Object {
    New-GitHubIssueComment -IssueNumber $_.number -Body "Updated documentation guidelines available"
}
```

### Automated Progress Tracking
```powershell
# Check epic progress
$parent = 100
$children = Get-GitHubIssue | Where-Object { $_.body -match "Parent: #$parent" }
$completed = ($children | Where-Object { $_.state -eq "closed" }).Count
$total = $children.Count
$percent = [math]::Round(($completed / $total) * 100)

# Update parent issue
Update-GitHubIssue -IssueNumber $parent -Body "Progress: $percent% ($completed/$total)"
```

## Contributing

When modifying GitHub integration tools:
1. Follow PowerShell best practices
2. Handle API errors gracefully
3. Respect rate limits
4. Log all operations
5. Add help documentation
6. Test with various inputs
7. Update this README

## Future Development

Planned additions:
- [ ] GitHub Projects v2 integration
- [ ] Automated issue triage
- [ ] Machine learning for issue categorization
- [ ] Integration with other project management tools
- [ ] Visual dependency graphing
- [ ] Automated progress reports
- [ ] Slack/Discord notifications
- [ ] Custom GitHub App
