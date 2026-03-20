# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`dotsync` is a bash CLI that keeps dotfiles in sync across multiple machines via rsync + SSH. It supports bidirectional sync with conflict detection, 3-way merging, and symlink preservation.

## Commands

```bash
# Run unit tests
bash tests/dotsync-test

# Run unit + integration tests (requires localhost SSH)
bash tests/dotsync-test --integration

# Lint
shellcheck -x bin/dotsync
shellcheck -x -P tests tests/dotsync-test tests/test-helpers.sh
```

## Architecture

Single-file CLI (`bin/dotsync`, ~1350 lines of bash 4+). No plugins — all logic is self-contained.

### Config layer

Three manifest tiers control what gets synced where:

- `dotsync-paths` — synced to all hosts
- `dotsync-paths-work` — synced to work hosts only (never leaks to personal hosts)
- `dotsync-paths-extra` — machine-local additions, synced to all hosts

Two host files (`dotsync-hosts`, `dotsync-hosts-work`) determine host tier. Work-tier hosts receive all manifests; personal-tier hosts receive only personal + extra. Work manifest paths are treated as implicit excludes during personal-tier directory expansion.

Exclude patterns (`!pattern` in manifests) filter files discovered during directory expansion but never block explicit includes.

### State management

State lives under `$DOTSYNC_STATE_DIR` (default `~/.local/state/dotsync/`), organized as `<host>/<path>` with two files per synced file:

- Content copy — serves as 3-way merge base for future conflicts
- `.dotsync-md5` hash — compared against current local/remote checksums to detect changes

**Safety invariant**: state is never written unless the corresponding transfer succeeded.

### Sync algorithm (`_sync_host`)

The core bidirectional sync compares local md5, remote md5, and stored state md5 to classify each file into one of: push, pull, both-changed-same, conflict (3-way merge for text, `.conflict.<host>` copy for binary), or deletion propagation. The `_resolve_local_files` / `_resolve_remote_files` functions expand directories, apply excludes, and compute checksums.

Remote checksums are computed via a fixed `REMOTE_MD5_SCRIPT` piped over SSH to avoid command-length limits.

### Symlink handling

Symlinks are recorded before rsync (`_record_local_symlinks` / `_record_remote_symlinks`) and restored after (`_restore_local_symlinks` / `_restore_remote_symlinks`). This preserves symlink structure since rsync follows symlinks by default.

### Testing

Tests source `bin/dotsync` with `DOTSYNC_SOURCED=1` to access internal functions without executing `main`. The test framework (`tests/test-helpers.sh`) provides assertions (`_assert_eq`, `_assert_contains`, etc.) and temp directory management. Integration tests use localhost SSH.

### Key patterns

- `DOTSYNC_SOURCED=1` exports functions without running arg parsing.
- All remote commands use `$HOME` (literal `$` via `\$HOME`) so the remote shell expands it.
- Atomic lock directory (`$STATE_DIR/.lock/`) with PID file prevents concurrent runs.
- Exit codes: 0=success, 1=conflicts, 2=errors.
- Host SSH destinations are resolved via `ssh -G <host>` to honor `~/.ssh/config`.

## Releasing

1. Bump `VERSION` file, commit, push to main.
2. Tag and push: `git tag v<version> && git push origin v<version>`
3. The release workflow (`.github/workflows/release.yml`) runs tests, creates a tarball, and publishes the GitHub release automatically.
4. Optionally edit the release notes via `gh release edit v<version> --notes-file <file>`.
