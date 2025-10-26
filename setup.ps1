# Final Fantasy Mystic Quest - Development Environment Setup (PowerShell)
# Modern PowerShell script for setting up the FFMQ development environment

Write-Host "Final Fantasy Mystic Quest - Development Environment Setup" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "Makefile")) {
    Write-Host "Error: Makefile not found. Please run this from the project root directory." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check for Python
Write-Host "Checking for Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Python found: $pythonVersion" -ForegroundColor Green
    } else {
        throw "Python not found"
    }
} catch {
    Write-Host "Error: Python not found. Please install Python 3.x" -ForegroundColor Red
    Write-Host "Download from: https://python.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

# Check for Git (since we're using it)
Write-Host "Checking for Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Git found: $gitVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Git not found. Some features may not work." -ForegroundColor Yellow
}
Write-Host ""

# Setup directories
Write-Host "Setting up directories..." -ForegroundColor Yellow

$directories = @("roms", "build", "assets", "assets\graphics", "assets\text", "assets\music")

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        Write-Host "Creating $dir directory..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Check ROM directory
if (-not (Get-ChildItem -Path "roms" -Filter "*.sfc" -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "ROM files not found in roms directory." -ForegroundColor Yellow
    Write-Host "Please copy your Final Fantasy Mystic Quest ROM files to the ~roms directory:" -ForegroundColor White
    Write-Host "  - Final Fantasy - Mystic Quest (U) (V1.1).sfc (recommended)" -ForegroundColor White
    Write-Host "  - Other regional versions (optional)" -ForegroundColor White
    Write-Host ""
    
    # Offer to open the ROM directory
    $openDir = Read-Host "Open ~roms directory in Explorer? (y/n)"
    if ($openDir -eq "y" -or $openDir -eq "Y") {
        Start-Process explorer.exe -ArgumentList (Resolve-Path "~roms").Path
    }
    
    Read-Host "Press Enter when you have copied the ROM files"
}

Write-Host ""
Write-Host "Checking ROM files..." -ForegroundColor Yellow
try {
    $result = python tools\setup_rom.py "~roms"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ROM setup completed with warnings. Check the output above." -ForegroundColor Yellow
    } else {
        Write-Host "ROM setup completed successfully!" -ForegroundColor Green
    }
} catch {
    Write-Host "ROM setup failed. Please check the ROM files and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Development Environment Setup Complete!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Available commands:" -ForegroundColor White
Write-Host "  make setup-env     - Check development tools" -ForegroundColor Cyan
Write-Host "  make extract-assets - Extract graphics, text, and music" -ForegroundColor Cyan
Write-Host "  make rom           - Build the ROM" -ForegroundColor Cyan
Write-Host "  make test          - Test ROM in emulator" -ForegroundColor Cyan
Write-Host "  make clean         - Clean build files" -ForegroundColor Cyan
Write-Host "  make help          - Show all available commands" -ForegroundColor Cyan
Write-Host ""

Write-Host "Tool requirements:" -ForegroundColor White
Write-Host "  - ca65/cc65: https://cc65.github.io/" -ForegroundColor Yellow
Write-Host "  - asar: https://github.com/RPGHacker/asar" -ForegroundColor Yellow
Write-Host "  - MesenS (optional): https://github.com/SourMesen/Mesen-S" -ForegroundColor Yellow
Write-Host ""

Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Install the required tools (see URLs above)" -ForegroundColor White
Write-Host "  2. Run: make setup-env" -ForegroundColor White
Write-Host "  3. Run: make extract-assets" -ForegroundColor White
Write-Host "  4. Run: make rom" -ForegroundColor White
Write-Host ""

# Check if Make is available
Write-Host "Checking for Make..." -ForegroundColor Yellow
try {
    $makeVersion = make --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Make found!" -ForegroundColor Green
        Write-Host ""
        $runSetup = Read-Host "Run 'make setup-env' now to check for development tools? (y/n)"
        if ($runSetup -eq "y" -or $runSetup -eq "Y") {
            Write-Host ""
            make setup-env
        }
    }
} catch {
    Write-Host "Make not found. You can use the individual Python tools instead:" -ForegroundColor Yellow
    Write-Host "  python tools\setup_rom.py" -ForegroundColor Cyan
    Write-Host "  python tools\extract_graphics.py" -ForegroundColor Cyan
    Write-Host "  python tools\extract_text.py" -ForegroundColor Cyan
    Write-Host "  python tools\extract_music.py" -ForegroundColor Cyan
}

Write-Host ""
Read-Host "Press Enter to finish"