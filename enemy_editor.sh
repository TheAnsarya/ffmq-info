#!/bin/bash
# FFMQ Enemy Editor Launcher (Linux/Mac)
# Quick launcher for the GUI enemy editor

echo ""
echo "========================================"
echo " FFMQ Enemy Editor"
echo "========================================"
echo ""

# Check if virtual environment exists
if [ -f ".venv/bin/python" ]; then
    echo "Using virtual environment..."
    .venv/bin/python tools/enemy_editor_gui.py
else
    echo "Using system Python..."
    python3 tools/enemy_editor_gui.py
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "========================================"
    echo " Error launching editor!"
    echo "========================================"
    echo ""
    echo "Make sure enemy data is extracted first:"
    echo "  python tools/extraction/extract_enemies.py"
    echo ""
    read -p "Press Enter to continue..."
fi
