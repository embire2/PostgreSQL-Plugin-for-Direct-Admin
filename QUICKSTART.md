# PostgreSQL Plugin for DirectAdmin - Quickstart Guide

This quickstart guide will help you download and install the PostgreSQL Plugin for DirectAdmin in just a few minutes.

## Quick Download & Install

### One-Step Download & Install

For a quick installation, run this one-line command on your DirectAdmin server:

```bash
curl -sSL https://codecore.codes/software/install-remote.sh | bash
```

This script will automatically download and install the plugin with default settings.

### Manual Download & Install (Alternative)

If you prefer to do it step-by-step:

1. **Download** the plugin package:
   ```bash
   cd /usr/src
   wget https://codecore.codes/software/postgresql_plugin-2.0.tar.gz
   ```

2. **Extract** the package:
   ```bash
   tar -xzf postgresql_plugin-2.0.tar.gz
   cd postgresql_plugin-2.0
   ```

3. **Install** the plugin:
   ```bash
   bash install.sh
   ```

## After Installation

1. **Access the plugin** in DirectAdmin:
   - Admin interface: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin`
   - User interface: `https://your-server:2222/CMD_PLUGINS/postgresql_plugin`

2. **Check installation status**:
   ```bash
   grep "postgresql_plugin" /usr/local/directadmin/conf/plugins.conf
   systemctl status postgresql
   ```

## Basic Usage

### For Administrators

- **Create a database**:
  1. Go to the Admin interface
  2. Click on "Databases"
  3. Click "Create Database"
  4. Enter database name and select options
  5. Click "Create"

- **Create a database user**:
  1. Go to the Admin interface
  2. Click on "Users"
  3. Click "Create User"
  4. Enter username and password
  5. Click "Create"

### For End Users

- **Create a database**:
  1. Go to the User interface
  2. Click on "Databases"
  3. Click "Create Database"
  4. Enter database name
  5. Click "Create"

## Common Issues

- **Plugin not appearing**: Restart DirectAdmin with `service directadmin restart`
- **Connection errors**: Ensure PostgreSQL is running with `systemctl status postgresql`

## Getting Help

- Detailed documentation: [INSTALLATION_FROM_CODECORE.md](INSTALLATION_FROM_CODECORE.md)
- GitHub repository: [https://github.com/yourusername/directadmin-postgresql-plugin](https://github.com/yourusername/directadmin-postgresql-plugin)
- Support website: [https://codecore.codes](https://codecore.codes)