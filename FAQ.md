# PostgreSQL Plugin for DirectAdmin: Frequently Asked Questions

This document provides answers to frequently asked questions about the PostgreSQL Plugin for DirectAdmin.

## Table of Contents

1. [General Questions](#general-questions)
2. [Installation Questions](#installation-questions)
3. [Upgrade Questions](#upgrade-questions)
4. [Configuration Questions](#configuration-questions)
5. [Admin Questions](#admin-questions)
6. [User Questions](#user-questions)
7. [Database Questions](#database-questions)
8. [Performance Questions](#performance-questions)
9. [Security Questions](#security-questions)
10. [Troubleshooting Questions](#troubleshooting-questions)

---

## General Questions

### What is the PostgreSQL Plugin for DirectAdmin?

The PostgreSQL Plugin for DirectAdmin is an integration that allows administrators and users to manage PostgreSQL databases through the DirectAdmin control panel. It provides a user-friendly interface for creating and managing databases, users, and permissions without needing to use the command line.

### What are the main features of the plugin?

The main features include:
- Installation and management of PostgreSQL server
- Creation and management of databases and users
- Database backup and restore
- PostgreSQL server configuration
- User-friendly web interface for both administrators and users
- DirectAdmin user integration (automatic database creation/deletion)
- Performance monitoring and optimization

### What versions of PostgreSQL are supported?

The plugin supports PostgreSQL versions 10, 11, 12, 13, 14, and 15. The recommended version is PostgreSQL 14 or higher for the best performance and feature support.

### Is the plugin compatible with all DirectAdmin versions?

The plugin requires DirectAdmin 1.60.0 or later. It has been tested with DirectAdmin versions up to 1.65.x. Always ensure you're using the latest version of both DirectAdmin and the PostgreSQL plugin for the best compatibility.

---

## Installation Questions

### What's the recommended installation method?

The recommended installation method is through DirectAdmin's CustomBuild system. This ensures proper integration with DirectAdmin's package management and update system.

```bash
cd /usr/local/directadmin/custombuild
./build set postgresql yes
./build update
./build postgresql
```

### Can I install the plugin manually?

Yes, you can install the plugin manually by downloading the package, extracting it, and running the installation script. See the [README.md](README.md) file for detailed instructions on manual installation.

### Does the plugin install PostgreSQL automatically?

Yes, if PostgreSQL is not already installed on the server, the plugin will install it during the setup process. The installation script will detect the operating system and install the appropriate PostgreSQL packages.

### Can I use an existing PostgreSQL installation?

Yes, if PostgreSQL is already installed, the plugin will detect it and configure itself to work with the existing installation. However, the plugin may need to modify some PostgreSQL configuration files to ensure proper integration with DirectAdmin.

### What operating systems are supported?

The plugin supports:
- CentOS 7/8
- AlmaLinux 8
- Rocky Linux 8
- Debian 10/11
- Ubuntu 20.04/22.04

Other Linux distributions might work but are not officially supported.

---

## Upgrade Questions

### How do I upgrade the plugin to a newer version?

The easiest way to upgrade is through the DirectAdmin Plugin Manager:
1. Log in to DirectAdmin as admin
2. Navigate to Plugin Manager
3. Find the PostgreSQL Plugin in the list
4. Click the "Update" button

Alternatively, if you installed via CustomBuild:
```bash
cd /usr/local/directadmin/custombuild
./build update
./build postgresql
```

### Will upgrading affect my existing databases?

No, upgrading the plugin will not affect your existing databases or users. The upgrade process only updates the plugin files and, if necessary, the PostgreSQL server software. Your data remains intact.

### Can I downgrade to a previous version?

Downgrading is not officially supported and may cause issues with plugin functionality. If you need to downgrade, it's recommended to uninstall the current version completely and then install the specific version you need.

### How do I know which version I'm currently using?

You can check the current version in several ways:
1. In the DirectAdmin Plugin Manager
2. In the PostgreSQL Plugin admin interface header
3. By checking the plugins.conf file:
   ```bash
   grep postgresql_plugin /usr/local/directadmin/conf/plugins.conf
   ```

---

## Configuration Questions

### How do I change the PostgreSQL port?

To change the PostgreSQL port:
1. Log in to the admin interface
2. Navigate to the "Configuration" tab
3. Locate the "port" setting and change it to your desired port
4. Click "Save Changes" and restart PostgreSQL

Remember to update any firewall rules to allow connections on the new port.

### Can I configure PostgreSQL to accept remote connections?

Yes, to allow remote connections:
1. In the admin interface, go to "Configuration"
2. Set "listen_addresses" to '*' (for all interfaces) or specific IP addresses
3. Add appropriate entries to pg_hba.conf for remote hosts
4. Save changes and restart PostgreSQL
5. Configure your firewall to allow connections on the PostgreSQL port

### How do I increase the maximum connections limit?

To increase the maximum connections:
1. In the admin interface, go to "Configuration"
2. Locate the "max_connections" setting
3. Increase the value to your desired limit
4. Save changes and restart PostgreSQL

Note that higher values require more system resources, especially shared memory.

### How do I optimize PostgreSQL for my server's resources?

The plugin provides recommended settings based on your server resources. For manual optimization:
1. Go to "Configuration" in the admin interface
2. Adjust these key parameters:
   - shared_buffers (typically 25% of RAM)
   - effective_cache_size (typically 75% of RAM)
   - maintenance_work_mem (typically 128MB-1GB depending on RAM)
   - work_mem (typically 32-64MB)
3. Save changes and restart PostgreSQL

For servers with limited resources, be conservative with these values to avoid memory pressure.

---

## Admin Questions

### How do I create a new database user?

To create a new database user:
1. Log in to the admin interface
2. Go to the "Users" tab
3. Click "Create New User"
4. Enter a username
5. Set a strong password or generate one automatically
6. Optionally, associate with a DirectAdmin user
7. Set privileges as needed
8. Click "Create User"

### How do I grant a user access to a database?

To grant database access:
1. Log in to the admin interface
2. Go to the "Databases" tab
3. Find the database and click "Privileges"
4. Select the user from the dropdown
5. Choose the appropriate privilege level (Read Only, Read/Write, Full Access)
6. Click "Grant Access"

### How do I view the PostgreSQL server logs?

To view server logs:
1. Log in to the admin interface
2. Go to the "Logs" tab
3. Select the log file and date range
4. Click "View Logs"
5. Use the filtering options to search for specific events

### How do I backup all databases?

To backup all databases:
1. Log in to the admin interface
2. Go to the "Backup" tab
3. Select "All Databases" option
4. Choose backup format (SQL or custom)
5. Set backup location and filename
6. Click "Create Backup"

You can also schedule automatic backups from this interface.

---

## User Questions

### How many databases can a user create?

The number of databases a user can create depends on the quota set by the administrator. By default, there's no hard limit, but administrators can set a per-user database quota in the admin interface.

### Can users create their own database users?

No, regular users cannot create new database users. Only administrators can create PostgreSQL users. Regular users can only create databases associated with their own account.

### How do users connect to their databases?

Users can connect to their databases using:
1. The connection information provided in the user interface
2. Any PostgreSQL client (e.g., psql, pgAdmin, DBeaver)
3. Their application's database configuration

The connection information includes host, port, username, password, and database name.

### Can users import existing databases?

Yes, users can import existing databases:
1. In the user interface, go to the "Databases" tab
2. Click "Import" next to the target database
3. Upload a SQL dump file or provide a URL to download from
4. Click "Import Database"

Note that very large imports might time out through the web interface. For large databases, command-line imports are recommended.

---

## Database Questions

### What is the maximum database size supported?

PostgreSQL itself has no practical database size limit (maximum table size is 32TB). However, actual limits depend on:
- Available disk space
- System resources
- DirectAdmin or hosting provider quotas

For practical performance, databases over 100GB may need additional tuning.

### Can I use PostgreSQL extensions?

Yes, the plugin supports PostgreSQL extensions. Administrators can install and enable extensions through the admin interface under "Extensions" tab. Common extensions like PostGIS, pg_stat_statements, and uuid-ossp are supported.

### How do I perform database maintenance?

The plugin automatically configures autovacuum for basic maintenance. For manual maintenance:
1. Log in to the admin interface
2. Go to the "Databases" tab
3. Select a database
4. Click "Maintenance"
5. Choose the maintenance operation (VACUUM, ANALYZE, REINDEX)
6. Click "Run Maintenance"

### Can I migrate from MySQL/MariaDB to PostgreSQL?

The plugin doesn't include direct MySQL-to-PostgreSQL migration tools. However, you can:
1. Export data from MySQL in a compatible format
2. Create the schema in PostgreSQL
3. Import the data
4. Adjust data types and queries as needed

There are third-party tools like pgLoader that can assist with this process.

---

## Performance Questions

### Why is my database slow?

Database slowness can be caused by:
1. Insufficient server resources
2. Unoptimized queries
3. Missing indexes
4. Configuration issues
5. Excessive connections

To troubleshoot:
1. Check system resources (CPU, memory, disk I/O)
2. Enable slow query logging
3. Use EXPLAIN to analyze query performance
4. Verify proper indexing
5. Adjust PostgreSQL configuration parameters

### How can I monitor database performance?

The plugin provides basic performance monitoring in the admin interface. For more detailed monitoring:
1. Go to "Monitoring" tab
2. View real-time statistics on connections, queries, and resource usage
3. Check the query statistics for slow queries
4. Review system resource graphs

Consider enabling the pg_stat_statements extension for detailed query performance tracking.

### What are the recommended server specifications?

Minimum recommended specifications:
- CPU: 2 cores
- RAM: 4GB (8GB+ recommended)
- Disk: SSD storage with at least 20GB free space
- Network: 100Mbps+ for optimal remote connections

Higher specs are recommended for production environments with multiple databases or high query volumes.

---

## Security Questions

### Is PostgreSQL exposed to the internet?

By default, PostgreSQL is configured to only accept connections from localhost. The plugin maintains this secure default. If remote access is needed, it must be explicitly configured by the administrator with proper security measures.

### How are database passwords stored?

Database passwords are stored securely in PostgreSQL's internal authentication system using strong hashing (SCRAM-SHA-256 or MD5 depending on PostgreSQL version). The plugin never stores the plain text passwords.

### Is SSL enabled for database connections?

SSL is not enabled by default but can be configured by the administrator:
1. In the admin interface, go to "Configuration"
2. Enable the SSL settings
3. Configure SSL certificate paths
4. Restart PostgreSQL
5. Update pg_hba.conf to require SSL for connections

### How do I reset a user's password?

To reset a user's password:
1. Log in to the admin interface
2. Go to the "Users" tab
3. Find the user and click "Change Password"
4. Enter a new password or generate one automatically
5. Click "Save Changes"

---

## Troubleshooting Questions

### PostgreSQL won't start. What should I do?

If PostgreSQL won't start:
1. Check the PostgreSQL logs (in the admin interface or at /var/log/postgresql/)
2. Verify file permissions on data directory
3. Ensure sufficient disk space is available
4. Look for configuration errors
5. Check system resource availability

See the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) document for detailed steps.

### I can't connect to my database. What's wrong?

Connection issues could be caused by:
1. PostgreSQL service not running
2. Incorrect connection parameters
3. Authentication failure
4. Firewall blocking connection
5. Network issue

Check the "Connection Issues" section in [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed diagnostic steps.

### How do I recover a deleted database?

If a database was recently deleted:
1. Check if you have a recent backup
2. Restore from the backup using the restore function
3. If no backup exists, check if WAL archiving was enabled (point-in-time recovery)

For future protection, set up regular automated backups through the admin interface.

### The plugin interface shows errors. How do I fix them?

Interface errors could be caused by:
1. PHP configuration issues
2. DirectAdmin permission problems
3. Plugin file corruption
4. Compatibility issues

Try:
1. Checking the web server error logs
2. Verifying file permissions
3. Reinstalling the plugin
4. Updating to the latest version

---

If your question isn't addressed here, please refer to the [USER_GUIDE.md](USER_GUIDE.md), [TROUBLESHOOTING.md](TROUBLESHOOTING.md), or contact support for assistance.