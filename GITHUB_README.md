# PostgreSQL Plugin for DirectAdmin

A DirectAdmin plugin that provides PostgreSQL database management through the DirectAdmin interface, allowing server administrators and users to easily create and manage PostgreSQL databases.

![PostgreSQL Plugin for DirectAdmin](https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/screenshot.png)

## Features

- **Admin Interface**
  - Install and manage PostgreSQL server
  - Create and manage PostgreSQL databases
  - Create and manage database users with granular permissions
  - Monitor database server status and resources
  - Configure PostgreSQL server settings
  - View database size statistics and usage metrics

- **User Interface**
  - Create and manage personal PostgreSQL databases
  - Manage database access privileges
  - View database connection information
  - Monitor database size and resource usage

## Download & Installation

### Option 1: Quick Installation (Recommended)

Download and install the plugin directly from our website:

```bash
cd /usr/src
wget https://codecore.codes/software/postgresql_plugin-2.2.tar.gz
tar -xzf postgresql_plugin-2.2.tar.gz
cd postgresql_plugin-2.2
bash install.sh
```

### Option 2: Direct GitHub Installation

Install directly from this GitHub repository:

```bash
cd /usr/src
wget https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/install-remote.sh
chmod +x install-remote.sh
./install-remote.sh
```

Or use this one-line command:

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/install-remote.sh | bash
```

## Requirements

- DirectAdmin 1.60.0 or later
- CentOS 7/8, AlmaLinux 8, Rocky Linux 8, Debian 10/11, or Ubuntu 20.04/22.04
- Root access to the server
- Minimum 2GB RAM (4GB recommended)
- At least 10GB of free disk space

## Detailed Installation Instructions

### Step 1: Download the Plugin

Choose one of the following methods:

#### Option A: Download from codecore.codes

```bash
cd /usr/src
wget https://codecore.codes/software/postgresql_plugin-2.2.tar.gz
tar -xzf postgresql_plugin-2.2.tar.gz
cd postgresql_plugin-2.2
```

#### Option B: Clone from GitHub

```bash
cd /usr/src
git clone https://github.com/yourusername/directadmin-postgresql-plugin.git
cd directadmin-postgresql-plugin
```

### Step 2: Run the Installation Script

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

### Step 3: Verify the Installation

1. Log in to the DirectAdmin control panel as an admin
2. Navigate to `Custom Features` or the `Plugins` section
3. Look for "PostgreSQL Manager" and click on it
4. The PostgreSQL plugin dashboard should load with server status information

## Admin Usage Guide

After installation, administrators can access the plugin at:
`https://your-server:2222/CMD_PLUGINS/postgresql_plugin`

From the admin interface, you can:

1. **Dashboard**: View PostgreSQL server status, database count, and user count
2. **Databases**: Create, manage, and delete databases
3. **Users**: Create, manage, and delete database users
4. **Settings**: Configure PostgreSQL server settings
5. **Server Status**: View detailed server metrics and logs

## User Usage Guide

Users can access the plugin at:
`https://your-server:2222/CMD_PLUGINS/postgresql_plugin`

From the user interface, they can:

1. **Dashboard**: View owned databases and usage statistics
2. **Databases**: Create, manage, and delete personal databases
3. **Connection Info**: View database connection credentials

## Troubleshooting

If you encounter any issues during installation:

1. **Check the installation logs**:
   ```bash
   cat /usr/local/directadmin/logs/postgresql_install.log
   ```

2. **Verify PostgreSQL is running**:
   ```bash
   systemctl status postgresql
   ```

3. **Check if the plugin is registered**:
   ```bash
   grep "postgresql_plugin" /usr/local/directadmin/conf/plugins.conf
   ```

4. **Verify the hook scripts are linked**:
   ```bash
   ls -la /usr/local/directadmin/scripts/custom/postgresql_*
   ```

5. **Check PostgreSQL logs**:
   ```bash
   # Debian/Ubuntu
   cat /var/log/postgresql/postgresql-*.log
   
   # CentOS/RHEL
   cat /var/lib/pgsql/*/data/log/postgresql-*.log
   ```

## Uninstallation

To uninstall the plugin:

```bash
cd /usr/src/postgresql_plugin-2.2  # or the directory where you installed from
bash uninstall.sh
```

The script will ask if you want to:
- Remove only the plugin (keeping PostgreSQL and its data)
- Remove both the plugin and PostgreSQL (including all databases)

## License

This plugin is released under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

For support, please:
- Open an issue in this GitHub repository
- Visit our website at [codecore.codes](https://codecore.codes)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

- Developed by [Your Name/Team]
- Special thanks to the PostgreSQL and DirectAdmin communities

---

## Changelog

### Version 2.2
- Added installation success message with login credentials
- Enhanced user experience with beautiful command-line output
- Improved database connection display after installation

### Version 2.1
- Fixed issue with log directory creation
- Improved error handling during installation
- Added directory existence checks for configurations

### Version 2.0
- Initial public release
- Admin and user interfaces
- Database and user management
- PostgreSQL integration with DirectAdmin

---

*This plugin is not officially affiliated with DirectAdmin or PostgreSQL.*