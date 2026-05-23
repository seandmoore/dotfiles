#!/bin/bash

# ============================================================================
# Dotfiles Installation Script
# ============================================================================
# This script automates the setup of your development environment by
# cloning the dotfiles repository and creating necessary symlinks.
#
# Usage: ./install.sh
# ============================================================================

set -e  # Exit on error

# Configuration Variables
REPO_URL="https://github.com/seandmoore/dotfiles.git"
REPO_NAME="dotfiles"
INSTALL_DIR="$HOME/$REPO_NAME"

# ============================================================================
# Helper Functions
# ============================================================================

# Print colored output for better readability
print_status() {
    echo "▶ $1"
}

print_success() {
    echo "✓ $1"
}

print_error() {
    echo "✗ $1" >&2
}

# ============================================================================
# Main Installation Steps
# ============================================================================

print_status "Starting dotfiles installation..."

# Step 1: Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install git first."
    exit 1
fi
print_success "Git is installed"

# Step 2: Clone the repository
if [ -d "$INSTALL_DIR" ]; then
    print_status "Dotfiles directory already exists. Updating..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    print_status "Cloning dotfiles repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi
print_success "Repository cloned/updated"

# Step 3: Create symlinks for dotfiles (customize as needed)
# Uncomment and modify these lines based on your dotfiles structure:
# ln -sf "$INSTALL_DIR/.bashrc" "$HOME/.bashrc"
# ln -sf "$INSTALL_DIR/.gitconfig" "$HOME/.gitconfig"

print_success "Dotfiles installation complete!"
print_status "Next steps: Review and customize symlinks in this script"
