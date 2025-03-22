# PostgreSQL Plugin for DirectAdmin

This plugin integrates PostgreSQL database server with DirectAdmin, providing a web interface for users to manage their PostgreSQL databases.

## Features

- Automatic PostgreSQL server installation and configuration
- Database management through DirectAdmin interface (create, delete, backup)
- User management (create, delete, update passwords)
- Connection information for database clients
- Automatic integration with DirectAdmin users
- Database backup and restore functionality

## Requirements

- DirectAdmin 1.60 or later
- Linux OS supported by PostgreSQL (CentOS, RHEL, Ubuntu, Debian)
- Minimum 1GB RAM (2GB recommended)
- 10GB free disk space

## Installation

1. Log in to your DirectAdmin server as root
2. Change to the DirectAdmin plugins directory:
   ```
   cd /usr/local/directadmin/plugins
   