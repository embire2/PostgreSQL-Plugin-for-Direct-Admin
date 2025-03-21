#!/bin/bash
# Hook script for PostgreSQL user creation in DirectAdmin

# This script is triggered when a new user is created in DirectAdmin

# Exit on errors
set -e

# Default values
LOG_FILE="/var/log/directadmin/postgresql_hooks.log"

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
touch $LOG_FILE

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Get username from environment variable or command line argument
USERNAME="$1"
if [ -z "$USERNAME" ]; then
    USERNAME="$username"  # DirectAdmin sets this environment variable
fi

if [ -z "$USERNAME" ]; then
    log "No username provided, cannot create PostgreSQL user"
    exit 1
fi

log "Hook triggered: Creating PostgreSQL user for DirectAdmin user: $USERNAME"

# Generate a random password
PASSWORD=$(openssl rand -base64 12)

# Call the script to create a PostgreSQL user
SCRIPT_DIR="/usr/local/directadmin/plugins/postgres_plugin/scripts"
$SCRIPT_DIR/create_user.sh "$USERNAME" "$PASSWORD"

if [ $? -eq 0 ]; then
    log "Successfully created PostgreSQL user: $USERNAME"
    
    # Save the password to the user's home directory securely
    USER_HOME="/home/$USERNAME"
    if [ -d "$USER_HOME" ]; then
        PG_INFO_FILE="$USER_HOME/.postgresql_credentials"
        echo "PostgreSQL Username: $USERNAME" > "$PG_INFO_FILE"
        echo "PostgreSQL Password: $PASSWORD" >> "$PG_INFO_FILE"
        chown "$USERNAME:$USERNAME" "$PG_INFO_FILE"
        chmod 600 "$PG_INFO_FILE"
        
        log "Saved PostgreSQL credentials to $PG_INFO_FILE"
    else
        log "Warning: User home directory $USER_HOME not found, couldn't save credentials"
    fi
else
    log "Failed to create PostgreSQL user: $USERNAME"
fi

exit 0
