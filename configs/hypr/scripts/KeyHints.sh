#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — KEYHINTS
# Quick keybind reference — gum TUI
# ════════════════════════════════════════════════════════════

pkill rofi 2>/dev/null || true

gum table --separator "│" --columns "Keybind,Action" --widths "30,50" << 'EOF'
SUPER + Enter│Terminal
SUPER + SHIFT + Enter│Dropdown Terminal
SUPER + B│Browser
SUPER + D│App Launcher
SUPER + E│File Manager
SUPER + W│Wallpaper Select
SUPER + SHIFT + W│Wallpaper Effects
CTRL + ALT + W│Random Wallpaper
SUPER + H│This Cheat Sheet
SUPER + SHIFT + E│Necrodermis Settings
SUPER + SHIFT + K│Search Keybinds
SUPER + S│Web Search
SUPER + CTRL + S│Window Switcher
SUPER + Q│Close Window
SUPER + SHIFT + Q│Kill Process
SUPER + SHIFT + F│Fullscreen
SUPER + CTRL + F│Maximise
SUPER + SPACE│Float Window
SUPER + ALT + SPACE│Float All Windows
SUPER + T│Dropdown Terminal
SUPER + M│Reload Hyprland
SUPER + N│Night Light Toggle
SUPER + SHIFT + N│Notification Panel
SUPER + SHIFT + G│Game Mode
SUPER + ALT + O│Toggle Blur
SUPER + CTRL + O│Toggle Opacity
SUPER + SHIFT + A│Animations Menu
SUPER + ALT + L│Toggle Layout
SUPER + ALT + V│Clipboard Manager
SUPER + ALT + E│Emoji Menu
SUPER + ALT + C│Calculator
CTRL + ALT + L│Lock Screen
CTRL + ALT + P│Power Menu
CTRL + ALT + Delete│Exit Hyprland
CTRL + SHIFT + Escape│System Monitor (btop)
SUPER + Print│Screenshot
SUPER + SHIFT + Print│Screenshot Region
SUPER + SHIFT + S│Screenshot (Swappy)
SUPER + CTRL + Print│Screenshot 5s
SUPER + CTRL + SHIFT + Print│Screenshot 10s
ALT + Print│Screenshot Active Window
SUPER + Tab│Next Workspace
SUPER + SHIFT + Tab│Previous Workspace
SUPER + Mouse Scroll│Cycle Workspaces
SUPER + [1-0]│Switch to Workspace
SUPER + SHIFT + [1-0]│Move Window to Workspace
SUPER + Arrow Keys│Focus Window
SUPER + SHIFT + Arrows│Resize Window
SUPER + CTRL + Arrows│Move Window
SUPER + ALT + Arrows│Swap Window
SUPER + G│Toggle Group
SUPER + CTRL + F9-F12│Move Workspace to Monitor
EOF
