#!/bin/bash

#############################################
# AWS EFS Lab - Verification Script
# Run this to check if everything is set up correctly
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AWS EFS Lab - Setup Verification${NC}"
echo -e "${GREEN}========================================${NC}"

# Read resource IDs from lab-summary.txt if it exists
if [ -f "lab-summary.txt" ]; then
    VPC_ID=$(grep "VPC ID:" lab-summary.txt | awk '{print $4}')
    INSTANCE1_ID=$(grep "Instance 1 ID:" lab-summary.txt | awk '{print $4}')
    INSTANCE2_ID=$(grep "Instance 2 ID:" lab-summary.txt | awk '{print $4}')
    EFS_ID=$(grep "EFS ID:" lab-summary.txt | awk '{print $3}')
    REGION="us-east-1"
else
    echo -e "${RED}Error: lab-summary.txt not found. Run aws-efs-lab-setup.sh first.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Checking Instance 1 Status...${NC}"
INSTANCE1_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE1_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

INSTANCE1_STATUS=$(aws ec2 describe-instance-status \
    --instance-ids $INSTANCE1_ID \
    --region $REGION \
    --query 'InstanceStatuses[0].InstanceStatus.Status' \
    --output text 2>/dev/null || echo "initializing")

echo -e "Instance 1 State: ${GREEN}$INSTANCE1_STATE${NC}"
echo -e "Instance 1 Status Checks: ${GREEN}$INSTANCE1_STATUS${NC}"

echo -e "\n${YELLOW}Checking Instance 2 Status...${NC}"
INSTANCE2_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE2_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

INSTANCE2_STATUS=$(aws ec2 describe-instance-status \
    --instance-ids $INSTANCE2_ID \
    --region $REGION \
    --query 'InstanceStatuses[0].InstanceStatus.Status' \
    --output text 2>/dev/null || echo "initializing")

echo -e "Instance 2 State: ${GREEN}$INSTANCE2_STATE${NC}"
echo -e "Instance 2 Status Checks: ${GREEN}$INSTANCE2_STATUS${NC}"

echo -e "\n${YELLOW}Checking EFS Status...${NC}"
EFS_STATE=$(aws efs describe-file-systems \
    --file-system-id $EFS_ID \
    --region $REGION \
    --query 'FileSystems[0].LifeCycleState' \
    --output text)

EFS_MOUNTS=$(aws efs describe-mount-targets \
    --file-system-id $EFS_ID \
    --region $REGION \
    --query 'length(MountTargets)' \
    --output text)

echo -e "EFS State: ${GREEN}$EFS_STATE${NC}"
echo -e "Mount Targets: ${GREEN}$EFS_MOUNTS${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Verification Summary${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$INSTANCE1_STATUS" == "ok" ] && [ "$INSTANCE2_STATUS" == "ok" ]; then
    echo -e "${GREEN}✓ Both instances are ready for SSH connection${NC}"
    echo -e "${GREEN}✓ You can now connect and test EFS${NC}"
else
    echo -e "${YELLOW}⚠ Instances are still initializing${NC}"
    echo -e "${YELLOW}⚠ Wait 1-2 more minutes and run this script again${NC}"
fi

if [ "$EFS_STATE" == "available" ]; then
    echo -e "${GREEN}✓ EFS is available and ready${NC}"
else
    echo -e "${YELLOW}⚠ EFS is still being created${NC}"
fi

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Connect to instances using EC2 Instance Connect (browser)"
echo -e "2. Or use SSH: ssh -i efs-lab-key.pem ec2-user@<INSTANCE_IP>"
echo -e "3. Verify EFS mount: df -h | grep efs"
echo -e "4. Test shared storage by creating files"
