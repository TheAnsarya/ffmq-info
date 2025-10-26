# FFMQ Modern Build System - Quick Entry Point
# Usage: .\modern-build.ps1 <target>
# Targets: build, watch, dev, test, verify, compare, extract, status

param([string]$Target = "help")

# Load the comprehensive build system
& "$PSScriptRoot\tools\modern-build-system.ps1" $Target @args
