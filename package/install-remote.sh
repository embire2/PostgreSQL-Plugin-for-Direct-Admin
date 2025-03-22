#!/bin/bash
#
# PostgreSQL Plugin for DirectAdmin
# Remote installation script - Installs directly from GitHub
#

# Define constants
GITHUB_REPO="https://github.com/yourusername/directadmin-postgresql-plugin"
TEMP_DIR="/tmp/directadmin-postgresql-plugin"
DA_ROOT="/usr/local/directadmin"
PLUGIN_NAME="postgresql_plugin"
PLUGIN_PATH="${DA_ROOT}/plugins/${PLUGIN_NAME}"
LOG_FILE="${DA_ROOT}/logs/postgresql_install.log"

# Create logs directory if it doesn't exist
mkdir -p "${DA_ROOT}/logs"

# Initialize log file
echo "[$( date '+%Y-%m-%d %H:%M:%S' )] Starting PostgreSQL plugin installation from GitHub" > $LOG_FILE

# Function to log messages
log_message() {
    echo "[$( date '+%Y-%m-%d %H:%M:%S' )] $1" >> $LOG_FILE
    echo "$1"
}

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    log_message "Error: This script must be run as root."
    exit 1
fi

# Check if DirectAdmin is installed
if [ ! -d "$DA_ROOT" ]; then
    log_message "Error: DirectAdmin installation not found at $DA_ROOT."
    exit 1
fi

# Clean up any existing temporary directory
rm -rf "$TEMP_DIR"

# Check if Git is installed
if command -v git &> /dev/null; then
    log_message "Git is installed. Cloning repository..."
    git clone "$GITHUB_REPO" "$TEMP_DIR"
    if [ $? -ne 0 ]; then
        log_message "Error: Failed to clone repository. Trying direct download instead."
        USE_WGET=1
    fi
else
    log_message "Git not found. Using direct download instead."
    USE_WGET=1
fi

# If Git failed or isn't installed, use wget to download
if [ "$USE_WGET" = "1" ]; then
    log_message "Downloading repository archive..."
    mkdir -p "$TEMP_DIR"
    wget -q "${GITHUB_REPO}/archive/refs/heads/main.zip" -O "/tmp/plugin.zip"
    if [ $? -ne 0 ]; then
        log_message "Error: Failed to download the repository. Please check your internet connection."
        exit 1
    fi
    
    log_message "Extracting archive..."
    unzip -q "/tmp/plugin.zip" -d "/tmp"
    mv "/tmp/directadmin-postgresql-plugin-main/"* "$TEMP_DIR/"
    rm -f "/tmp/plugin.zip"
fi

# Check if the download was successful
if [ ! -f "$TEMP_DIR/install.sh" ]; then
    log_message "Error: Installation files are incomplete. Download failed."
    exit 1
fi

# Run the local installation script
log_message "Running installation script..."
cd "$TEMP_DIR"
bash install.sh

# Clean up
log_message "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

log_message "Installation from GitHub completed. Please check the logs for any errors."
log_message "You can access the plugin at https://your-server:2222/CMD_PLUGINS/postgresql_plugin"

exit 0