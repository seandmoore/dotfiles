#!/usr/bin/env bash
# aliases.sh — shell aliases (managed by dotfiles; sourced from ~/.bashrc).

# ── Claude Code ────────────────────────────────────────────────────────────────
alias cc='claude'
# Dangerous mode: bypass ALL permission prompts (YOLO). Use only in trusted dirs.
alias ccd='claude --dangerously-skip-permissions'

# ── OpenCode ─────────────────────────────────────────────────────────────────────
alias oc='opencode'
# Full-auto: runs the 'yolo' agent (all permissions allowed) — defined in
# opencode/agent/yolo.md. The opencode equivalent of Claude Code's ccd.
alias ocd='opencode --agent yolo'
