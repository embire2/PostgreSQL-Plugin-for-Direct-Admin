# PostgreSQL Plugin for DirectAdmin - Installation Guide

This guide provides detailed step-by-step instructions for installing and configuring the PostgreSQL Plugin for DirectAdmin.

## Prerequisites

Before installing the plugin, ensure your server meets the following requirements:

1. DirectAdmin 1.60.0 or later
2. One of the following operating systems:
   - CentOS 7 or 8
   - AlmaLinux 8
   - Rocky Linux 8
   - Debian 10 or 11
   - Ubuntu 20.04 or 22.04
3. Root access to the server
4. Minimum 2GB RAM (4GB recommended)
5. At least 10GB of free disk space
6. A fully qualified domain name (FQDN) for the server

## Installation Steps

### Step 1: Download the Plugin Package

Download the plugin package to your server:

```bash
cd /usr/src
wget https://yoursite.com/downloads/postgresql_plugin-2.0.tar.gz
```

### Step 2: Extract the Package

Extract the downloaded package:

```bash
tar -xzf postgresql_plugin-2.0.tar.gz
cd postgresql_plugin-2.0
```

### Step 3: Run the Installation Script

Execute the installation script with root privileges:

```bash
bash install.sh
```

This script will:
- Install PostgreSQL if not already installed
- Configure PostgreSQL for DirectAdmin integration
- Install the plugin files in DirectAdmin's plugin directory
- Register the plugin with DirectAdmin
- Create necessary hooks for user creation and deletion
- Restart DirectAdmin to apply changes

### Step 4: Verify the Installation

After the installation is complete, verify that the plugin is working correctly:

1. Log in to your DirectAdmin control panel as an admin user
2. Navigate to the "Plugins" section
3. Click on "PostgreSQL Manager"
4. The PostgreSQL plugin dashboard should be displayed with:
   - PostgreSQL status
   - Database statistics
   - User statistics
   - System information

### Step 5: Configure PostgreSQL (Optional)

If you need to customize the PostgreSQL configuration:

1. Log in to the server via SSH
2. Edit the PostgreSQL configuration file:
   ```bash
   nano /etc/postgresql/*/main/postgresql.conf  # Debian/Ubuntu
   # or
   nano /var/lib/pgsql/*/data/postgresql.conf   # CentOS/RHEL
   ```
3. Adjust the parameters according to your needs
4. Save the file and restart PostgreSQL:
   ```bash
   systemctl restart postgresql
   ```

## User Instructions

### For Administrators

Administrators can access the plugin at: https://your-server:2222/CMD_PLUGINS/postgresql_plugin

From the admin interface, you can:
- Monitor PostgreSQL server status
- Create and manage databases
- Create and manage database users
- Configure PostgreSQL settings
- View system statistics

### For Users

Users can access the plugin at: https://your-server:2222/CMD_PLUGINS/postgresql_plugin

From the user interface, they can:
- Create and manage their PostgreSQL databases
- View connection credentials
- Monitor database size and usage

## Troubleshooting

If you encounter any issues during or after installation, check the following:

1. **Installation Logs**: Review logs at `/usr/local/directadmin/logs/postgresql_install.log`

2. **PostgreSQL Service Status**: Check if PostgreSQL is running:
   ```bash
   systemctl status postgresql
   ```

3. **DirectAdmin Plugin Configuration**: Verify the plugin is registered:
   ```bash
   grep "postgresql_plugin" /usr/local/directadmin/conf/plugins.conf
   ```

4. **Hook Scripts**: Ensure hook scripts are correctly linked:
   ```bash
   ls -la /usr/local/directadmin/scripts/custom/postgresql_*
   ```

5. **Permission Issues**: Check file permissions:
   ```bash
   ls -la /usr/local/directadmin/plugins/postgresql_plugin/
   ```

6. **PostgreSQL Logs**: Review PostgreSQL logs:
   ```bash
   # Debian/Ubuntu
   cat /var/log/postgresql/postgresql-*.log
   
   # CentOS/RHEL
   cat /var/lib/pgsql/*/data/log/postgresql-*.log
   ```

## Uninstallation

If you need to uninstall the plugin:

```bash
cd /usr/src/postgresql_plugin-2.0
bash uninstall.sh
```

The script will ask if you want to:
- Remove only the plugin (keeping PostgreSQL and its data)
- Remove both the plugin and PostgreSQL (including all databases)

## Support

For additional support:
- Check the README file for documentation
- Contact your DirectAdmin support representative
- Visit our support forum at [your support forum URL]

## License

This plugin is released under the MIT License.