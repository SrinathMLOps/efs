#!/bin/bash

#############################################
# ⚠️ DANGER: AWS Account-Wide Cleanup
# This script is intentionally named with DANGER prefix
#############################################

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                    ⚠️  DANGER ZONE  ⚠️                         ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${RED}This script will DELETE resources in ALL AWS regions!${NC}"
echo -e "\n${YELLOW}RECOMMENDED: Run scan first to see what will be deleted${NC}"
echo -e "${YELLOW}Command: ./scan-all-regions.sh${NC}"

echo -e "\n${RED}Do you want to continue with deletion?${NC}"
read -p "Type 'YES-DELETE-EVERYTHING' to proceed: " CONFIRM

if [ "$CONFIRM" != "YES-DELETE-EVERYTHING" ]; then
    echo -e "${GREEN}Cancelled. No resources were deleted.${NC}"
    echo -e "\n${YELLOW}To scan resources without deleting:${NC}"
    echo -e "  ./scan-all-regions.sh"
    exit 0
fi

# Run the actual cleanup
chmod +x cleanup-all-regions.sh
./cleanup-all-regions.sh
