
# PostgreSQL Plugin for DirectAdmin

This plugin integrates PostgreSQL database management into the DirectAdmin control panel, allowing administrators and users to manage PostgreSQL databases through the DirectAdmin interface.

## Features

- **Admin Panel**:
  - Install and manage PostgreSQL server
  - Create and manage databases
  - Create and manage database users
  - View PostgreSQL status and statistics
  - Configure PostgreSQL settings

- **User Panel**:
  - Create and manage PostgreSQL databases
  - View database credentials
  - Access database statistics
  
- **Integration**:
  - Full DirectAdmin CustomBuild integration
  - DirectAdmin Plugin Manager support
  - Automatic updates
  - User and database synchronization with DirectAdmin accounts

## Requirements

- DirectAdmin 1.60.0 or later
- CentOS 7/8, AlmaLinux 8, Rocky Linux 8, Debian 10/11, or Ubuntu 20.04/22.04
- Root access to the server

## Installation

### CustomBuild Installation (Recommended)

1. SSH into your server as root
2. Run CustomBuild commands to install the plugin:
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build set postgresql yes
   ./build update
   ./build postgresql
   ```

This will:
- Download the latest version of the plugin
- Install PostgreSQL if not already installed
- Configure PostgreSQL for DirectAdmin integration
- Install the plugin files in DirectAdmin's plugin directory
- Register the plugin with DirectAdmin
- Create necessary hooks for user creation and deletion

### DirectAdmin Plugin Manager Installation

1. Log in to DirectAdmin as admin
2. Navigate to the Plugin Manager
3. Click on "Install Plugin from URL"
4. Enter the plugin URL: `https://codecore.codes/software/postgresql_plugin-2.2.tar.gz`
5. Click "Install"

The Plugin Manager will handle the installation process automatically.

### Manual Installation with Script

1. Download the latest release package to your server:
   ```bash
   wget https://codecore.codes/software/postgresql_plugin-2.2.tar.gz
   ```

2. Extract the package:
   ```bash
   tar -xzf postgresql_plugin-2.2.tar.gz
   ```

3. Navigate to the extracted directory:
   ```bash
   cd postgresql_plugin-2.2
   ```

4. Run the installation script:
   ```bash
   bash install.sh
   ```

The script will:
- Install PostgreSQL if not already installed
- Configure PostgreSQL for DirectAdmin integration
- Install the plugin files in DirectAdmin's plugin directory
- Register the plugin with DirectAdmin
- Create necessary hooks for user creation and deletion

### Fully Manual Installation

1. Download and unzip the plugin package:
   ```bash
   wget https://github.com/embire2/PostgreSQL-Plugin-for-Direct-Admin/raw/main/DirectAdmin-PostgreSQLv2_0.zip
   unzip DirectAdmin-PostgreSQLv2_0.zip -d postgresql_plugin
   ```

2. Copy the plugin files to DirectAdmin's plugin directory:
   ```bash
   mkdir -p /usr/local/directadmin/plugins/postgresql_plugin
   cp -rf postgresql_plugin/* /usr/local/directadmin/plugins/postgresql_plugin/
   ```

3. Set proper permissions:
   ```bash
   chown -R diradmin:diradmin /usr/local/directadmin/plugins/postgresql_plugin
   chmod -R 755 /usr/local/directadmin/plugins/postgresql_plugin
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/exec/*.sh
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/hooks/*.sh
   chmod +x /usr/local/directadmin/plugins/postgresql_plugin/scripts/*.sh
   ```

4. Register hooks with DirectAdmin:
   ```bash
   ln -sf /usr/local/directadmin/plugins/postgresql_plugin/hooks/postgresql_create_user.sh /usr/local/directadmin/scripts/custom/postgresql_create_user.sh
   ln -sf /usr/local/directadmin/plugins/postgresql_plugin/hooks/postgresql_delete_user.sh /usr/local/directadmin/scripts/custom/postgresql_delete_user.sh
   ```

