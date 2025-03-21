#!/bin/bash
# Script to assign a PostgreSQL user to a database

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
    echo "Usage: $0 <database_name> <username> [privileges]"
    exit 1
fi

# Get parameters
DB_NAME="$1"
USERNAME="$2"
PRIVILEGES="$3"

# Default privileges if not specified
if [ -z "$PRIVILEGES" ]; then
    PRIVILEGES="ALL"
fi

log "Assigning PostgreSQL user $USERNAME to database $DB_NAME with privileges: $PRIVILEGES"

# Check if the database exists
su - postgres -c "psql -l | grep -q $DB_NAME" > /dev/null 2>&1 && DB_EXISTS=1 || DB_EXISTS=0

if [ $DB_EXISTS -eq 0 ]; then
    log "Database $DB_NAME does not exist"
    echo "Database $DB_NAME does not exist"
    exit 1
fi

# Check if the user exists
su - postgres -c "psql -c \"SELECT 1 FROM pg_roles WHERE rolname = '$USERNAME'\" | grep -q 1" > /dev/null 2>&1 && USER_EXISTS=1 || USER_EXISTS=0

if [ $USER_EXISTS -eq 0 ]; then
    log "User $USERNAME does not exist"
    echo "User $USERNAME does not exist"
    exit 1
fi

# Grant privileges on the database
log "Granting $PRIVILEGES privileges on $DB_NAME to $USERNAME"
su - postgres -c "psql -c \"GRANT $PRIVILEGES ON DATABASE \\\"$DB_NAME\\\" TO \\\"$USERNAME\\\";\""

# If ALL privileges are granted, also grant schema privileges
if [ "$PRIVILEGES" == "ALL" ]; then
    # Connect to the database and grant privileges on schema public
    log "Granting schema privileges on $DB_NAME to $USERNAME"
    su - postgres -c "psql -d \"$DB_NAME\" -c \"GRANT ALL ON SCHEMA public TO \\\"$USERNAME\\\";\""
    
    # Grant privileges on all existing tables
    log "Granting privileges on all tables in $DB_NAME to $USERNAME"
    su - postgres -c "psql -d \"$DB_NAME\" -c \"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \\\"$USERNAME\\\";\""
    
    # Grant privileges on all sequences
    log "Granting privileges on all sequences in $DB_NAME to $USERNAME"
    su - postgres -c "psql -d \"$DB_NAME\" -c \"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \\\"$USERNAME\\\";\""
    
    # Grant privileges on all functions
    log "Granting privileges on all functions in $DB_NAME to $USERNAME"
    su - postgres -c "psql -d \"$DB_NAME\" -c \"GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO \\\"$USERNAME\\\";\""
    
    # Set default privileges for future tables
    log "Setting default privileges for future objects in $DB_NAME for $USERNAME"
    su - postgres -c "psql -d \"$DB_NAME\" -c \"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO \\\"$USERNAME\\\";\""
    su - postgres -c "psql -d \"$DB_NAME\" -c \"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO \\\"$USERNAME\\\";\""
    su - postgres -c "psql -d \"$DB_NAME\" -c \"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO \\\"$USERNAME\\\";\""
fi

log "Successfully assigned user $USERNAME to database $DB_NAME with $PRIVILEGES privileges"
echo "Successfully assigned user $USERNAME to database $DB_NAME with $PRIVILEGES privileges"
exit 0
