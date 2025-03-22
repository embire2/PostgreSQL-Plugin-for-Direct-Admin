#!/bin/bash
#
# PostgreSQL Plugin for DirectAdmin
# Update script
#

# Define constants
DA_ROOT="/usr/local/directadmin"
PLUGIN_NAME="postgresql_plugin"
PLUGIN_PATH="${DA_ROOT}/plugins/${PLUGIN_NAME}"
CONFIG_PATH="${DA_ROOT}/conf"
LOG_FILE="${DA_ROOT}/logs/postgresql_update.log"
TEMP_DIR="/tmp/postgresql_plugin_update"
DOWNLOAD_URL="https://codecore.codes/software/postgresql_plugin-2.2.tar.gz"

# Create logs directory if it doesn't exist
mkdir -p "${DA_ROOT}/logs"

# Initialize log file
echo "[$( date '+%Y-%m-%d %H:%M:%S' )] Starting PostgreSQL plugin update" > $LOG_FILE

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

# Check if the plugin is installed
if [ ! -d "$PLUGIN_PATH" ]; then
    log_message "Error: PostgreSQL plugin is not installed. Please install it first."
    exit 1
fi

# Get current version
CURRENT_VERSION=$(grep -oP 'postgresql_plugin=\K[0-9.]+' "${CONFIG_PATH}/plugins.conf" 2>/dev/null || echo "unknown")
log_message "Current version: ${CURRENT_VERSION}"
log_message "Target version: 2.2"

# Create temporary directory
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download the latest version
log_message "Downloading latest version..."
if command -v curl &> /dev/null; then
    curl -sSL "$DOWNLOAD_URL" -o "${TEMP_DIR}/postgresql_plugin.tar.gz"
elif command -v wget &> /dev/null; then
    wget -q "$DOWNLOAD_URL" -O "${TEMP_DIR}/postgresql_plugin.tar.gz"
else
    log_message "Error: Neither curl nor wget is installed. Please install one of them and try again."
    exit 1
fi

# Check if the download was successful
if [ ! -f "${TEMP_DIR}/postgresql_plugin.tar.gz" ]; then
    log_message "Error: Failed to download the plugin package. Please check your internet connection."
    exit 1
fi

# Extract the package
log_message "Extracting plugin package..."
tar -xzf "${TEMP_DIR}/postgresql_plugin.tar.gz" -C "$TEMP_DIR"
if [ $? -ne 0 ]; then
    log_message "Error: Failed to extract the plugin package."
    exit 1
fi

# Find the extracted directory
EXTRACT_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [ ! -d "$EXTRACT_DIR" ]; then
    log_message "Error: Extracted directory not found."
    exit 1
fi

# Backup configuration files
log_message "Backing up configuration files..."
CONFIG_BACKUP_DIR="${TEMP_DIR}/backup_config"
mkdir -p "$CONFIG_BACKUP_DIR"

# Backup any configuration files you want to preserve
if [ -f "${PLUGIN_PATH}/config.php" ]; then
    cp "${PLUGIN_PATH}/config.php" "${CONFIG_BACKUP_DIR}/"
fi

# Update the plugin files
log_message "Updating plugin files..."
# Remove old files except for any data directories you want to preserve
find "$PLUGIN_PATH" -mindepth 1 -maxdepth 1 ! -name 'data' ! -name 'logs' -exec rm -rf {} \;

# Copy new files
cp -rf "${EXTRACT_DIR}/"* "$PLUGIN_PATH/"
if [ $? -ne 0 ]; then
    log_message "Error: Failed to copy new plugin files."
    exit 1
fi

# Restore configuration files
log_message "Restoring configuration files..."
if [ -f "${CONFIG_BACKUP_DIR}/config.php" ]; then
    cp "${CONFIG_BACKUP_DIR}/config.php" "${PLUGIN_PATH}/"
fi

# Set proper permissions
log_message "Setting file permissions..."
chown -R diradmin:diradmin "$PLUGIN_PATH"
chmod -R 755 "$PLUGIN_PATH"
chmod +x "$PLUGIN_PATH/exec/"*.sh
chmod +x "$PLUGIN_PATH/hooks/"*.sh
chmod +x "$PLUGIN_PATH/scripts/"*.sh

