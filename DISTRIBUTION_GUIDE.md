# PostgreSQL Plugin for DirectAdmin - Distribution Guide

This guide explains how to distribute and install the PostgreSQL Plugin for DirectAdmin from both a packaged distribution or directly from GitHub.

## Distributing the Plugin

There are two main methods for distributing the plugin:

1. **Traditional Package Distribution** - Create a .tar.gz package for easy installation
2. **GitHub Repository Distribution** - Allow users to install directly from your GitHub repository

## Method 1: Creating a Distribution Package

### Step 1: Prepare the Package

1. Navigate to the package directory:
   ```bash
   cd package
   ```

2. Run the packaging script to create a distribution tarball:
   ```bash
   bash package.sh
   ```

3. This will create a file named `postgresql_plugin-2.0.tar.gz` in the current directory, containing:
   - All plugin files
   - Installation scripts
   - Documentation

### Step 2: Distribute the Package

Upload the package to your distribution channel:

- Your website download section
- DirectAdmin's third-party plugin repository
- File hosting service

### Step 3: Installation Instructions for Package Users

Direct your users to download and install the package with:

```bash
cd /usr/src
wget https://your-site.com/downloads/postgresql_plugin-2.0.tar.gz
tar -xzf postgresql_plugin-2.0.tar.gz
cd postgresql_plugin-2.0
bash install.sh
```

## Method 2: GitHub Repository Distribution

### Step 1: Create a GitHub Repository

1. Create a new GitHub repository (e.g., `directadmin-postgresql-plugin`)
2. Initialize it with:
   - README.md
   - LICENSE file (e.g., MIT)
   - .gitignore file

### Step 2: Upload Plugin Files

Organize your repository with the following structure:

```
directadmin-postgresql-plugin/
├── postgres_plugin/          # Main plugin files
│   ├── admin/                # Admin interface
│   ├── user/                 # User interface  
│   ├── exec/                 # Executive scripts
│   ├── hooks/                # DirectAdmin hooks
│   └── scripts/              # Utility scripts
├── install.sh                # Main installation script
├── uninstall.sh              # Uninstallation script
├── install-remote.sh         # One-line remote installation script
├── README.md                 # Plugin documentation
├── INSTALLATION_GUIDE.md     # Detailed installation instructions
└── LICENSE                   # License file
```

### Step 3: Set Up Direct Installation

Create a one-line installation script that allows users to install the plugin with a single command:

```bash
# Content for install-remote.sh
curl -sSL https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/install-remote.sh | bash
```

### Step 4: Update Documentation

Ensure your README.md includes clear installation instructions for both methods:

1. Traditional package installation
2. Direct GitHub installation
3. One-line installation command

## Installation Instructions for End Users

### From Package Distribution

```bash
cd /usr/src
wget https://your-site.com/downloads/postgresql_plugin-2.0.tar.gz
tar -xzf postgresql_plugin-2.0.tar.gz
cd postgresql_plugin-2.0
bash install.sh
```

### From GitHub Repository

#### Method 1: Clone the Repository

```bash
cd /usr/src
git clone https://github.com/yourusername/directadmin-postgresql-plugin.git
cd directadmin-postgresql-plugin
bash install.sh
```

#### Method 2: Download ZIP Archive

```bash
cd /usr/src
wget https://github.com/yourusername/directadmin-postgresql-plugin/archive/refs/heads/main.zip
unzip main.zip
cd directadmin-postgresql-plugin-main
bash install.sh
```

#### Method 3: One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/directadmin-postgresql-plugin/main/install-remote.sh | bash
```

## Verifying the Installation

After installation, verify that the plugin is working correctly:

1. Log in to DirectAdmin control panel as an admin
2. Navigate to the "Plugins" section
3. Click on "PostgreSQL Manager"
4. Verify the plugin dashboard loads properly

## Supporting Users

Support channels for plugin users:

1. GitHub Issues - For bug reports and feature requests
2. Documentation - Keep installation guides and FAQs updated
3. Email Support - Provide an email address for direct support
4. Community Forum - Create a dedicated thread on DirectAdmin forums

## Updating the Plugin

Provide instructions for updating the plugin:

1. From package:
   ```bash
   cd /usr/src
   wget https://your-site.com/downloads/postgresql_plugin-2.1.tar.gz
   tar -xzf postgresql_plugin-2.1.tar.gz
   cd postgresql_plugin-2.1
   bash install.sh
   ```

2. From GitHub:
   ```bash
   cd /usr/src/directadmin-postgresql-plugin
   git pull
   bash install.sh
   ```