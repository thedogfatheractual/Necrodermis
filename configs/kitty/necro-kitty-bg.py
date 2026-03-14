#!/usr/bin/env python3
# ════════════════════════════════════════════════════════════
# NECRODERMIS — necro-kitty-bg.py
# Dims the Necron warrior image for use as kitty background.
#
# Usage:
#   python3 ~/.config/kitty/necro-kitty-bg.py
#
# Input:  ~/.config/kitty/necrodermis-warrior.png
# Output: ~/.config/kitty/necrodermis-bg.png
#
# Tweak OPACITY and re-run to adjust visibility.
# ════════════════════════════════════════════════════════════

import os, sys

try:
    from PIL import Image, ImageEnhance
except ImportError:
    print("  [FAIL ]  Pillow not found -- installing...")
    os.system(f"{sys.executable} -m pip install pillow --break-system-packages -q")
    from PIL import Image, ImageEnhance

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT      = os.path.join(SCRIPT_DIR, "necrodermis-warrior.png")
OUTPUT     = os.path.join(SCRIPT_DIR, "necrodermis-bg.png")

# 0.0 = black, 1.0 = full brightness
# 0.10 very subtle | 0.13 default | 0.20 visible | 0.30 bold
OPACITY = 0.13

if not os.path.exists(INPUT):
    print(f"  [FAIL ]  not found: {INPUT}")
    print(f"           copy necrodermis-warrior.png to {SCRIPT_DIR}")
    sys.exit(1)

print(f"  [ OK  ]  loading {INPUT}")
img = Image.open(INPUT).convert("RGB")
dimmed = ImageEnhance.Brightness(img).enhance(OPACITY)
dimmed.save(OUTPUT, "PNG", optimize=True)
w, h = dimmed.size
print(f"  [ OK  ]  written to {OUTPUT}  ({w}x{h}  opacity={OPACITY})")
print(f"  [ OK  ]  restart kitty to apply")
