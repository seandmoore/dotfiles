# dotfiles

A Hyprland desktop configuration themed with [Catppuccin](https://github.com/catppuccin/catppuccin) (Mocha dark / Latte light).

## Components

| Component | Description |
|-----------|-------------|
| **Hyprland** | Tiling Wayland compositor — Lua config (0.55+) covering animations, borders, keybinds, touchpad gestures, and per-monitor HDR and wide-gamut color management. The same config auto-adapts to a desktop or a laptop (see [Laptop support](#laptop-support)). |
| **Quickshell** | Status bar with audio visualizer, CPU/RAM graphs, and media controls, plus an app launcher with file search, a Places menu, a notification center with Do-Not-Disturb, clipboard history, a system-update menu (pacman + AUR + Flatpak), volume/brightness OSD, and a keybind cheat sheet. |
| **Hyprlock** | Lock screen with a blurred background and clock. |
| **Hypridle** | Idle daemon (dim, lock, display off, suspend). |
| **Hyprpaper** | Wallpaper manager. |
| **Hyprpolkitagent** | Authentication agent for privilege prompts. |
| **SDDM** | Catppuccin-themed login screen; follows the active flavor via `sync-theme.sh`. |
| **Kitty** | Terminal emulator with Catppuccin colors, powerline tabs, a cursor trail, and a background matched to the GTK apps. |
| **Starship** | Catppuccin powerline shell prompt; follows the active flavor. |
| **Neovim** | Editor configured with lazy.nvim, Telescope, Treesitter, and Lualine. |
| **xsettingsd** | Broadcasts GTK/cursor theme changes to XWayland apps. |
| **nwg-look** | GTK theme picker; selections are saved per mode and restored on theme switch. |

## Status bar

A single centered bar that groups every widget into one element, left to right:

- **App menu** — click for the launcher (with a Files mode that searches `~`), hover for the installed-app list. Apps are scanned and cached at startup, and the list refreshes automatically when apps are installed or removed (pacman, AUR, Flatpak, or a manual `.desktop` drop).
- **Places** — a folder icon listing your home folders; click one to open it in Nautilus. Folders are scanned at startup.
- **Workspaces** — per-monitor indicator; scroll the dots to cycle that monitor's workspaces. The hover menu shows per-workspace window counts.
- **Visualizer** — a waveform driven by [`cava`](https://github.com/karlstav/cava).
- **Clock** — hover opens the calendar.
- **System** — CPU and RAM usage graphs (hover for per-core and memory detail) and the MPRIS media player.
- **Battery** — charge percentage and an icon that reflects the charging state; hover for a dropdown with a charge bar, time-to-full/empty, power draw, and battery health. Shown only on machines that have a battery (laptops); it hides itself on the desktop.
- **Updates** — package icon with a count badge; the dropdown lists official-repo, AUR, and Flatpak updates and offers **Update All**, which opens a terminal running `yay`/`paru -Syu` and `flatpak update`.
- **Notifications** — bell with an unread badge; the dropdown is a notification center with history, a **Do-Not-Disturb** toggle, and a *"Mute for…"* submenu.
- **Clipboard** — recent text copies; click one to restore it to the clipboard.
- **Display** — DP-1 color controls: HDR/SDR and vibrant/accurate-sRGB toggles, a night-shift toggle, an **Auto (sunset → sunrise)** schedule, and a color-temperature slider. These drive the same scripts as the `SUPER+SHIFT+{D,A,N}` binds.
- **Controls** — volume (scroll to adjust, click to mute), theme toggle, wallpaper switcher, and power.

Widgets are animated, and the bar follows the active Catppuccin flavor. The config hot-reloads on save.

## HDR & color management

Color is managed per monitor in `hypr/hyprland.lua`:

- **HDR displays** use the HDR10 path: BT.2020 (Rec. 2020) primaries with PQ (ST. 2084) transfer at 10-bit. SDR content inside the HDR container is adjusted via `sdrbrightness` / `sdrsaturation`, and panel peak and SDR-white levels via `max_luminance` / `sdr_max_luminance`.
- **SDR displays** use the `srgb` color space.

**HDR + vibrant** (the login default) approximates KDE Plasma's *SDR Color Intensity* slider at 100%. At that setting KDE reinterprets sRGB content with full BT.2020 primaries ([`sdrGamutWideness = 1.0`](https://zamundaaa.github.io/wayland/2023/12/18/update-on-hdr-and-colormanagement-in-plasma.html)), which a QD-OLED panel clips to its native P3 gamut. Hyprland's `sdrsaturation` uses different math (a luma-anchored chroma extrapolation on PQ-encoded values in `cm_helpers.glsl`), so no value matches exactly. **`sdrsaturation = 1.35`** is the least-error fit (minimum mean ΔE\_ITP over the sRGB cube against the KDE target, cross-checked in Oklab). Vibrant **SDR** mode (`cm = "wide"`) produces the same result natively, since wide-gamut mode renders sRGB values with the panel's primaries directly.

The Quickshell UI and Kitty use opaque surfaces (no compositor blur), matched to the GTK apps such as Nautilus for legibility. This also keeps them consistent across HDR and SDR, since Hyprland cannot blur a color-managed HDR output. Opacity is controlled by `Frost.glass()` in `quickshell/theme/Frost.qml` (return `a` instead of `1.0` for a translucent look) and Kitty's `background_opacity`.

Each `hl.monitor({ … })` block is commented with what each setting does and how it maps to KDE's *maximum SDR brightness* and *SDR color intensity* settings.

These modes are switchable at runtime, both from the keybinds (`SUPER+SHIFT+D` HDR/SDR, `SUPER+SHIFT+A` vibrant/accurate sRGB, `SUPER+SHIFT+N` night shift) and from the bar's **Display** dropdown, which adds a color-temperature slider and an **Auto** night-shift schedule (warm shift on at sunset, off at sunrise). Sun position is computed locally from a cached latitude/longitude (IP-geolocated on first enable; override with `scripts/night-shift.sh location <lat> <lon>`). Taking manual control of the toggle or slider exits Auto mode. State is seeded to the login defaults on startup and persisted under `~/.cache/hypr/`, so Auto mode resumes across logins. The toggles are driven by `scripts/{display-color,hdr-toggle,color-accuracy-toggle,night-shift}.sh`; night shift uses `hyprsunset`.

## VRAM foreground boosting (dmemcg)

Gives the focused window priority on GPU VRAM, evicting background apps to slower system RAM (GTT) first when VRAM is contended — the Hyprland counterpart to KDE's `plasma-foreground-booster`. It builds on the DRM device-memory cgroup controller (`CONFIG_CGROUP_DMEM`, mainline since Linux 6.14, also known as "Valve's VRAM patch").

A user daemon (`vram/hypr-dmemcg-foreground`) watches Hyprland's `socket2` and, on each focus change, raises `dmem.low` on the focused window's cgroup and releases the previous one. The AUR `dmemcg-booster` package enables the controller tree-wide and sets baseline protection on `app.slice`; a custom `steam.desktop` launches Steam under `app.slice` so the boost applies to it. The full profile of `install.sh` symlinks these files, enables `hypr-dmemcg-foreground.service`, and installs a pacman hook (`scripts/check-dmem-config.sh`) that verifies `CONFIG_CGROUP_DMEM` is present after each kernel update. See [`vram/README.md`](vram/README.md) for details.

## Screenshots

> Screenshots coming soon.

## Installation (Arch Linux)

The install script handles packages, symlinks, and services, and offers two profiles:

**Minimal** — recommended for installing these dotfiles on your own machine. Provides the complete desktop (Hyprland, the Quickshell bar/launcher/notifications, Catppuccin theming including SDDM, Kitty, Neovim, Starship, audio, screenshots, and Firefox) without the hardware- and workflow-specific extras:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/install.sh) --minimal
```

**Full** — everything in Minimal plus extras tuned for the author's machine (ROCm for AMD GPU compute, VRAM foreground boosting, the Ollama ROCm drop-in, AI-CLI shell aliases, Rust PATH wiring, and Zen Browser):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/install.sh)
```

Run with no flag to select a profile interactively, or preset it with `DOTFILES_PROFILE=minimal`. Either profile will:

1. Verify you are on Arch Linux
2. Clone or update the dotfiles repo to `~/dotfiles`
3. Activate the Git pre-commit hook that lints staged files (`core.hooksPath` → `.githooks/`)
4. Install all required packages via `pacman`
5. Prompt to install [yay](https://github.com/Jguer/yay) and AUR packages (Catppuccin themes/cursors)
6. Install Firefox via Flatpak (set as the default browser) and apply Catppuccin Flatpak theme overrides
7. Install the Catppuccin **SDDM** login theme plus the helper that lets the Mocha/Latte toggle switch the login screen too
8. Create all config symlinks under `~/.config/`
9. Seed the active Catppuccin flavor via `sync-theme.sh` (the same path the bar toggle uses) — generates the libadwaita `gtk.css`, kitty colors, Starship palette and Qt/Kvantum themes
10. Enable systemd user services (PipeWire, XDG portals) and the bluetooth service
11. Refresh the font cache

The **full** profile additionally:

- Configures **ROCm** for AMD GPUs (graphical-session env + adds you to the `render`/`video` groups) and installs the Ollama ROCm drop-in
- Sets up **VRAM foreground boosting** (dmemcg) — the `dmemcg-booster` AUR package, focus daemon + Steam launcher, its systemd user service, and the `CONFIG_CGROUP_DMEM` kernel-check pacman hook
- Installs **Zen Browser** (Flatpak) and wires AI-CLI shell aliases (Claude Code / OpenCode) and Rust (`~/.cargo`) into your shell rc files

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
| `quickshell` *(repo)* | Status bar, launcher, notifications, OSD |
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
| `grimblast` *(AUR)* | Screenshot helper |
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
| `sddm` | Login / display manager (Catppuccin themed) |
| `hyprsunset` | Night-shift color-temperature daemon (`SUPER+SHIFT+N`) |
| `dmemcg-booster` *(AUR)* | Enables the `dmem` cgroup controller + baseline VRAM protection for foreground boosting — full profile only |

**Apps**

| Package | Purpose |
|---------|---------|
| `nautilus` | File manager (`SUPER+E`) |
| Firefox *(Flatpak)* | Default web browser, `SUPER+B` (themed with the Catppuccin add-on) |
| Zen Browser *(Flatpak)* | Secondary web browser — full profile only |

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
| `SUPER + B` | Browser (Firefox) |
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
| `` SUPER + ` `` | Toggle scratchpad (special workspace) |
| `` SUPER + SHIFT + ` `` | Send window to scratchpad |
| `SUPER + S` | Screenshot a region → clipboard **and** `~/Pictures` |
| `SUPER + SHIFT + S` | Screenshot every monitor → `~/Pictures` |
| `SUPER + SHIFT + D` | Toggle HDR ↔ SDR (DP-1) |
| `SUPER + SHIFT + A` | Toggle vibrant ↔ accurate sRGB color (DP-1) |
| `SUPER + SHIFT + N` | Toggle night shift (warm color temperature) |
| `XF86AudioRaiseVolume/LowerVolume/Mute` | Volume control |
| `XF86AudioPlay/Next/Prev` | Media control |
| `XF86MonBrightnessUp/Down` | Brightness control |

## Touchpad gestures

Defined in `hypr/hyprland.lua` with Hyprland's gesture system. The rule of thumb is **3 fingers navigate, 4 fingers manage the focused window**. They're harmless on the desktop (with no touchpad they simply never fire), and the brightness/volume media keys above also work on a laptop's function row.

| Gesture | Action |
|---------|--------|
| 3-finger swipe ←/→ | Switch workspace (with momentum follow) |
| 3-finger swipe ↑ | Toggle fullscreen on the focused window |
| 3-finger swipe ↓ | Toggle floating on the focused window |
| 4-finger swipe ←/→ | Throw the focused window to the adjacent workspace (and follow) |
| 4-finger swipe ↑ | Show / hide the scratchpad (special workspace) |

Touchpad behavior (tap-to-click, natural scroll, tap-and-drag, disable-while-typing) is configured in the same file's `input.touchpad` block.

## Laptop support

The config serves both a desktop and a laptop from one file — no per-machine branches to maintain. At startup `hyprland.lua` checks for a battery under `/sys/class/power_supply` and adapts:

- **Monitors** — the desktop's `DP-1` (HDR) + `HDMI-A-1` (portrait) blocks only match when those outputs are present, so on a laptop they're inert; the internal panel (`eDP-1`) is driven by the fallback rule (native mode, auto scale). Set an explicit `scale` there if you prefer integer scaling.
- **Workspaces** — on the desktop, 1–5 are pinned to `DP-1` and 6–10 to `HDMI-A-1`; on a laptop all ten stay persistent but unpinned, so they aren't stranded on absent outputs.
- **Autostart** — the `focusmonitor DP-1` nudge and the DP-1 HDR/vibrant colour-mode seeds are skipped on a laptop. Night shift (`hyprsunset`) still runs on both.
- **Bar** — the battery indicator appears only when a battery is present.
- **Lid & idle** — `hypridle` already dims, locks, blanks, and suspends on a timer, and `before_sleep_cmd = loginctl lock-session` locks before any suspend (including a lid-close suspend handled by logind).

## Theming

The setup uses [Catppuccin](https://github.com/catppuccin/catppuccin) in two flavors:

- **Mocha** (dark) — default
- **Latte** (light) — toggle via the bar button, or press `SUPER+G` to open `nwg-look` and apply changes, or run directly:

```bash
~/dotfiles/scripts/sync-theme.sh latte   # switch to light
~/dotfiles/scripts/sync-theme.sh mocha   # switch to dark
```

`sync-theme.sh` applies the flavor across Hyprland borders, GTK/Qt, icons, cursors, Kitty, and the Starship prompt (its `palette` line is swapped so open shells re-color on the next prompt). The selected theme is persisted to `$XDG_CACHE_HOME/catppuccin-mode` and restored on next login. It also re-themes the **SDDM** login screen.

**Firefox** keeps its default UI and is themed with the [Catppuccin browser add-on](https://github.com/catppuccin/firefox) rather than a custom userChrome.

`nwg-look` changes are saved per mode to `~/.local/share/catppuccin/gtk-{3,4}.0-{mode}.ini` so that font, cursor, and widget choices survive theme switches.

## Development

Config files are syntax-checked by `scripts/verify.sh` — Lua via `luac`, shell via `bash -n`, QML via `qmllint`, plus brace-balance checks for Hyprland/Kitty configs:

```bash
scripts/verify.sh            # check every tracked file
scripts/verify.sh --staged   # check only staged files
```

`install.sh` wires this in as a Git pre-commit hook (`core.hooksPath` → `.githooks/pre-commit`), so broken configs are caught before they land in a commit. Bypass with `git commit --no-verify` when needed.

## License

Licensed under GPL-3.0. See [LICENSE](LICENSE) for details.
