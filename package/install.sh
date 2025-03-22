#!/bin/bash
#
# PostgreSQL Plugin for DirectAdmin
# Installation script
#

# Define constants
DA_ROOT="/usr/local/directadmin"
PLUGIN_NAME="postgresql_plugin"
PLUGIN_PATH="${DA_ROOT}/plugins/${PLUGIN_NAME}"
CONFIG_PATH="${DA_ROOT}/conf"
LOG_FILE="${DA_ROOT}/logs/postgresql_install.log"

# Initialize log file
echo "[$( date '+%Y-%m-%d %H:%M:%S' )] Starting PostgreSQL plugin installation" > $LOG_FILE

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

# Create plugin directory if it doesn't exist
if [ ! -d "$PLUGIN_PATH" ]; then
    log_message "Creating plugin directory at $PLUGIN_PATH"
    mkdir -p "$PLUGIN_PATH"
fi

# Extract the plugin package
log_message "Extracting plugin files to $PLUGIN_PATH"
cp -rf ../postgres_plugin/* "$PLUGIN_PATH/"

# Set proper permissions
log_message "Setting proper permissions"
chown -R diradmin:diradmin "$PLUGIN_PATH"
chmod -R 755 "$PLUGIN_PATH"
chmod +x "$PLUGIN_PATH/exec/"*.sh
chmod +x "$PLUGIN_PATH/hooks/"*.sh
chmod +x "$PLUGIN_PATH/scripts/"*.sh

# Register hooks with DirectAdmin
log_message "Registering hooks with DirectAdmin"
if [ -d "${DA_ROOT}/scripts/custom" ]; then
    # Create symbolic links to the hook scripts
    ln -sf "${PLUGIN_PATH}/hooks/postgresql_create_user.sh" "${DA_ROOT}/scripts/custom/postgresql_create_user.sh"
    ln -sf "${PLUGIN_PATH}/hooks/postgresql_delete_user.sh" "${DA_ROOT}/scripts/custom/postgresql_delete_user.sh"
    log_message "Hooks registered successfully"
else
    log_message "Warning: DirectAdmin custom scripts directory not found at ${DA_ROOT}/scripts/custom"
    log_message "Please create the directory and manually link the hook scripts:"
    log_message "mkdir -p ${DA_ROOT}/scripts/custom"
    log_message "ln -sf ${PLUGIN_PATH}/hooks/postgresql_create_user.sh ${DA_ROOT}/scripts/custom/postgresql_create_user.sh"
    log_message "ln -sf ${PLUGIN_PATH}/hooks/postgresql_delete_user.sh ${DA_ROOT}/scripts/custom/postgresql_delete_user.sh"
fi

# Install PostgreSQL if not already installed
log_message "Checking if PostgreSQL is already installed"
if ! command -v psql &> /dev/null; then
    log_message "PostgreSQL not found. Installing PostgreSQL..."
    bash "${PLUGIN_PATH}/scripts/install_postgresql.sh"
    if [ $? -ne 0 ]; then
        log_message "Error: Failed to install PostgreSQL. Please check ${LOG_FILE} for details."
        exit 1
    fi
    log_message "PostgreSQL installed successfully"
else
    log_message "PostgreSQL is already installed"
fi

# Configure PostgreSQL for DirectAdmin integration
log_message "Configuring PostgreSQL for DirectAdmin integration"
bash "${PLUGIN_PATH}/exec/postgres_control.sh" configure
if [ $? -ne 0 ]; then
    log_message "Error: Failed to configure PostgreSQL. Please check ${LOG_FILE} for details."
    exit 1
fi

# Add plugin to DirectAdmin's plugin.conf
if grep -q "^postgresql_plugin=" "${CONFIG_PATH}/plugins.conf"; then
    log_message "Plugin already registered in plugins.conf"
else
    log_message "Adding plugin to DirectAdmin plugins.conf"
    echo "postgresql_plugin=2.0" >> "${CONFIG_PATH}/plugins.conf"
fi

# Restart DirectAdmin to apply changes
log_message "Restarting DirectAdmin to apply changes"
service directadmin restart
if [ $? -ne 0 ]; then
    log_message "Warning: Failed to restart DirectAdmin. Please restart it manually."
fi

log_message "Installation complete. PostgreSQL plugin is now installed and ready to use."
log_message "You can access the plugin at https://your-server:2222/CMD_PLUGINS/postgresql_plugin"
log_message "For detailed installation log, see ${LOG_FILE}"

exit 0