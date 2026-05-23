#!/bin/bash

# Simple Dotfiles Installation Script
# This script sets up your dotfiles by cloning the repo and creating links

set -e

# Where to install the dotfiles
REPO_URL="https://github.com/seandmoore/dotfiles.git"
INSTALL_DIR="$HOME/dotfiles"

echo "Installing dotfiles..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed"
    exit 1
fi

# Clone or update the repository
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing dotfiles..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo "Downloading dotfiles..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo "Done! Your dotfiles are ready."
echo "Next: Edit this script to add your config file links"

