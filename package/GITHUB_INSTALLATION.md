# Installing PostgreSQL DirectAdmin Plugin from GitHub

This guide provides instructions for installing the PostgreSQL DirectAdmin plugin directly from GitHub.

## Method 1: Manual Installation from GitHub

### Step 1: Clone the Repository

Connect to your DirectAdmin server via SSH and clone the repository:

```bash
cd /usr/src
git clone https://github.com/yourusername/directadmin-postgresql-plugin.git
cd directadmin-postgresql-plugin
```

### Step 2: Install the Plugin

Run the installation script:

```bash
bash install.sh
```

This script will:
- Install PostgreSQL if not already installed
- Configure PostgreSQL for DirectAdmin integration
- Install the plugin files in DirectAdmin's plugin directory
- Register the plugin with DirectAdmin
- Create necessary hooks for user creation and deletion

## Method 2: Installation using wget (Without Git)

If your server doesn't have Git installed, you can download a ZIP archive of the repository:

### Step 1: Download the Latest Release

```bash
cd /usr/src
wget https://github.com/yourusername/directadmin-postgresql-plugin/archive/refs/heads/main.zip
unzip main.zip
cd directadmin-postgresql-plugin-main
```

### Step 2: Install the Plugin

Run the installation script:

```bash
bash install.sh
```

## Method 3: One-Line Installation Script

For quick installation, you can use this one-liner that downloads and installs the plugin in a single command:

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/install-remote.sh | bash
```

## Verifying the Installation

After installation, verify that the plugin is working correctly:

1. Log in to your DirectAdmin control panel as an admin
2. Navigate to the "Plugins" section
3. Click on "PostgreSQL Manager"
4. The PostgreSQL plugin dashboard should display with server status and statistics

## Accessing the Plugin

- **Admin Interface**: https://your-server:2222/CMD_PLUGINS/postgresql_plugin
- **User Interface**: https://your-server:2222/CMD_PLUGINS/postgresql_plugin (when logged in as a user)

## Troubleshooting

If you encounter any issues during installation:

1. Check the installation logs: `/usr/local/directadmin/logs/postgresql_install.log`
2. Verify PostgreSQL is running: `systemctl status postgresql`
3. Check GitHub Issues for similar problems: https://github.com/yourusername/directadmin-postgresql-plugin/issues
4. Create a new issue if needed, providing detailed information about the error

## Updating the Plugin

To update the plugin to the latest version from GitHub:

```bash
cd /usr/src/directadmin-postgresql-plugin
git pull
bash update.sh
```

Or if you downloaded the ZIP archive:

```bash
cd /usr/src
rm -rf directadmin-postgresql-plugin-main
wget https://github.com/yourusername/directadmin-postgresql-plugin/archive/refs/heads/main.zip
unzip main.zip
cd directadmin-postgresql-plugin-main
bash install.sh
```

## Contributing

If you'd like to contribute to the development of this plugin, please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

We welcome bug fixes, feature additions, and documentation improvements!