#!/bin/bash

#############################################
# AWS EFS Lab - Instance Testing Script
# Run this ON the EC2 instance to test EFS
#############################################

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AWS EFS Lab - Instance Test${NC}"
echo -e "${GREEN}========================================${NC}"

HOSTNAME=$(hostname)
echo -e "\n${YELLOW}Running on: $HOSTNAME${NC}"

# Test 1: Check if EFS is mounted
echo -e "\n${YELLOW}Test 1: Checking EFS mount...${NC}"
if mountpoint -q /mnt/efs; then
    echo -e "${GREEN}✓ EFS is mounted at /mnt/efs${NC}"
    df -h | grep efs
else
    echo -e "${RED}✗ EFS is NOT mounted${NC}"
    echo -e "${YELLOW}Attempting to mount...${NC}"
    sudo mount -a
    if mountpoint -q /mnt/efs; then
        echo -e "${GREEN}✓ EFS mounted successfully${NC}"
    else
        echo -e "${RED}✗ Failed to mount EFS${NC}"
        echo -e "${YELLOW}Check logs: sudo cat /var/log/user-data.log${NC}"
        exit 1
    fi
fi

# Test 2: Check write permissions
echo -e "\n${YELLOW}Test 2: Checking write permissions...${NC}"
TEST_FILE="/mnt/efs/test-write-$HOSTNAME.txt"
if echo "Write test from $HOSTNAME at $(date)" | sudo tee $TEST_FILE > /dev/null; then
    echo -e "${GREEN}✓ Can write to EFS${NC}"
else
    echo -e "${RED}✗ Cannot write to EFS${NC}"
    exit 1
fi

# Test 3: Check read permissions
echo -e "\n${YELLOW}Test 3: Checking read permissions...${NC}"
if cat $TEST_FILE > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Can read from EFS${NC}"
else
    echo -e "${RED}✗ Cannot read from EFS${NC}"
    exit 1
fi

# Test 4: List all files
echo -e "\n${YELLOW}Test 4: Listing all files in EFS...${NC}"
FILE_COUNT=$(ls /mnt/efs/ | wc -l)
echo -e "${GREEN}✓ Found $FILE_COUNT files/directories${NC}"
ls -lh /mnt/efs/

# Test 5: Check for files from other instance
echo -e "\n${YELLOW}Test 5: Checking for shared files...${NC}"
if ls /mnt/efs/mount-info-* > /dev/null 2>&1; then
    MOUNT_FILES=$(ls /mnt/efs/mount-info-* | wc -l)
    echo -e "${GREEN}✓ Found $MOUNT_FILES mount-info files${NC}"
    echo -e "${YELLOW}Mount info files:${NC}"
    ls -l /mnt/efs/mount-info-*
else
    echo -e "${YELLOW}⚠ No mount-info files found yet${NC}"
fi

# Test 6: Storage usage
echo -e "\n${YELLOW}Test 6: Checking storage usage...${NC}"
USAGE=$(du -sh /mnt/efs/ | awk '{print $1}')
echo -e "${GREEN}✓ EFS storage used: $USAGE${NC}"

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Test Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ EFS is mounted and working${NC}"
echo -e "${GREEN}✓ Read/Write permissions OK${NC}"
echo -e "${GREEN}✓ Total files: $FILE_COUNT${NC}"
echo -e "${GREEN}✓ Storage used: $USAGE${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Create test files: echo 'test' | sudo tee /mnt/efs/myfile.txt"
echo -e "2. Connect to other instance and verify files appear"
echo -e "3. Check TESTING-GUIDE.md for detailed test scenarios"

echo -e "\n${GREEN}========================================${NC}"
