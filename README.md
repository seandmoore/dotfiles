# dotfiles

A stylish Hyprland dotfiles setup themed with [Catppuccin](https://github.com/catppuccin/catppuccin) (Mocha dark / Latte light).

## Components

| Component | Description |
|-----------|-------------|
| **Hyprland** | Dynamic tiling Wayland compositor — Lua config (0.55+), animations, borders, keybinds. |
| **Quickshell** | Status bar, app launcher, notification daemon, volume/brightness OSD. |
| **Hyprlock** | Lock screen with blurred background and animated clock. |
| **Hypridle** | Idle daemon — dim → lock → display off → suspend. |
| **Hyprpaper** | Wallpaper manager. |
| **Hyprpolkitagent** | Authentication agent for privilege prompts. |
| **Kitty** | Terminal emulator with Catppuccin theme and powerline tabs. |
| **Neovim** | Editor with lazy.nvim, Telescope, Treesitter, Lualine, and more. |

## Screenshots

> Screenshots coming soon.

## Installation (Arch Linux)

Run the install script — it handles packages, symlinks, and services automatically:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/install.sh)
```

The script will:

1. Verify you are on Arch Linux
2. Clone or update the dotfiles repo to `~/dotfiles`
3. Install all required packages via `pacman`
4. Prompt to install [yay](https://github.com/Jguer/yay) and AUR packages (`quickshell-git`, `grimblast-git`)
5. Create all config symlinks under `~/.config/`
6. Enable systemd user services (PipeWire, XDG portals) and the bluetooth service
7. Refresh the font cache

After the script finishes, place a wallpaper at `~/.config/hypr/wallpaper.png` and run `Hyprland`.

## Manual Installation

```bash
git clone https://github.com/seandmoore/dotfiles ~/dotfiles
cd ~/dotfiles

# Hyprland
mkdir -p ~/.config/hypr
ln -sf ~/dotfiles/hypr/hyprland.lua   ~/.config/hypr/hyprland.lua
ln -sf ~/dotfiles/hypr/hyprpaper.conf ~/.config/hypr/hyprpaper.conf
ln -sf ~/dotfiles/hypr/hyprlock.conf  ~/.config/hypr/hyprlock.conf
ln -sf ~/dotfiles/hypr/hypridle.conf  ~/.config/hypr/hypridle.conf

# Quickshell
mkdir -p ~/.config/quickshell
ln -sf ~/dotfiles/quickshell ~/.config/quickshell/config
ln -sf ~/dotfiles/scripts    ~/.config/quickshell/scripts

# Kitty
mkdir -p ~/.config/kitty
ln -sf ~/dotfiles/kitty/kitty.conf        ~/.config/kitty/kitty.conf
ln -sf ~/dotfiles/kitty/colors-mocha.conf ~/.config/kitty/colors-mocha.conf
ln -sf ~/dotfiles/kitty/colors-latte.conf ~/.config/kitty/colors-latte.conf
cp     ~/dotfiles/kitty/colors-mocha.conf ~/.config/kitty/active-colors.conf

# Neovim
mkdir -p ~/.config/nvim
ln -sf ~/dotfiles/nvim/init.lua ~/.config/nvim/init.lua
ln -sf ~/dotfiles/nvim/lua      ~/.config/nvim/lua
```

## Dependencies

All packages are available in the Arch official repositories unless noted as AUR.

**Compositor & Wayland stack**

| Package | Purpose |
|---------|---------|
| `hyprland` | Compositor |
| `hyprpaper` | Wallpaper manager |
| `hyprlock` | Lock screen |
| `hypridle` | Idle daemon |
| `hyprpolkitagent` | Authentication agent |
| `xdg-desktop-portal` | Wayland portal base |
| `xdg-desktop-portal-hyprland` | Screen sharing and file pickers |
| `xorg-xwayland` | X11 app compatibility |

**UI**

| Package | Purpose |
|---------|---------|
| `quickshell-git` *(AUR)* | Status bar, launcher, notifications, OSD |
| `qt5-wayland` / `qt6-wayland` | Native Wayland backend for Qt apps |

**Terminal & Editor**

| Package | Purpose |
|---------|---------|
| `kitty` | Terminal emulator |
| `neovim` | Text editor (v0.9+) |

**Audio & Video**

| Package | Purpose |
|---------|---------|
| `pipewire` + `wireplumber` + `pipewire-pulse` | Audio stack |
| `pavucontrol` | Volume control GUI |
| `playerctl` | Media player control |

**Input & Display**

| Package | Purpose |
|---------|---------|
| `brightnessctl` | Brightness control |
| `wl-clipboard` | Clipboard support |
| `grim` + `slurp` | Screenshot dependencies |
| `grimblast-git` *(AUR)* | Screenshot tool |
| `inotify-tools` | Brightness change monitoring |

**Network & Bluetooth**

| Package | Purpose |
|---------|---------|
| `networkmanager` + `network-manager-applet` | Network management |
| `bluez` + `bluez-utils` + `blueman` | Bluetooth stack and manager |

**Apps**

| Package | Purpose |
|---------|---------|
| `ranger` | Terminal file manager (`SUPER+E`) |
| `firefox` | Web browser (`SUPER+B`) |

**Fonts**

| Package | Purpose |
|---------|---------|
| `ttf-jetbrains-mono-nerd` | Primary font (terminal, bar, lock screen) |
| `noto-fonts` + `noto-fonts-emoji` | Unicode and emoji fallbacks |

## Keybinds (Hyprland)

| Keys | Action |
|------|--------|
| `SUPER + Return` | Open terminal (Kitty) |
| `SUPER + SPACE` | Toggle app launcher |
| `SUPER + Q` | Close window |
| `SUPER + E` | File manager (ranger) |
| `SUPER + B` | Browser (Firefox) |
| `SUPER + M` | Exit Hyprland |
| `SUPER + H/J/K/L` | Move focus left/down/up/right |
| `SUPER + SHIFT + H/J/K/L` | Move window left/down/up/right |
| `SUPER + 1–9` | Switch to workspace |
| `SUPER + SHIFT + 1–9` | Move window to workspace |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Toggle pseudotile |
| `Print` | Screenshot selection (copy) |
| `SHIFT + Print` | Screenshot full screen (copy) |
| `XF86AudioRaiseVolume/LowerVolume/Mute` | Volume control |
| `XF86AudioPlay/Next/Prev` | Media control |
| `XF86MonBrightnessUp/Down` | Brightness control |

## Theming

The setup uses [Catppuccin](https://github.com/catppuccin/catppuccin) in two flavors:

- **Mocha** (dark) — default
- **Latte** (light) — toggle via the bar button or run:

```bash
~/.config/quickshell/scripts/sync-theme.sh latte   # switch to light
~/.config/quickshell/scripts/sync-theme.sh mocha   # switch to dark
```

The selected theme is persisted to `$XDG_CACHE_HOME/catppuccin-mode` and restored on next login.

## License

Licensed under GPL-3.0. See [LICENSE](LICENSE) for details.
