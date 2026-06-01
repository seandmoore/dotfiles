# dotfiles

A stylish Hyprland dotfiles setup themed with [Catppuccin](https://github.com/catppuccin/catppuccin) (Mocha dark / Latte light).

## Components

| Component | Description |
|-----------|-------------|
| **Hyprland** | Dynamic tiling Wayland compositor — Lua config (0.55+), animations, borders, keybinds, per-monitor HDR & wide-gamut color management. |
| **Quickshell** | Centered frosted-glass pill bar (live audio visualizer, CPU/RAM graphs, media controls, hover menus), app launcher with file search, notification center with Do-Not-Disturb, clipboard history, system-update menu (pacman + AUR + Flatpak), volume/brightness OSD, keybind cheat sheet. |
| **Hyprlock** | Lock screen with blurred background and animated clock. |
| **Hypridle** | Idle daemon — dim → lock → display off → suspend. |
| **Hyprpaper** | Wallpaper manager. |
| **Hyprpolkitagent** | Authentication agent for privilege prompts. |
| **Kitty** | Terminal emulator with Catppuccin theme, powerline tabs, and a smooth cursor trail. |
| **Starship** | Catppuccin powerline shell prompt; flavor follows the active Mocha/Latte theme. |
| **Neovim** | Editor with lazy.nvim, Telescope, Treesitter, Lualine, and more. |
| **xsettingsd** | Broadcasts GTK/cursor theme changes to XWayland apps live. |
| **nwg-look** | GTK theme picker — changes are snapshotted per mode and restored on theme switch. |

## Status bar

A single centered, fully-rounded frosted-glass **pill** that gathers every widget into one island, left to right:

- **App menu** — click for the full launcher (with a Files mode that searches `~` live), hover for the installed-app list. Apps are scanned once at startup and cached, so the menus open instantly with icons already resolved.
- **Workspaces** — per-monitor indicator (scroll over the dots to cycle that monitor's own workspaces, keeping focus on-screen); the hover menu shows live per-workspace window counts.
- **Visualizer** — a fluid waveform driven by [`cava`](https://github.com/karlstav/cava).
- **Clock** — hover opens the calendar.
- **System** — live CPU & RAM usage graphs (hover for per-core / memory detail) and the MPRIS media player.
- **Updates** — package icon with a count badge; the dropdown breaks down official-repo, AUR, and Flatpak updates and offers **Update All** (opens an interactive terminal running `yay`/`paru -Syu` + `flatpak update`).
- **Notifications** — bell with an unread badge; the dropdown is a notification center with history and a **Do-Not-Disturb** toggle plus a *"Mute for…"* submenu.
- **Clipboard** — recent text copies; click one to put it back on the clipboard.
- **Controls** — volume (scroll to adjust, click to mute), theme toggle, wallpaper, and power.

Everything animates — menus spring open, lists cascade in, badges pop, and the bar follows the active Catppuccin flavor. The whole config hot-reloads on save.

## HDR & color management

Color is managed per monitor in `hypr/hyprland.lua`:

- **HDR displays** run the full HDR10 path — BT.2020 (Rec. 2020) primaries + PQ (ST. 2084) transfer at 10-bit. SDR content inside the HDR container is tunable via `sdrbrightness` / `sdrsaturation`, with panel peak and SDR-white levels set by `max_luminance` / `sdr_max_luminance`.
- **SDR displays** use the `srgb` color space.

Each `hl.monitor({ … })` block is commented with what every knob does and how it maps to KDE's *maximum SDR brightness* / *SDR color intensity* settings.

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
3. Activate the Git pre-commit hook that lints staged files (`core.hooksPath` → `.githooks/`)
4. Install all required packages via `pacman`
5. Prompt to install [yay](https://github.com/Jguer/yay) and AUR packages (`quickshell-git`, Catppuccin themes/cursors, etc.)
6. Install Zen Browser via Flatpak and apply Catppuccin theme overrides
7. Create all config symlinks under `~/.config/`
8. Enable systemd user services (PipeWire, XDG portals) and the bluetooth service
9. Refresh the font cache

After the script finishes, place a wallpaper at `~/Pictures/` and update `~/dotfiles/hypr/hyprpaper.conf` with its path, then run `Hyprland`.

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

# Starship prompt — copy (not symlink): sync-theme.sh rewrites its palette line
cp ~/dotfiles/starship/starship.toml ~/.config/starship.toml
echo 'eval "$(starship init bash)"' >> ~/.bashrc

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
| `pacman-contrib` | `checkupdates` — repo update counts for the bar's update menu |
| `yay` *(AUR helper)* | Drives repo + AUR upgrades from the update menu (`paru` also supported) |

**Terminal & Editor**

| Package | Purpose |
|---------|---------|
| `kitty` | Terminal emulator |
| `neovim` | Text editor (v0.9+) |
| `starship` | Shell prompt (Catppuccin powerline) |

**Audio & Video**

| Package | Purpose |
|---------|---------|
| `pipewire` + `wireplumber` + `pipewire-pulse` | Audio stack |
| `pavucontrol` | Volume control GUI |
| `playerctl` | Media player control |
| `cava` | Audio spectrum feed for the bar visualizer |

**Input & Display**

| Package | Purpose |
|---------|---------|
| `brightnessctl` | Brightness control |
| `wl-clipboard` | Clipboard support + clipboard-history watcher |
| `grim` + `slurp` | Screenshot capture / region select |
| `ffmpeg` | HDR-safe screenshot conversion (PPM → PNG) |
| `jq` | Per-monitor screenshot enumeration |
| `libnotify` | Desktop notifications (`notify-send`) |
| `grimblast-git` *(AUR)* | Screenshot helper |
| `inotify-tools` | Brightness change monitoring |

**Network & Bluetooth**

| Package | Purpose |
|---------|---------|
| `networkmanager` + `network-manager-applet` | Network management |
| `bluez` + `bluez-utils` + `blueman` | Bluetooth stack and manager |

**Theme & Display tools**

| Package | Purpose |
|---------|---------|
| `nwg-look` | GTK theme picker (`SUPER+G`) |
| `xsettingsd` | Live X11/XWayland theme broadcast |
| `uwsm` | Session manager used for clean logout |

**Apps**

| Package | Purpose |
|---------|---------|
| `nautilus` | File manager (`SUPER+E`) |
| Zen Browser *(Flatpak)* | Web browser (`SUPER+B`) |

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
| `SUPER + C` | Close window |
| `SUPER + E` | File manager (Nautilus) |
| `SUPER + B` | Browser (Zen) |
| `SUPER + G` | GTK theme picker (nwg-look) |
| `SUPER + W` | Wallpaper switcher |
| `SUPER + H` | Keybind cheat sheet |
| `SUPER + M` | Exit Hyprland |
| `SUPER + J/K/L` | Move focus down/up/right |
| `SUPER + SHIFT + H/J/K/L` | Move window left/down/up/right |
| `SUPER + ALT + H/J/K/L` | Resize window left/down/up/right |
| `SUPER + 1–9`, `SUPER + 0` | Switch to workspace (`0` = workspace 10) |
| `SUPER + SHIFT + 1–9`, `SUPER + SHIFT + 0` | Move window to workspace |
| `SUPER + Scroll` | Cycle workspaces |
| Scroll over bar workspaces | Cycle this monitor's workspaces |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Toggle pseudotile |
| `SUPER + T` | Toggle split (dwindle) |
| `SUPER + S` | Screenshot a region → clipboard **and** `~/Pictures` |
| `SUPER + SHIFT + S` | Screenshot every monitor → `~/Pictures` |
| `XF86AudioRaiseVolume/LowerVolume/Mute` | Volume control |
| `XF86AudioPlay/Next/Prev` | Media control |
| `XF86MonBrightnessUp/Down` | Brightness control |

## Theming

The setup uses [Catppuccin](https://github.com/catppuccin/catppuccin) in two flavors:

- **Mocha** (dark) — default
- **Latte** (light) — toggle via the bar button, or press `SUPER+G` to open `nwg-look` and apply changes, or run directly:

```bash
~/dotfiles/scripts/sync-theme.sh latte   # switch to light
~/dotfiles/scripts/sync-theme.sh mocha   # switch to dark
```

`sync-theme.sh` propagates the flavor everywhere live — Hyprland borders, GTK/Qt, icons, cursors, Kitty, and the Starship prompt (its `palette` line is swapped so open shells re-color on the next prompt). The selected theme is persisted to `$XDG_CACHE_HOME/catppuccin-mode` and restored on next login.

`nwg-look` changes are snapshotted per mode to `~/.local/share/catppuccin/gtk-{3,4}.0-{mode}.ini` so that font, cursor, and widget variant choices survive theme switches.

## Development

Config files are syntax-checked by `scripts/verify.sh` — Lua via `luac`, shell via `bash -n`, QML via `qmllint`, plus brace-balance checks for Hyprland/Kitty configs:

```bash
scripts/verify.sh            # check every tracked file
scripts/verify.sh --staged   # check only staged files
```

`install.sh` wires this in as a Git pre-commit hook (`core.hooksPath` → `.githooks/pre-commit`), so broken configs are caught before they land in a commit. Bypass with `git commit --no-verify` when needed.

## License

Licensed under GPL-3.0. See [LICENSE](LICENSE) for details.
