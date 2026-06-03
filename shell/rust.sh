# Rust (rustup) — managed by dotfiles.
# rustup installs its proxies (rustc, cargo, …) under ~/.cargo/bin and writes
# ~/.cargo/env to prepend it to PATH. Source it for interactive shells so the
# toolchain is on PATH (covers bare TTY/SSH; the graphical session inherits PATH
# from the login shell). Guarded so it's a no-op if rustup isn't installed.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
