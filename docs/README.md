# Documentation Index

Welcome to the Final Fantasy Mystic Quest Disassembly Project documentation!

This index provides an organized view of all available documentation to help you navigate the project.

## 📖 Quick Start

**New to the project?** Start here:

1. **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - How to build the ROM from source
2. **[CONTRIBUTING.md](../CONTRIBUTING.md)** - How to contribute to the project
3. **[MODDING_GUIDE.md](MODDING_GUIDE.md)** - How to create your own mods

## 📚 Documentation Categories

### 🏗️ Build System

Documentation for building and assembling the ROM:

- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Comprehensive build instructions
  - Prerequisites and setup
  - Step-by-step build process
  - Build options and verification
  - Platform-specific notes
  - Troubleshooting common issues

- **[BUILD_SYSTEM.md](BUILD_SYSTEM.md)** - Build system architecture
  - How the build system works internally
  - Build scripts and their roles
  - Integration with asar assembler

- **[BUILD_INTEGRATION_SUMMARY.md](BUILD_INTEGRATION_SUMMARY.md)** - Build integration details
  - How different components integrate
  - Build pipeline overview

- **[BYTE_PERFECT_REBUILD.md](BYTE_PERFECT_REBUILD.md)** - Achieving byte-perfect ROMs
  - Why byte-perfect rebuilds matter
  - How to verify your build
  - Troubleshooting build differences

- **[BUILD_SYSTEM_V2_SUMMARY.md](BUILD_SYSTEM_V2_SUMMARY.md)** - Build system version 2 updates

- **[build-instructions.md](build-instructions.md)** - Quick build reference

### 💻 Code & Development

Documentation for working with the codebase:

- **[CONTRIBUTING.md](../CONTRIBUTING.md)** ⭐ - **Start here for contributing!**
  - Development environment setup
  - Code style guidelines (ASM, Python, PowerShell)
  - Documentation standards
  - Commit message format
  - Pull request process
  - Testing requirements
  - Label naming conventions

- **[coding-standards.md](coding-standards.md)** - Detailed coding standards
  - Assembly code conventions
  - Comment style and documentation
  - File organization

### 🎨 Modding & Customization

Learn how to modify the game:

- **[MODDING_GUIDE.md](MODDING_GUIDE.md)** ⭐ - **Complete modding guide!**
  - Character stats modification
  - Dialogue and text editing
  - Graphics replacement (sprites, tiles, palettes)
  - Items and equipment creation
  - Spells and abilities
  - Maps and encounters
  - Example mods (Hard Mode, Easy Mode, Randomizer)
  - Common pitfalls and best practices

### 🖼️ Graphics & Assets

Working with game graphics and assets:

- **[graphics-format.md](graphics-format.md)** - SNES graphics format details
  - Tile format (4bpp)
  - Palette structure
  - Graphics memory organization

- **[graphics-quickstart.md](graphics-quickstart.md)** - Quick start for graphics work

- **[GRAPHICS_PALETTE_WORKFLOW.md](GRAPHICS_PALETTE_WORKFLOW.md)** - Palette workflow guide

- **[PALETTE_EXTRACTION_SUMMARY.md](PALETTE_EXTRACTION_SUMMARY.md)** - Palette extraction process

- **[EXTRACTION_COMPLETE.md](EXTRACTION_COMPLETE.md)** - Asset extraction status

### 📊 Data Structures

Understanding game data:

- **[data_formats.md](data_formats.md)** - Game data format specifications
  - Character data structures
  - Enemy stats format
  - Item and equipment data
  - Map data format
  - Text encoding

### 🔧 Tools & Automation

Documentation for project tools:

- **[INSTALL_ASAR.md](INSTALL_ASAR.md)** - Installing the asar assembler

- **[testing.md](testing.md)** - Testing framework and procedures

- **[AUTOMATIC-TRACKING.md](AUTOMATIC-TRACKING.md)** - Automated progress tracking

- **[KEEP-LOGS-UPDATED.md](KEEP-LOGS-UPDATED.md)** - Log maintenance guidelines

### 📋 Project Management

GitHub and project organization:

- **[GITHUB_SETUP_GUIDE.md](GITHUB_SETUP_GUIDE.md)** - GitHub repository setup

