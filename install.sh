#!/usr/bin/env bash
# install.sh — install dotsync to ~/.local/bin and set up default config.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
CONF_DIR="${DOTSYNC_CONF_DIR:-$HOME/.config/dotsync}"

echo "Installing dotsync..."

# Install binary
mkdir -p "$PREFIX/bin"
cp bin/dotsync "$PREFIX/bin/dotsync"
chmod +x "$PREFIX/bin/dotsync"
echo "  installed $PREFIX/bin/dotsync"

# Create config directory with examples if not present
mkdir -p "$CONF_DIR"
if [[ ! -f "$CONF_DIR/dotsync-hosts" ]]; then
    cp examples/dotsync-hosts "$CONF_DIR/dotsync-hosts"
    echo "  created $CONF_DIR/dotsync-hosts (edit with your hosts)"
fi
if [[ ! -f "$CONF_DIR/dotsync-paths" ]]; then
    cp examples/dotsync-paths "$CONF_DIR/dotsync-paths"
    echo "  created $CONF_DIR/dotsync-paths (edit with your paths)"
fi

echo "done."
echo ""
echo "Next steps:"
echo "  1. Edit $CONF_DIR/dotsync-hosts with your SSH hosts"
echo "  2. Edit $CONF_DIR/dotsync-paths with files to sync"
echo "  3. Run: dotsync push <host>"
