# CustomBuild Integration for PostgreSQL Plugin

This document provides detailed information on installing, configuring, and managing the PostgreSQL plugin using DirectAdmin's CustomBuild system.

## Table of Contents

1. [Overview](#overview)
2. [How CustomBuild Integration Works](#how-custombuild-integration-works)
3. [Installation via CustomBuild](#installation-via-custombuild)
4. [Updating the Plugin](#updating-the-plugin)
5. [Configuration Options](#configuration-options)
6. [Uninstalling the Plugin](#uninstalling-the-plugin)
7. [Troubleshooting CustomBuild Integration](#troubleshooting)
8. [Advanced CustomBuild Options](#advanced-custombuild-options)
9. [Additional Resources](#additional-resources)

---

## Overview

The PostgreSQL plugin is fully integrated with DirectAdmin's CustomBuild system, allowing you to easily install, update, and manage PostgreSQL directly from the CustomBuild interface. This integration provides several benefits:

- Simplified installation process
- Automatic dependency management
- Seamless updates
- Consistent configurations
- Integration with DirectAdmin's package management system

## How CustomBuild Integration Works

The CustomBuild integration consists of several components:

1. **CustomBuild Configuration Files**:
   - `postgresql.conf`: Defines the build options and dependencies
   - `postgresql_install.sh`: Script for installing the plugin
   - `postgresql_uninstall.sh`: Script for uninstalling the plugin
   - Entry in `options.conf`: Enables the PostgreSQL option in CustomBuild

2. **Plugin Registration**:
   - Adds the plugin to DirectAdmin's plugin registry
   - Sets up proper permissions and ownership
   - Creates necessary symlinks and directories

3. **Hook Integration**:
   - Configures DirectAdmin hooks for user creation/deletion
   - Sets up connection with DirectAdmin's user management system

## Installation via CustomBuild

### Method 1: Using the CustomBuild Web Interface

1. Log in to DirectAdmin as the admin user
2. Navigate to **Admin Level** → **CustomBuild**
3. In the **Server Software** section, locate "PostgreSQL Plugin"
4. Check the box next to it and click "Install Selected Items"
5. Wait for the installation to complete
6. After installation, the plugin will appear in the DirectAdmin menu

### Method 2: Using the Command Line

To install the PostgreSQL plugin using the command line, SSH into your server as root and run:

```bash
cd /usr/local/directadmin/custombuild
./build set postgresql yes
./build update
./build postgresql
```

This sequence will:
1. Mark PostgreSQL for installation in CustomBuild options
2. Update CustomBuild's package index
3. Download and install the PostgreSQL plugin and all its dependencies

### Verifying the Installation

To verify that the installation completed successfully:

```bash
# Check if the plugin is registered in DirectAdmin
grep postgresql_plugin /usr/local/directadmin/conf/plugins.conf

# Check if PostgreSQL service is running
systemctl status postgresql

# Check if the plugin files are properly installed
ls -la /usr/local/directadmin/plugins/postgresql_plugin/
```

## Updating the Plugin

### Automatic Updates

The plugin is configured to check for updates automatically. When updates are available, they will be shown in the DirectAdmin admin interface.

### Manual Updates via CustomBuild

To update the PostgreSQL plugin to the latest version through CustomBuild:

```bash
cd /usr/local/directadmin/custombuild
./build update
./build postgresql
```

This process will:
1. Download the latest version of the plugin
2. Preserve existing databases and configurations
3. Update the plugin files and PostgreSQL if necessary
4. Restart PostgreSQL service
5. Update the plugin version in DirectAdmin's registry

### Update Notifications

The plugin will display notifications in the DirectAdmin interface when updates are available. Administrators can also set up email notifications for available updates.

## Configuration Options

CustomBuild provides several configuration options for the PostgreSQL plugin:

### Setting PostgreSQL Version

```bash
# To specify a PostgreSQL version (e.g., 14):
./build set postgresql_version 14
```

Supported versions: 10, 11, 12, 13, 14, 15

### Setting Data Directory

```bash
# To specify a custom data directory:
./build set postgresql_data /path/to/data
```

### Setting Port

```bash
# To specify a custom port:
./build set postgresql_port 5432
```

### Additional Options

View all available PostgreSQL options with:
```bash
./build show|grep postgresql
```

## Uninstalling the Plugin

### Complete Uninstallation

To completely uninstall the PostgreSQL plugin and remove all databases:

```bash
cd /usr/local/directadmin/custombuild
./build set postgresql no
./build postgresql uninstall
```

This will:
1. Stop the PostgreSQL service
2. Remove PostgreSQL packages
3. Remove the plugin files
4. Remove database data (warning: this deletes all PostgreSQL databases)
5. Remove the plugin from DirectAdmin's registry

### Removing Just the Plugin

To remove only the plugin while preserving PostgreSQL and databases:

```bash
cd /usr/local/directadmin/custombuild
./build set postgresql_plugin no
./build postgresql_plugin uninstall
```

## Troubleshooting

If you encounter issues with the CustomBuild integration, follow these steps:

### Common Issues and Solutions

#### PostgreSQL Option Not Showing in CustomBuild

**Solution**:
1. Ensure CustomBuild is up to date: 
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build update
   ```

2. Manually check/add the option:
   ```bash
   grep postgresql /usr/local/directadmin/custombuild/options.conf
   # If not found, add it:
   echo "postgresql=yes" >> /usr/local/directadmin/custombuild/options.conf
   ```

3. Rebuild the options cache:
   ```bash
   ./build cache
   ```

#### Installation Fails with Dependencies Error

**Solution**:
1. Update system packages:
   ```bash
   # For RHEL/CentOS
   yum update
   
   # For Debian/Ubuntu
   apt update && apt upgrade
   ```

2. Check CustomBuild logs:
   ```bash
   cat /usr/local/directadmin/custombuild/custom_build.log
   ```

3. Try with debug option:
   ```bash
   ./build postgresql debug
   ```

#### PostgreSQL Service Won't Start After Installation

**Solution**:
1. Check PostgreSQL logs:
   ```bash
   cat /var/log/postgresql/postgresql-*.log
   ```

2. Verify data directory exists and has correct permissions:
   ```bash
   ls -la /var/lib/pgsql/data  # RHEL/CentOS
   # or
   ls -la /var/lib/postgresql/*/main  # Debian/Ubuntu
   ```

3. Ensure proper ownership:
   ```bash
   chown -R postgres:postgres /var/lib/pgsql/data  # RHEL/CentOS
   # or
   chown -R postgres:postgres /var/lib/postgresql/*/main  # Debian/Ubuntu
   ```

### Diagnostic Commands

Use these commands to diagnose CustomBuild integration issues:

```bash
# Check CustomBuild version
cat /usr/local/directadmin/custombuild/version.txt

# List all enabled options
./build show

# Check available plugin updates
./build package_updates

# View PostgreSQL-specific logs
grep -i postgresql /usr/local/directadmin/custombuild/custom_build.log

# Check system resource usage
free -m
df -h
```

## Advanced CustomBuild Options

### Configuring PostgreSQL with Custom Settings

You can specify custom PostgreSQL configuration parameters:

```bash
./build set postgresql_max_connections 200
./build set postgresql_shared_buffers "2GB"
./build set postgresql_effective_cache_size "6GB"
./build set postgresql_work_mem "64MB"
```

After setting these options, rebuild PostgreSQL:

```bash
./build postgresql
```

### Building from Source

For advanced users, CustomBuild supports building PostgreSQL from source:

```bash
./build set postgresql_method source
./build postgresql
```

This method provides more flexibility but takes longer to install.

### Integration with Other Services

CustomBuild automatically integrates PostgreSQL with other DirectAdmin services:

1. **PHP Integration**: If PHP is installed via CustomBuild, it will automatically build with PostgreSQL support
2. **Backup Integration**: DirectAdmin backups will include PostgreSQL databases if the plugin is installed

To enable these integrations:

```bash
# For PHP
./build set php_pgsql yes
./build php n

# For backup integration
./build set backup_pgsql yes
./build rewrite_confs
```

## Additional Resources

- For detailed plugin documentation, see the [README.md](README.md) file
- For detailed usage guide, see the [USER_GUIDE.md](USER_GUIDE.md) file
- For troubleshooting information, see the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) file
- For manual installation instructions, see the [INSTALLATION_FROM_CODECORE.md](INSTALLATION_FROM_CODECORE.md) file
- For frequently asked questions, see the [FAQ.md](FAQ.md) file

If you need further assistance, please contact support at support@codecore.codes