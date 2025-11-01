# Documentation Templates

**Purpose**: Standardized templates for creating consistent, high-quality documentation  
**Created**: November 1, 2025  
**Issue**: #18 - Documentation Planning and Templates

## Available Templates

### 1. System Documentation Template
**File**: `SYSTEM_DOCUMENTATION_TEMPLATE.md`  
**Use For**: Architecture docs, system overviews, technical specifications  
**Examples**: ARCHITECTURE.md, BUILD_SYSTEM.md, ROM_STRUCTURE.md

**Sections Included**:
- Quick Reference
- Introduction & Prerequisites
- System Architecture
- Components (detailed)
- Data Structures
- Workflows
- Examples
- Troubleshooting
- Related Documentation

### 2. Guide Document Template
**File**: `GUIDE_DOCUMENT_TEMPLATE.md`  
**Use For**: Step-by-step tutorials, how-to guides, walkthroughs  
**Examples**: BUILD_GUIDE.md, MODDING_GUIDE.md, GRAPHICS_EXTRACTION_GUIDE.md

**Sections Included**:
- Learning Outcomes
- Prerequisites & Setup
- Step-by-Step Instructions
- Examples
- Troubleshooting
- Tips & Best Practices
- Next Steps
- FAQ

### 3. Reference Document Template
**File**: `REFERENCE_DOCUMENT_TEMPLATE.md`  
**Use For**: Technical references, lookup tables, API docs  
**Examples**: RAM_MAP.md, ROM_DATA_MAP.md, FUNCTION_INDEX.md

**Sections Included**:
- Quick Lookup Table
- Alphabetical Index
- Detailed Reference (one entry per item)
- Cross-References
- Usage Examples
- Memory Maps

## How to Use Templates

### 1. Copy the Template
```bash
# Copy template to your new document
cp docs/templates/SYSTEM_DOCUMENTATION_TEMPLATE.md docs/YOUR_NEW_DOC.md
```

### 2. Fill in the Blanks
- Replace all `[placeholders]` with actual content
- Remove sections that don't apply
- Add custom sections if needed
- Follow the structure and formatting

### 3. Update Metadata
- Set the status (Draft/In Progress/Complete)
- Add your name as author
- Link related issues
- Set the date

### 4. Peer Review
- Have someone review for clarity
- Check that all required sections are complete
- Verify examples work
- Ensure cross-references are correct

## Template Selection Guide

### Choose SYSTEM_DOCUMENTATION_TEMPLATE when:
- ✅ Documenting a system or subsystem
- ✅ Explaining architecture
- ✅ Describing how components interact
- ✅ Need detailed technical specifications
- ✅ Target audience: developers/maintainers

### Choose GUIDE_DOCUMENT_TEMPLATE when:
- ✅ Teaching someone how to do something
- ✅ Step-by-step instructions needed
- ✅ Hands-on tutorial or walkthrough
- ✅ Examples are essential
- ✅ Target audience: users/contributors

### Choose REFERENCE_DOCUMENT_TEMPLATE when:
- ✅ Creating lookup tables
- ✅ Documenting APIs or functions
- ✅ Memory maps or data structures
- ✅ Need quick-reference format
- ✅ Target audience: implementers

## Documentation Standards

### Required Elements
All documentation must include:
- [ ] Clear title and purpose
- [ ] Last updated date
- [ ] Table of contents (if >500 words)
- [ ] Code examples (if applicable)
- [ ] Links to related docs
- [ ] Author/maintainer information

### Formatting Standards
- **Headings**: Use ATX-style (`#`, `##`, `###`)
- **Code Blocks**: Always specify language
- **Links**: Use reference-style for repeated links
- **Tables**: Use GitHub Flavored Markdown
- **Lists**: Use `-` for unordered, `1.` for ordered

### Writing Style
- **Voice**: Second person ("you") for guides, third person for technical docs
- **Tense**: Present tense
- **Tone**: Professional but friendly
- **Clarity**: Short sentences, avoid jargon
- **Examples**: Always include working examples

## Quality Checklist

Before marking documentation as complete:

### Content
- [ ] All placeholders replaced
- [ ] All sections complete or removed if not applicable
- [ ] Examples tested and working
- [ ] Cross-references verified
- [ ] No TODO/FIXME markers remaining

### Formatting
- [ ] Markdown renders correctly
- [ ] Code blocks have language specified
- [ ] Tables are properly formatted
- [ ] Links work
- [ ] Images (if any) display correctly

### Accuracy
- [ ] Technical details verified
- [ ] Code examples tested
- [ ] Commands/scripts work as documented
- [ ] Version numbers current
- [ ] File paths correct

### Usability
- [ ] Table of contents complete
- [ ] Navigation links work
- [ ] Search-friendly (good headings)
- [ ] Beginner-friendly (or clearly marked as advanced)
- [ ] Peer reviewed

## Maintenance

### When to Update Documentation
- Code changes affect documented behavior
- New features added
- Bugs fixed that were documented as "known issues"
- User feedback indicates confusion
- Every 3 months (review for currency)

### Version Control
- Update "Last Updated" date
- Add entry to Version History table
- Note what changed
- Link to related commits/issues

## Examples

### Good Documentation Example
```markdown
## Installing the Build Tools

**Estimated Time**: 10 minutes  
**Prerequisites**: Python 3.8+

### Step 1: Install Python

Download Python from [python.org](https://python.org):

Windows:
\`\`\`powershell
choco install python
\`\`\`

Verify installation:
\`\`\`bash
python --version
# Expected: Python 3.8.0 or higher
\`\`\`
```

### Poor Documentation Example (Don't Do This)
```markdown
## Installing

Install python and stuff. Use the command to install. Make sure it works.
```

## Getting Help

### Questions About Templates
- Open an issue with label `documentation`
- Ask in discussion forums
- Contact documentation maintainer

### Suggesting Improvements
- Fork and submit PR with changes
- Explain why the change improves template
- Provide examples of improvement

---

**Maintained By**: Documentation Team  
**Last Updated**: November 1, 2025  
**Related Issues**: #18, #19, #20, #21, #22
