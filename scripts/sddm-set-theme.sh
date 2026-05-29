#!/bin/bash
# /usr/local/bin/sddm-set-theme — run via sudo from sync-theme.sh
# Sets the active SDDM theme by writing /etc/sddm.conf.d/theme.conf
set -e
THEME="${1:?Usage: sddm-set-theme <theme-name>}"
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/theme.conf << EOF
[Theme]
Current=$THEME
EOF
