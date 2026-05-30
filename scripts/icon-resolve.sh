#!/usr/bin/env bash
# icon-resolve.sh <icon-name-or-path> [icon-theme] [theme|original]
#
# mode=theme    (default): the icon theme (Papirus) is preferred, app's own icon as
#                          fallback — used for normal apps.
# mode=original          : skip the theme entirely and use the app's OWN icon — used for
#                          games, so they show real art instead of a Papirus stand-in.
#
# Resolve a freedesktop `Icon=` value to an on-disk file path for the quickshell
# launcher. The active theme (Papirus) is tried first; if it has no icon for the app,
# fall back to the app's OWN icon (hicolor / user icons incl. Steam game icons under
# ~/.local/share/icons / flatpak exports / pixmaps). Prints the path, or nothing — in
# which case the launcher shows its built-in letter placeholder (only when no icon
# exists anywhere).
#
# Notes:
#  - Papirus-Dark keeps almost no app icons itself; they live in base Papirus and are
#    reached via inheritance. So we search the theme, its base variant (…-Dark → …), its
#    index.theme Inherits=, and finally hicolor.
#  - Within a theme, prefer a scalable SVG, else the largest raster size (HiDPI @2x dirs
#    are handled), preferring SVG and the apps/ category on ties.
set -uo pipefail
shopt -s nullglob

icon="${1:-}"; theme="${2:-Papirus-Dark}"; mode="${3:-theme}"   # mode: theme | original
[ -n "$icon" ] || exit 0

# Some .desktop files give an absolute path directly — honour it if it's real.
case "$icon" in
    /*) [ -f "$icon" ] && printf '%s\n' "$icon"; exit 0 ;;
esac

xdg="${XDG_DATA_HOME:-$HOME/.local/share}"
icon_bases=( /usr/share/icons "$HOME/.local/share/icons" )

# ── Build the theme search order ──────────────────────────────────────────────
themes=()
add_theme() { case " ${themes[*]-} " in *" $1 "*) ;; *) themes+=("$1") ;; esac; }

# Games (mode=original) skip the icon theme entirely and use the app's OWN icon, so each
# game shows its real art rather than a Papirus stand-in — and the rule applies to any
# future game too. Everything else is themed (Papirus) first, own icon only as fallback.
if [ "$mode" != "original" ]; then
    add_theme "$theme"
    # Papirus-Dark / Papirus-Light share their app icons with base Papirus.
    base_variant="${theme%-[Dd]ark}"; base_variant="${base_variant%-[Ll]ight}"
    [ "$base_variant" != "$theme" ] && add_theme "$base_variant"
    # Honour the theme's own Inherits= chain (one level is enough in practice).
    for b in "${icon_bases[@]}"; do
        idx="$b/$theme/index.theme"
        if [ -f "$idx" ]; then
            for i in $(sed -n 's/^Inherits=//p' "$idx" | head -1 | tr ',' ' '); do add_theme "$i"; done
            break
        fi
    done
fi
add_theme hicolor   # freedesktop fallback theme (apps + Steam drop their own icons here)

# Concrete directories to search, in priority order.
dirs=()
for t in "${themes[@]}"; do for b in "${icon_bases[@]}"; do dirs+=("$b/$t"); done; done
dirs+=( "/var/lib/flatpak/exports/share/icons/hicolor" "$xdg/flatpak/exports/share/icons/hicolor" )

# ── Search ────────────────────────────────────────────────────────────────────
for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    # Globs with * are expanded (nullglob drops misses); the scalable/apps patterns have
    # no metacharacter and stay literal, so every candidate is verified with -f.
    cands=()
    for p in \
        "$d"/scalable/apps/"$icon".svg   "$d"/scalable/*/"$icon".svg \
        "$d"/*/apps/"$icon".svg          "$d"/*/apps/"$icon".png \
        "$d"/*/*/"$icon".svg             "$d"/*/*/"$icon".png
    do
        [ -f "$p" ] && cands+=("$p")
    done
    [ ${#cands[@]} -gt 0 ] || continue

    best=$(printf '%s\n' "${cands[@]}" | awk '
        {
            p = $0; score = 500                                      # unsized (pixmaps etc.)
            if (p ~ /\/scalable\//)                       score = -1000           # vector = best
            else if (match(p, /\/([0-9]+)x[0-9]+/, a)) {  score = 1000 - a[1]      # bigger raster wins
                                                          if (p ~ /@2x\//) score -= 1 }  # prefer HiDPI on a tie
            if (p ~ /\.svg$/)   score -= 1               # prefer svg over png on a size tie
            if (p ~ /\/apps\//) score -= 2               # prefer the apps/ category
            print score "\t" p
        }' | sort -n | head -1 | cut -f2-)
    [ -n "$best" ] && { printf '%s\n' "$best"; exit 0; }
done

# Flat icon dirs — icon files sit directly in the folder (no size/category nesting).
for ext in svg png xpm; do
    f="/usr/share/pixmaps/$icon.$ext"
    [ -f "$f" ] && { printf '%s\n' "$f"; exit 0; }
done

exit 0
