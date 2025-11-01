# Copilot Chat History

This folder contains saved conversations with GitHub Copilot to track the development progress and decisions made during the FFMQ SNES development project.

## Auto-Update System 🤖

**Chat logs are now automatically updated!** The system tracks:
- ✅ **Every git commit** - Automatically logged via git hook
- ✅ **Significant changes** - Manual logging with helper script
- ✅ **Questions & answers** - Track decisions and research
- ✅ **Daily sessions** - Organized by date for easy reference

### Quick Start

**No setup needed for commits** - They're logged automatically!

**For manual updates:**
```powershell
# Log a change
.\log.ps1 -Type change -Message "Fixed tile extraction bug"

# Log a question
.\log.ps1 -Type question -Message "How does 4BPP work?"

# View today's summary
.\log.ps1 -Type summary
```

See the [detailed README](AUTO-UPDATE-README.md) for complete documentation.

## Purpose

These chat logs serve as:
- **Development Journal** - Track what was done and why
- **Decision Documentation** - Record technical decisions and reasoning
- **Knowledge Base** - Reference for future development
- **Onboarding Resource** - Help new developers understand the project evolution

## File Naming Convention

Files are named using the format: `YYYY-MM-DD-topic-description.md`

Examples:
- `2025-01-24-project-reorganization.md`
- `2025-01-25-graphics-tools-development.md`
- `2025-02-01-text-editing-system.md`

## What's Included

Each chat log typically contains:
- **Session Overview** - High-level summary of the conversation
- **Tasks Completed** - Detailed list of accomplishments
- **Files Created/Modified** - What changed in the codebase
- **Technical Details** - Important implementation notes
- **Next Steps** - What to work on next
- **Issues/Solutions** - Problems encountered and how they were resolved
- **Commands Used** - Useful commands for reference

## How to Use These Logs

### For Reference
Search these logs when you need to:
- Remember why a decision was made
- Find how something was implemented
- Understand the evolution of the project
- Locate specific commands or configurations

### For Continuation
Before starting a new chat session:
1. Review the most recent chat log
2. Check the "Next Steps" section
3. Note any open issues or TODOs
4. Continue from where the previous session left off

### For Onboarding
New team members should:
1. Read logs in chronological order
2. Focus on "Technical Details" sections
3. Run the commands listed to understand the workflow
4. Review "Issues/Solutions" to avoid known pitfalls

## Auto-Save Feature

**Note:** GitHub Copilot does not automatically save chat history to files. To preserve future conversations:

1. **Manual Save:**
   - Copy the conversation content
   - Create a new `.md` file in this folder
   - Use the naming convention above
   - Include key details (overview, tasks, files, etc.)

2. **Request Save:**
   - Ask Copilot: "Save this chat to the copilot-chats folder"
   - Copilot will create a formatted markdown file
   - Review and edit as needed

3. **Session End:**
   - Before closing VS Code or ending a session
   - Request a summary and save
   - Include any unfinished tasks in "Next Steps"

## Current Chat Logs

- **2025-01-24-project-reorganization.md** - Complete project restructuring from legacy to modern SNES development environment. Includes setup of build system, testing environment, and initial tool development.

## Tips for Future Chats

### Good Practices
- ✅ Save at logical stopping points (completed features)
- ✅ Include context about what you were trying to achieve
- ✅ Note any unusual problems or solutions
- ✅ List exact commands that worked
- ✅ Document configuration changes

### What to Include
- Session date and main topic
- Todo items completed/started
- Files created or significantly modified
- Tools or dependencies added
- Build/test results
- Next planned work

### What to Avoid
- ❌ Saving every minor conversation
- ❌ Including sensitive information
- ❌ Duplicate information across logs
- ❌ Vague descriptions without context

## Integration with Todo List

These chat logs complement the project's todo list:
- Todo list (`manage_todo_list`) = What needs to be done
- Chat logs = How it was done and why

Cross-reference between them for complete project understanding.

## Maintenance

### Monthly Review
- Consolidate related sessions if needed
- Archive very old logs to `archive/` subfolder
- Update this README with new logs
- Remove outdated information

### Backup
These chat logs are part of the git repository and should be:
- Committed with meaningful messages
- Pushed to remote repository
- Included in project backups

## Questions?

If you're unsure about:
- What to include in a chat log
- How detailed to be
- When to save a conversation

**Rule of thumb:** If it took more than 15 minutes and produced code or made decisions, save it!

---

**Last Updated:** January 24, 2025  
**Chat Logs Count:** 1  
**Project Phase:** Graphics Tools Development
