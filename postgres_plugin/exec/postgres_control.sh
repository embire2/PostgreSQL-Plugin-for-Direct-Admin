#!/bin/bash
# PostgreSQL control script for DirectAdmin plugin

# Exit on errors
set -e

# Default values
LOG_FILE="/var/log/directadmin/postgresql_control.log"

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
touch $LOG_FILE

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Display usage information
usage() {
    echo "Usage: $0 {start|stop|restart|status|version|config}"
    exit 1
}

# Check if we are root
if [ "$(id -u)" != "0" ]; then
    log "This script must be run as root"
    echo "This script must be run as root"
    exit 1
fi

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
    echo "Unsupported operating system"
    exit 1
fi

# Check if action parameter is provided
if [ $# -lt 1 ]; then
    usage
fi

# Function to start PostgreSQL
start_postgres() {
    log "Starting PostgreSQL service..."
    systemctl start postgresql
    if [ $? -eq 0 ]; then
        log "PostgreSQL successfully started"
        echo "PostgreSQL started"
    else
        log "Failed to start PostgreSQL"
        echo "Failed to start PostgreSQL"
        exit 1
    fi
}

# Function to stop PostgreSQL
stop_postgres() {
    log "Stopping PostgreSQL service..."
    systemctl stop postgresql
    if [ $? -eq 0 ]; then
        log "PostgreSQL successfully stopped"
        echo "PostgreSQL stopped"
    else
        log "Failed to stop PostgreSQL"
        echo "Failed to stop PostgreSQL"
        exit 1
    fi
}

# Function to restart PostgreSQL
restart_postgres() {
    log "Restarting PostgreSQL service..."
    systemctl restart postgresql
    if [ $? -eq 0 ]; then
        log "PostgreSQL successfully restarted"
        echo "PostgreSQL restarted"
    else
        log "Failed to restart PostgreSQL"
        echo "Failed to restart PostgreSQL"
        exit 1
    fi
}

# Function to check PostgreSQL status
status_postgres() {
    log "Checking PostgreSQL service status..."
    systemctl status postgresql
    
    # Get additional information
    if command -v psql > /dev/null; then
        echo "----- PostgreSQL Running Processes -----"
        ps aux | grep postgres | grep -v grep
        
        echo "----- PostgreSQL Connection Info -----"
        # Use command that can be executed by root without switching user
        su - postgres -c "psql -c '\conninfo'"
        
        echo "----- PostgreSQL Databases -----"
        su - postgres -c "psql -l"
    else
        echo "PostgreSQL command-line tools not found"
    fi
}

# Function to get PostgreSQL version
version_postgres() {
    if command -v psql > /dev/null; then
        echo "PostgreSQL version:"
        su - postgres -c "psql --version"
        
        echo "Database server version:"
        su - postgres -c "psql -c 'SELECT version();'"
    else
        echo "PostgreSQL command-line tools not found"
    fi
}

# Function to display PostgreSQL configuration
config_postgres() {
    echo "PostgreSQL Configuration:"
    
    # Find the postgresql.conf file based on the OS
    if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
        PGDATA=$(su - postgres -c "echo \$PGDATA")
        if [ -z "$PGDATA" ]; then
            PGDATA="/var/lib/pgsql/data"
        fi
    elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
        # Find the PostgreSQL version
        PG_VERSION=$(pg_config --version | grep -o '[0-9]\+' | head -1)
        PGDATA="/etc/postgresql/$PG_VERSION/main"
    else
        log "Unsupported OS for configuration display: $OS"
        echo "Unsupported OS for configuration display"
        exit 1
    fi
    
    if [ -f "$PGDATA/postgresql.conf" ]; then
        echo "Configuration file: $PGDATA/postgresql.conf"
        echo "----- Key Settings -----"
        grep -v "^#" "$PGDATA/postgresql.conf" | grep -v "^$"
    else
        echo "PostgreSQL configuration file not found in $PGDATA"
    fi
}

# Main case statement to handle commands
case "$1" in
    start)
        start_postgres
        ;;
    stop)
        stop_postgres
        ;;
    restart)
        restart_postgres
        ;;
    status)
        status_postgres
        ;;
    version)
        version_postgres
        ;;
    config)
        config_postgres
        ;;
    *)
        usage
        ;;
esac

exit 0
