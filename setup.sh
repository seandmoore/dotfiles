#!/bin/bash

# Dotfiles Setup Script
# Run with: curl -fsSL https://raw.githubusercontent.com/seandmoore/dotfiles/main/setup.sh | sh

set -e

REPO_URL="https://github.com/seandmoore/dotfiles.git"
INSTALL_DIR="$HOME/dotfiles"

echo "🚀 Installing dotfiles..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed"
    exit 1
fi

# Clone or update the repository
if [ -d "$INSTALL_DIR" ]; then
    echo "📦 Updating existing dotfiles..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo "⬇️  Downloading dotfiles..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo "✅ Done! Your dotfiles are ready."
echo "📍 Location: $INSTALL_DIR"
echo "📝 Next: Edit $INSTALL_DIR/install.sh to add your config file links"
