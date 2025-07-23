#!/bin/sh
set -e

echo "Activating feature 'opencode'"

# Get the options from environment variables
INSTALL_LOCATION=${INSTALLLOCATION:-""}
THEME=${THEME:-""}
MODEL=${MODEL:-""}
SMALL_MODEL=${SMALLMODEL:-""}
USERNAME=${USERNAME:-""}
AUTOUPDATE=${AUTOUPDATE:-"true"}
SHARE=${SHARE:-"disabled"}
LEADER_KEY=${LEADERKEY:-"ctrl+x"}

# Set default install location if not provided
if [ -z "$INSTALL_LOCATION" ]; then
    # Use OpenCode's default installation directory
    INSTALL_LOCATION="$HOME/.opencode/bin"
    echo "Using OpenCode's default installation location: $INSTALL_LOCATION"
else
    echo "Using custom installation location: $INSTALL_LOCATION"
fi
echo "Theme: $THEME"
echo "Model: $MODEL"
echo "Small model: $SMALL_MODEL"
echo "Username: $USERNAME"
echo "Auto-update: $AUTOUPDATE"
echo "Share: $SHARE"
echo "Leader key: $LEADER_KEY"

# The 'install.sh' entrypoint script is always executed as the root user.
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"
echo "The effective dev container containerUser is '$_CONTAINER_USER'"
echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"

# Install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl jq

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_LOCATION"

# Install opencode using the official install script
if [ "$INSTALL_LOCATION" != "$HOME/.opencode/bin" ]; then
    # Custom installation location
    export OPENCODE_INSTALL_DIR="$INSTALL_LOCATION"
    echo "Installing opencode to custom location: $OPENCODE_INSTALL_DIR..."
else
    # Use OpenCode's default location
    echo "Installing opencode to default location: $INSTALL_LOCATION..."
fi

if ! curl -fsSL https://opencode.ai/install | bash; then
    echo "Error: Failed to install opencode"
    exit 1
fi

# Verify installation
if [ ! -f "$INSTALL_LOCATION/opencode" ]; then
    echo "Error: opencode binary not found at $INSTALL_LOCATION/opencode"
    exit 1
fi

echo "OpenCode binary successfully installed at $INSTALL_LOCATION/opencode"

# Add installation directory to PATH if it's not already there
if ! echo "$PATH" | grep -q "$INSTALL_LOCATION"; then
    echo "Adding $INSTALL_LOCATION to PATH..."
    # Add to multiple shell configuration files to ensure it's available
    echo "export PATH=\"$INSTALL_LOCATION:\$PATH\"" >> /etc/environment
    
    # Add to bash configuration
    if [ -f /etc/bash.bashrc ]; then
        echo "export PATH=\"$INSTALL_LOCATION:\$PATH\"" >> /etc/bash.bashrc
    fi
    
    # Add to zsh configuration
    if [ -f /etc/zsh/zshenv ]; then
        echo "export PATH=\"$INSTALL_LOCATION:\$PATH\"" >> /etc/zsh/zshenv
    fi
    
    # Add to fish configuration if it exists
    if [ -d /etc/fish ]; then
        mkdir -p /etc/fish/conf.d
        echo "set -gx PATH $INSTALL_LOCATION \$PATH" > /etc/fish/conf.d/opencode.fish
    fi
    
    # Set PATH for current session
    export PATH="$INSTALL_LOCATION:$PATH"
else
    echo "$INSTALL_LOCATION is already in PATH"
fi

# Create opencode configuration directory for the container user
CONFIG_DIR=""
if [ -n "$_CONTAINER_USER_HOME" ]; then
    CONFIG_DIR="$_CONTAINER_USER_HOME/.opencode"
elif [ -n "$_REMOTE_USER_HOME" ]; then
    CONFIG_DIR="$_REMOTE_USER_HOME/.opencode"
else
    CONFIG_DIR="/root/.opencode"
fi

mkdir -p "$CONFIG_DIR"

# Create opencode configuration file
CONFIG_FILE="$CONFIG_DIR/config.json"
echo "Creating configuration file at $CONFIG_FILE..."

# Start with empty JSON object
echo '{}' > "$CONFIG_FILE"

# Add configuration options if they are provided using jq
if [ -n "$THEME" ]; then
    jq --arg theme "$THEME" '.theme = $theme' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

if [ -n "$MODEL" ]; then
    jq --arg model "$MODEL" '.model = $model' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

if [ -n "$SMALL_MODEL" ]; then
    jq --arg small_model "$SMALL_MODEL" '.small_model = $small_model' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

if [ -n "$USERNAME" ]; then
    jq --arg username "$USERNAME" '.username = $username' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

if [ "$AUTOUPDATE" = "true" ] || [ "$AUTOUPDATE" = "false" ]; then
    jq --argjson autoupdate "$AUTOUPDATE" '.autoupdate = $autoupdate' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

if [ -n "$SHARE" ]; then
    jq --arg share "$SHARE" '.share = $share' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

# Add keybinds configuration with leader key
if [ -n "$LEADER_KEY" ]; then
    jq --arg leader "$LEADER_KEY" '.keybinds.leader = $leader' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

# Validate the JSON
if ! jq '.' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Warning: Generated configuration file is not valid JSON"
    echo "Configuration content:"
    cat "$CONFIG_FILE"
else
    echo "Configuration file created successfully"
fi

# Set appropriate ownership for the config file
if [ -n "$_CONTAINER_USER" ] && [ "$_CONTAINER_USER" != "root" ]; then
    chown -R "$_CONTAINER_USER:$_CONTAINER_USER" "$CONFIG_DIR"
elif [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != "root" ]; then
    chown -R "$_REMOTE_USER:$_REMOTE_USER" "$CONFIG_DIR"
fi

echo "OpenCode installation completed successfully!"
echo "Binary installed to: $INSTALL_LOCATION/opencode"
echo "Configuration file created at: $CONFIG_FILE"
