#!/bin/bash
# PostgreSQL backup script for DirectAdmin plugin

# Exit on errors
set -e

# Default values
BACKUP_LOG="/var/log/directadmin/postgresql_backup.log"
BACKUP_DIR="/var/backups/directadmin/postgresql"
DATE=$(date +%Y-%m-%d-%H%M%S)
RETENTION_DAYS=7

# Create log file and directory if they don't exist
mkdir -p /var/log/directadmin
mkdir -p $BACKUP_DIR
touch $BACKUP_LOG

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $BACKUP_LOG
}

# Display usage information
usage() {
    echo "Usage: $0 {backup_all|backup_db DB_NAME|list|restore BACKUP_FILE DB_NAME}"
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

# Function to backup all databases
backup_all_dbs() {
    log "Starting backup of all PostgreSQL databases..."
    
    # Create a directory for this backup set
    BACKUP_SET_DIR="${BACKUP_DIR}/${DATE}"
    mkdir -p "$BACKUP_SET_DIR"
    
    # Get a list of all databases
    DB_LIST=$(su - postgres -c "psql -t -c \"SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres');\"")
    
    # Backup each database
    for DB in $DB_LIST; do
        DB_NAME=$(echo $DB | tr -d ' ')
        BACKUP_FILE="${BACKUP_SET_DIR}/${DB_NAME}.sql"
        
        log "Backing up database: $DB_NAME to $BACKUP_FILE"
        su - postgres -c "pg_dump -F p \"$DB_NAME\" > \"$BACKUP_FILE\""
        
        if [ $? -eq 0 ]; then
            # Compress the backup file
            gzip "$BACKUP_FILE"
            log "Successfully backed up and compressed database: $DB_NAME"
        else
            log "Failed to backup database: $DB_NAME"
        fi
    done
    
    # Create a metadata file with date and DB list
    echo "Backup Date: $DATE" > "${BACKUP_SET_DIR}/backup_info.txt"
    echo "Databases Included:" >> "${BACKUP_SET_DIR}/backup_info.txt"
    for DB in $DB_LIST; do
        echo "- $(echo $DB | tr -d ' ')" >> "${BACKUP_SET_DIR}/backup_info.txt"
    done
    
    # Cleanup old backups
    find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
    
    log "Backup of all databases completed. Backup stored in: $BACKUP_SET_DIR"
    echo "Backup of all databases completed. Backup stored in: $BACKUP_SET_DIR"
}

# Function to backup a single database
backup_single_db() {
    if [ -z "$2" ]; then
        log "Database name not provided"
        echo "Database name not provided"
        usage
    fi
    
    DB_NAME="$2"
    log "Starting backup of PostgreSQL database: $DB_NAME"
    
    # Create a directory for this backup
    BACKUP_SET_DIR="${BACKUP_DIR}/${DATE}"
    mkdir -p "$BACKUP_SET_DIR"
    BACKUP_FILE="${BACKUP_SET_DIR}/${DB_NAME}.sql"
    
    # Check if the database exists
    DB_EXISTS=$(su - postgres -c "psql -t -c \"SELECT 1 FROM pg_database WHERE datname='$DB_NAME';\"")
    if [ -z "$DB_EXISTS" ]; then
        log "Database $DB_NAME does not exist"
        echo "Error: Database $DB_NAME does not exist"
        exit 1
    fi
    
    # Backup the database
    log "Backing up database: $DB_NAME to $BACKUP_FILE"
    su - postgres -c "pg_dump -F p \"$DB_NAME\" > \"$BACKUP_FILE\""
    
    if [ $? -eq 0 ]; then
        # Compress the backup file
        gzip "$BACKUP_FILE"
        log "Successfully backed up and compressed database: $DB_NAME"
        echo "Successfully backed up database: $DB_NAME to ${BACKUP_FILE}.gz"
    else
        log "Failed to backup database: $DB_NAME"
        echo "Failed to backup database: $DB_NAME"
        exit 1
    fi
    
    # Create a metadata file
    echo "Backup Date: $DATE" > "${BACKUP_SET_DIR}/backup_info.txt"
    echo "Database: $DB_NAME" >> "${BACKUP_SET_DIR}/backup_info.txt"
}

# Function to list backups
list_backups() {
    log "Listing PostgreSQL backups..."
    echo "Available PostgreSQL backups:"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        echo "No backups found in $BACKUP_DIR"
        exit 0
    fi
    
    # List all backup directories with their content
    for BACKUP_SET in $(ls -t "$BACKUP_DIR"); do
        echo "----------------------------------------"
        echo "Backup set: $BACKUP_SET"
        if [ -f "$BACKUP_DIR/$BACKUP_SET/backup_info.txt" ]; then
            cat "$BACKUP_DIR/$BACKUP_SET/backup_info.txt"
        fi
        echo "Files:"
        ls -lh "$BACKUP_DIR/$BACKUP_SET" | grep -v backup_info.txt
        echo ""
    done
}

# Function to restore a database
restore_db() {
    if [ -z "$2" ] || [ -z "$3" ]; then
        log "Backup file or database name not provided"
        echo "Backup file or database name not provided"
        usage
    fi
    
    BACKUP_FILE="$2"
    DB_NAME="$3"
    
    # Check if the backup file exists
    if [ ! -f "$BACKUP_FILE" ]; then
        log "Backup file $BACKUP_FILE does not exist"
        echo "Error: Backup file $BACKUP_FILE does not exist"
        exit 1
    fi
    
    log "Restoring PostgreSQL database: $DB_NAME from $BACKUP_FILE"
    
    # Check if the file is compressed
    if [[ "$BACKUP_FILE" == *.gz ]]; then
        # Create a temporary file for the uncompressed backup
        TEMP_FILE="/tmp/postgresql_restore_temp.sql"
        gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"
        RESTORE_FILE="$TEMP_FILE"
    else
        RESTORE_FILE="$BACKUP_FILE"
    fi
    
    # Check if the database exists
    DB_EXISTS=$(su - postgres -c "psql -t -c \"SELECT 1 FROM pg_database WHERE datname='$DB_NAME';\"")
    
    if [ -z "$DB_EXISTS" ]; then
        # Create the database
        log "Creating database $DB_NAME..."
        su - postgres -c "createdb \"$DB_NAME\""
        if [ $? -ne 0 ]; then
            log "Failed to create database: $DB_NAME"
            echo "Failed to create database: $DB_NAME"
            exit 1
        fi
    else
        # Confirm before overwriting an existing database
        echo "Warning: Database $DB_NAME already exists. All data will be overwritten."
        echo -n "Do you want to continue? (y/n): "
        read confirm
        
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log "Restore cancelled by user"
            echo "Restore cancelled"
            exit 0
        fi
        
        # Drop existing connections to the database
        su - postgres -c "psql -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB_NAME' AND pid <> pg_backend_pid();\""
    fi
    
    # Restore the database
    log "Restoring database $DB_NAME from $RESTORE_FILE..."
    su - postgres -c "psql \"$DB_NAME\" < \"$RESTORE_FILE\""
    
    if [ $? -eq 0 ]; then
        log "Successfully restored database: $DB_NAME"
        echo "Successfully restored database: $DB_NAME from $BACKUP_FILE"
    else
        log "Failed to restore database: $DB_NAME"
        echo "Failed to restore database: $DB_NAME"
        exit 1
    fi
    
    # Clean up temporary file if needed
    if [[ "$BACKUP_FILE" == *.gz ]]; then
        rm -f "$TEMP_FILE"
    fi
}

# Main case statement to handle commands
case "$1" in
    backup_all)
        backup_all_dbs
        ;;
    backup_db)
        backup_single_db "$@"
        ;;
    list)
        list_backups
        ;;
    restore)
        restore_db "$@"
        ;;
    *)
        usage
        ;;
esac

exit 0
