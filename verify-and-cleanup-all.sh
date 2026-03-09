#!/bin/bash

#############################################
# AWS EFS Lab - Complete Verification & Cleanup
# Checks current region, removes all resources, verifies clean state
#############################################

set +e  # Continue on errors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AWS EFS Lab - Complete Verification & Cleanup Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

# Step 1: Detect Current Region
echo -e "\n${YELLOW}[Step 1/3] Detecting Current AWS Region...${NC}"

# Try multiple methods to detect region
REGION=""

# Method 1: AWS CLI default region
REGION=$(aws configure get region 2>/dev/null)

# Method 2: EC2 metadata (if running on EC2)
if [ -z "$REGION" ]; then
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)
fi

# Method 3: Environment variable
if [ -z "$REGION" ]; then
    REGION=$AWS_DEFAULT_REGION
fi

# Method 4: CloudShell default
if [ -z "$REGION" ]; then
    REGION=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].RegionName' --output text 2>/dev/null)
fi

# Default to us-east-1 if nothing found
if [ -z "$REGION" ] || [ "$REGION" == "None" ]; then
    REGION="us-east-1"
    echo -e "${YELLOW}⚠ Could not detect region, defaulting to: $REGION${NC}"
else
    echo -e "${GREEN}✓ Detected Region: $REGION${NC}"
fi

# Confirm with user
echo -e "\n${YELLOW}Current AWS Region: ${GREEN}$REGION${NC}"
read -p "Is this correct? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter the correct region (e.g., us-east-1): " REGION
    echo -e "${GREEN}✓ Using region: $REGION${NC}"
fi

# Step 2: Scan for EFS Lab Resources
echo -e "\n${YELLOW}[Step 2/3] Scanning for EFS Lab Resources in $REGION...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

RESOURCES_FOUND=0

# Check EC2 Instances
echo -e "\n${YELLOW}Checking EC2 Instances...${NC}"
INSTANCES=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-Instance-*" "Name=instance-state-name,Values=running,stopped,pending,stopping" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
    --output text 2>/dev/null)

if [ ! -z "$INSTANCES" ]; then
    echo -e "${RED}✗ Found EC2 Instances:${NC}"
    echo "$INSTANCES" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No EC2 instances found${NC}"
fi

# Check EFS File Systems
echo -e "\n${YELLOW}Checking EFS File Systems...${NC}"
EFS_SYSTEMS=$(aws efs describe-file-systems \
    --region $REGION \
    --query 'FileSystems[?Name==`EFS-Lab-FileSystem`].[FileSystemId,Name,LifeCycleState]' \
    --output text 2>/dev/null)

if [ ! -z "$EFS_SYSTEMS" ]; then
    echo -e "${RED}✗ Found EFS File Systems:${NC}"
    echo "$EFS_SYSTEMS" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No EFS file systems found${NC}"
fi

