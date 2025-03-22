# PostgreSQL Plugin for DirectAdmin: Troubleshooting Guide

This document provides detailed troubleshooting guidance for common issues with the PostgreSQL Plugin for DirectAdmin.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Connection Issues](#connection-issues)
3. [Performance Issues](#performance-issues)
4. [Database Management Issues](#database-management-issues)
5. [User Management Issues](#user-management-issues)
6. [CustomBuild Issues](#custombuild-issues)
7. [Plugin Manager Issues](#plugin-manager-issues)
8. [DirectAdmin Integration Issues](#directadmin-integration-issues)
9. [Log File Locations](#log-file-locations)
10. [Getting Help](#getting-help)

---

## Installation Issues

### PostgreSQL Not Installing Properly

**Symptoms:**
- Installation script completes but PostgreSQL service doesn't start
- Error messages about missing PostgreSQL packages

**Solutions:**
1. Check system prerequisites:
   ```bash
   # For RHEL/CentOS/Rocky/AlmaLinux
   yum check-update
   
   # For Debian/Ubuntu
   apt update
   ```

2. Verify installation logs:
   ```bash
   cat /usr/local/directadmin/logs/postgresql_install.log
   ```

3. Try manual installation to see detailed errors:
   ```bash
   # For RHEL/CentOS/Rocky/AlmaLinux
   yum install postgresql postgresql-server
   
   # For Debian/Ubuntu
   apt install postgresql
   ```

4. Check disk space and ensure sufficient space is available:
   ```bash
   df -h
   ```

### Plugin Files Not Copying Correctly

**Symptoms:**
- Missing plugin files
- Permission denied errors
- Plugin not appearing in DirectAdmin

**Solutions:**
1. Verify plugin files were extracted correctly:
   ```bash
   ls -la /usr/local/directadmin/plugins/postgresql_plugin/
   ```

2. Check permissions:
   ```bash
   chmod -R 755 /usr/local/directadmin/plugins/postgresql_plugin/
   chown -R diradmin:diradmin /usr/local/directadmin/plugins/postgresql_plugin/
   ```

3. Make script files executable:
   ```bash
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/exec/*.sh
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/hooks/*.sh
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/scripts/*.sh
   ```

4. Manually register the plugin if needed:
   ```bash
   echo "postgresql_plugin=2.2" >> /usr/local/directadmin/conf/plugins.conf
   ```

5. Restart DirectAdmin:
   ```bash
   systemctl restart directadmin
   ```

---

## Connection Issues

### Cannot Connect to PostgreSQL Server

**Symptoms:**
- "Connection refused" errors
- "Could not connect to server" messages
- Database operations fail

**Solutions:**
1. Check if PostgreSQL is running:
   ```bash
   systemctl status postgresql
   ```

2. If not running, start it:
   ```bash
   systemctl start postgresql
   ```

3. Verify PostgreSQL is listening on the correct address:
   ```bash
   sudo -u postgres psql -c "SHOW listen_addresses;"
   ```

4. Check pg_hba.conf for proper client authentication rules:
   ```bash
   cat /var/lib/pgsql/data/pg_hba.conf  # RHEL/CentOS
   # or
   cat /etc/postgresql/*/main/pg_hba.conf  # Debian/Ubuntu
   ```

5. Verify firewall settings:
   ```bash
   # For firewalld
   firewall-cmd --list-all
   
   # For iptables
   iptables -L
   ```

### Authentication Failures

**Symptoms:**
- "Password authentication failed for user" errors
- Cannot log in with provided credentials

**Solutions:**
1. Reset password for the PostgreSQL user:
   ```bash
   sudo -u postgres psql -c "ALTER USER username WITH PASSWORD 'new_password';"
   ```

2. Check authentication method in pg_hba.conf:
   ```bash
   # Look for entries like:
   # host all all 127.0.0.1/32 md5
   # Ensure they're using md5 or scram-sha-256 (not trust, ident, or peer)
   ```

3. Restart PostgreSQL after changing pg_hba.conf:
   ```bash
   systemctl restart postgresql
   ```

4. Verify user exists:
   ```bash
   sudo -u postgres psql -c "\du"
   ```

---

## Performance Issues

### Slow Database Operations

**Symptoms:**
- Queries taking longer than expected
- DirectAdmin interface becoming sluggish
- Timeouts when performing database operations

**Solutions:**
1. Check system resources:
   ```bash
   free -m           # Memory usage
   df -h             # Disk space
   top               # CPU and process load
   ```

2. Optimize PostgreSQL configuration based on server resources:
   - Edit postgresql.conf:
     ```
     shared_buffers = 25% of RAM (up to 8GB)
     effective_cache_size = 75% of RAM
     work_mem = 32MB-64MB (adjust based on complex queries)
     maintenance_work_mem = 256MB-1GB
     ```

3. Enable and check slow query logging:
   ```bash
   sudo -u postgres psql -c "ALTER SYSTEM SET log_min_duration_statement = 1000;"  # Log queries over 1 second
   sudo -u postgres psql -c "SELECT pg_reload_conf();"
   ```

4. Check for and optimize inefficient queries:
   ```bash
   sudo -u postgres psql -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
   ```

5. Run VACUUM and ANALYZE to optimize database performance:
   ```bash
   sudo -u postgres psql -c "VACUUM ANALYZE;"
   ```

### High Disk Usage

**Symptoms:**
- Rapidly increasing database size
- Disk space warnings
- Server becoming unresponsive

**Solutions:**
1. Identify large databases:
   ```bash
   sudo -u postgres psql -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size FROM pg_database ORDER BY pg_database_size(pg_database.datname) DESC;"
   ```

2. Identify large tables:
   ```bash
   sudo -u postgres psql -d database_name -c "SELECT nspname || '.' || relname AS relation, pg_size_pretty(pg_total_relation_size(C.oid)) AS total_size FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname NOT IN ('pg_catalog', 'information_schema') AND C.relkind <> 'i' AND nspname !~ '^pg_toast' ORDER BY pg_total_relation_size(C.oid) DESC LIMIT 20;"
   ```

3. Enable autovacuum to reclaim space:
   ```bash
   sudo -u postgres psql -c "ALTER SYSTEM SET autovacuum = on;"
   sudo -u postgres psql -c "ALTER SYSTEM SET autovacuum_vacuum_scale_factor = 0.1;"
   sudo -u postgres psql -c "ALTER SYSTEM SET autovacuum_analyze_scale_factor = 0.05;"
   sudo -u postgres psql -c "SELECT pg_reload_conf();"
   ```

4. Set up log rotation for PostgreSQL logs:
   ```bash
   # Check if log rotation is properly configured
   cat /etc/logrotate.d/postgresql
   ```

---

## Database Management Issues

### Cannot Create Database

**Symptoms:**
- "Permission denied" when creating a database
- "Database already exists" errors
- Creation fails with no error message

**Solutions:**
1. Check user permissions:
   ```bash
   sudo -u postgres psql -c "\du username"
   ```

2. Grant necessary permissions:
   ```bash
   sudo -u postgres psql -c "ALTER USER username CREATEDB;"
   ```

3. Check if database already exists:
   ```bash
   sudo -u postgres psql -c "\l" | grep database_name
   ```

4. Verify disk space availability:
   ```bash
   df -h
   ```

5. Check PostgreSQL logs for specific error messages:
   ```bash
   tail -n 100 /var/log/postgresql/postgresql-*.log
   ```

### Database Import/Export Failures

**Symptoms:**
- Timeout during import/export
- Errors about file permissions
- Incomplete data transfer

**Solutions:**
1. Check file permissions:
   ```bash
   ls -la /path/to/dump/file
   ```

2. Ensure sufficient disk space:
   ```bash
   df -h
   ```

3. For large databases, use pg_dump with compression:
   ```bash
   pg_dump -Fc -Z9 -U username database_name > /path/to/output.dump
   ```

4. Import using pg_restore for custom format dumps:
   ```bash
   pg_restore -U username -d database_name /path/to/dump.dump
   ```

5. For very large databases, consider breaking the process into smaller transactions:
   ```bash
   pg_restore -U username -d database_name --disable-triggers --no-owner /path/to/dump.dump
   ```

---

## User Management Issues

### Cannot Create User

**Symptoms:**
- User creation fails in DirectAdmin interface
- Error messages about duplicate users
- Permission issues during creation

**Solutions:**
1. Check if user already exists:
   ```bash
   sudo -u postgres psql -c "\du" | grep username
   ```

2. Verify PostgreSQL user limits:
   ```bash
   sudo -u postgres psql -c "SHOW max_connections;"
   ```

3. Ensure the DirectAdmin user has sufficient permissions:
   ```bash
   sudo -u postgres psql -c "SELECT rolcreaterole FROM pg_roles WHERE rolname = 'directadmin';"
   ```

4. Grant necessary permissions if needed:
   ```bash
   sudo -u postgres psql -c "ALTER USER directadmin CREATEROLE;"
   ```

### User Permissions Issues

**Symptoms:**
- Users cannot access certain databases
- "Permission denied" errors for specific operations
- Users can access databases they shouldn't

**Solutions:**
1. Check user permissions:
   ```bash
   sudo -u postgres psql -c "\du username"
   ```

2. Verify database access privileges:
   ```bash
   sudo -u postgres psql -c "\l"
   ```

3. Grant necessary privileges:
   ```bash
   sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE database_name TO username;"
   ```

4. For table-level privileges:
   ```bash
   sudo -u postgres psql -d database_name -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO username;"
   ```

5. Set default privileges for new tables:
   ```bash
   sudo -u postgres psql -d database_name -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO username;"
   ```

---

## CustomBuild Issues

### PostgreSQL Option Not Showing in CustomBuild

**Symptoms:**
- PostgreSQL option missing from CustomBuild menu
- `./build set postgresql yes` command fails

**Solutions:**
1. Update CustomBuild:
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build update
   ```

2. Manually add PostgreSQL option files:
   ```bash
   mkdir -p /usr/local/directadmin/custombuild/custom
   cp /path/to/postgresql.conf /usr/local/directadmin/custombuild/custom/
   cp /path/to/postgresql_install.sh /usr/local/directadmin/custombuild/custom/
   cp /path/to/postgresql_uninstall.sh /usr/local/directadmin/custombuild/custom/
   chmod +x /usr/local/directadmin/custombuild/custom/postgresql_*.sh
   ```

3. Add to options.conf:
   ```bash
   echo "postgresql=yes" >> /usr/local/directadmin/custombuild/options.conf
   ```

4. Rebuild the options cache:
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build cache
   ```

### CustomBuild Installation Fails

**Symptoms:**
- CustomBuild installation process fails
- Errors in build logs
- PostgreSQL service doesn't start after installation

**Solutions:**
1. Check CustomBuild logs:
   ```bash
   cat /usr/local/directadmin/custombuild/custom_build.log
   ```

2. Verify script permissions:
   ```bash
   chmod +x /usr/local/directadmin/custombuild/custom/postgresql_*.sh
   ```

3. Run with debug option:
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build postgresql debug
   ```

4. Verify script syntax:
   ```bash
   bash -n /usr/local/directadmin/custombuild/custom/postgresql_install.sh
   ```

5. Check for package conflicts:
   ```bash
   # For RHEL/CentOS
   yum list installed | grep postgres
   
   # For Debian/Ubuntu
   dpkg -l | grep postgres
   ```

---

## Plugin Manager Issues

### Plugin Not Appearing in Plugin Manager

**Symptoms:**
- Plugin doesn't appear in DirectAdmin Plugin Manager
- Cannot install from Plugin Manager
- "Unknown plugin" errors

**Solutions:**
1. Verify plugin.info file exists and has correct format:
   ```bash
   cat /usr/local/directadmin/plugins/postgresql_plugin/plugin.info
   ```

2. Check setup.json for correct structure:
   ```bash
   cat /usr/local/directadmin/plugins/postgresql_plugin/setup.json
   ```

3. Ensure plugin is registered with DirectAdmin:
   ```bash
   grep postgresql_plugin /usr/local/directadmin/conf/plugins.conf
   ```

4. Manually register if needed:
   ```bash
   echo "postgresql_plugin=2.2" >> /usr/local/directadmin/conf/plugins.conf
   ```

5. Restart DirectAdmin:
   ```bash
   systemctl restart directadmin
   ```

### Plugin Update Issues

**Symptoms:**
- Update process fails
- Version doesn't change after update
- Features missing after update

**Solutions:**
1. Check update script:
   ```bash
   cat /usr/local/directadmin/plugins/postgresql_plugin/update.sh
   ```

2. Verify permissions:
   ```bash
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/update.sh
   ```

3. Run update manually:
   ```bash
   cd /usr/local/directadmin/plugins/postgresql_plugin
   ./update.sh
   ```

4. Check for update logs:
   ```bash
   cat /usr/local/directadmin/logs/postgresql_update.log
   ```

---

## DirectAdmin Integration Issues

### Hooks Not Working

**Symptoms:**
- User creation in DirectAdmin doesn't create PostgreSQL user
- Deleted DirectAdmin users still have PostgreSQL accounts
- DirectAdmin operations don't trigger PostgreSQL actions

**Solutions:**
1. Check hook symlinks:
   ```bash
   ls -la /usr/local/directadmin/scripts/custom/postgresql_*.sh
   ```

2. Create missing symlinks:
   ```bash
   ln -sf /usr/local/directadmin/plugins/postgresql_plugin/hooks/postgresql_create_user.sh /usr/local/directadmin/scripts/custom/postgresql_create_user.sh
   ln -sf /usr/local/directadmin/plugins/postgresql_plugin/hooks/postgresql_delete_user.sh /usr/local/directadmin/scripts/custom/postgresql_delete_user.sh
   ```

3. Verify hook script permissions:
   ```bash
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/hooks/*.sh
   ```

4. Test hooks manually:
   ```bash
   /usr/local/directadmin/plugins/postgresql_plugin/hooks/postgresql_create_user.sh testuser
   ```

5. Check DirectAdmin task.queue processing:
   ```bash
   grep "task.queue" /usr/local/directadmin/logs/error.log
   ```

### Plugin Interface Not Accessible

**Symptoms:**
- 404 errors when accessing plugin URL
- Blank page when accessing plugin
- Access denied messages

**Solutions:**
1. Verify plugin directory permissions:
   ```bash
   chmod -R 755 /usr/local/directadmin/plugins/postgresql_plugin
   chown -R diradmin:diradmin /usr/local/directadmin/plugins/postgresql_plugin
   ```

2. Check for PHP errors:
   ```bash
   tail -n 100 /var/log/httpd/error_log  # Apache
   # or
   tail -n 100 /var/log/nginx/error.log  # Nginx
   ```

3. Verify .htaccess configuration:
   ```bash
   cat /usr/local/directadmin/plugins/postgresql_plugin/.htaccess
   ```

4. Check DirectAdmin access logs:
   ```bash
   tail -n 100 /usr/local/directadmin/logs/access.log
   ```

5. Restart web server:
   ```bash
   systemctl restart httpd  # Apache
   # or
   systemctl restart nginx  # Nginx
   ```

---

## Log File Locations

For troubleshooting, check these log files:

### PostgreSQL Logs
- RHEL/CentOS/Rocky/AlmaLinux: `/var/lib/pgsql/data/log/` or `/var/log/postgresql/`
- Debian/Ubuntu: `/var/log/postgresql/postgresql-*.log`

### DirectAdmin Logs
- Main log: `/usr/local/directadmin/logs/error.log`
- Access log: `/usr/local/directadmin/logs/access.log`
- Plugin installation log: `/usr/local/directadmin/logs/postgresql_install.log`
- Plugin update log: `/usr/local/directadmin/logs/postgresql_update.log`

### Web Server Logs
- Apache:
  - Error log: `/var/log/httpd/error_log`
  - Access log: `/var/log/httpd/access_log`
- Nginx:
  - Error log: `/var/log/nginx/error.log`
  - Access log: `/var/log/nginx/access.log`

### Plugin-Specific Logs
- Operation logs: `/usr/local/directadmin/plugins/postgresql_plugin/logs/`

### CustomBuild Logs
- Main log: `/usr/local/directadmin/custombuild/custom_build.log`

---

## Getting Help

If you're unable to resolve an issue using this guide, please:

1. **Gather Information**:
   - DirectAdmin version (`cat /usr/local/directadmin/version`)
   - PostgreSQL plugin version (`grep postgresql_plugin /usr/local/directadmin/conf/plugins.conf`)
   - PostgreSQL version (`sudo -u postgres psql -c "SELECT version();"`)
   - Operating system version (`cat /etc/os-release`)
   - Relevant log entries
   - Steps to reproduce the issue

2. **Contact Support**:
   - Open an issue on the plugin's GitHub repository
   - Contact your DirectAdmin support representative
   - Post on the DirectAdmin community forums

3. **For Urgent Issues**:
   - Contact the plugin maintainer directly
   - Consider professional PostgreSQL support services