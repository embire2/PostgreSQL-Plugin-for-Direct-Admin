# PostgreSQL Plugin for DirectAdmin v2.4

## What's New in Version 2.4

This updated version includes several critical fixes and improvements:

- **Fixed Menu Display Issue:** The plugin now correctly appears in the DirectAdmin menu
- **Improved Installation Process:** Enhanced error handling during plugin installation
- **Better Plugin Registration:** Fixed issues with DirectAdmin plugin registration
- **Updated User Interface:** Enhanced dashboard and admin interface
- **Streamlined Configuration:** Automatic configuration verification

## Installation Instructions

### Method 1: Standard Installation

1. Download the package to your DirectAdmin server:
   ```bash
   cd /usr/src
   wget https://yourdomain.com/downloads/postgresql_plugin-2.4.tar.gz
   ```

2. Extract the package:
   ```bash
   tar -xzf postgresql_plugin-2.4.tar.gz
   cd postgresql_plugin-2.4
   ```

3. Run the installation script:
   ```bash
   bash install.sh
   ```

4. Access the plugin through DirectAdmin:
   - Admin interface: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin`
   - User interface: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin`

### Method 2: CustomBuild Installation

If you're using DirectAdmin with CustomBuild, you can install the plugin through CustomBuild:

1. Extract the package:
   ```bash
   cd /usr/src
   tar -xzf postgresql_plugin-2.4.tar.gz
   cd postgresql_plugin-2.4
   ```

2. Copy CustomBuild files:
   ```bash
   cp -rf custombuild/custom/* /usr/local/directadmin/custombuild/custom/
   echo "postgresql=yes" >> /usr/local/directadmin/custombuild/options.conf
   ```

3. Run CustomBuild commands:
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build update
   ./build postgresql
   ```

## Troubleshooting

### Plugin Not Appearing in DirectAdmin Menu

If the plugin does not appear in the DirectAdmin menu, verify:

1. Check if the plugin is registered:
   ```bash
   grep postgresql_plugin /usr/local/directadmin/conf/plugins.conf
   ```

2. Verify the plugin files exist:
   ```bash
   ls -la /usr/local/directadmin/plugins/postgresql_plugin/
   ```

3. Check DirectAdmin error logs:
   ```bash
   tail -f /var/log/directadmin/error.log
   ```

4. Reinstall the plugin with verbose output:
   ```bash
   bash install.sh
   ```

### PostgreSQL Service Issues

If PostgreSQL is not working properly:

1. Check PostgreSQL service status:
   ```bash
   systemctl status postgresql
   ```

2. Review PostgreSQL logs:
   ```bash
   tail -f /var/log/postgresql/postgresql-*.log
   ```

3. Verify PostgreSQL configuration:
   ```bash
   ls -la /etc/postgresql/*/main/
   ```

## Support

If you encounter issues with this plugin, please contact support at support@yourdomain.com or visit our knowledge base at https://yourdomain.com/kb/postgresql-plugin/.