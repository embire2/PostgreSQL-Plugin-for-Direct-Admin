#!/bin/bash
# Script to update PostgreSQL configuration settings

# Exit on errors
set -e

# Default values
CONFIG_LOG="/var/log/directadmin/postgresql_config.log"

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
touch $CONFIG_LOG

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $CONFIG_LOG
}

# Display usage information
usage() {
    echo "Usage: $0 {set_param PARAM VALUE|reload|show_param PARAM|show_all}"
    exit 1
}

# Check if we are root
if [ "$(id -u)" != "0" ]; then
    log "This script must be run as root"
    echo "This script must be run as root"
    exit 1
fi

# Check if action parameter is provided
if [ $# -lt 1 ]; then
    usage
fi

# Detect OS and PostgreSQL data directory
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
    echo "Unsupported operating system"
    exit 1
fi

# Find PostgreSQL configuration directory
if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
    PGDATA=$(su - postgres -c "echo \$PGDATA")
    if [ -z "$PGDATA" ]; then
        PGDATA="/var/lib/pgsql/data"
    fi
elif [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    # Find the PostgreSQL version
    PG_VERSION=$(pg_config --version | grep -o '[0-9]\+' | head -1)
    if [ -z "$PG_VERSION" ]; then
        # Try alternative method if pg_config not available
        PG_VERSION=$(find /etc/postgresql -maxdepth 1 -type d | grep -o '[0-9]\+' | sort -n | tail -1)
    fi
    PGDATA="/etc/postgresql/$PG_VERSION/main"
else
    log "Unsupported OS for PostgreSQL configuration: $OS"
    echo "Unsupported OS for PostgreSQL configuration"
    exit 1
fi

# Check if postgresql.conf exists
if [ ! -f "$PGDATA/postgresql.conf" ]; then
    log "PostgreSQL configuration file not found at $PGDATA/postgresql.conf"
    echo "PostgreSQL configuration file not found"
    exit 1
fi

# Function to set a PostgreSQL parameter
set_param() {
    if [ -z "$2" ] || [ -z "$3" ]; then
        log "Parameter name or value not provided"
        echo "Parameter name or value not provided"
        usage
    fi
    
    PARAM="$2"
    VALUE="$3"
    
    log "Setting PostgreSQL parameter $PARAM to $VALUE"
    
    # Check if parameter already exists in the configuration
    if grep -q "^[[:space:]]*$PARAM[[:space:]]*=" "$PGDATA/postgresql.conf"; then
        # Parameter exists, update it
        sed -i "s/^[[:space:]]*$PARAM[[:space:]]*=.*/$PARAM = $VALUE/g" "$PGDATA/postgresql.conf"
    else
        # Parameter doesn't exist, add it
        echo "$PARAM = $VALUE" >> "$PGDATA/postgresql.conf"
    fi
    
    log "Parameter $PARAM successfully set to $VALUE"
    echo "Parameter $PARAM successfully set to $VALUE"
}

# Function to reload PostgreSQL configuration
reload_config() {
    log "Reloading PostgreSQL configuration..."
    
    # Use systemctl or pg_ctl based on OS
    if [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
        systemctl reload postgresql
    else
        su - postgres -c "pg_ctl reload"
    fi
    
    if [ $? -eq 0 ]; then
        log "PostgreSQL configuration successfully reloaded"
        echo "PostgreSQL configuration successfully reloaded"
    else
        log "Failed to reload PostgreSQL configuration"
        echo "Failed to reload PostgreSQL configuration"
        exit 1
    fi
}

# Function to show a specific parameter
show_param() {
    if [ -z "$2" ]; then
        log "Parameter name not provided"
        echo "Parameter name not provided"
        usage
    fi
    
    PARAM="$2"
    log "Showing PostgreSQL parameter $PARAM"
    
    # Extract the parameter from postgresql.conf
    CONFIG_VALUE=$(grep "^[[:space:]]*$PARAM[[:space:]]*=" "$PGDATA/postgresql.conf" | sed "s/^[[:space:]]*$PARAM[[:space:]]*=[[:space:]]*//g")
    
    if [ -n "$CONFIG_VALUE" ]; then
        echo "Parameter $PARAM is set to: $CONFIG_VALUE"
    else
        # If not found in configuration file, try to get the current runtime value
        RUNTIME_VALUE=$(su - postgres -c "psql -t -c \"SHOW $PARAM;\"" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$RUNTIME_VALUE" ]; then
            echo "Parameter $PARAM is set to (runtime): $RUNTIME_VALUE"
        else
            echo "Parameter $PARAM is not explicitly set in postgresql.conf"
        fi
    fi
}

# Function to show all parameters
show_all() {
    log "Showing all PostgreSQL parameters"
    
    echo "PostgreSQL Configuration Parameters:"
    echo "----------------------------------"
    echo "File: $PGDATA/postgresql.conf"
    echo ""
    
    # Show all non-commented parameters
    grep -v "^[[:space:]]*#" "$PGDATA/postgresql.conf" | grep -v "^$" | sort
    
    echo ""
    echo "Runtime Parameters:"
    echo "------------------"
    
    # Show runtime parameters
    su - postgres -c "psql -c \"SHOW ALL;\"" | grep -v "^-" | grep -v "^("
}

# Main case statement to handle commands
case "$1" in
    set_param)
        set_param "$@"
        ;;
    reload)
        reload_config
        ;;
    show_param)
        show_param "$@"
        ;;
    show_all)
        show_all
        ;;
    *)
        usage
        ;;
esac

exit 0
