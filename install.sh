#!/usr/bin/env bash
# NECRODERMIS // TOMB-WORLD INSTALLER
# Bootstraps dependencies then hands off to the Rust TUI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUI_DIR="$SCRIPT_DIR/necro-detect"
BINARY="$TUI_DIR/target/release/necro-detect"

echo ""
echo "  NECRODERMIS // AWAKENING SEQUENCE"
echo ""

# ── 1. base-devel (C linker) ──────────────────────────────────────────────────
if ! command -v cc &>/dev/null; then
    echo "  [BUILD] Installing base-devel (C linker required for Rust)..."
    sudo pacman -S --needed --noconfirm base-devel
fi

# ── 2. rustup + stable toolchain ─────────────────────────────────────────────
if ! command -v cargo &>/dev/null; then
    echo "  [BUILD] Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source "$HOME/.cargo/env"
fi

# Ensure stable toolchain is set
if ! rustup toolchain list | grep -q stable; then
    echo "  [BUILD] Setting stable toolchain..."
    rustup default stable
fi

# ── 3. Build necro-detect ─────────────────────────────────────────────────────
cd "$TUI_DIR"

if [[ ! -f "$BINARY" ]] || [[ src/main.rs -nt "$BINARY" ]] || [[ src/tui.rs -nt "$BINARY" ]]; then
    echo "  [BUILD] Compiling necro-detect..."
    cargo build --release --quiet
    echo "  [ OK ]  Build complete"
fi

# ── 4. Hand off to TUI ───────────────────────────────────────────────────────
exec "$BINARY"
