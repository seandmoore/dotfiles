# dotfiles

A stylish Hyprland dotfiles setup themed with [Catppuccin](https://github.com/catppuccin/catppuccin).

## Components

| Component       | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| **Hyprland**     | Dynamic tiling Wayland compositor — Lua config (0.55+), animations, borders, keybinds. |
| **Quickshell**   | Status bar, notifications, OSD overlays, app launcher.                    |
| **Hyprlock**     | Lock screen with blurred background.                                       |
| **Hypridle**     | Idle daemon — dim → lock → suspend.                                        |
| **Kitty**        | Terminal emulator with Catppuccin theme.                                  |
| **Neovim**       | Editor with lazy.nvim, Telescope, Treesitter, Lualine.                    |

## Screenshots

> Screenshots coming soon.

## Prerequisites

- [Hyprland](https://hyprland.org/)
- [Quickshell](https://quickshell.outfoxxed.me/)
- [Hyprlock](https://github.com/hyprwm/hyprlock)
- [Hypridle](https://github.com/hyprwm/hypridle)
- [Kitty](https://sw.kovidgoyal.net/kitty/)
- [Neovim](https://neovim.io/) (v0.9 or later)
- A [Nerd Font](https://www.nerdfonts.com/) — JetBrainsMono Nerd Font recommended
- `brightnessctl` — For brightness OSD.
- `pipewire` / `wireplumber` + `pactl` — For volume OSD.
- `hyprpaper` — For wallpaper management.

## Installation

Clone this repository and symlink the configuration files into place using [GNU Stow](https://www.gnu.org/software/stow/) or manually:

```bash
git clone https://github.com/seandmoore/dotfiles ~/.dotfiles
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

## Quick Install with Curl

You can quickly install the dotfiles by running the following command, which downloads and executes the setup script:

```bash
curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/install.sh | sh
```

This script will:
- Ensure Git is installed.
- Clone or update the dotfiles repository at `~/dotfiles`.
- Provide further instructions for setting up configuration file links.

For customizations, you can edit the `install.sh` script after installation.

## Keybinds (Hyprland)

| Keys                  | Action                     |
|-----------------------|----------------------------|
| `SUPER + Return`      | Open terminal (Kitty).     |
| `SUPER + SPACE`       | Toggle app launcher.       |
| `SUPER + Q`           | Close window.             |
| `SUPER + H/J/K/L`     | Move focus left/down/up/right. |
| `SUPER + SHIFT + H/J/K/L` | Move window left/down/up/right. |
| `SUPER + 1-9`         | Switch to workspace.       |
| `SUPER + SHIFT + 1-9` | Move window to workspace.  |
| `SUPER + F`           | Toggle fullscreen mode.    |
| `SUPER + V`           | Toggle floating mode.      |
| `SUPER + P`           | Toggle pseudotile.        |

## License

Licensed under GPL-3.0. See [LICENSE](LICENSE) for details.
