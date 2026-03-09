#!/bin/bash

#############################################
# AWS EFS Lab - Complete Resource Cleanup
# Deletes ALL EFS lab resources in the region
#############################################

set +e  # Continue on errors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGION="us-east-1"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AWS EFS Lab - Complete Cleanup${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Step 1: Terminating EC2 Instances...${NC}"
INSTANCES=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-Instance-*" "Name=instance-state-name,Values=running,stopped,pending" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ ! -z "$INSTANCES" ]; then
    echo -e "Found instances: $INSTANCES"
    aws ec2 terminate-instances --instance-ids $INSTANCES --region $REGION
    echo -e "${YELLOW}Waiting for instances to terminate...${NC}"
    aws ec2 wait instance-terminated --instance-ids $INSTANCES --region $REGION 2>/dev/null || sleep 60
    echo -e "${GREEN}✓ Instances terminated${NC}"
else
    echo -e "${YELLOW}No instances found${NC}"
fi

echo -e "\n${YELLOW}Step 2: Deleting EFS Mount Targets...${NC}"
EFS_SYSTEMS=$(aws efs describe-file-systems \
    --region $REGION \
    --query 'FileSystems[?Name==`EFS-Lab-FileSystem`].FileSystemId' \
    --output text)

if [ ! -z "$EFS_SYSTEMS" ]; then
    for EFS_ID in $EFS_SYSTEMS; do
        echo -e "Processing EFS: $EFS_ID"
        MOUNT_TARGETS=$(aws efs describe-mount-targets \
            --file-system-id $EFS_ID \
            --region $REGION \
            --query 'MountTargets[*].MountTargetId' \
            --output text)
        
        if [ ! -z "$MOUNT_TARGETS" ]; then
            for MT_ID in $MOUNT_TARGETS; do
                echo -e "Deleting mount target: $MT_ID"
                aws efs delete-mount-target --mount-target-id $MT_ID --region $REGION
            done
            echo -e "${YELLOW}Waiting for mount targets to be deleted...${NC}"
            sleep 45
        fi
    done
    echo -e "${GREEN}✓ Mount targets deleted${NC}"
else
    echo -e "${YELLOW}No EFS systems found${NC}"
fi

echo -e "\n${YELLOW}Step 3: Deleting EFS File Systems...${NC}"
if [ ! -z "$EFS_SYSTEMS" ]; then
    for EFS_ID in $EFS_SYSTEMS; do
        echo -e "Deleting EFS: $EFS_ID"
        aws efs delete-file-system --file-system-id $EFS_ID --region $REGION
    done
    echo -e "${GREEN}✓ EFS file systems deleted${NC}"
else
    echo -e "${YELLOW}No EFS systems to delete${NC}"
fi

echo -e "\n${YELLOW}Step 4: Deleting Security Groups...${NC}"
# Get VPC ID first
VPC_ID=$(aws ec2 describe-vpcs \
    --region $REGION \
    --filters "Name=tag:Name,Values=EFS-Lab-VPC" \
    --query 'Vpcs[0].VpcId' \
    --output text)

if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    # Delete EFS security group
    EFS_SG=$(aws ec2 describe-security-groups \
        --region $REGION \
        --filters "Name=group-name,Values=EFS-Lab-EFS-SG" "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' \
        --output text)
    
    if [ "$EFS_SG" != "None" ] && [ ! -z "$EFS_SG" ]; then
        echo -e "Deleting EFS security group: $EFS_SG"
        aws ec2 delete-security-group --group-id $EFS_SG --region $REGION 2>/dev/null || echo "Failed to delete EFS SG (may have dependencies)"
    fi
    
    # Wait a bit for dependencies to clear
    sleep 10
    
    # Delete EC2 security group
    EC2_SG=$(aws ec2 describe-security-groups \
        --region $REGION \
        --filters "Name=group-name,Values=EFS-Lab-EC2-SG" "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' \
        --output text)
    
    if [ "$EC2_SG" != "None" ] && [ ! -z "$EC2_SG" ]; then
        echo -e "Deleting EC2 security group: $EC2_SG"
        aws ec2 delete-security-group --group-id $EC2_SG --region $REGION 2>/dev/null || echo "Failed to delete EC2 SG (may have dependencies)"
    fi
    
    echo -e "${GREEN}✓ Security groups deleted${NC}"
fi

echo -e "\n${YELLOW}Step 5: Deleting Subnets...${NC}"
if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    SUBNETS=$(aws ec2 describe-subnets \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'Subnets[*].SubnetId' \
        --output text)
    
    if [ ! -z "$SUBNETS" ]; then
        for SUBNET_ID in $SUBNETS; do
            echo -e "Deleting subnet: $SUBNET_ID"
            aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
        done
        echo -e "${GREEN}✓ Subnets deleted${NC}"
    fi
fi

echo -e "\n${YELLOW}Step 6: Detaching and Deleting Internet Gateway...${NC}"
if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --region $REGION \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text)
    
    if [ "$IGW_ID" != "None" ] && [ ! -z "$IGW_ID" ]; then
        echo -e "Detaching IGW: $IGW_ID"
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
        echo -e "Deleting IGW: $IGW_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
        echo -e "${GREEN}✓ Internet Gateway deleted${NC}"
    fi
fi

echo -e "\n${YELLOW}Step 7: Deleting Route Tables...${NC}"
if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    ROUTE_TABLES=$(aws ec2 describe-route-tables \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=EFS-Lab-RT" \
        --query 'RouteTables[*].RouteTableId' \
        --output text)
    
    if [ ! -z "$ROUTE_TABLES" ]; then
        for RT_ID in $ROUTE_TABLES; do
            echo -e "Deleting route table: $RT_ID"
            aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION 2>/dev/null || echo "Skipped (may be main route table)"
        done
        echo -e "${GREEN}✓ Route tables deleted${NC}"
    fi
fi

echo -e "\n${YELLOW}Step 8: Deleting VPC...${NC}"
if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    echo -e "Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
    echo -e "${GREEN}✓ VPC deleted${NC}"
fi

echo -e "\n${YELLOW}Step 9: Deleting Key Pair...${NC}"
KEY_PAIRS=$(aws ec2 describe-key-pairs \
    --region $REGION \
    --filters "Name=key-name,Values=efs-lab-key" \
    --query 'KeyPairs[*].KeyName' \
    --output text)

if [ ! -z "$KEY_PAIRS" ]; then
    aws ec2 delete-key-pair --key-name efs-lab-key --region $REGION
    echo -e "${GREEN}✓ Key pair deleted from AWS${NC}"
fi

# Delete local key file
if [ -f "efs-lab-key.pem" ]; then
    rm -f efs-lab-key.pem
    echo -e "${GREEN}✓ Local key file deleted${NC}"
fi

# Delete generated files
rm -f user-data.sh lab-summary.txt cleanup-efs-lab.sh

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All EFS lab resources have been removed from $REGION${NC}"
echo -e "${YELLOW}You can now run ./aws-efs-lab-setup.sh to start fresh${NC}"
