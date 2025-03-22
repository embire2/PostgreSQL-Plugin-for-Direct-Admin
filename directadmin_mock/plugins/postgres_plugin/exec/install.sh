#!/bin/bash
# PostgreSQL DirectAdmin plugin installation script
# This script installs PostgreSQL and sets up the DirectAdmin plugin

# Exit on errors
set -e

# Default values
INSTALL_LOG="/var/log/directadmin/postgresql_install.log"
PLUGIN_DIR="/usr/local/directadmin/plugins/postgres_plugin"
PLUGIN_CONF="${PLUGIN_DIR}/plugin.conf"
SCRIPTS_DIR="${PLUGIN_DIR}/scripts"

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
touch $INSTALL_LOG

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $INSTALL_LOG
}

log "Starting PostgreSQL plugin installation..."

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    log "This script must be run as root" 
    exit 1
fi

# Check if DirectAdmin is installed
if [ ! -d "/usr/local/directadmin" ]; then
    log "DirectAdmin is not installed. Please install DirectAdmin first."
    exit 1
fi

# Detect OS and version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
elif [ -f /etc/redhat-release ]; then
    OS="rhel"
elif [ -f /etc/debian_version ]; then
    OS="debian"
else
    log "Unsupported operating system"
    exit 1
fi

log "Detected OS: $OS $VERSION"

# Install PostgreSQL using the script
log "Installing PostgreSQL..."
bash "${SCRIPTS_DIR}/install_postgresql.sh"
if [ $? -ne 0 ]; then
    log "PostgreSQL installation failed. See log for details."
    exit 1
fi

# Create PostgreSQL configuration
log "Setting up PostgreSQL configuration..."

# Ensure PostgreSQL service is enabled and started
if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
    systemctl enable postgresql
    systemctl start postgresql
elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    systemctl enable postgresql
    systemctl start postgresql
else
    log "Unsupported OS for service management: $OS"
    exit 1
fi

# Set up DirectAdmin hooks
log "Setting up DirectAdmin hooks..."
chmod +x ${PLUGIN_DIR}/hooks/*
chmod +x ${PLUGIN_DIR}/exec/*
chmod +x ${SCRIPTS_DIR}/*

# Create symlinks for DirectAdmin hooks
ln -sf ${PLUGIN_DIR}/hooks/postgresql_create_user.sh /usr/local/directadmin/scripts/custom/postgresql_create_user.sh
ln -sf ${PLUGIN_DIR}/hooks/postgresql_delete_user.sh /usr/local/directadmin/scripts/custom/postgresql_delete_user.sh

# Set permissions for the plugin
chown -R diradmin:diradmin ${PLUGIN_DIR}
find ${PLUGIN_DIR} -type f -name "*.sh" -exec chmod +x {} \;
find ${PLUGIN_DIR} -type f -name "*.php" -exec chmod 644 {} \;

# Register the plugin with DirectAdmin
if [ -f /usr/local/directadmin/plugins/plugin.conf ]; then
    if ! grep -q "postgres_plugin" /usr/local/directadmin/plugins/plugin.conf; then
        echo "postgres_plugin=1" >> /usr/local/directadmin/plugins/plugin.conf
    fi
fi

# Restart DirectAdmin to apply changes
systemctl restart directadmin

log "PostgreSQL plugin installation complete!"
log "Access the PostgreSQL management interface through DirectAdmin"

exit 0
