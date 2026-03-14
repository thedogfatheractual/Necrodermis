#!/usr/bin/env bash
# NECRODERMIS // TOMB-WORLD INSTALLER
# Routes to the Rust TUI. Falls back to legacy bash if cargo unavailable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUI_DIR="$SCRIPT_DIR/necro-detect"
BINARY="$TUI_DIR/target/release/necro-detect"

if ! command -v cargo &>/dev/null; then
    echo ""
    echo "  [WARN]  cargo not found — falling back to legacy bash installer"
    echo "          Install Rust: https://rustup.rs"
    echo ""
    exec bash "$SCRIPT_DIR/install-legacy.sh"
fi

echo ""
echo "  NECRODERMIS // AWAKENING SEQUENCE"
echo ""

cd "$TUI_DIR"

if [[ ! -f "$BINARY" ]] || [[ src/main.rs -nt "$BINARY" ]] || [[ src/tui.rs -nt "$BINARY" ]]; then
    echo "  [BUILD] Compiling necro-detect..."
    cargo build --release --quiet
    echo "  [ OK ]  Build complete"
fi

exec "$BINARY"
