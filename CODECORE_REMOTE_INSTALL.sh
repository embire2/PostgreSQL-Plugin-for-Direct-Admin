#!/bin/bash
#
# PostgreSQL Plugin for DirectAdmin - Remote Installation Script
# Download and install from codecore.codes
#

# Define constants
DOWNLOAD_URL="https://codecore.codes/software/postgresql_plugin-2.0.tar.gz"
TEMP_DIR="/tmp/postgresql_plugin"
DA_ROOT="/usr/local/directadmin"
LOG_FILE="${DA_ROOT}/logs/postgresql_install.log"

# Initialize log file
echo "[$( date '+%Y-%m-%d %H:%M:%S' )] Starting PostgreSQL plugin installation from codecore.codes" > $LOG_FILE

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
mkdir -p "$TEMP_DIR"

# Download the plugin package
log_message "Downloading plugin package from codecore.codes..."
if command -v curl &> /dev/null; then
    curl -sSL "$DOWNLOAD_URL" -o "$TEMP_DIR/postgresql_plugin.tar.gz"
elif command -v wget &> /dev/null; then
    wget -q "$DOWNLOAD_URL" -O "$TEMP_DIR/postgresql_plugin.tar.gz"
else
    log_message "Error: Neither curl nor wget is installed. Please install one of them and try again."
    exit 1
fi

# Check if the download was successful
if [ ! -f "$TEMP_DIR/postgresql_plugin.tar.gz" ]; then
    log_message "Error: Failed to download the plugin package. Please check your internet connection."
    exit 1
fi

# Extract the package
log_message "Extracting plugin package..."
tar -xzf "$TEMP_DIR/postgresql_plugin.tar.gz" -C "$TEMP_DIR"
if [ $? -ne 0 ]; then
    log_message "Error: Failed to extract the plugin package."
    exit 1
fi

# Find the installation directory
INSTALL_DIR=$(find "$TEMP_DIR" -name "install.sh" -not -path "*/\.*" | head -n 1 | xargs dirname)
if [ -z "$INSTALL_DIR" ]; then
    log_message "Error: Could not find the installation script in the package."
    exit 1
fi

# Run the installation script
log_message "Running installation script..."
cd "$INSTALL_DIR"
bash install.sh

# Check if installation was successful
if [ $? -ne 0 ]; then
    log_message "Error: Installation failed. Please check the logs for details."
    exit 1
fi

# Clean up
log_message "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

log_message "Installation from codecore.codes completed successfully."
log_message "You can access the plugin at https://your-server:2222/CMD_PLUGINS/postgresql_plugin"

exit 0