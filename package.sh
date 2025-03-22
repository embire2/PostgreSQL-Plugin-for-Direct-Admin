#!/bin/bash
#
# Main packaging script for PostgreSQL DirectAdmin Plugin v2.4
#

# Define color codes for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}  PostgreSQL DirectAdmin Plugin v2.4 Packaging Tool${NC}"
echo -e "${BLUE}==========================================================${NC}"
echo

# Check if we are in the correct directory
if [ ! -d "postgres_plugin" ]; then
    echo -e "${RED}Error: Cannot find postgres_plugin directory.${NC}"
    echo -e "${RED}Make sure you are running this script from the project root directory.${NC}"
    exit 1
fi

# Check if package directory exists
if [ ! -d "package" ]; then
    echo -e "${RED}Error: Cannot find package directory.${NC}"
    echo -e "${RED}Make sure you are running this script from the project root directory.${NC}"
    exit 1
fi

# Create a dist directory for the output
mkdir -p ./dist

# Copy the updated install.sh to the package directory
echo -e "${YELLOW}Copying updated install.sh to package directory...${NC}"
cp install.sh package/install.sh
echo -e "${GREEN}✓ install.sh copied successfully${NC}"

# Run the package script
echo -e "\n${YELLOW}Running the package script...${NC}"
cd package
bash package.sh
RESULT=$?

# Check if packaging was successful
if [ $RESULT -ne 0 ]; then
    echo -e "${RED}Error: Packaging failed. See above for errors.${NC}"
    exit 1
fi

# Copy the package to the root directory for easy access
echo -e "\n${YELLOW}Copying package to project root...${NC}"
cp ./dist/postgresql_plugin-2.4.tar.gz ../dist/
echo -e "${GREEN}✓ Package copied to dist/postgresql_plugin-2.4.tar.gz${NC}"

echo -e "\n${GREEN}✓ Package is ready for upload!${NC}"
echo -e "\n${BLUE}Package details:${NC}"
echo -e "${BLUE}  • Path: ${NC}dist/postgresql_plugin-2.4.tar.gz"
echo -e "${BLUE}  • Size: ${NC}$(du -h ../dist/postgresql_plugin-2.4.tar.gz | cut -f1)"
echo -e "\n${GREEN}Done!${NC}"

cd ..
exit 0