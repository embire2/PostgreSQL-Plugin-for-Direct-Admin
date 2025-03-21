#!/bin/bash
# Script to create a PostgreSQL database

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
if [ $# -lt 2 ]; then
    echo "Usage: $0 <database_name> <owner_username>"
    exit 1
fi

# Get parameters
DB_NAME="$1"
OWNER="$2"

log "Creating PostgreSQL database: $DB_NAME with owner: $OWNER"

# Check if the owner user exists
su - postgres -c "psql -c \"SELECT 1 FROM pg_roles WHERE rolname = '$OWNER'\" | grep -q 1" > /dev/null 2>&1 && OWNER_EXISTS=1 || OWNER_EXISTS=0

if [ $OWNER_EXISTS -eq 0 ]; then
    log "ERROR: Owner user $OWNER does not exist"
    echo "ERROR: Owner user $OWNER does not exist"
    exit 1
fi

# Check if the database already exists
su - postgres -c "psql -l | grep -q $DB_NAME" > /dev/null 2>&1 && DB_EXISTS=1 || DB_EXISTS=0

if [ $DB_EXISTS -eq 1 ]; then
    log "Database $DB_NAME already exists"
    echo "Database $DB_NAME already exists"
    
    # Change the owner if the database exists
    log "Changing owner of database $DB_NAME to $OWNER"
    su - postgres -c "psql -c \"ALTER DATABASE \\\"$DB_NAME\\\" OWNER TO \\\"$OWNER\\\";\""
else
    # Create the database with the specified owner
    log "Creating new database $DB_NAME with owner $OWNER"
    su - postgres -c "createdb \"$DB_NAME\" -O \"$OWNER\""
fi

# Grant privileges to the owner on the database
log "Granting all privileges on database $DB_NAME to $OWNER"
su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE \\\"$DB_NAME\\\" TO \\\"$OWNER\\\";\""

# Verify database creation
su - postgres -c "psql -l | grep -q $DB_NAME"
if [ $? -eq 0 ]; then
    log "Database $DB_NAME successfully created/updated with owner $OWNER"
    echo "PostgreSQL database $DB_NAME successfully created/updated with owner $OWNER"
    exit 0
else
    log "Failed to create PostgreSQL database $DB_NAME"
    echo "Failed to create PostgreSQL database $DB_NAME"
    exit 1
fi