# Check VPCs
echo -e "\n${YELLOW}Checking VPCs...${NC}"
VPCS=$(aws ec2 describe-vpcs \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-VPC" \
    --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock]' \
    --output text 2>/dev/null)

if [ ! -z "$VPCS" ]; then
    echo -e "${RED}✗ Found VPCs:${NC}"
    echo "$VPCS" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No VPCs found${NC}"
fi

# Check Security Groups
echo -e "\n${YELLOW}Checking Security Groups...${NC}"
SECURITY_GROUPS=$(aws ec2 describe-security-groups \
    --region $REGION \
    --filters "Name=group-name,Values=EFS-Lab-*" \
    --query 'SecurityGroups[*].[GroupId,GroupName,VpcId]' \
    --output text 2>/dev/null)

if [ ! -z "$SECURITY_GROUPS" ]; then
    echo -e "${RED}✗ Found Security Groups:${NC}"
    echo "$SECURITY_GROUPS" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No security groups found${NC}"
fi

# Check Subnets
echo -e "\n${YELLOW}Checking Subnets...${NC}"
SUBNETS=$(aws ec2 describe-subnets \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-Subnet-*" \
    --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0],CidrBlock,AvailabilityZone]' \
    --output text 2>/dev/null)

if [ ! -z "$SUBNETS" ]; then
    echo -e "${RED}✗ Found Subnets:${NC}"
    echo "$SUBNETS" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No subnets found${NC}"
fi

# Check Internet Gateways
echo -e "\n${YELLOW}Checking Internet Gateways...${NC}"
IGWS=$(aws ec2 describe-internet-gateways \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-IGW" \
    --query 'InternetGateways[*].[InternetGatewayId,Tags[?Key==`Name`].Value|[0],Attachments[0].VpcId]' \
    --output text 2>/dev/null)

if [ ! -z "$IGWS" ]; then
    echo -e "${RED}✗ Found Internet Gateways:${NC}"
    echo "$IGWS" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No internet gateways found${NC}"
fi

# Check Route Tables
echo -e "\n${YELLOW}Checking Route Tables...${NC}"
ROUTE_TABLES=$(aws ec2 describe-route-tables \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-RT" \
    --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0],VpcId]' \
    --output text 2>/dev/null)

if [ ! -z "$ROUTE_TABLES" ]; then
    echo -e "${RED}✗ Found Route Tables:${NC}"
    echo "$ROUTE_TABLES" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No route tables found${NC}"
fi

# Check Key Pairs
echo -e "\n${YELLOW}Checking Key Pairs...${NC}"
KEY_PAIRS=$(aws ec2 describe-key-pairs \
    --region $REGION \
    --filters "Name=key-name,Values=efs-lab-key" \
    --query 'KeyPairs[*].[KeyName,KeyPairId]' \
    --output text 2>/dev/null)

if [ ! -z "$KEY_PAIRS" ]; then
    echo -e "${RED}✗ Found Key Pairs:${NC}"
    echo "$KEY_PAIRS" | while read line; do
        echo -e "  ${RED}→${NC} $line"
    done
    RESOURCES_FOUND=$((RESOURCES_FOUND + 1))
else
    echo -e "${GREEN}✓ No key pairs found${NC}"
fi

# Summary
echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
if [ $RESOURCES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ No EFS Lab resources found in region $REGION${NC}"
    echo -e "${GREEN}✓ Region is clean!${NC}"
    echo -e "\n${GREEN}You can now run: ./aws-efs-lab-setup-v2.sh${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $RESOURCES_FOUND types of EFS Lab resources${NC}"
    echo -e "${YELLOW}⚠ Cleanup required${NC}"
fi

# Step 3: Cleanup Resources
echo -e "\n${YELLOW}[Step 3/3] Cleanup Resources${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

read -p "Do you want to delete all EFS Lab resources? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled by user${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Starting cleanup process...${NC}"

# 1. Terminate EC2 Instances
if [ ! -z "$INSTANCES" ]; then
    echo -e "\n${YELLOW}[1/9] Terminating EC2 Instances...${NC}"
    INSTANCE_IDS=$(echo "$INSTANCES" | awk '{print $1}')
    if [ ! -z "$INSTANCE_IDS" ]; then
        aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION
        echo -e "${YELLOW}Waiting for instances to terminate (this may take 2-3 minutes)...${NC}"
        aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region $REGION 2>/dev/null || sleep 90
        echo -e "${GREEN}✓ Instances terminated${NC}"
    fi
else
    echo -e "\n${GREEN}[1/9] No EC2 instances to terminate${NC}"
fi

# 2. Delete EFS Mount Targets
if [ ! -z "$EFS_SYSTEMS" ]; then
    echo -e "\n${YELLOW}[2/9] Deleting EFS Mount Targets...${NC}"
    EFS_IDS=$(echo "$EFS_SYSTEMS" | awk '{print $1}')
    for EFS_ID in $EFS_IDS; do
        echo -e "Processing EFS: $EFS_ID"
        MOUNT_TARGETS=$(aws efs describe-mount-targets \
            --file-system-id $EFS_ID \
            --region $REGION \
            --query 'MountTargets[*].MountTargetId' \
            --output text 2>/dev/null)
        
        if [ ! -z "$MOUNT_TARGETS" ]; then
            for MT_ID in $MOUNT_TARGETS; do
                echo -e "  Deleting mount target: $MT_ID"
                aws efs delete-mount-target --mount-target-id $MT_ID --region $REGION 2>/dev/null
            done
            echo -e "${YELLOW}  Waiting for mount targets to be deleted...${NC}"
            sleep 60
        fi
    done
    echo -e "${GREEN}✓ Mount targets deleted${NC}"
else
    echo -e "\n${GREEN}[2/9] No EFS mount targets to delete${NC}"
fi

# 3. Delete EFS File Systems
if [ ! -z "$EFS_SYSTEMS" ]; then
    echo -e "\n${YELLOW}[3/9] Deleting EFS File Systems...${NC}"
    for EFS_ID in $EFS_IDS; do
        echo -e "  Deleting EFS: $EFS_ID"
        aws efs delete-file-system --file-system-id $EFS_ID --region $REGION 2>/dev/null
    done
    echo -e "${GREEN}✓ EFS file systems deleted${NC}"
else
    echo -e "\n${GREEN}[3/9] No EFS file systems to delete${NC}"
fi

# 4. Delete Security Groups
if [ ! -z "$SECURITY_GROUPS" ]; then
    echo -e "\n${YELLOW}[4/9] Deleting Security Groups...${NC}"
    sleep 15  # Wait for dependencies to clear
    
    # Delete EFS security group first
    EFS_SG=$(aws ec2 describe-security-groups \
        --region $REGION \
        --filters "Name=group-name,Values=EFS-Lab-EFS-SG" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null)
    
    if [ "$EFS_SG" != "None" ] && [ ! -z "$EFS_SG" ]; then
        echo -e "  Deleting EFS security group: $EFS_SG"
        aws ec2 delete-security-group --group-id $EFS_SG --region $REGION 2>/dev/null || echo "  (may have dependencies, will retry)"
    fi
    
    sleep 10
    
    # Delete EC2 security group
    EC2_SG=$(aws ec2 describe-security-groups \
        --region $REGION \
        --filters "Name=group-name,Values=EFS-Lab-EC2-SG" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null)
    
    if [ "$EC2_SG" != "None" ] && [ ! -z "$EC2_SG" ]; then
        echo -e "  Deleting EC2 security group: $EC2_SG"
        aws ec2 delete-security-group --group-id $EC2_SG --region $REGION 2>/dev/null || echo "  (may have dependencies, will retry)"
    fi
    
    echo -e "${GREEN}✓ Security groups deleted${NC}"
else
    echo -e "\n${GREEN}[4/9] No security groups to delete${NC}"
fi

# 5. Delete Subnets
if [ ! -z "$SUBNETS" ]; then
    echo -e "\n${YELLOW}[5/9] Deleting Subnets...${NC}"
    SUBNET_IDS=$(echo "$SUBNETS" | awk '{print $1}')
    for SUBNET_ID in $SUBNET_IDS; do
        echo -e "  Deleting subnet: $SUBNET_ID"
        aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION 2>/dev/null
    done
    echo -e "${GREEN}✓ Subnets deleted${NC}"
else
    echo -e "\n${GREEN}[5/9] No subnets to delete${NC}"
fi

# 6. Detach and Delete Internet Gateways
if [ ! -z "$IGWS" ]; then
    echo -e "\n${YELLOW}[6/9] Detaching and Deleting Internet Gateways...${NC}"
    echo "$IGWS" | while read IGW_ID NAME VPC_ID; do
        if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
            echo -e "  Detaching IGW $IGW_ID from VPC $VPC_ID"
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION 2>/dev/null
        fi
        echo -e "  Deleting IGW: $IGW_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION 2>/dev/null
    done
    echo -e "${GREEN}✓ Internet gateways deleted${NC}"
else
    echo -e "\n${GREEN}[6/9] No internet gateways to delete${NC}"
fi

# 7. Delete Route Tables
if [ ! -z "$ROUTE_TABLES" ]; then
    echo -e "\n${YELLOW}[7/9] Deleting Route Tables...${NC}"
    RT_IDS=$(echo "$ROUTE_TABLES" | awk '{print $1}')
    for RT_ID in $RT_IDS; do
        echo -e "  Deleting route table: $RT_ID"
        aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION 2>/dev/null || echo "  (may be main route table, skipped)"
    done
    echo -e "${GREEN}✓ Route tables deleted${NC}"
else
    echo -e "\n${GREEN}[7/9] No route tables to delete${NC}"
fi

# 8. Delete VPCs
if [ ! -z "$VPCS" ]; then
    echo -e "\n${YELLOW}[8/9] Deleting VPCs...${NC}"
    VPC_IDS=$(echo "$VPCS" | awk '{print $1}')
    for VPC_ID in $VPC_IDS; do
        echo -e "  Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null
    done
    echo -e "${GREEN}✓ VPCs deleted${NC}"
else
    echo -e "\n${GREEN}[8/9] No VPCs to delete${NC}"
fi

# 9. Delete Key Pairs
if [ ! -z "$KEY_PAIRS" ]; then
    echo -e "\n${YELLOW}[9/9] Deleting Key Pairs...${NC}"
    aws ec2 delete-key-pair --key-name efs-lab-key --region $REGION 2>/dev/null
    echo -e "${GREEN}✓ Key pair deleted from AWS${NC}"
    
    # Delete local key file
    if [ -f "efs-lab-key.pem" ]; then
        rm -f efs-lab-key.pem
        echo -e "${GREEN}✓ Local key file deleted${NC}"
    fi
else
    echo -e "\n${GREEN}[9/9] No key pairs to delete${NC}"
fi

# Delete generated files
rm -f user-data.sh lab-summary.txt cleanup-efs-lab.sh 2>/dev/null

# Final Verification
echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Running final verification...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

REMAINING=0

# Re-check all resources
echo -e "\n${YELLOW}Verifying EC2 Instances...${NC}"
INSTANCES_CHECK=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-Instance-*" "Name=instance-state-name,Values=running,stopped,pending,stopping" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text 2>/dev/null)
if [ -z "$INSTANCES_CHECK" ]; then
    echo -e "${GREEN}✓ No EC2 instances remaining${NC}"
else
    echo -e "${RED}✗ Some instances still exist: $INSTANCES_CHECK${NC}"
    REMAINING=$((REMAINING + 1))
fi

echo -e "\n${YELLOW}Verifying EFS File Systems...${NC}"
EFS_CHECK=$(aws efs describe-file-systems \
    --region $REGION \
    --query 'FileSystems[?Name==`EFS-Lab-FileSystem`].FileSystemId' \
    --output text 2>/dev/null)
if [ -z "$EFS_CHECK" ]; then
    echo -e "${GREEN}✓ No EFS file systems remaining${NC}"
else
    echo -e "${RED}✗ Some EFS systems still exist: $EFS_CHECK${NC}"
    REMAINING=$((REMAINING + 1))
fi

echo -e "\n${YELLOW}Verifying VPCs...${NC}"
VPC_CHECK=$(aws ec2 describe-vpcs \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-VPC" \
    --query 'Vpcs[*].VpcId' \
    --output text 2>/dev/null)
if [ -z "$VPC_CHECK" ]; then
    echo -e "${GREEN}✓ No VPCs remaining${NC}"
else
    echo -e "${RED}✗ Some VPCs still exist: $VPC_CHECK${NC}"
    REMAINING=$((REMAINING + 1))
fi

echo -e "\n${YELLOW}Verifying Security Groups...${NC}"
SG_CHECK=$(aws ec2 describe-security-groups \
    --region $REGION \
    --filters "Name=group-name,Values=EFS-Lab-*" \
    --query 'SecurityGroups[*].GroupId' \
    --output text 2>/dev/null)
if [ -z "$SG_CHECK" ]; then
    echo -e "${GREEN}✓ No security groups remaining${NC}"
else
    echo -e "${RED}✗ Some security groups still exist: $SG_CHECK${NC}"
    REMAINING=$((REMAINING + 1))
fi

echo -e "\n${YELLOW}Verifying Key Pairs...${NC}"
KEY_CHECK=$(aws ec2 describe-key-pairs \
    --region $REGION \
    --filters "Name=key-name,Values=efs-lab-key" \
    --query 'KeyPairs[*].KeyName' \
    --output text 2>/dev/null)
if [ -z "$KEY_CHECK" ]; then
    echo -e "${GREEN}✓ No key pairs remaining${NC}"
else
    echo -e "${RED}✗ Key pair still exists: $KEY_CHECK${NC}"
    REMAINING=$((REMAINING + 1))
fi

# Final Summary
echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
if [ $REMAINING -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✓ CLEANUP SUCCESSFUL                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}✓ All EFS Lab resources removed from region: $REGION${NC}"
    echo -e "${GREEN}✓ Region is now clean!${NC}"
    echo -e "\n${BLUE}You can now run: ./aws-efs-lab-setup-v2.sh${NC}"
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║              ⚠ CLEANUP PARTIALLY COMPLETE                      ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}⚠ Some resources may still exist (dependencies or timing)${NC}"
    echo -e "${YELLOW}⚠ Wait 2-3 minutes and run this script again${NC}"
    echo -e "\n${YELLOW}Or manually check AWS Console for remaining resources${NC}"
fi

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Script completed at $(date)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
