# Setting Up FFMQ Disassembly Project Board

## ✅ Issues Created Successfully!

**12+ issues have been created** on GitHub. Now let's set up a Kanban board to track progress.

---

## 🎯 Quick Setup Guide

### **Option 1: Web Interface (Recommended - 5 minutes)**

1. **Go to Projects page**:
   - URL: https://github.com/TheAnsarya/ffmq-info/projects
   - Or: Click "Projects" tab at top of repository

2. **Create New Project**:
   - Click green **"New project"** button
   - Select **"Board"** template (classic Kanban layout)
   - Name: **"FFMQ Disassembly Progress"**
   - Click **"Create project"**

3. **Configure Columns** (rename default columns):
   - **📋 Backlog** (was "Todo") - Future tasks, not ready to start
   - **📝 Ready** (was "Ready") - Planned, ready to begin
   - **🔄 In Progress** (was "In Progress") - Currently working on
   - **👀 Review** (new column) - Completed, needs verification
   - **✅ Done** (was "Done") - Fully complete

4. **Add Issues to Board**:
   - Click **"Add item"** in each column
   - Type `#` to see issue list
   - Or drag from the right sidebar

5. **Organize Issues by Priority**:

   **📝 Ready (High Priority - Start Here)**:
   - #1 - 🎨 ASM Code Formatting
   - #2 - 📚 Basic Documentation
   - (And the Code Labeling issue if it exists)

   **📋 Backlog (Medium Priority)**:
   - #3 - 🏷️ Memory Address Labels
   - #4 - 🖼️ Graphics Extraction
   - #5 - 📦 Data Extraction
   - #11 - 🔄 Asset Build System

   **📋 Backlog (Low Priority)**:
   - #6 - 🔍 Bank 04 Disassembly
   - #7 - 🔍 Bank 05 Disassembly
   - #8 - 🔍 Bank 06 Disassembly
   - #9 - 🔍 Bank 0E Disassembly
   - #10 - 🔍 Bank 0F Disassembly
   - #12 - 📚 Comprehensive Documentation

---

## 🚀 Workflow Setup

### **Recommended Workflow**

1. **Backlog** → Ideas, future work, not prioritized
2. **Ready** → Prioritized, ready to start when bandwidth available
3. **In Progress** → Actively working (limit to 1-3 items!)
4. **Review** → Code complete, needs testing/verification
5. **Done** → Tested, verified, merged, closed

### **Using the Board**

#### **Starting Work on an Issue**:
```powershell
# 1. Pick issue from "Ready" column
# 2. Move to "In Progress" on board
# 3. Create branch
git checkout -b issue-1-asm-formatting

# 4. Work on the task...
```

#### **Completing Work**:
```powershell
# 1. Commit with issue reference
git commit -m "Add .editorconfig for ASM formatting (#1)"

# 2. Push and create PR
git push -u origin issue-1-asm-formatting
gh pr create --title "ASM formatting standardization" --body "Closes #1"

# 3. Move issue to "Review" on board
# 4. After PR merged, issue auto-moves to "Done"
```

---

## 🔧 Advanced: GitHub CLI (Beta)

If you want to try the GitHub CLI for project management:

```powershell
# List projects (if any exist)
gh project list --owner TheAnsarya

# View project (after creation via web)
gh project view [PROJECT_NUMBER]

# Add issue to project (manual for now)
# This is still in beta and may not work perfectly
```

**Note**: For now, the web interface is more reliable for project board setup.

---

## 📊 Project Board Layout

Once set up, your board should look like this:

```
┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│  📋 Backlog │  📝 Ready   │ 🔄 In Prog. │  👀 Review  │   ✅ Done   │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ #3 Memory   │ #1 ASM      │             │             │             │
│ #4 Graphics │   Format    │             │             │             │
│ #5 Data     │ #2 Basic    │             │             │             │
│ #6 Bank 04  │   Docs      │             │             │             │
│ #7 Bank 05  │             │             │             │             │
│ #8 Bank 06  │             │             │             │             │
│ #9 Bank 0E  │             │             │             │             │
│ #10 Bank 0F │             │             │             │             │
│ #11 Build   │             │             │             │             │
│ #12 Comp    │             │             │             │             │
│     Docs    │             │             │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

---

## 💡 Tips for Managing the Board

1. **Limit WIP**: Keep 1-3 items in "In Progress" max
2. **Update Regularly**: Move cards as status changes
3. **Use Labels**: Filter by priority, type, effort
4. **Add Notes**: Comment on issues with progress updates
5. **Link PRs**: PRs automatically link when you use "Closes #N"
6. **Archive Done**: Periodically archive old "Done" items to keep board clean

---

## 🎯 Automation Ideas (Optional)

You can set up GitHub Actions to automate board updates:

- **Auto-move to "In Progress"** when PR created
- **Auto-move to "Review"** when PR is ready for review
- **Auto-move to "Done"** when PR merged
- **Auto-add labels** based on file paths changed

Example automation file: `.github/workflows/project-automation.yml`

---

## ✅ Checklist for Setup

- [ ] Go to https://github.com/TheAnsarya/ffmq-info/projects
- [ ] Click "New project" → Select "Board"
- [ ] Name it "FFMQ Disassembly Progress"
- [ ] Rename columns: Backlog, Ready, In Progress, Review, Done
- [ ] Add all 12+ issues to appropriate columns
- [ ] Prioritize: High → Ready, Medium/Low → Backlog
- [ ] Start working on first issue from Ready column!

---

## 🚀 Ready to Start!

Once your board is set up:

1. **Pick Issue #1 or #2** from Ready column
2. **Move to In Progress**
3. **Create branch and start working**
4. **Update board as you progress**
5. **Celebrate when you move it to Done!** 🎉

---

**Setup Time**: ~5 minutes via web interface  
**Benefit**: Visual progress tracking, clear priorities, team collaboration

**Go set it up now!** → https://github.com/TheAnsarya/ffmq-info/projects
