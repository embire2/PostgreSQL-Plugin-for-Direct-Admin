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

# Detect OS
if [ -f /etc/redhat-release ]; then
    OS="centos"
    if grep -q -i "centos linux release 8" /etc/redhat-release || grep -q -i "centos linux release 9" /etc/redhat-release; then
        OS_VERSION="8"
    elif grep -q -i "rocky linux release 8" /etc/redhat-release || grep -q -i "almalinux release 8" /etc/redhat-release; then
        OS_VERSION="8"
    else
        OS_VERSION="7"
    fi
    log_message "Detected OS: CentOS/RHEL/Rocky/AlmaLinux ${OS_VERSION}"
    PACKAGE_MANAGER="yum"
    PG_SERVICE="postgresql"
    PG_CONFIG_DIR="/var/lib/pgsql/data"
elif [ -f /etc/debian_version ]; then
    OS="debian"
    if grep -q -i "10" /etc/debian_version; then
        OS_VERSION="10"
    elif grep -q -i "11" /etc/debian_version; then
        OS_VERSION="11"
    elif grep -q -i "12" /etc/debian_version; then
        OS_VERSION="12"
    else
        OS_VERSION="unknown"
    fi
    log_message "Detected OS: Debian ${OS_VERSION}"
    PACKAGE_MANAGER="apt-get"
    PG_SERVICE="postgresql"
    PG_CONFIG_DIR="/etc/postgresql/*/main"
elif [ -f /etc/lsb-release ] && grep -q -i "ubuntu" /etc/lsb-release; then
    OS="ubuntu"
    OS_VERSION=$(grep -i "release" /etc/lsb-release | cut -d= -f2)
    log_message "Detected OS: Ubuntu ${OS_VERSION}"
    PACKAGE_MANAGER="apt-get"
    PG_SERVICE="postgresql"
    PG_CONFIG_DIR="/etc/postgresql/*/main"
else
    log_message "Warning: Unsupported OS detected. Installation may not work correctly."
    OS="unknown"
    OS_VERSION="unknown"
    PACKAGE_MANAGER="unknown"
    PG_SERVICE="postgresql"
    PG_CONFIG_DIR="/etc/postgresql"
fi

# Create plugin directory
log_message "Creating plugin directory at $PLUGIN_PATH"
mkdir -p "$PLUGIN_PATH"

# Check if PostgreSQL is installed
POSTGRESQL_INSTALLED=0
if command -v psql &> /dev/null; then
    log_message "PostgreSQL is already installed."
    POSTGRESQL_INSTALLED=1
fi

# Install PostgreSQL if not already installed
if [ $POSTGRESQL_INSTALLED -eq 0 ]; then
    log_message "Installing PostgreSQL..."
    
    if [ "$OS" = "centos" ]; then
        if [ "$OS_VERSION" = "7" ]; then
            $PACKAGE_MANAGER install -y postgresql-server postgresql-contrib
            postgresql-setup initdb
        else
            # CentOS 8/9, Rocky Linux 8, AlmaLinux 8
            $PACKAGE_MANAGER install -y @postgresql:13
            postgresql-setup --initdb
        fi
        systemctl enable postgresql
        systemctl start postgresql
    elif [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        $PACKAGE_MANAGER update
        $PACKAGE_MANAGER install -y postgresql postgresql-contrib
    else
        log_message "Error: Unable to install PostgreSQL on unsupported OS."
        exit 1
    fi
    
    if [ $? -ne 0 ]; then
        log_message "Error: Failed to install PostgreSQL."
        exit 1
    fi
    
    log_message "PostgreSQL installed successfully."
fi

# Copy plugin files
log_message "Copying plugin files to ${PLUGIN_PATH}"
cp -rf ./* "$PLUGIN_PATH/"
if [ $? -ne 0 ]; then
    log_message "Error: Failed to copy plugin files."
    exit 1
fi

# Set proper permissions
log_message "Setting file permissions"
chown -R diradmin:diradmin "$PLUGIN_PATH"
chmod -R 755 "$PLUGIN_PATH"
chmod +x "$PLUGIN_PATH/exec/"*.sh
chmod +x "$PLUGIN_PATH/hooks/"*.sh
chmod +x "$PLUGIN_PATH/scripts/"*.sh

# Create symbolic links for hook scripts
log_message "Creating hook scripts"
ln -sf "${PLUGIN_PATH}/hooks/postgresql_create_user.sh" "${DA_ROOT}/scripts/custom/postgresql_create_user.sh"
ln -sf "${PLUGIN_PATH}/hooks/postgresql_delete_user.sh" "${DA_ROOT}/scripts/custom/postgresql_delete_user.sh"

# Configure PostgreSQL for DirectAdmin
log_message "Configuring PostgreSQL for DirectAdmin integration"
if [ -f "${PLUGIN_PATH}/exec/postgres_control.sh" ]; then
    bash "${PLUGIN_PATH}/exec/postgres_control.sh" configure
    if [ $? -ne 0 ]; then
        log_message "Warning: Failed to configure PostgreSQL. Please configure it manually."
    fi
else
    log_message "Warning: PostgreSQL configuration script not found."
fi

# Register plugin with DirectAdmin
log_message "Registering plugin with DirectAdmin"
if ! grep -q "^postgresql_plugin=" "${CONFIG_PATH}/plugins.conf"; then
    echo "postgresql_plugin=2.0" >> "${CONFIG_PATH}/plugins.conf"
else
    sed -i 's/^postgresql_plugin=.*/postgresql_plugin=2.0/' "${CONFIG_PATH}/plugins.conf"
fi

# Restart DirectAdmin to apply changes
log_message "Restarting DirectAdmin to apply changes"
service directadmin restart
if [ $? -ne 0 ]; then
    log_message "Warning: Failed to restart DirectAdmin. Please restart it manually."
fi

log_message "Installation complete. PostgreSQL plugin is now available in DirectAdmin."
log_message "Admin URL: https://your-server:2222/CMD_PLUGINS/postgresql_plugin"
log_message "User URL: https://your-server:2222/CMD_PLUGINS/postgresql_plugin"
log_message "For detailed installation log, see ${LOG_FILE}"

exit 0