#!/bin/bash
#
# Script to create a distribution package for the PostgreSQL DirectAdmin plugin v2.4
# This updated script includes better error handling and more informative output
#

# Define color codes for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define variables
PLUGIN_NAME="postgresql_plugin"
VERSION="2.4"
PACKAGE_NAME="${PLUGIN_NAME}-${VERSION}"
TEMP_DIR="/tmp/${PACKAGE_NAME}"
OUTPUT_DIR="./dist"
CURRENT_DIR=$(pwd)

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    # Clean up on error
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    exit 1
}

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR" || handle_error "Failed to create output directory"

# Print banner
echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}    PostgreSQL DirectAdmin Plugin Packaging Tool v2.4${NC}"
echo -e "${BLUE}==========================================================${NC}"
echo

# Create temporary directory
echo -e "${YELLOW}Step 1: Preparing temporary directory...${NC}"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR" || handle_error "Failed to create temporary directory"
echo -e "${GREEN}✓ Temporary directory created${NC}"

# Copy plugin files
echo -e "\n${YELLOW}Step 2: Copying plugin files...${NC}"
cp -rf ../postgres_plugin/* "$TEMP_DIR/" || handle_error "Failed to copy plugin files"
echo -e "${GREEN}✓ Plugin files copied successfully${NC}"

# Copy installation scripts
echo -e "\n${YELLOW}Step 3: Copying installation scripts...${NC}"
cp install.sh "$TEMP_DIR/" || handle_error "Failed to copy install.sh"
cp uninstall.sh "$TEMP_DIR/" || handle_error "Failed to copy uninstall.sh"
cp README.md "$TEMP_DIR/" || handle_error "Failed to copy README.md"
echo -e "${GREEN}✓ Installation scripts copied successfully${NC}"

# Copy CustomBuild files
echo -e "\n${YELLOW}Step 4: Copying CustomBuild files...${NC}"
mkdir -p "$TEMP_DIR/custombuild/custom" || handle_error "Failed to create CustomBuild directory"
cp custombuild/custom/postgresql.conf "$TEMP_DIR/custombuild/custom/" || handle_error "Failed to copy postgresql.conf"
cp custombuild/custom/postgresql_install.sh "$TEMP_DIR/custombuild/custom/" || handle_error "Failed to copy postgresql_install.sh"
cp custombuild/custom/postgresql_uninstall.sh "$TEMP_DIR/custombuild/custom/" || handle_error "Failed to copy postgresql_uninstall.sh"
cp custombuild/options.conf "$TEMP_DIR/custombuild/" || handle_error "Failed to copy options.conf"
echo -e "${GREEN}✓ CustomBuild files copied successfully${NC}"

# Set execution permissions
echo -e "\n${YELLOW}Step 5: Setting file permissions...${NC}"
chmod +x "$TEMP_DIR/install.sh" || handle_error "Failed to set permissions on install.sh"
chmod +x "$TEMP_DIR/uninstall.sh" || handle_error "Failed to set permissions on uninstall.sh"
chmod +x "$TEMP_DIR/exec/"*.sh || handle_error "Failed to set permissions on exec scripts"
chmod +x "$TEMP_DIR/hooks/"*.sh || handle_error "Failed to set permissions on hook scripts"
chmod +x "$TEMP_DIR/scripts/"*.sh || handle_error "Failed to set permissions on other scripts"
chmod +x "$TEMP_DIR/custombuild/custom/postgresql_install.sh" || handle_error "Failed to set permissions on CustomBuild install script"
chmod +x "$TEMP_DIR/custombuild/custom/postgresql_uninstall.sh" || handle_error "Failed to set permissions on CustomBuild uninstall script"
echo -e "${GREEN}✓ File permissions set successfully${NC}"

# Create tar.gz archive
echo -e "\n${YELLOW}Step 6: Creating package archive...${NC}"
cd /tmp || handle_error "Failed to change directory to /tmp"
tar -czf "${CURRENT_DIR}/${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME" || handle_error "Failed to create archive"
echo -e "${GREEN}✓ Package archive created successfully${NC}"

# Clean up
echo -e "\n${YELLOW}Step 7: Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR" || handle_error "Failed to clean up temporary directory"
echo -e "${GREEN}✓ Temporary files cleaned up${NC}"

echo -e "\n${GREEN}✓ Package created successfully: ${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz${NC}"
echo -e "\n${BLUE}Package details:${NC}"
echo -e "${BLUE}  • Plugin name: ${NC}PostgreSQL Manager"
echo -e "${BLUE}  • Version: ${NC}$VERSION"
echo -e "${BLUE}  • File path: ${NC}${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz"
echo -e "${BLUE}  • File size: ${NC}$(du -h "${CURRENT_DIR}/${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz" | cut -f1)"

echo -e "\n${BLUE}Installation command:${NC}"
echo -e "  cd /usr/src"
echo -e "  wget https://yourdomain.com/downloads/${PACKAGE_NAME}.tar.gz"
echo -e "  tar -xzf ${PACKAGE_NAME}.tar.gz"
echo -e "  cd ${PACKAGE_NAME}"
echo -e "  bash install.sh"

echo -e "\n${GREEN}Done!${NC}"