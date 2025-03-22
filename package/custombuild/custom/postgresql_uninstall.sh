#!/bin/bash
#
# CustomBuild uninstallation script for PostgreSQL Plugin
#

DA_ROOT="/usr/local/directadmin"
PLUGIN_DIR="${DA_ROOT}/plugins/postgresql_plugin"
LOG_FILE="${DA_ROOT}/logs/postgresql_uninstall.log"

# Create logs directory if it doesn't exist
mkdir -p "${DA_ROOT}/logs"

# Initialize log file
echo "[$( date '+%Y-%m-%d %H:%M:%S' )] Starting PostgreSQL plugin uninstallation from CustomBuild" > $LOG_FILE

# Function to log messages
log_message() {
    echo "[$( date '+%Y-%m-%d %H:%M:%S' )] $1" >> $LOG_FILE
    echo "$1"
}

# Check if plugin is installed
if [ ! -d "$PLUGIN_DIR" ]; then
    log_message "PostgreSQL plugin is not installed. Nothing to uninstall."
    exit 0
fi

# Check if there is an uninstall script in the plugin directory
if [ -f "$PLUGIN_DIR/uninstall.sh" ]; then
    log_message "Running plugin's uninstall script..."
    cd "$PLUGIN_DIR"
    bash uninstall.sh
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_message "Warning: Plugin uninstall script exited with code $exit_code"
    fi
else
    # Manual uninstallation process
    log_message "No uninstall script found. Performing manual uninstallation..."

    # Remove plugin from plugins.conf
    if grep -q "postgresql_plugin" "${DA_ROOT}/conf/plugins.conf"; then
        log_message "Removing plugin from DirectAdmin configuration..."
        sed -i '/^postgresql_plugin=/d' "${DA_ROOT}/conf/plugins.conf"
    fi

    # Remove hooks
    log_message "Removing hooks..."
    for hook in "${DA_ROOT}/scripts/custom/postgresql_"*; do
        if [ -L "$hook" ]; then
            rm -f "$hook"
            log_message "Removed hook: $hook"
        fi
    done

    # Remove plugin directory
    log_message "Removing plugin directory..."
    rm -rf "$PLUGIN_DIR"
fi

# Restart DirectAdmin
log_message "Restarting DirectAdmin..."
service directadmin restart
if [ $? -ne 0 ]; then
    log_message "Warning: Failed to restart DirectAdmin. Please restart it manually."
fi

log_message "PostgreSQL plugin uninstallation completed."

exit 0