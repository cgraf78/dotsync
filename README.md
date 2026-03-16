# dotsync

Bidirectional file sync across hosts via rsync + SSH.

Syncs files listed in manifests across configured hosts. Designed for dotfiles and config that live outside version control — no special server or daemon required, just SSH.

## Quick Start

```bash
# Install
git clone https://github.com/cgraf78/dotsync.git
cd dotsync && ./install.sh

# Configure
echo "server1 server1.example.com" >> ~/.config/dotsync/dotsync-hosts
echo ".bashrc" >> ~/.config/dotsync/dotsync-paths

# Sync
dotsync push server1          # one-way push
dotsync pull server1          # one-way pull
dotsync sync                  # bidirectional sync with all reachable hosts
```

## Prerequisites

- SSH key access between machines (configure ports/keys in `~/.ssh/config`)
- `rsync` and `md5sum` on each host (standard on Linux; macOS has `md5`)
- Optional: `diff3` for 3-way merge (falls back to conflict-copy if missing)

## Usage

```
dotsync push <host>     rsync listed files TO host
dotsync pull <host>     rsync listed files FROM host
dotsync sync            bidirectional sync with all reachable hosts
dotsync diff <host>     dry-run showing what sync would do
dotsync list            show all paths from all manifests
dotsync hosts           show configured hosts

Flags:
  --dry-run, -n         show what would be done without changes
```

## Configuration

Config lives in `$DOTSYNC_CONF_DIR` (default `~/.config/dotsync/`).

### Hosts

Format: `alias ssh-destination`, one per line.

```
# ~/.config/dotsync/dotsync-hosts
server1    server1.example.com
laptop     laptop.local
nas        nas.example.net
```

Two tiers for host-based path filtering:

| File | Receives |
|------|----------|
| `dotsync-hosts` | Personal + extra paths |
| `dotsync-hosts-work` | Personal + work + extra paths |

### Paths (manifests)

One path per line, relative to `$HOME`. Directories are synced recursively. Glob patterns supported.

```
# ~/.config/dotsync/dotsync-paths
.bashrc
.config/dotsync
!*/__pycache__          # exclude pattern
!*.pyc                  # exclude by extension
```

Three manifest tiers:

| File | Synced to |
|------|-----------|
| `dotsync-paths` | All hosts |
| `dotsync-paths-work` | Work hosts only |
| `dotsync-paths-extra` | All hosts (machine-local, untracked) |

Work paths are **never** synced to personal-tier hosts.

## Sync Behavior

### push / pull

Simple one-way rsync. Does not propagate deletions. Updates sync state for subsequent `sync` calls.

### sync

Bidirectional sync with conflict detection:

| Local | Remote | Action |
|-------|--------|--------|
| changed | unchanged | push |
| unchanged | changed | pull |
| both changed (same) | — | update state |
| both changed (different, text) | — | 3-way merge via `diff3` |
| both changed (different, binary) | — | save `.conflict` copy |
| deleted | unchanged | propagate deletion |
| exists | missing (first sync) | push |

### Symlinks

Symlinks are preserved transparently. Content is read/written through symlinks without replacing them.

### Conflicts

- **Text files**: 3-way merge using stored last-synced copy as merge base. Failed merges save remote as `<file>.conflict.<host>`.
- **Binary files**: Remote saved as `<file>.conflict.<host>`.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTSYNC_CONF_DIR` | `~/.config/dotsync` | Config directory |
| `DOTSYNC_STATE_DIR` | `~/.local/share/dotsync` | Sync state directory |

## Cron Usage

```crontab
*/30 * * * * $HOME/.local/bin/dotsync sync >> /tmp/dotsync.log 2>&1
```

Lock file prevents concurrent runs. Exit codes: 0=success, 1=conflicts, 2=errors.

## Testing

```bash
bash tests/dotsync-test                  # unit tests
bash tests/dotsync-test --integration    # includes SSH tests via localhost
```

## License

MIT
