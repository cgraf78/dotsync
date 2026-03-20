#!/usr/bin/env bash
# install.sh — install dotsync to ~/.local/bin and set up default config.
#
# Two modes:
#   From source tree:  cd dotsync && bash install.sh
#   Standalone:        curl -sL https://raw.githubusercontent.com/cgraf78/dotsync/main/install.sh | bash
#
# When run standalone (no bin/dotsync in the current directory), the script
# fetches the latest release tarball, extracts to a temp directory, and
# installs from there.
set -euo pipefail

REPO="cgraf78/dotsync"
PREFIX="${PREFIX:-$HOME/.local}"
CONF_DIR="${DOTSYNC_CONF_DIR:-$HOME/.config/dotsync}"

# If not in a source tree, fetch the latest release tarball.
cleanup=""
if [[ ! -f bin/dotsync ]]; then
    echo "Fetching latest release..."
    tag=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
    if [[ -z "$tag" ]]; then
        echo "error: failed to determine latest release" >&2
        exit 1
    fi
    tmpdir=$(mktemp -d)
    cleanup="$tmpdir"
    trap 'rm -rf "$cleanup"' EXIT
    curl -sL "https://github.com/$REPO/releases/download/${tag}/dotsync-${tag}.tar.gz" | tar xz -C "$tmpdir"
    cd "$tmpdir/dotsync-${tag}"
    echo "  resolved $tag"
fi

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
echo "  1. Edit $CONF_DIR/dotsync-hosts with your SSH host aliases"
echo "  2. Edit $CONF_DIR/dotsync-paths with files to sync"
echo "  3. Run: dotsync push <host>"
