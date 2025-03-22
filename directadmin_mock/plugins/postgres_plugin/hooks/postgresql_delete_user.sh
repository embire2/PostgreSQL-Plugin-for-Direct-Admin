#!/bin/bash
# Hook script for PostgreSQL user deletion in DirectAdmin

# This script is triggered when a user is deleted in DirectAdmin

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
    log "No username provided, cannot delete PostgreSQL user"
    exit 1
fi

log "Hook triggered: Deleting PostgreSQL user for DirectAdmin user: $USERNAME"

# Call the script to delete the PostgreSQL user
SCRIPT_DIR="/usr/local/directadmin/plugins/postgres_plugin/scripts"
$SCRIPT_DIR/delete_user.sh "$USERNAME"

if [ $? -eq 0 ]; then
    log "Successfully deleted PostgreSQL user: $USERNAME"
else
    log "Failed to delete PostgreSQL user: $USERNAME"
fi

exit 0
