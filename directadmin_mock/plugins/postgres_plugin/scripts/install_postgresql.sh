#!/bin/bash
# Script to install PostgreSQL server for DirectAdmin plugin

# Exit on errors
set -e

# Default values
INSTALL_LOG="/var/log/directadmin/postgresql_install.log"
PLUGIN_DIR="/usr/local/directadmin/plugins/postgres_plugin"

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
touch $INSTALL_LOG

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $INSTALL_LOG
}

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    log "This script must be run as root" 
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

# Install PostgreSQL based on the OS
if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
    log "Installing PostgreSQL on CentOS/RHEL/Fedora..."
    
    # Install PostgreSQL from the official repository
    if [ ! -f /etc/yum.repos.d/pgdg.repo ]; then
        log "Adding PostgreSQL repository..."
        yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-$(rpm -E %{rhel})-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    fi
    
    # Install PostgreSQL server
    log "Installing PostgreSQL server packages..."
    yum install -y postgresql14-server postgresql14-contrib
    
    # Initialize the database
    log "Initializing PostgreSQL database..."
    /usr/pgsql-14/bin/postgresql-14-setup initdb
    
    # Start and enable the service
    log "Starting and enabling PostgreSQL service..."
    systemctl enable postgresql-14
    systemctl start postgresql-14
    
    # Verify installation
    if systemctl is-active postgresql-14 >/dev/null 2>&1; then
        log "PostgreSQL server is now running."
    else
        log "PostgreSQL server failed to start. Check system logs for details."
        exit 1
    fi
    
    # Set environment variables for PostgreSQL
    PGDATA="/var/lib/pgsql/14/data"
    
elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    log "Installing PostgreSQL on Debian/Ubuntu..."
    
    # Update package lists
    apt-get update
    
    # Install PostgreSQL from the official repository
    log "Installing PostgreSQL server packages..."
    apt-get install -y postgresql postgresql-contrib
    
    # Start and enable the service
    log "Starting and enabling PostgreSQL service..."
    systemctl enable postgresql
    systemctl start postgresql
    
    # Verify installation
    if systemctl is-active postgresql >/dev/null 2>&1; then
        log "PostgreSQL server is now running."
    else
        log "PostgreSQL server failed to start. Check system logs for details."
        exit 1
    fi
    
    # Find the PostgreSQL version and data directory
    PG_VERSION=$(pg_config --version | grep -o '[0-9]\+' | head -1)
    if [ -z "$PG_VERSION" ]; then
        # Try alternative method if pg_config not available
        PG_VERSION=$(find /etc/postgresql -maxdepth 1 -type d | grep -o '[0-9]\+' | sort -n | tail -1)
    fi
    PGDATA="/etc/postgresql/$PG_VERSION/main"
    
else
    log "Unsupported operating system: $OS"
    exit 1
fi

# Configure PostgreSQL to listen on all addresses
log "Configuring PostgreSQL to listen on all addresses..."
if [ -f "$PGDATA/postgresql.conf" ]; then
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PGDATA/postgresql.conf"
else
    log "WARNING: Could not find postgresql.conf at $PGDATA"
fi

# Configure PostgreSQL to allow remote connections
log "Configuring PostgreSQL to allow remote connections..."
if [ -f "$PGDATA/pg_hba.conf" ]; then
    # Add rule for IPv4 remote connections with password authentication
    echo "# Allow remote connections for IPv4" >> "$PGDATA/pg_hba.conf"
    echo "host    all             all             0.0.0.0/0               md5" >> "$PGDATA/pg_hba.conf"
    # Add rule for IPv6 remote connections with password authentication
    echo "# Allow remote connections for IPv6" >> "$PGDATA/pg_hba.conf"
    echo "host    all             all             ::/0                    md5" >> "$PGDATA/pg_hba.conf"
else
    log "WARNING: Could not find pg_hba.conf at $PGDATA"
fi

# Restart PostgreSQL to apply configuration changes
log "Restarting PostgreSQL to apply configuration changes..."
if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
    systemctl restart postgresql-14
elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    systemctl restart postgresql
fi

# Set a password for the postgres user
log "Setting password for PostgreSQL postgres user..."
PG_PASS=$(openssl rand -base64 12)
if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
    # On CentOS/RHEL, use su to run psql
    su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '$PG_PASS';\""
elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    # On Debian/Ubuntu, use su to run psql
    su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '$PG_PASS';\""
fi

# Save the PostgreSQL admin password securely
POSTGRES_CREDS_FILE="/root/.postgres_admin_credentials"
echo "PostgreSQL Admin Username: postgres" > $POSTGRES_CREDS_FILE
echo "PostgreSQL Admin Password: $PG_PASS" >> $POSTGRES_CREDS_FILE
chmod 600 $POSTGRES_CREDS_FILE

log "PostgreSQL admin credentials saved to $POSTGRES_CREDS_FILE"
log "PostgreSQL installation and configuration completed successfully."

exit 0
