#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# scripts/verify.sh (the repo's linter, also run by the pre-commit hook) checks
# Lua configs with `luac`, which isn't present in the bare web container. Install
# Lua here so verification works in-session — catching Hyprland-config and shell
# errors before they're pushed. (QML is left to the local pre-commit hook, where
# Quickshell's QML modules are available; verify.sh skips QML without qmllint.)
set -euo pipefail

# Local sessions already have the full toolchain — only set up the remote env.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Idempotent: skip the install once `luac` resolves.
if ! command -v luac >/dev/null 2>&1; then
  # `|| true`: some images carry extra third-party PPAs that can fail to refresh;
  # those are unrelated to lua5.4 (which lives in the main Ubuntu universe repo),
  # so a partial update is fine and shouldn't abort session startup.
  sudo apt-get update -y || true
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y lua5.4
  # Ubuntu ships the compiler as luac5.4; expose a plain `luac` for verify.sh.
  if ! command -v luac >/dev/null 2>&1 && command -v luac5.4 >/dev/null 2>&1; then
    sudo ln -sf "$(command -v luac5.4)" /usr/local/bin/luac
  fi
fi

echo "session-start: luac -> $(command -v luac 2>/dev/null || echo 'NOT FOUND')"
