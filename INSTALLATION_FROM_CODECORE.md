# PostgreSQL Plugin for DirectAdmin - Installation Guide

This guide provides detailed step-by-step instructions for downloading and installing the PostgreSQL Plugin for DirectAdmin v2.4 from cloudcore.codes, with specific instructions for Ubuntu servers.

![PostgreSQL Plugin for DirectAdmin](https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/screenshot.png)

## Download Options

The PostgreSQL plugin for DirectAdmin is available through the following methods:

### Option 1: Direct Download from cloudcore.codes (Recommended)

Download the latest version directly from our website:

**URL**: [https://cloudcore.codes/software/postgresql_plugin-2.4.tar.gz](https://cloudcore.codes/software/postgresql_plugin-2.4.tar.gz)

### Option 2: GitHub Repository

Clone or download from our GitHub repository:

**URL**: [https://github.com/yourusername/directadmin-postgresql-plugin](https://github.com/yourusername/directadmin-postgresql-plugin)

## System Requirements

Before installing, ensure your server meets these requirements:

1. DirectAdmin 1.60.0 or later
2. One of the following operating systems:
   - CentOS 7 or 8
   - AlmaLinux 8 or 9
   - Rocky Linux 8 or 9
   - Debian 10, 11 or 12
   - Ubuntu 20.04, 22.04 or 24.04
3. Root access to the server
4. Minimum 2GB RAM (4GB recommended)
5. At least 10GB of free disk space
6. A fully qualified domain name (FQDN) for the server

## Installation Methods

### Method 1: Installation from cloudcore.codes Package (Recommended)

#### Step 1: Download the Plugin Package

Connect to your server via SSH and download the plugin package:

```bash
cd /usr/src
wget https://cloudcore.codes/software/postgresql_plugin-2.4.tar.gz
```

#### Step 2: Extract the Package

Extract the downloaded package:

```bash
tar -xzf postgresql_plugin-2.4.tar.gz
cd postgresql_plugin-2.4
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
- Install CustomBuild integration files
- Set correct file permissions for plugin components
- Restart DirectAdmin to apply changes

#### Ubuntu-Specific Installation Steps

For Ubuntu servers (20.04, 22.04, or 24.04), follow these additional steps for optimal performance:

1. Before installation, ensure you have the necessary dependencies:

```bash
apt update
apt install -y wget curl gnupg2 lsb-release apt-transport-https ca-certificates
```

2. If you don't have PostgreSQL installed yet, add the PostgreSQL repository to get the latest version:

```bash
# Create the repository configuration file
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Update package lists
apt update
```

3. Then proceed with the regular installation:

```bash
cd /usr/src
wget https://cloudcore.codes/software/postgresql_plugin-2.4.tar.gz
tar -xzf postgresql_plugin-2.4.tar.gz
cd postgresql_plugin-2.4
bash install.sh
```

### Method 2: CustomBuild Installation

If you're using DirectAdmin with CustomBuild, you can install the plugin directly through CustomBuild:

```bash
# First copy the CustomBuild files
cd /usr/src
wget https://cloudcore.codes/software/postgresql_plugin-2.4.tar.gz
tar -xzf postgresql_plugin-2.4.tar.gz
cd postgresql_plugin-2.4
cp -rf custombuild/custom/* /usr/local/directadmin/custombuild/custom/

# Then run the CustomBuild commands
cd /usr/local/directadmin/custombuild
./build set postgresql yes
./build update
./build postgresql
```

This method leverages the CustomBuild integration for seamless installation.

### Method 3: One-Line Installation (Advanced)

For a quick, one-line installation that automatically downloads and installs the plugin:

```bash
curl -sSL https://cloudcore.codes/software/install-remote.sh | bash
```

Or if you prefer using wget:

```bash
wget -O - https://cloudcore.codes/software/install-remote.sh | bash
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

3. Ensure plugin.conf exists and has correct permissions:
   ```bash
   ls -la /usr/local/directadmin/plugins/postgresql_plugin/plugin.conf
   chmod 644 /usr/local/directadmin/plugins/postgresql_plugin/plugin.conf
   ```

4. Restart DirectAdmin:
   ```bash
   service directadmin restart
   ```

### Ubuntu-Specific Troubleshooting

For Ubuntu servers, consider these additional troubleshooting steps:

1. If PostgreSQL service doesn't start, check AppArmor status:
   ```bash
   aa-status
   systemctl status apparmor
   ```

2. Verify PostgreSQL is properly installed from the repository:
   ```bash
   apt policy postgresql postgresql-contrib
   ```

3. Check PostgreSQL user and group existence:
   ```bash
   getent passwd postgres
   getent group postgres
   ```

4. For permission issues on Ubuntu:
   ```bash
   # Fix ownership of PostgreSQL files
   chown -R postgres:postgres /var/lib/postgresql/
   
   # Fix permission on configuration files
   chmod 644 /etc/postgresql/*/main/pg_hba.conf
   chmod 644 /etc/postgresql/*/main/postgresql.conf
   ```

## Uninstallation

If you need to uninstall the plugin:

```bash
cd /usr/src/postgresql_plugin-2.4
bash uninstall.sh
```

The uninstallation script will provide options to:
- Remove only the plugin (keeping PostgreSQL and its data)
- Remove both the plugin and PostgreSQL (including all databases)

### Ubuntu-Specific Uninstallation Notes

On Ubuntu systems, if you choose to completely remove PostgreSQL during uninstallation, you may want to also clean up the PostgreSQL repository:

```bash
# Remove the repository configuration
rm -f /etc/apt/sources.list.d/pgdg.list

# Update package lists
apt update
```

## Getting Support

If you continue to experience issues with the installation or usage of the plugin:

1. Check our [GitHub repository](https://github.com/yourusername/directadmin-postgresql-plugin) for known issues
2. Open a new issue on GitHub with detailed information about your problem
3. Contact us through our website: [cloudcore.codes](https://cloudcore.codes)

## Upgrading

To upgrade the plugin to a newer version:

1. Download the new version
2. Extract it to a temporary location
3. Run the installation script, which will update the existing installation

### What's New in Version 2.4

- **Fixed Menu Display Issue**: The plugin now correctly appears in the DirectAdmin menu after installation
- **Improved File Permissions**: Corrected permissions for all plugin files and directories
- **Enhanced Plugin Configuration**: Fixed issues with DirectAdmin plugin registration
- **Better Ubuntu Support**: Optimized installation process for Ubuntu servers
- **Improved Installation Verification**: Added checks to ensure all components are properly installed

### What's New in Version 2.3

- **CustomBuild Integration**: Full support for DirectAdmin's CustomBuild system, making installation easier through the CustomBuild interface
- **Extended OS Support**: Added compatibility with AlmaLinux 9, Rocky Linux 9, Debian 12, and Ubuntu 24.04
- **Improved Installation**: Enhanced detection of existing PostgreSQL installations
- **Automatic CustomBuild Configuration**: The plugin now automatically configures CustomBuild with PostgreSQL options

---

Thank you for using the PostgreSQL Plugin for DirectAdmin. We hope it enhances your server management experience!