5. Install PostgreSQL if not already installed:
   ```bash
   bash /usr/local/directadmin/plugins/postgresql_plugin/scripts/install_postgresql.sh
   ```

6. Configure PostgreSQL for DirectAdmin integration:
   ```bash
   bash /usr/local/directadmin/plugins/postgresql_plugin/exec/postgres_control.sh configure
   ```

7. Register the plugin with DirectAdmin:
   ```bash
   echo "postgresql_plugin=2.0" >> /usr/local/directadmin/conf/plugins.conf
   ```

8. Restart DirectAdmin:
   ```bash
   service directadmin restart
   ```

## Accessing the Plugin

After installation, you can access the plugin at:

- **Admin Access**: https://your-server:2222/CMD_PLUGINS/postgresql_plugin  
- **User Access**: https://your-server:2222/CMD_PLUGINS/postgresql_plugin

## Uninstallation

### CustomBuild Uninstallation (Recommended)

1. SSH into your server as root
2. Run CustomBuild commands to uninstall the plugin:
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build set postgresql no
   ./build postgresql uninstall
   ```

This method ensures a clean removal with proper cleanup.

### DirectAdmin Plugin Manager Uninstallation

1. Log in to DirectAdmin as admin
2. Navigate to the Plugin Manager
3. Locate the PostgreSQL plugin in the list
4. Click "Uninstall" next to the plugin

### Script Uninstallation

1. Navigate to the plugin directory
   ```bash
   cd /usr/local/directadmin/plugins/postgresql_plugin
   ```
2. Run the uninstallation script:
   ```bash
   bash uninstall.sh
   ```

The script will prompt you to choose whether to uninstall PostgreSQL and remove all data, or just remove the plugin while preserving the PostgreSQL installation and data.

### Manual Uninstallation

1. Remove DirectAdmin hooks:
   ```bash
   rm -f /usr/local/directadmin/scripts/custom/postgresql_create_user.sh
   rm -f /usr/local/directadmin/scripts/custom/postgresql_delete_user.sh
   ```

2. Remove the plugin from DirectAdmin's plugin configuration:
   ```bash
   sed -i '/^postgresql_plugin=/d' /usr/local/directadmin/conf/plugins.conf
   ```

3. Remove the plugin directory:
   ```bash
   rm -rf /usr/local/directadmin/plugins/postgresql_plugin
   ```

4. Optionally, uninstall PostgreSQL:
   - For CentOS/RHEL:
     ```bash
     yum remove postgresql postgresql-server
     ```
   - For Debian/Ubuntu:
     ```bash
     apt-get remove postgresql postgresql-client
     ```

5. Restart DirectAdmin:
   ```bash
   service directadmin restart
   ```

## Troubleshooting

Check the installation logs at `/usr/local/directadmin/logs/postgresql_install.log` for details about any installation issues.

### Common Issues

- **Permission denied errors**: Ensure all script files are executable (`chmod +x`)
- **PostgreSQL connection errors**: Check PostgreSQL is running and properly configured
- **Hook not working**: Verify the hook symbolic links are correct
- **CustomBuild errors**: Check CustomBuild logs in `/usr/local/directadmin/custombuild/custom_build.log`

### CustomBuild Troubleshooting

If you encounter issues with CustomBuild installation:

1. Update CustomBuild database:
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build update
   ```

2. Verify the plugin is set correctly:
   ```bash
   ./build show|grep postgresql
   ```

3. Check CustomBuild cache:
   ```bash
   ./build cache
   ```

4. For more detailed information, run:
   ```bash
   ./build postgresql debug
   ```

For a more comprehensive guide to troubleshooting CustomBuild-related issues, see [CUSTOMBUILD_INTEGRATION.md](CUSTOMBUILD_INTEGRATION.md).

## Support

For support, please open an issue in the GitHub repository or contact your DirectAdmin support representative.

## License

This plugin is released under the MIT License. See the LICENSE file for details.
