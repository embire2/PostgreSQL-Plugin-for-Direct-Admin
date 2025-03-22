#!/bin/bash
# Script to delete a PostgreSQL database

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
    echo "Usage: $0 <database_name>"
    exit 1
fi

# Get parameters
DB_NAME="$1"

log "Deleting PostgreSQL database: $DB_NAME"

# Check if the database exists
su - postgres -c "psql -l | grep -q $DB_NAME" > /dev/null 2>&1 && DB_EXISTS=1 || DB_EXISTS=0

if [ $DB_EXISTS -eq 0 ]; then
    log "Database $DB_NAME does not exist"
    echo "Database $DB_NAME does not exist"
    exit 1
fi

# Close all connections to the database
log "Closing all connections to database $DB_NAME"
su - postgres -c "psql -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME';\""

# Drop the database
log "Dropping database $DB_NAME"
su - postgres -c "dropdb \"$DB_NAME\""

# Verify database deletion
su - postgres -c "psql -l | grep -q $DB_NAME" > /dev/null 2>&1 && DB_STILL_EXISTS=1 || DB_STILL_EXISTS=0

if [ $DB_STILL_EXISTS -eq 0 ]; then
    log "Database $DB_NAME successfully deleted"
    echo "PostgreSQL database $DB_NAME successfully deleted"
    exit 0
else
    log "Failed to delete PostgreSQL database $DB_NAME"
    echo "Failed to delete PostgreSQL database $DB_NAME"
    exit 1
fi
