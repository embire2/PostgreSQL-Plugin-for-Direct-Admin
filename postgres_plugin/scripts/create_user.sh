#!/bin/bash
# Script to create a PostgreSQL user

# Exit on errors
set -e

# Default values
LOG_FILE="/var/log/directadmin/postgresql_scripts.log"

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
touch $LOG_FILE

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Display usage if no parameters are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <username> [password]"
    exit 1
fi

# Get parameters
USERNAME="$1"
PASSWORD="$2"

# If no password provided, generate a random one
if [ -z "$PASSWORD" ]; then
    PASSWORD=$(openssl rand -base64 12)
fi

log "Creating PostgreSQL user: $USERNAME"

# Escape special characters in password for SQL
ESCAPED_PASSWORD=$(echo "$PASSWORD" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Create the PostgreSQL user
su - postgres -c "psql -c \"SELECT 1 FROM pg_roles WHERE rolname = '$USERNAME'\" | grep -q 1" > /dev/null 2>&1 && USER_EXISTS=1 || USER_EXISTS=0

if [ $USER_EXISTS -eq 1 ]; then
    log "User $USERNAME already exists, updating password"
    su - postgres -c "psql -c \"ALTER USER \\\"$USERNAME\\\" WITH ENCRYPTED PASSWORD '$ESCAPED_PASSWORD';\""
else
    log "Creating new user $USERNAME"
    su - postgres -c "psql -c \"CREATE USER \\\"$USERNAME\\\" WITH ENCRYPTED PASSWORD '$ESCAPED_PASSWORD';\""
fi

# Verify user creation
su - postgres -c "psql -c \"SELECT 1 FROM pg_roles WHERE rolname = '$USERNAME'\"" | grep -q 1
if [ $? -eq 0 ]; then
    log "User $USERNAME successfully created/updated"
    echo "PostgreSQL user $USERNAME successfully created/updated"
    # Return the password for scripting purposes
    echo "Password: $PASSWORD"
    exit 0
else
    log "Failed to create PostgreSQL user $USERNAME"
    echo "Failed to create PostgreSQL user $USERNAME"
    exit 1
fi
