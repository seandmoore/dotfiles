#!/usr/bin/env bash
# sddm-install.sh — install the Catppuccin SDDM login theme and the plumbing that
# lets the Mocha<->Latte theme toggle (sync-theme.sh) switch the login screen too.
#
# Run as root:   sudo bash ~/dotfiles/scripts/sddm-install.sh
#
# It performs four steps, all idempotent:
#   1. Download the catppuccin/sddm Mocha-mauve + Latte-mauve themes into
#      /usr/share/sddm/themes/ (names match SDDM_THEME in sync-theme.sh).
#   2. Install scripts/sddm-set-theme.sh -> /usr/local/bin/sddm-set-theme.
#   3. Install a NOPASSWD sudoers rule so sync-theme.sh can flip the theme without
#      a password prompt (locked to the two known theme names).
#   4. Seed /etc/sddm.conf.d/theme.conf so the login screen uses Mocha right away.
set -euo pipefail

CATPPUCCIN_SDDM_VERSION="v1.1.2"
THEMES=(catppuccin-mocha-mauve catppuccin-latte-mauve)
DEFAULT_THEME="catppuccin-mocha-mauve"

info() { printf '\e[34m[info]\e[0m  %s\n' "$*"; }
ok()   { printf '\e[32m[ ok ]\e[0m  %s\n' "$*"; }
die()  { printf '\e[31m[fail]\e[0m  %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash $0"

# Who will be allowed to run sddm-set-theme without a password.
TARGET_USER="${SUDO_USER:-root}"
[[ "$TARGET_USER" != "root" ]] || die "Run via sudo (need SUDO_USER for the sudoers rule), not as a root login."

# Repo dir (this script lives in <repo>/scripts/).
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── 1. Themes ────────────────────────────────────────────────────────────────
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for theme in "${THEMES[@]}"; do
    dest="/usr/share/sddm/themes/$theme"
    if [[ -f "$dest/metadata.desktop" ]]; then
        ok "SDDM theme already present: $theme"
        continue
    fi
    info "Downloading SDDM theme: $theme ($CATPPUCCIN_SDDM_VERSION) ..."
    url="https://github.com/catppuccin/sddm/releases/download/${CATPPUCCIN_SDDM_VERSION}/${theme}-sddm.zip"
    curl -fsSL -o "$tmp/$theme.zip" "$url" || die "Download failed: $url"
    if command -v unzip &>/dev/null; then
        unzip -q -o "$tmp/$theme.zip" -d "$tmp/$theme-x"
    else
        python3 -c "import zipfile,sys; zipfile.ZipFile('$tmp/$theme.zip').extractall('$tmp/$theme-x')"
    fi
    # The zip contains a single top-level dir named exactly "$theme".
    [[ -d "$tmp/$theme-x/$theme" ]] || die "Unexpected zip layout for $theme"
    mkdir -p /usr/share/sddm/themes
    rm -rf "$dest"
    cp -a "$tmp/$theme-x/$theme" "$dest"
    ok "Installed SDDM theme: $theme"
done

# ── 2. sddm-set-theme helper ─────────────────────────────────────────────────
install -Dm755 "$REPO_DIR/scripts/sddm-set-theme.sh" /usr/local/bin/sddm-set-theme
ok "Installed /usr/local/bin/sddm-set-theme"

# ── 3. NOPASSWD sudoers rule (locked to the known theme names) ───────────────
sudoers_file="/etc/sudoers.d/10-sddm-set-theme"
{
    printf '# Managed by dotfiles (sddm-install.sh): let the theme toggle flip the\n'
    printf '# SDDM login theme without a password. Restricted to the known themes.\n'
    for theme in "${THEMES[@]}"; do
        printf '%s ALL=(root) NOPASSWD: /usr/local/bin/sddm-set-theme %s\n' "$TARGET_USER" "$theme"
    done
} > "$sudoers_file.tmp"
chmod 0440 "$sudoers_file.tmp"
if visudo -cf "$sudoers_file.tmp" >/dev/null; then
    mv "$sudoers_file.tmp" "$sudoers_file"
    ok "Installed sudoers rule: $sudoers_file"
else
    rm -f "$sudoers_file.tmp"
    die "Generated sudoers file failed validation; not installing."
fi

# ── 4. Seed the active theme ─────────────────────────────────────────────────
/usr/local/bin/sddm-set-theme "$DEFAULT_THEME"
ok "Set active SDDM theme -> $DEFAULT_THEME (/etc/sddm.conf.d/theme.conf)"

echo
ok "Done. Test without logging out:  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/$DEFAULT_THEME"
echo "    (the theme applies on the next login screen / reboot)"
