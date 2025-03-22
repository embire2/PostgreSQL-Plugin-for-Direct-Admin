#!/bin/bash
#
# Script to create a distribution package for the PostgreSQL DirectAdmin plugin
#

# Define variables
PLUGIN_NAME="postgresql_plugin"
VERSION="2.1"
PACKAGE_NAME="${PLUGIN_NAME}-${VERSION}"
TEMP_DIR="/tmp/${PACKAGE_NAME}"
OUTPUT_DIR="."

# Create temporary directory
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy plugin files
echo "Copying plugin files..."
cp -rf ../postgres_plugin/* "$TEMP_DIR/"

# Copy installation scripts
echo "Copying installation scripts..."
cp install.sh "$TEMP_DIR/"
cp uninstall.sh "$TEMP_DIR/"
cp README.md "$TEMP_DIR/"

# Set execution permissions
chmod +x "$TEMP_DIR/install.sh"
chmod +x "$TEMP_DIR/uninstall.sh"
chmod +x "$TEMP_DIR/exec/"*.sh
chmod +x "$TEMP_DIR/hooks/"*.sh
chmod +x "$TEMP_DIR/scripts/"*.sh

# Create tar.gz archive
echo "Creating package archive..."
cd /tmp
tar -czvf "${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

# Clean up
rm -rf "$TEMP_DIR"

echo "Package created: ${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz"
echo "Done!"