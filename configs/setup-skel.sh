#!/bin/bash
# Setup /etc/skel with basic Aura configs for ISO

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AURA_SOURCE="$(cd "$SCRIPT_DIR/../../aura" && pwd)"
SKEL_DIR="$SCRIPT_DIR/airootfs/etc/skel"

echo "Setting up /etc/skel with Aura configs..."
echo "  Aura source: $AURA_SOURCE"
echo "  Skel target: $SKEL_DIR"

# Clean old skel directory for fresh build
if [ -d "$SKEL_DIR" ]; then
    echo "  Cleaning old skel directory..."
    sudo rm -rf "$SKEL_DIR"
fi

# Create skel directory
mkdir -p "$SKEL_DIR/.config"
mkdir -p "$SKEL_DIR/.local/bin"

# Copy all config directories from aura/default to .config (except hypr)
echo "Copying configs from aura/default..."
for dir in "$AURA_SOURCE/default"/*; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        # Skip hypr and sddm directories, we'll handle them specially
        # sddm is a system theme, not a user config
        if [ "$dirname" != "hypr" ] && [ "$dirname" != "sddm" ] && [ "$dirname" != "plymouth" ]; then
            echo "  - Copying $dirname"
            cp -r "$dir" "$SKEL_DIR/.config/"
        fi
    fi
done

# Copy hypr folder to .config/hypr
if [ -d "$AURA_SOURCE/default/hypr" ]; then
    echo "  - Copying hypr to .config/hypr"
    cp -r "$AURA_SOURCE/default/hypr" "$SKEL_DIR/.config/"
fi

# Create .config/aura directory with empty user config files
echo "  - Creating .config/aura directory"
mkdir -p "$SKEL_DIR/.config/aura"

# Create empty user config files if they don't exist
if [ ! -f "$SKEL_DIR/.config/aura/hypr-user.conf" ]; then
    cat > "$SKEL_DIR/.config/aura/hypr-user.conf" << 'EOF'
# User-specific Hyprland configuration
# Add your custom Hyprland configs here
# This file is sourced by hyprland.conf

EOF
fi

if [ ! -f "$SKEL_DIR/.config/aura/hypr-vars.conf" ]; then
    cat > "$SKEL_DIR/.config/aura/hypr-vars.conf" << 'EOF'
# User-specific Hyprland variables
# Add your custom variables here
# This file is sourced by variables.conf

EOF
fi

# Copy config files from aura/default
echo "Copying config files..."
[ -f "$AURA_SOURCE/default/starship.toml" ] && cp "$AURA_SOURCE/default/starship.toml" "$SKEL_DIR/.config/"
[ -f "$AURA_SOURCE/default/bashrc" ] && cp "$AURA_SOURCE/default/bashrc" "$SKEL_DIR/.bashrc"
[ -f "$AURA_SOURCE/default/xcompose" ] && cp "$AURA_SOURCE/default/xcompose" "$SKEL_DIR/.XCompose"
[ -f "$AURA_SOURCE/default/xdg-terminals.list" ] && cp "$AURA_SOURCE/default/xdg-terminals.list" "$SKEL_DIR/.config/"

# Copy aura bin scripts
echo "Copying aura bin scripts..."
cp -r "$AURA_SOURCE/bin"/* "$SKEL_DIR/.local/bin/"

# Make all bin scripts executable
chmod +x "$SKEL_DIR/.local/bin"/*

# Copy aura-cli source code to .local/src
echo "Copying aura-cli source code..."
mkdir -p "$SKEL_DIR/.local/src"
CLI_SOURCE="$(cd "$SCRIPT_DIR/../../aura-cli" && pwd)"
if [ -d "$CLI_SOURCE" ]; then
    cp -r "$CLI_SOURCE" "$SKEL_DIR/.local/src/aura-cli"
    echo "  - aura-cli source copied"
else
    echo "  - WARNING: aura-cli source not found at $CLI_SOURCE"
fi

# Copy aura-shell source code to .config/quickshell/aura
echo "Copying aura-shell source code..."
mkdir -p "$SKEL_DIR/.config/quickshell"
SHELL_SOURCE="$(cd "$SCRIPT_DIR/../../Aura-Shell" && pwd)"
if [ -d "$SHELL_SOURCE" ]; then
    cp -r "$SHELL_SOURCE" "$SKEL_DIR/.config/quickshell/aura"
    echo "  - aura-shell source copied"
else
    echo "  - WARNING: aura-shell source not found at $SHELL_SOURCE"
fi

echo "✅ /etc/skel setup complete!"
echo "New users will get:"
echo "  - Complete Hyprland configs (.config/hypr)"
echo "  - Aura configs (.config/aura)"
echo "  - All app configs (foot, ghostty, fastfetch, etc.)"
echo "  - Aura utility scripts (~/.local/bin)"
echo "  - aura-cli source code (~/.local/src/aura-cli)"
echo "  - aura-shell source code (~/.config/quickshell/aura)"
