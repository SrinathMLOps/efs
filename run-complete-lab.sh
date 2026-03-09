#!/bin/bash

#############################################
# AWS EFS Lab - Master Script
# Complete workflow: Check region → Cleanup → Setup → Verify → Test
#############################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           AWS EFS Lab - Complete Workflow                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

# Make all scripts executable
chmod +x *.sh 2>/dev/null

# Step 1: Check Region
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 1: Checking Current AWS Region${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
./check-current-region.sh

read -p "Press Enter to continue..."

# Step 2: Verify and Cleanup
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 2: Verify and Cleanup Existing Resources${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
./verify-and-cleanup-all.sh

read -p "Press Enter to continue with setup..."

# Step 3: Run Setup
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 3: Running EFS Lab Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
./aws-efs-lab-setup-v2.sh

# Step 4: Verify Setup
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 4: Verifying Setup Completion${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
./verify-setup.sh

# Step 5: Display Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 5: Lab Summary and Next Steps${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

if [ -f "lab-summary.txt" ]; then
    cat lab-summary.txt
fi

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    LAB SETUP COMPLETE!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}📖 Next Steps:${NC}"
echo -e "${GREEN}1. Connect to instances using EC2 Instance Connect (browser)${NC}"
echo -e "${GREEN}2. Or use: ./connect-instances.sh${NC}"
echo -e "${GREEN}3. Follow TESTING-GUIDE.md for verification steps${NC}"
echo -e "${GREEN}4. When done: ./cleanup-efs-lab.sh${NC}"

echo -e "\n${YELLOW}📚 Documentation:${NC}"
echo -e "  • HOW-TO-RUN.md - Running instructions"
echo -e "  • TESTING-GUIDE.md - Testing procedures"
echo -e "  • QUICK-REFERENCE.md - Command cheat sheet"
echo -e "  • ARCHITECTURE-EXPLAINED.md - Architecture details"
echo -e "  • MANUAL-CONSOLE-SETUP.md - Manual setup guide"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