- **[GITHUB_SETUP_SUMMARY.md](GITHUB_SETUP_SUMMARY.md)** - GitHub setup summary

- **[GITHUB_SUB_ISSUES_GUIDE.md](GITHUB_SUB_ISSUES_GUIDE.md)** - Managing sub-issues

- **[GRANULAR_ISSUES_SUMMARY.md](GRANULAR_ISSUES_SUMMARY.md)** - Issue organization strategy

- **[PROJECT_BOARD_SETUP.md](PROJECT_BOARD_SETUP.md)** - GitHub project board setup

### 📈 Progress & Status

Tracking project progress:

- **[HONEST_PROGRESS.md](HONEST_PROGRESS.md)** - Honest project status assessment

- **[MODERN_BUILD_STATUS.md](MODERN_BUILD_STATUS.md)** - Current build system status

- **[MODERN_SNES_TOOLCHAIN.md](MODERN_SNES_TOOLCHAIN.md)** - Toolchain overview

- **[ROM_CONFIG_VERIFICATION.md](ROM_CONFIG_VERIFICATION.md)** - ROM configuration checks

- **[integration-complete.md](integration-complete.md)** - Integration milestones

### 📝 Session Logs

Daily development logs and chat sessions:

- **[session-logs/](session-logs/)** - Directory containing daily session logs
  - Detailed records of development sessions
  - Progress tracking
  - Decisions and discussions

## 🎯 Recommended Reading Order

### For New Contributors

1. **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Get the project building
2. **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Learn contribution guidelines
3. **[coding-standards.md](coding-standards.md)** - Understand code standards
4. **[data_formats.md](data_formats.md)** - Learn game data structures
5. Pick an area to work on! (graphics, documentation, disassembly)

### For Modders

1. **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Set up your environment
2. **[MODDING_GUIDE.md](MODDING_GUIDE.md)** - Learn modding techniques
3. **[data_formats.md](data_formats.md)** - Understand data structures
4. **[graphics-format.md](graphics-format.md)** - If editing graphics
5. Start creating your mod!

### For Researchers

1. **[data_formats.md](data_formats.md)** - Game data organization
2. **[graphics-format.md](graphics-format.md)** - Graphics system
3. **[BYTE_PERFECT_REBUILD.md](BYTE_PERFECT_REBUILD.md)** - Verification methods
4. Review source code in `src/asm/` directory
5. Check session logs for research notes

## 🔗 Related Resources

### External Documentation

- **SNES Development**:
  - [Fullsnes Documentation](https://problemkaputt.de/fullsnes.htm)
  - [65816 Opcodes Reference](http://www.oxyron.de/html/opcodes816.html)
  - [SNES Assembly Tutorial](https://www.chibiakumas.com/snes/)

- **ROM Hacking**:
  - [ROMhacking.net Resources](https://www.romhacking.net/)
  - [SMW Central Forums](https://www.smwcentral.net/)
  - [asar Assembler Docs](https://github.com/RPGHacker/asar)

### Tools

- **[asar](https://github.com/RPGHacker/asar)** - SNES assembler
- **[Mesen-S](https://github.com/SourMesen/Mesen-S)** - SNES emulator/debugger
- **[Diztinguish](https://github.com/Dotsarecool/DiztinGUIsh)** - Disassembly tool
- **[YY-CHR](https://www.romhacking.net/utilities/119/)** - Graphics editor

## 📧 Getting Help

If you can't find what you're looking for:

1. **Search this documentation** using your editor's search (Ctrl+F)
2. **Check GitHub Issues** for related discussions
3. **Search session logs** in `docs/session-logs/` for context
4. **Ask on GitHub** by creating an issue with the `question` label
5. **Check CONTRIBUTING.md** for contribution questions

## 🤝 Contributing to Documentation

Found an error? Have a suggestion? Want to add documentation?

1. See **[CONTRIBUTING.md](../CONTRIBUTING.md)** for guidelines
2. Follow the **[Documentation Standards](../CONTRIBUTING.md#documentation-standards)**
3. Submit a pull request with your improvements
4. Add links to this index if creating new docs

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

**Last Updated**: November 1, 2025

**Need something specific?** Use Ctrl+F to search this page or check the category listings above!
