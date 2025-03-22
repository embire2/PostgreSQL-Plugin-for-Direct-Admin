# PostgreSQL Plugin for DirectAdmin - Installation Guide

This guide provides detailed step-by-step instructions for downloading and installing the PostgreSQL Plugin for DirectAdmin from codecore.codes.

![PostgreSQL Plugin for DirectAdmin](https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/screenshot.png)

## Download Options

The PostgreSQL plugin for DirectAdmin is available through the following methods:

### Option 1: Direct Download from codecore.codes (Recommended)

Download the latest version directly from our website:

**URL**: [https://codecore.codes/software/postgresql_plugin-2.0.tar.gz](https://codecore.codes/software/postgresql_plugin-2.0.tar.gz)

### Option 2: GitHub Repository

Clone or download from our GitHub repository:

**URL**: [https://github.com/yourusername/directadmin-postgresql-plugin](https://github.com/yourusername/directadmin-postgresql-plugin)

## System Requirements

Before installing, ensure your server meets these requirements:

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

## Installation Methods

### Method 1: Installation from codecore.codes Package (Recommended)

#### Step 1: Download the Plugin Package

Connect to your server via SSH and download the plugin package:

```bash
cd /usr/src
wget https://codecore.codes/software/postgresql_plugin-2.0.tar.gz
```

#### Step 2: Extract the Package

Extract the downloaded package:

```bash
tar -xzf postgresql_plugin-2.0.tar.gz
cd postgresql_plugin-2.0
```

#### Step 3: Run the Installation Script

Execute the installation script with root privileges:

```bash
bash install.sh
```

This script will:
- Install PostgreSQL if not already installed
- Configure PostgreSQL for DirectAdmin integration
- Install the plugin files in DirectAdmin's plugin directory
- Register the plugin with DirectAdmin
- Create necessary hooks for user management
- Restart DirectAdmin to apply changes

### Method 2: One-Line Installation (Advanced)

For a quick, one-line installation that automatically downloads and installs the plugin:

```bash
curl -sSL https://codecore.codes/software/install-remote.sh | bash
```

Or if you prefer using wget:

```bash
wget -O - https://codecore.codes/software/install-remote.sh | bash
```

## Post-Installation Verification

After the installation is complete, verify that the plugin is working correctly:

1. Log in to your DirectAdmin control panel as an admin user
2. Navigate to the "Plugins" or "Custom Features" section
3. Click on "PostgreSQL Manager"
4. You should see the PostgreSQL plugin dashboard with:
   - PostgreSQL server status
   - Database statistics
   - User statistics

## Accessing the Plugin

The plugin can be accessed at:

- **Admin Interface**: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin`
- **User Interface**: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin` (when logged in as a user)

## Common Issues and Troubleshooting

If you encounter any issues during or after installation, check the following:

### Installation Fails

1. Check the installation logs:
   ```bash
   cat /usr/local/directadmin/logs/postgresql_install.log
   ```

2. Ensure you have enough disk space:
   ```bash
   df -h
   ```

3. Verify your operating system is supported by checking the OS detection in the logs

### PostgreSQL Service Not Starting

1. Check the PostgreSQL service status:
   ```bash
   systemctl status postgresql
   ```

2. View PostgreSQL logs:
   ```bash
   # For Debian/Ubuntu
   cat /var/log/postgresql/postgresql-*.log
   
   # For CentOS/RHEL
   cat /var/lib/pgsql/*/data/log/postgresql-*.log
   ```

### Plugin Not Appearing in DirectAdmin

1. Verify the plugin is registered:
   ```bash
   grep "postgresql_plugin" /usr/local/directadmin/conf/plugins.conf
   ```

2. Check file permissions:
   ```bash
   ls -la /usr/local/directadmin/plugins/postgresql_plugin/
   ```

3. Restart DirectAdmin:
   ```bash
   service directadmin restart
   ```

## Uninstallation

If you need to uninstall the plugin:

```bash
cd /usr/src/postgresql_plugin-2.0
bash uninstall.sh
```

The uninstallation script will provide options to:
- Remove only the plugin (keeping PostgreSQL and its data)
- Remove both the plugin and PostgreSQL (including all databases)

## Getting Support

If you continue to experience issues with the installation or usage of the plugin:

1. Check our [GitHub repository](https://github.com/yourusername/directadmin-postgresql-plugin) for known issues
2. Open a new issue on GitHub with detailed information about your problem
3. Contact us through our website: [codecore.codes](https://codecore.codes)

## Upgrading

To upgrade the plugin to a newer version:

1. Download the new version
2. Extract it to a temporary location
3. Run the installation script, which will update the existing installation

---

Thank you for using the PostgreSQL Plugin for DirectAdmin. We hope it enhances your server management experience!