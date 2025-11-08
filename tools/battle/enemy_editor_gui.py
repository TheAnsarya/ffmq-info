#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FFMQ Enemy Editor - GUI Application
====================================

Visual editor for Final Fantasy Mystic Quest enemy stats.

Features:
  - Browse and edit all 83 enemies
  - Visual element resistance/weakness selection
  - Real-time HP/stat editing
  - One-click export to ASM
  - GameFAQs data comparison
  - Undo/Redo support

Usage:
    python tools/enemy_editor_gui.py

Requirements:
    - Python 3.7+
    - tkinter (usually included with Python)

Author: FFMQ Disassembly Project
Date: 2025-11-02
"""

import sys
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Optional
import tkinter as tk
from tkinter import ttk, messagebox, filedialog


# Element bitfield definitions
ELEMENT_BITS = {
    # Status effects (0x0001-0x0080)
    'Silence': 0x0001,
    'Blind': 0x0002,
    'Poison': 0x0004,
    'Confusion': 0x0008,
    'Sleep': 0x0010,
    'Paralysis': 0x0020,
    'Stone': 0x0040,
    'Doom': 0x0080,
    # Damage types (0x0100-0x0800)
    'Projectile': 0x0100,
    'Bomb': 0x0200,
    'Axe': 0x0400,
    'Zombie': 0x0800,
    # Elements (0x1000-0x8000)
    'Air': 0x1000,
    'Fire': 0x2000,
    'Water': 0x4000,
    'Earth': 0x8000,
}

ELEMENT_NAMES = list(ELEMENT_BITS.keys())


class EnemyEditorApp:
    """Main application class for the enemy editor."""

    def __init__(self, root):
        """Initialize the application."""
        self.root = root
        self.root.title("FFMQ Enemy Editor")
        self.root.geometry("1000x700")

        # Data
        self.enemies = []
        self.current_enemy_idx = 0
        self.modified = False
        self.undo_stack = []

        # Load data
        self.load_enemy_data()

        # Create UI
        self.create_menu()
        self.create_ui()

        # Load first enemy
        self.load_enemy(0)

    def load_enemy_data(self):
        """Load enemy data from JSON."""
        json_path = Path("data/extracted/enemies/enemies.json")

        if not json_path.exists():
            messagebox.showerror(
                "Error",
                f"Enemy data not found!\n\n"
                f"Expected: {json_path}\n\n"
                f"Please run: python tools/extraction/extract_enemies.py"
            )
            sys.exit(1)

        with open(json_path, 'r') as f:
            data = json.load(f)

        self.enemies = data['enemies']
        self.metadata = data.get('metadata', {})

    def save_enemy_data(self):
        """Save enemy data to JSON."""
        json_path = Path("data/extracted/enemies/enemies.json")

        data = {
            'metadata': self.metadata,
            'enemies': self.enemies
        }

        # Backup existing file
        if json_path.exists():
            backup_path = json_path.with_suffix('.json.backup')
            import shutil
            shutil.copy(json_path, backup_path)

        with open(json_path, 'w') as f:
            json.dump(data, f, indent=2)

        self.modified = False
        self.update_title()
        messagebox.showinfo("Success", "Enemy data saved successfully!")

    def create_menu(self):
        """Create the menu bar."""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)

        # File menu
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="Save", command=self.save_enemy_data, accelerator="Ctrl+S")
        file_menu.add_command(label="Export to ASM", command=self.export_to_asm, accelerator="Ctrl+E")
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)

        # Edit menu
        edit_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Edit", menu=edit_menu)
        edit_menu.add_command(label="Undo", command=self.undo, accelerator="Ctrl+Z")
        edit_menu.add_separator()
        edit_menu.add_command(label="Reset Enemy", command=self.reset_enemy)
        edit_menu.add_command(label="Reset All", command=self.reset_all)

        # Tools menu
        tools_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Tools", menu=tools_menu)
        tools_menu.add_command(label="Verify vs GameFAQs", command=self.verify_gamefaqs)
        tools_menu.add_command(label="Test Pipeline", command=self.test_pipeline)

        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="About", command=self.show_about)

        # Keyboard shortcuts
        self.root.bind('<Control-s>', lambda e: self.save_enemy_data())
        self.root.bind('<Control-e>', lambda e: self.export_to_asm())
        self.root.bind('<Control-z>', lambda e: self.undo())

    def create_ui(self):
        """Create the main UI layout."""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(1, weight=1)

        # Enemy selector (left side)
        self.create_enemy_selector(main_frame)

        # Editor panel (right side)
        self.create_editor_panel(main_frame)

        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(self.root, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.grid(row=1, column=0, sticky=(tk.W, tk.E))

    def create_enemy_selector(self, parent):
        """Create the enemy list selector."""
        selector_frame = ttk.LabelFrame(parent, text="Enemies", padding="5")
        selector_frame.grid(row=0, column=0, rowspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 10))

        # Search box
        search_frame = ttk.Frame(selector_frame)
        search_frame.pack(fill=tk.X, pady=(0, 5))

        ttk.Label(search_frame, text="Search:").pack(side=tk.LEFT)
        self.search_var = tk.StringVar()
        self.search_var.trace_add('write', self.filter_enemies)
        search_entry = ttk.Entry(search_frame, textvariable=self.search_var)
        search_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(5, 0))

        # Enemy listbox with scrollbar
        list_frame = ttk.Frame(selector_frame)
        list_frame.pack(fill=tk.BOTH, expand=True)

        scrollbar = ttk.Scrollbar(list_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.enemy_listbox = tk.Listbox(
            list_frame,
            yscrollcommand=scrollbar.set,
            width=25,
            height=35
        )
        self.enemy_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.config(command=self.enemy_listbox.yview)

        # Populate list
        self.populate_enemy_list()

        # Bind selection event
        self.enemy_listbox.bind('<<ListboxSelect>>', self.on_enemy_select)

    def create_editor_panel(self, parent):
        """Create the main editor panel."""
        editor_frame = ttk.Frame(parent)
        editor_frame.grid(row=0, column=1, rowspan=2, sticky=(tk.W, tk.E, tk.N, tk.S))
        editor_frame.columnconfigure(0, weight=1)
        editor_frame.rowconfigure(1, weight=1)

        # Enemy info header
        info_frame = ttk.LabelFrame(editor_frame, text="Enemy Information", padding="10")
        info_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        info_frame.columnconfigure(1, weight=1)

        self.enemy_name_var = tk.StringVar()
        self.enemy_id_var = tk.StringVar()

        ttk.Label(info_frame, text="ID:").grid(row=0, column=0, sticky=tk.W)
        ttk.Label(info_frame, textvariable=self.enemy_id_var).grid(row=0, column=1, sticky=tk.W, padx=(5, 0))

        ttk.Label(info_frame, text="Name:").grid(row=1, column=0, sticky=tk.W)
        ttk.Entry(info_frame, textvariable=self.enemy_name_var, width=30).grid(row=1, column=1, sticky=(tk.W, tk.E), padx=(5, 0))

        # Notebook for different editor sections
        notebook = ttk.Notebook(editor_frame)
        notebook.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Stats tab
        stats_tab = ttk.Frame(notebook, padding="10")
        notebook.add(stats_tab, text="Stats")
        self.create_stats_tab(stats_tab)

        # Resistances tab
        resist_tab = ttk.Frame(notebook, padding="10")
        notebook.add(resist_tab, text="Resistances")
        self.create_resistance_tab(resist_tab)

        # Weaknesses tab
        weak_tab = ttk.Frame(notebook, padding="10")
        notebook.add(weak_tab, text="Weaknesses")
        self.create_weakness_tab(weak_tab)

        # Level/Rewards tab
        rewards_tab = ttk.Frame(notebook, padding="10")
        notebook.add(rewards_tab, text="Level & Rewards")
        self.create_rewards_tab(rewards_tab)

        # Action buttons
        button_frame = ttk.Frame(editor_frame, padding="5")
        button_frame.grid(row=2, column=0, sticky=(tk.W, tk.E))

        ttk.Button(button_frame, text="Previous Enemy", command=self.prev_enemy).pack(side=tk.LEFT, padx=2)
        ttk.Button(button_frame, text="Next Enemy", command=self.next_enemy).pack(side=tk.LEFT, padx=2)
        ttk.Button(button_frame, text="Apply Changes", command=self.apply_changes).pack(side=tk.RIGHT, padx=2)

    def create_stats_tab(self, parent):
        """Create the stats editor tab."""
        # Create a scrollable frame
        canvas = tk.Canvas(parent)
        scrollbar = ttk.Scrollbar(parent, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        # Stats fields
        self.stat_vars = {}
        stats_config = [
            ('hp', 'HP', 0, 65535),
            ('attack', 'Attack', 0, 255),
            ('defense', 'Defense', 0, 255),
            ('speed', 'Speed', 0, 255),
            ('magic', 'Magic', 0, 255),
            ('accuracy', 'Accuracy', 0, 255),
            ('evade', 'Evade', 0, 255),
            ('magic_defense', 'Magic Defense', 0, 255),
            ('magic_evade', 'Magic Evade', 0, 255),
        ]

        for row, (key, label, min_val, max_val) in enumerate(stats_config):
            frame = ttk.Frame(scrollable_frame)
            frame.grid(row=row, column=0, sticky=(tk.W, tk.E), pady=5, padx=10)
            frame.columnconfigure(1, weight=1)

            ttk.Label(frame, text=f"{label}:", width=15).grid(row=0, column=0, sticky=tk.W)

            var = tk.IntVar()
            self.stat_vars[key] = var

            spinbox = ttk.Spinbox(
                frame,
                from_=min_val,
                to=max_val,
                textvariable=var,
                width=10
            )
            spinbox.grid(row=0, column=1, sticky=tk.W, padx=(5, 10))

            # Scale for visual feedback
            scale = ttk.Scale(
                frame,
                from_=min_val,
                to=max_val,
                orient=tk.HORIZONTAL,
                variable=var
            )
            scale.grid(row=0, column=2, sticky=(tk.W, tk.E))

            # Current value label
            value_label = ttk.Label(frame, textvariable=var, width=6)
            value_label.grid(row=0, column=3, sticky=tk.W, padx=(5, 0))

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

    def create_resistance_tab(self, parent):
        """Create the resistances editor tab."""
        ttk.Label(
            parent,
            text="Select elements the enemy resists:",
            font=('', 10, 'bold')
        ).pack(pady=(0, 10))

        self.resistance_vars = {}

        # Create checkboxes in a grid
        frame = ttk.Frame(parent)
        frame.pack(fill=tk.BOTH, expand=True)

        for idx, element in enumerate(ELEMENT_NAMES):
            var = tk.BooleanVar()
            self.resistance_vars[element] = var

            cb = ttk.Checkbutton(
                frame,
                text=element,
                variable=var,
                command=self.mark_modified
            )
            cb.grid(row=idx // 2, column=idx % 2, sticky=tk.W, padx=20, pady=5)

        # Current bitfield value display
        info_frame = ttk.LabelFrame(parent, text="Technical Info", padding="10")
        info_frame.pack(fill=tk.X, pady=(10, 0))

        self.resist_value_var = tk.StringVar()
        ttk.Label(info_frame, text="Hex Value:").pack(side=tk.LEFT)
        ttk.Label(info_frame, textvariable=self.resist_value_var, font=('Courier', 10)).pack(side=tk.LEFT, padx=(5, 0))

    def create_weakness_tab(self, parent):
        """Create the weaknesses editor tab."""
        ttk.Label(
            parent,
            text="Select elements the enemy is weak to:",
            font=('', 10, 'bold')
        ).pack(pady=(0, 10))

        self.weakness_vars = {}

        # Create checkboxes in a grid
        frame = ttk.Frame(parent)
        frame.pack(fill=tk.BOTH, expand=True)

        for idx, element in enumerate(ELEMENT_NAMES):
            var = tk.BooleanVar()
            self.weakness_vars[element] = var

            cb = ttk.Checkbutton(
                frame,
                text=element,
                variable=var,
                command=self.mark_modified
            )
            cb.grid(row=idx // 2, column=idx % 2, sticky=tk.W, padx=20, pady=5)

        # Current bitfield value display
        info_frame = ttk.LabelFrame(parent, text="Technical Info", padding="10")
        info_frame.pack(fill=tk.X, pady=(10, 0))

        self.weak_value_var = tk.StringVar()
        ttk.Label(info_frame, text="Hex Value:").pack(side=tk.LEFT)
        ttk.Label(info_frame, textvariable=self.weak_value_var, font=('Courier', 10)).pack(side=tk.LEFT, padx=(5, 0))

    def create_rewards_tab(self, parent):
        """Create the level/rewards editor tab."""
        # Level section
        level_frame = ttk.LabelFrame(parent, text="Level & Multipliers", padding="10")
        level_frame.pack(fill=tk.X, pady=(0, 10))
        level_frame.columnconfigure(1, weight=1)

        self.level_var = tk.IntVar()
        self.xp_mult_var = tk.IntVar()
        self.gp_mult_var = tk.IntVar()

        # Level
        ttk.Label(level_frame, text="Level:").grid(row=0, column=0, sticky=tk.W)
        ttk.Spinbox(
            level_frame,
            from_=1,
            to=99,
            textvariable=self.level_var,
            width=10
        ).grid(row=0, column=1, sticky=tk.W, padx=(5, 0))

        # XP Multiplier
        ttk.Label(level_frame, text="XP Multiplier:").grid(row=1, column=0, sticky=tk.W, pady=(5, 0))
        ttk.Spinbox(
            level_frame,
            from_=0,
            to=255,
            textvariable=self.xp_mult_var,
            width=10
        ).grid(row=1, column=1, sticky=tk.W, padx=(5, 0), pady=(5, 0))

        # GP Multiplier
        ttk.Label(level_frame, text="GP Multiplier:").grid(row=2, column=0, sticky=tk.W, pady=(5, 0))
        ttk.Spinbox(
            level_frame,
            from_=0,
            to=255,
            textvariable=self.gp_mult_var,
            width=10
        ).grid(row=2, column=1, sticky=tk.W, padx=(5, 0), pady=(5, 0))

        # Info label
        info_text = (
            "Note: XP and GP rewards are calculated as:\n"
            "  XP = Base XP × XP Multiplier\n"
            "  GP = Base GP × GP Multiplier"
        )
        ttk.Label(parent, text=info_text, foreground='gray').pack(pady=(10, 0))

    def populate_enemy_list(self, filter_text=""):
        """Populate the enemy listbox."""
        self.enemy_listbox.delete(0, tk.END)

        for idx, enemy in enumerate(self.enemies):
            name = enemy['name']
            if filter_text.lower() in name.lower():
                display = f"{idx:02d}: {name}"
                self.enemy_listbox.insert(tk.END, display)

    def filter_enemies(self, *args):
        """Filter enemy list based on search."""
        self.populate_enemy_list(self.search_var.get())

    def on_enemy_select(self, event):
        """Handle enemy selection from listbox."""
        selection = self.enemy_listbox.curselection()
        if selection:
            # Parse ID from the selection text
            text = self.enemy_listbox.get(selection[0])
            enemy_id = int(text.split(':')[0])
            self.load_enemy(enemy_id)

    def load_enemy(self, idx):
        """Load enemy data into the editor."""
        if idx < 0 or idx >= len(self.enemies):
            return

        self.current_enemy_idx = idx
        enemy = self.enemies[idx]

        # Update UI
        self.enemy_id_var.set(f"{idx:03d}")
        self.enemy_name_var.set(enemy['name'])

        # Stats
        for key, var in self.stat_vars.items():
            var.set(enemy.get(key, 0))

        # Level/Rewards
        self.level_var.set(enemy.get('level', 1))
        self.xp_mult_var.set(enemy.get('xp_mult', 1))
        self.gp_mult_var.set(enemy.get('gp_mult', 1))

        # Resistances
        resist_bits = enemy.get('resistances', 0)
        for element, var in self.resistance_vars.items():
            bit = ELEMENT_BITS[element]
            var.set(bool(resist_bits & bit))
        self.resist_value_var.set(f"0x{resist_bits:04X}")

        # Weaknesses
        weak_bits = enemy.get('weaknesses', 0)
        for element, var in self.weakness_vars.items():
            bit = ELEMENT_BITS[element]
            var.set(bool(weak_bits & bit))
        self.weak_value_var.set(f"0x{weak_bits:04X}")

        # Update status
        self.status_var.set(f"Loaded: {enemy['name']} (#{idx})")

        # Select in listbox
        self.enemy_listbox.selection_clear(0, tk.END)
        # Find the item in listbox
        for i in range(self.enemy_listbox.size()):
            text = self.enemy_listbox.get(i)
            if text.startswith(f"{idx:02d}:"):
                self.enemy_listbox.selection_set(i)
                self.enemy_listbox.see(i)
                break

    def apply_changes(self):
        """Apply current editor values to the enemy data."""
        idx = self.current_enemy_idx
        enemy = self.enemies[idx]

        # Save to undo stack
        self.undo_stack.append(json.dumps(enemy))

        # Update stats
        enemy['name'] = self.enemy_name_var.get()
        for key, var in self.stat_vars.items():
            enemy[key] = var.get()

        # Update level/rewards
        enemy['level'] = self.level_var.get()
        enemy['xp_mult'] = self.xp_mult_var.get()
        enemy['gp_mult'] = self.gp_mult_var.get()

        # Update resistances
        resist_bits = 0
        for element, var in self.resistance_vars.items():
            if var.get():
                resist_bits |= ELEMENT_BITS[element]
        enemy['resistances'] = resist_bits

        # Decode resistances
        enemy['resistances_decoded'] = [
            elem for elem, var in self.resistance_vars.items() if var.get()
        ]

        # Update weaknesses
        weak_bits = 0
        for element, var in self.weakness_vars.items():
            if var.get():
                weak_bits |= ELEMENT_BITS[element]
        enemy['weaknesses'] = weak_bits

        # Decode weaknesses
        enemy['weaknesses_decoded'] = [
            elem for elem, var in self.weakness_vars.items() if var.get()
        ]

        # Update hex displays
        self.resist_value_var.set(f"0x{resist_bits:04X}")
        self.weak_value_var.set(f"0x{weak_bits:04X}")

        self.mark_modified()
        self.status_var.set(f"Applied changes to {enemy['name']}")

    def mark_modified(self):
        """Mark the data as modified."""
        self.modified = True
        self.update_title()

    def update_title(self):
        """Update window title."""
        title = "FFMQ Enemy Editor"
        if self.modified:
            title += " *"
        self.root.title(title)

    def prev_enemy(self):
        """Load previous enemy."""
        if self.current_enemy_idx > 0:
            self.load_enemy(self.current_enemy_idx - 1)

    def next_enemy(self):
        """Load next enemy."""
        if self.current_enemy_idx < len(self.enemies) - 1:
            self.load_enemy(self.current_enemy_idx + 1)

    def undo(self):
        """Undo last change."""
        if self.undo_stack:
            last_state = self.undo_stack.pop()
            enemy = json.loads(last_state)
            self.enemies[self.current_enemy_idx] = enemy
            self.load_enemy(self.current_enemy_idx)
            self.status_var.set("Undone last change")

    def reset_enemy(self):
        """Reset current enemy to original data."""
        if messagebox.askyesno("Confirm", "Reset current enemy to original data?"):
            # Reload from disk
            self.load_enemy_data()
            self.load_enemy(self.current_enemy_idx)
            self.status_var.set("Enemy reset to original data")

    def reset_all(self):
        """Reset all enemies to original data."""
        if messagebox.askyesno("Confirm", "Reset ALL enemies to original data?"):
            self.load_enemy_data()
            self.load_enemy(self.current_enemy_idx)
            self.modified = False
            self.update_title()
            self.status_var.set("All enemies reset to original data")

    def export_to_asm(self):
        """Export to ASM files."""
        if self.modified:
            if messagebox.askyesno("Save First?", "Save changes before exporting?"):
                self.save_enemy_data()

        self.status_var.set("Exporting to ASM...")
        self.root.update()

        try:
            result = subprocess.run(
                [sys.executable, "tools/conversion/convert_all.py"],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                messagebox.showinfo(
                    "Success",
                    "Exported to ASM successfully!\n\n"
                    "Files created:\n"
                    "  • data/converted/enemies/enemies_stats.asm\n"
                    "  • data/converted/enemies/enemies_level.asm\n"
                    "  • data/converted/attacks/attacks_data.asm\n"
                    "  • data/converted/attacks/enemy_attack_links.asm"
                )
                self.status_var.set("Export to ASM complete")
            else:
                messagebox.showerror("Error", f"Export failed:\n{result.stderr}")
                self.status_var.set("Export failed")

        except Exception as e:
            messagebox.showerror("Error", f"Export failed:\n{str(e)}")
            self.status_var.set("Export failed")

    def verify_gamefaqs(self):
        """Run GameFAQs verification."""
        self.status_var.set("Verifying against GameFAQs...")
        self.root.update()

        try:
            result = subprocess.run(
                [sys.executable, "tools/verify_gamefaqs_data.py"],
                capture_output=True,
                text=True
            )

            # Show output in a new window
            window = tk.Toplevel(self.root)
            window.title("GameFAQs Verification Results")
            window.geometry("800x600")

            text = tk.Text(window, wrap=tk.WORD, font=('Courier', 9))
            text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

            scrollbar = ttk.Scrollbar(window, command=text.yview)
            scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
            text.config(yscrollcommand=scrollbar.set)

            text.insert('1.0', result.stdout)
            text.config(state=tk.DISABLED)

            self.status_var.set("GameFAQs verification complete")

        except Exception as e:
            messagebox.showerror("Error", f"Verification failed:\n{str(e)}")
            self.status_var.set("Verification failed")

    def test_pipeline(self):
        """Run pipeline test."""
        self.status_var.set("Running pipeline test...")
        self.root.update()

        try:
            result = subprocess.run(
                [sys.executable, "tools/test_pipeline.py"],
                capture_output=True,
                text=True
            )

            # Show output in a new window
            window = tk.Toplevel(self.root)
            window.title("Pipeline Test Results")
            window.geometry("800x600")

            text = tk.Text(window, wrap=tk.WORD, font=('Courier', 9))
            text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

            scrollbar = ttk.Scrollbar(window, command=text.yview)
            scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
            text.config(yscrollcommand=scrollbar.set)

            text.insert('1.0', result.stdout)
            text.config(state=tk.DISABLED)

            self.status_var.set("Pipeline test complete")

        except Exception as e:
            messagebox.showerror("Error", f"Test failed:\n{str(e)}")
            self.status_var.set("Test failed")

    def show_about(self):
        """Show about dialog."""
        messagebox.showinfo(
            "About FFMQ Enemy Editor",
            "Final Fantasy Mystic Quest Enemy Editor\n"
            "Version 1.0\n\n"
            "A visual editor for modifying enemy stats, resistances,\n"
            "and weaknesses in Final Fantasy Mystic Quest.\n\n"
            "Part of the FFMQ Disassembly Project\n"
            "2025-11-02"
        )


def main():
    """Main entry point."""
    root = tk.Tk()
    app = EnemyEditorApp(root)
    root.mainloop()


if __name__ == '__main__':
    main()
