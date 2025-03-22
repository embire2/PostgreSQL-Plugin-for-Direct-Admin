#!/bin/bash
#
# PostgreSQL Plugin for DirectAdmin
# Uninstallation script
#

# Define constants
DA_ROOT="/usr/local/directadmin"
PLUGIN_NAME="postgresql_plugin"
PLUGIN_PATH="${DA_ROOT}/plugins/${PLUGIN_NAME}"
CONFIG_PATH="${DA_ROOT}/conf"
LOG_FILE="${DA_ROOT}/logs/postgresql_uninstall.log"

# Initialize log file
echo "[$( date '+%Y-%m-%d %H:%M:%S' )] Starting PostgreSQL plugin uninstallation" > $LOG_FILE

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

# Ask for confirmation
read -p "This will remove the PostgreSQL plugin from DirectAdmin. Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    log_message "Uninstallation cancelled by user."
    exit 0
fi

# Ask whether to keep PostgreSQL data
read -p "Do you want to keep PostgreSQL installed and preserve all databases? (y/n): " -n 1 -r
echo
KEEP_POSTGRESQL=0
if [[ $REPLY =~ ^[Yy]$ ]]
then
    KEEP_POSTGRESQL=1
    log_message "PostgreSQL installation and data will be preserved."
else
    log_message "PostgreSQL will be uninstalled and all data will be removed."
fi

# Remove hooks
log_message "Removing DirectAdmin hooks"
if [ -f "${DA_ROOT}/scripts/custom/postgresql_create_user.sh" ]; then
    rm -f "${DA_ROOT}/scripts/custom/postgresql_create_user.sh"
fi

if [ -f "${DA_ROOT}/scripts/custom/postgresql_delete_user.sh" ]; then
    rm -f "${DA_ROOT}/scripts/custom/postgresql_delete_user.sh"
fi

# Remove plugin from DirectAdmin's plugin.conf
if grep -q "^postgresql_plugin=" "${CONFIG_PATH}/plugins.conf"; then
    log_message "Removing plugin from DirectAdmin plugins.conf"
    sed -i '/^postgresql_plugin=/d' "${CONFIG_PATH}/plugins.conf"
fi

# Uninstall PostgreSQL if requested
if [ $KEEP_POSTGRESQL -eq 0 ]; then
    log_message "Uninstalling PostgreSQL..."
    if [ -f "${PLUGIN_PATH}/exec/uninstall.sh" ]; then
        bash "${PLUGIN_PATH}/exec/uninstall.sh"
        if [ $? -ne 0 ]; then
            log_message "Warning: Failed to uninstall PostgreSQL. Please uninstall it manually."
        else
            log_message "PostgreSQL uninstalled successfully"
        fi
    else
        log_message "Warning: PostgreSQL uninstallation script not found. Please uninstall PostgreSQL manually."
    fi
fi

# Remove plugin directory
if [ -d "$PLUGIN_PATH" ]; then
    log_message "Removing plugin directory at $PLUGIN_PATH"
    rm -rf "$PLUGIN_PATH"
fi

# Restart DirectAdmin to apply changes
log_message "Restarting DirectAdmin to apply changes"
service directadmin restart
if [ $? -ne 0 ]; then
    log_message "Warning: Failed to restart DirectAdmin. Please restart it manually."
fi

log_message "Uninstallation complete. PostgreSQL plugin has been removed from DirectAdmin."
log_message "For detailed uninstallation log, see ${LOG_FILE}"

exit 0