# CustomBuild Integration for PostgreSQL Plugin

This document explains how to install and manage the PostgreSQL plugin using DirectAdmin's CustomBuild system.

## Overview

The PostgreSQL plugin is fully integrated with DirectAdmin's CustomBuild system, allowing you to easily install, update, and manage PostgreSQL directly from the CustomBuild interface.

## Installation via CustomBuild

### Method 1: Using the CustomBuild Web Interface

1. Log in to DirectAdmin as the admin user
2. Navigate to the CustomBuild page
3. Locate "PostgreSQL Plugin" in the available options
4. Check the box next to it and click "Install Selected Items"
5. Wait for the installation to complete

### Method 2: Using the Command Line

To install the PostgreSQL plugin using the command line, SSH into your server as root and run:

```bash
cd /usr/local/directadmin/custombuild
./build set postgresql yes
./build update
./build postgresql
```

## Updating the Plugin

To update the PostgreSQL plugin to the latest version through CustomBuild:

```bash
cd /usr/local/directadmin/custombuild
./build update
./build postgresql
```

## Uninstalling the Plugin

To uninstall the PostgreSQL plugin through CustomBuild:

```bash
cd /usr/local/directadmin/custombuild
./build set postgresql no
./build postgresql uninstall
```

## Troubleshooting

If you encounter any issues with the CustomBuild integration, check the following:

1. Ensure CustomBuild is up to date: 
   ```bash
   cd /usr/local/directadmin/custombuild
   ./build update
   ```

2. Check the installation logs:
   ```bash
   cat /usr/local/directadmin/logs/postgresql_install.log
   ```

3. Verify DirectAdmin's configuration:
   ```bash
   grep -i postgresql /usr/local/directadmin/conf/plugins.conf
   ```

## Additional Resources

- For detailed plugin documentation, see the [README.md](README.md) file
- For manual installation instructions, see the [INSTALLATION_FROM_CODECORE.md](INSTALLATION_FROM_CODECORE.md) file

If you need further assistance, please contact support at support@codecore.codes