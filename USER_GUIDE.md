# PostgreSQL Plugin for DirectAdmin User Guide

This guide provides detailed instructions on how to use the PostgreSQL Plugin for DirectAdmin after it has been successfully installed.

## Table of Contents

1. [Accessing the Plugin](#accessing-the-plugin)
2. [Admin Interface](#admin-interface)
   - [Dashboard](#admin-dashboard)
   - [Managing PostgreSQL Server](#managing-postgresql-server)
   - [Database Management](#admin-database-management)
   - [User Management](#admin-user-management)
   - [Configuration](#postgresql-configuration)
   - [Backup & Restore](#backup-and-restore)
3. [User Interface](#user-interface)
   - [Dashboard](#user-dashboard)
   - [Creating Databases](#creating-databases)
   - [Managing Databases](#managing-databases)
   - [Viewing Access Credentials](#viewing-access-credentials)
4. [Advanced Usage](#advanced-usage)
   - [Remote Access](#remote-access)
   - [Performance Tuning](#performance-tuning)
   - [Security Best Practices](#security-best-practices)
5. [Troubleshooting](#troubleshooting)
   - [Common Issues](#common-issues)
   - [Log Locations](#log-locations)
   - [Getting Support](#getting-support)

---

## Accessing the Plugin

After installing the PostgreSQL Plugin, you can access it through the DirectAdmin control panel:

### Admin Access

1. Log in to DirectAdmin as an administrator
2. Navigate to **Extra Features** in the left menu
3. Click on **PostgreSQL Management**

Alternatively, you can directly access the plugin at: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin`

### User Access

1. Log in to DirectAdmin as a user
2. Navigate to **Extra Features** in the left menu
3. Click on **PostgreSQL Databases**

Alternatively, users can directly access the plugin at: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin`

---

## Admin Interface

### Admin Dashboard

The admin dashboard provides an overview of your PostgreSQL installation:

- **PostgreSQL Server Status**: Shows if the server is running and its version
- **Database Statistics**: Total number of databases and disk usage
- **User Statistics**: Total number of database users
- **Recent Activity**: Recent database operations
- **Resource Usage**: Current connections and memory usage

### Managing PostgreSQL Server

From the admin interface, you can:

1. **Start/Stop/Restart PostgreSQL Server**:
   - Click on the respective buttons in the server control panel
   - Changes take effect immediately

2. **View Server Logs**:
   - Click on "View Logs" to see the PostgreSQL server logs
   - Useful for troubleshooting issues

3. **Update PostgreSQL**:
   - The plugin will notify you when updates are available
   - Click "Update" to upgrade to the latest version
   - Always create a backup before updating

### Admin Database Management

#### Creating Databases

1. Click on the "Databases" tab
2. Click "Create New Database"
3. Enter a name for the database
   - Names can only contain letters, numbers, and underscores
   - Names are limited to 63 characters
4. Select the owner of the database (or create a new user)
5. Click "Create Database"

#### Managing Databases

1. Click on the "Databases" tab to see all databases
2. Use the search and filter options to find specific databases
3. For each database, you can:
   - **View Details**: Size, owner, creation date
   - **Change Owner**: Assign the database to a different user
   - **Backup**: Create a SQL dump of the database
   - **Restore**: Restore from a previous backup
   - **Delete**: Permanently remove the database

### Admin User Management

#### Creating Database Users

1. Click on the "Users" tab
2. Click "Create New User"
3. Enter a username
   - Names can only contain letters, numbers, and underscores
   - Names are limited to 63 characters
4. Set a strong password or generate one automatically
5. Optionally, associate the user with a DirectAdmin account
6. Click "Create User"

#### Managing Users

1. Click on the "Users" tab to see all database users
2. For each user, you can:
   - **Change Password**: Update the user's password
   - **View Privileges**: See which databases the user can access
   - **Modify Privileges**: Change access rights
   - **Delete**: Remove the user (note: this will not delete databases)

### PostgreSQL Configuration

The configuration section allows you to manage PostgreSQL server settings:

1. **General Settings**:
   - Max connections
   - Shared buffers
   - Effective cache size
   - Work memory
   - Maintenance work memory

2. **Logging Settings**:
   - Log level
   - Log destination
   - Log rotation

3. **WAL Settings**:
   - WAL level
   - Archive mode
   - Archive command

4. **Performance Settings**:
   - Autovacuum
   - Checkpoint segments
   - Random page cost

5. **Security Settings**:
   - SSL settings
   - Authentication methods
   - Client connection settings

Changes to these settings require a server restart to take effect.

### Backup and Restore

#### Creating Backups

1. Navigate to the "Backup" tab
2. Choose what to back up:
   - All databases
   - Specific databases
   - Configuration only
3. Select backup format:
   - SQL dump (recommended for portability)
   - Custom format (more flexible for selective restore)
4. Choose backup location:
   - Local server
   - Remote server (via SCP/SFTP)
   - Cloud storage (if configured)
5. Set scheduling options (optional):
   - Daily, weekly, or monthly
   - Time of day
   - Retention policy
6. Click "Create Backup"

#### Restoring from Backup

1. Navigate to the "Restore" tab
2. Select a backup file or upload one
3. Choose restore options:
   - Full restore
   - Selective restore (specific databases or tables)
   - Restore to different database names
4. Click "Restore"

---

## User Interface

### User Dashboard

The user dashboard provides an overview of the user's PostgreSQL resources:

- **Database Summary**: Number of databases and total size
- **Recent Activity**: Recent database operations
- **Quick Actions**: Create database, view connection information

### Creating Databases

1. From the user dashboard, click "Create New Database"
2. Enter a database name
   - Names can only contain letters, numbers, and underscores
   - Names are limited to 63 characters
   - Prefixed with the username (e.g., username_dbname)
3. Choose a character set and collation (optional)
4. Click "Create Database"

### Managing Databases

Users can manage their own databases:

1. View a list of all databases on the main page
2. For each database, users can:
   - **View Size**: See the current size of the database
   - **Export**: Create a SQL dump for backup purposes
   - **Import**: Import from a SQL dump file
   - **Delete**: Permanently remove the database

### Viewing Access Credentials

1. Click "Connection Info" to view database connection details:
   - Database host (usually localhost)
   - Username
   - Password
   - Port number
   - Connection URL format

2. These credentials can be used to connect to the database via:
   - Command-line client (psql)
   - GUI clients (pgAdmin, DBeaver, etc.)
   - Application configuration files

---

## Advanced Usage

### Remote Access

By default, PostgreSQL only accepts connections from localhost. To enable remote access:

1. Navigate to the admin interface
2. Go to "Configuration" tab
3. Set "listen_addresses" to '*' or specific IP addresses
4. Configure pg_hba.conf entries for remote hosts
5. Ensure your firewall allows connections on PostgreSQL port (default: 5432)
6. Restart PostgreSQL server

### Performance Tuning

The plugin provides recommended settings based on your server resources. For additional tuning:

1. Go to "Configuration" tab in the admin interface
2. Adjust parameters based on:
   - Available RAM (shared_buffers, work_mem)
   - CPU resources (max_worker_processes)
   - Storage type (random_page_cost, effective_cache_size)
3. Use the "Analyze" tool to identify slow queries
4. Enable query performance monitoring for detailed insights

### Security Best Practices

1. **Strong Passwords**:
   - Use the generate password feature for complex passwords
   - Regularly rotate passwords

2. **Limited Privileges**:
   - Grant only necessary permissions to database users
   - Use separate users for different applications

3. **Network Security**:
   - Restrict remote access by IP address when possible
   - Use SSL connections for remote access

4. **Regular Updates**:
   - Keep PostgreSQL updated to the latest version
   - Enable automatic security updates

---

## Troubleshooting

### Common Issues

#### Connection Refused

- **Cause**: PostgreSQL service is not running or listening on the wrong interface
- **Solution**: 
  - Check server status in admin panel
  - Verify listen_addresses configuration
  - Check firewall rules

#### Permission Denied

- **Cause**: Incorrect username/password or insufficient privileges
- **Solution**:
  - Verify credentials in connection information
  - Check user privileges in admin panel

#### Database Creation Fails

- **Cause**: Name conflicts, quota limits, or invalid characters
- **Solution**:
  - Choose a different database name
  - Check quota limits for the user
  - Use only allowed characters (letters, numbers, underscores)

#### Slow Performance

- **Cause**: Insufficient resources or unoptimized configuration
- **Solution**:
  - Adjust configuration parameters
  - Analyze and optimize slow queries
  - Increase server resources if necessary

### Log Locations

For troubleshooting issues, check these log files:

- **PostgreSQL Server Logs**: `/var/log/postgresql/postgresql-*.log`
- **Plugin Installation Log**: `/usr/local/directadmin/logs/postgresql_install.log`
- **Plugin Operation Logs**: `/usr/local/directadmin/plugins/postgresql_plugin/logs/`

### Getting Support

If you encounter issues that you cannot resolve:

1. Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) file for additional guidance
2. Visit the plugin GitHub repository for known issues and solutions
3. Contact DirectAdmin support with:
   - Detailed description of the issue
   - Relevant log files
   - Steps to reproduce the problem

---

## Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [DirectAdmin Knowledge Base](https://help.directadmin.com/)
- [Plugin GitHub Repository](https://github.com/username/postgresql-directadmin-plugin)

---

For more information or to report issues, please contact the plugin maintainer or DirectAdmin support.