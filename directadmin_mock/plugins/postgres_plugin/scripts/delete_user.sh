#!/bin/bash
# Script to delete a PostgreSQL user

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
    echo "Usage: $0 <username>"
    exit 1
fi

# Get parameters
USERNAME="$1"

log "Deleting PostgreSQL user: $USERNAME"

# Check if the user exists
su - postgres -c "psql -c \"SELECT 1 FROM pg_roles WHERE rolname = '$USERNAME'\" | grep -q 1" > /dev/null 2>&1 && USER_EXISTS=1 || USER_EXISTS=0

if [ $USER_EXISTS -eq 0 ]; then
    log "User $USERNAME does not exist"
    echo "User $USERNAME does not exist"
    exit 1
fi

# Get a list of databases owned by the user
OWNED_DATABASES=$(su - postgres -c "psql -t -c \"SELECT datname FROM pg_database WHERE datdba = (SELECT oid FROM pg_roles WHERE rolname = '$USERNAME');\"")

# Reassign ownership of the user's databases to postgres
for DB in $OWNED_DATABASES; do
    DB_NAME=$(echo $DB | tr -d ' ')
    log "Changing owner of database $DB_NAME from $USERNAME to postgres"
    su - postgres -c "psql -c \"ALTER DATABASE \\\"$DB_NAME\\\" OWNER TO postgres;\""
done

# Terminate all user connections
log "Terminating all connections for user $USERNAME"
su - postgres -c "psql -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = '$USERNAME';\""

# Drop the user
log "Dropping user $USERNAME"
su - postgres -c "dropuser \"$USERNAME\""

# Verify user deletion
su - postgres -c "psql -c \"SELECT 1 FROM pg_roles WHERE rolname = '$USERNAME'\" | grep -q 1" > /dev/null 2>&1 && USER_STILL_EXISTS=1 || USER_STILL_EXISTS=0

if [ $USER_STILL_EXISTS -eq 0 ]; then
    log "User $USERNAME successfully deleted"
    echo "PostgreSQL user $USERNAME successfully deleted"
    exit 0
else
    log "Failed to delete PostgreSQL user $USERNAME"
    echo "Failed to delete PostgreSQL user $USERNAME"
    exit 1
fi