# Update version in plugins.conf
log_message "Updating plugin version in DirectAdmin..."
if grep -q "^postgresql_plugin=" "${CONFIG_PATH}/plugins.conf"; then
    sed -i 's/^postgresql_plugin=.*/postgresql_plugin=2.2/' "${CONFIG_PATH}/plugins.conf"
else
    echo "postgresql_plugin=2.2" >> "${CONFIG_PATH}/plugins.conf"
fi

# Copy CustomBuild files if present
CUSTOMBUILD_PATH="${DA_ROOT}/custombuild"
if [ -d "${PLUGIN_PATH}/custombuild" ] && [ -d "$CUSTOMBUILD_PATH" ]; then
    log_message "Updating CustomBuild configuration files..."
    
    # Create CustomBuild directories
    mkdir -p "${CUSTOMBUILD_PATH}/custom"
    
    # Copy CustomBuild files
    if [ -f "${PLUGIN_PATH}/custombuild/custom/postgresql.conf" ]; then
        cp -f "${PLUGIN_PATH}/custombuild/custom/postgresql.conf" "${CUSTOMBUILD_PATH}/custom/"
        log_message "Updated CustomBuild configuration: postgresql.conf"
    fi
    
    if [ -f "${PLUGIN_PATH}/custombuild/custom/postgresql_install.sh" ]; then
        cp -f "${PLUGIN_PATH}/custombuild/custom/postgresql_install.sh" "${CUSTOMBUILD_PATH}/custom/"
        chmod +x "${CUSTOMBUILD_PATH}/custom/postgresql_install.sh"
        log_message "Updated CustomBuild script: postgresql_install.sh"
    fi
    
    if [ -f "${PLUGIN_PATH}/custombuild/custom/postgresql_uninstall.sh" ]; then
        cp -f "${PLUGIN_PATH}/custombuild/custom/postgresql_uninstall.sh" "${CUSTOMBUILD_PATH}/custom/"
        chmod +x "${CUSTOMBUILD_PATH}/custom/postgresql_uninstall.sh"
        log_message "Updated CustomBuild script: postgresql_uninstall.sh"
    fi
    
    if [ -f "${PLUGIN_PATH}/custombuild/options.conf" ]; then
        # Extract the postgresql section from the options.conf file
        grep -A 10 "\[postgresql_plugin\]" "${PLUGIN_PATH}/custombuild/options.conf" > "/tmp/postgresql_options.conf"
        
        # Check if the main options.conf file exists
        if [ -f "${CUSTOMBUILD_PATH}/options.conf" ]; then
            # Remove any existing postgresql section
            sed -i '/\[postgresql_plugin\]/,/\[/d' "${CUSTOMBUILD_PATH}/options.conf"
            
            # Add our postgresql section
            cat "/tmp/postgresql_options.conf" >> "${CUSTOMBUILD_PATH}/options.conf"
        else
            # Create a new options.conf file
            cp -f "${PLUGIN_PATH}/custombuild/options.conf" "${CUSTOMBUILD_PATH}/"
        fi
        
        rm -f "/tmp/postgresql_options.conf"
        log_message "Updated CustomBuild options: options.conf"
    fi
    
    # Rebuild CustomBuild cache if available
    if [ -x "${CUSTOMBUILD_PATH}/build" ]; then
        "${CUSTOMBUILD_PATH}/build" cache > /dev/null 2>&1
        log_message "CustomBuild cache rebuilt."
    fi
fi

# Clean up
log_message "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Restart DirectAdmin
log_message "Restarting DirectAdmin to apply changes..."
service directadmin restart
if [ $? -ne 0 ]; then
    log_message "Warning: Failed to restart DirectAdmin. Please restart it manually."
fi

log_message "PostgreSQL plugin successfully updated to version 2.2"
log_message "For detailed update log, see ${LOG_FILE}"

exit 0