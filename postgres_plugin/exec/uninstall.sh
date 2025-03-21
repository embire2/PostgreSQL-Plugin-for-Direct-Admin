#!/bin/bash
# PostgreSQL DirectAdmin plugin uninstallation script

# Exit on errors
set -e

# Default values
UNINSTALL_LOG="/var/log/directadmin/postgresql_uninstall.log"
PLUGIN_DIR="/usr/local/directadmin/plugins/postgres_plugin"

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
touch $UNINSTALL_LOG

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $UNINSTALL_LOG
}

log "Starting PostgreSQL plugin uninstallation..."

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    log "This script must be run as root" 
    exit 1
fi

# Ask for confirmation before uninstalling PostgreSQL
echo -n "Do you want to completely remove PostgreSQL server as well? (y/n): "
read remove_postgresql

# Remove DirectAdmin hooks
log "Removing DirectAdmin hooks..."
if [ -f /usr/local/directadmin/scripts/custom/postgresql_create_user.sh ]; then
    rm -f /usr/local/directadmin/scripts/custom/postgresql_create_user.sh
fi

if [ -f /usr/local/directadmin/scripts/custom/postgresql_delete_user.sh ]; then
    rm -f /usr/local/directadmin/scripts/custom/postgresql_delete_user.sh
fi

# Unregister the plugin from DirectAdmin
if [ -f /usr/local/directadmin/plugins/plugin.conf ]; then
    sed -i '/postgres_plugin=1/d' /usr/local/directadmin/plugins/plugin.conf
fi

# Remove PostgreSQL if requested
if [ "$remove_postgresql" == "y" ] || [ "$remove_postgresql" == "Y" ]; then
    log "Removing PostgreSQL server..."
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        log "Unsupported operating system"
        exit 1
    fi
    
    # Remove PostgreSQL based on the OS
    if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
        systemctl stop postgresql
        yum -y remove postgresql\* || log "Failed to remove PostgreSQL packages"
        rm -rf /var/lib/pgsql
    elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
        systemctl stop postgresql
        apt-get -y purge postgresql\* || log "Failed to remove PostgreSQL packages"
        apt-get -y autoremove
        rm -rf /var/lib/postgresql
    else
        log "Unsupported OS for PostgreSQL removal: $OS"
    fi
    
    log "PostgreSQL server has been removed."
else
    log "PostgreSQL server was not removed as per user request."
fi

# Remove the plugin directory
log "Removing plugin files..."
if [ -d "$PLUGIN_DIR" ]; then
    rm -rf "$PLUGIN_DIR"
fi

# Restart DirectAdmin to apply changes
systemctl restart directadmin

log "PostgreSQL plugin uninstallation complete!"

exit 0
