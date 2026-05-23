# dotfiles

A stylish Hyprland dotfiles setup themed with [Catppuccin](https://github.com/catppuccin/catppuccin).

## Components

| Component | Description |
|-----------|-------------|
| **Hyprland** | Dynamic tiling Wayland compositor — Lua config (0.55+), animations, borders, keybinds |
| **Quickshell** | Status bar, notifications, OSD overlays, app launcher |
| **Hyprlock** | Lock screen with blurred background |
| **Hypridle** | Idle daemon — dim → lock → suspend |
| **Kitty** | Terminal emulator with Catppuccin theme |
| **Neovim** | Editor with lazy.nvim, Telescope, Treesitter, Lualine |

## Screenshots

> Coming soon

## Prerequisites

- [Hyprland](https://hyprland.org/)
- [Quickshell](https://quickshell.outfoxxed.me/)
- [Hyprlock](https://github.com/hyprwm/hyprlock)
- [Hypridle](https://github.com/hyprwm/hypridle)
- [Kitty](https://sw.kovidgoyal.net/kitty/)
- [Neovim](https://neovim.io/) >= 0.9
- A [Nerd Font](https://www.nerdfonts.com/) — JetBrainsMono Nerd Font recommended
- `brightnessctl` — for brightness OSD
- `pipewire` / `wireplumber` + `pactl` — for volume OSD
- `hyprpaper` — for wallpaper

## Installation

Clone and symlink configs into place using [GNU Stow](https://www.gnu.org/software/stow/) or manually:

```bash
git clone https://github.com/seandmoore/draftworks ~/.dotfiles
cd ~/.dotfiles

# Hyprland
mkdir -p ~/.config/hypr
ln -sf ~/.dotfiles/hypr/hyprland.lua  ~/.config/hypr/hyprland.lua
ln -sf ~/.dotfiles/hypr/hyprpaper.conf ~/.config/hypr/hyprpaper.conf
ln -sf ~/.dotfiles/hypr/hyprlock.conf  ~/.config/hypr/hyprlock.conf
ln -sf ~/.dotfiles/hypr/hypridle.conf  ~/.config/hypr/hypridle.conf

# Quickshell
mkdir -p ~/.config/quickshell
ln -sf ~/.dotfiles/quickshell ~/.config/quickshell/config

# Kitty
mkdir -p ~/.config/kitty
ln -sf ~/.dotfiles/kitty/kitty.conf ~/.config/kitty/kitty.conf

# Neovim
mkdir -p ~/.config/nvim
ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua
ln -sf ~/.dotfiles/nvim/lua     ~/.config/nvim/lua
```

## Keybinds (Hyprland)

| Keys | Action |
|------|--------|
| `SUPER + Return` | Open terminal (Kitty) |
| `SUPER + SPACE` | Toggle app launcher |
| `SUPER + Q` | Close window |
| `SUPER + H/J/K/L` | Move focus left/down/up/right |
| `SUPER + SHIFT + H/J/K/L` | Move window left/down/up/right |
| `SUPER + 1-9` | Switch to workspace |
| `SUPER + SHIFT + 1-9` | Move window to workspace |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Toggle pseudotile |

## License

GPL-3.0 — see [LICENSE](LICENSE)
