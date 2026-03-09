#!/bin/bash

#############################################
# AWS EFS Lab - Complete Automation Script
# Purpose: Create VPC, EC2, EFS and demonstrate shared storage
#############################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration Variables
VPC_CIDR="10.0.0.0/16"
SUBNET1_CIDR="10.0.1.0/24"
SUBNET2_CIDR="10.0.2.0/24"
REGION="us-east-1"
AZ1="${REGION}a"
AZ2="${REGION}b"
KEY_NAME="efs-lab-key"
INSTANCE_TYPE="t2.micro"
AMI_ID=""  # Will be auto-detected

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AWS EFS Lab - Automated Setup${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Create VPC
echo -e "\n${YELLOW}Step 1: Creating VPC...${NC}"
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $REGION \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=EFS-Lab-VPC}]' \
    --query 'Vpc.VpcId' \
    --output text)
echo -e "${GREEN}✓ VPC Created: $VPC_ID${NC}"

# Enable DNS hostnames
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames \
    --region $REGION

# Step 2: Create Internet Gateway
echo -e "\n${YELLOW}Step 2: Creating Internet Gateway...${NC}"
IGW_ID=$(aws ec2 create-internet-gateway \
    --region $REGION \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=EFS-Lab-IGW}]' \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)
echo -e "${GREEN}✓ Internet Gateway Created: $IGW_ID${NC}"

# Attach IGW to VPC
aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID \
    --region $REGION

# Step 3: Create Subnets
echo -e "\n${YELLOW}Step 3: Creating Subnets...${NC}"
SUBNET1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET1_CIDR \
    --availability-zone $AZ1 \
    --region $REGION \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=EFS-Lab-Subnet-1}]' \
    --query 'Subnet.SubnetId' \
    --output text)
echo -e "${GREEN}✓ Subnet 1 Created: $SUBNET1_ID (AZ: $AZ1)${NC}"

SUBNET2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET2_CIDR \
    --availability-zone $AZ2 \
    --region $REGION \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=EFS-Lab-Subnet-2}]' \
    --query 'Subnet.SubnetId' \
    --output text)
echo -e "${GREEN}✓ Subnet 2 Created: $SUBNET2_ID (AZ: $AZ2)${NC}"

# Enable auto-assign public IP
aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET1_ID \
    --map-public-ip-on-launch \
    --region $REGION

aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET2_ID \
    --map-public-ip-on-launch \
    --region $REGION

# Step 4: Create Route Table
echo -e "\n${YELLOW}Step 4: Creating Route Table...${NC}"
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --region $REGION \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=EFS-Lab-RT}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)
echo -e "${GREEN}✓ Route Table Created: $ROUTE_TABLE_ID${NC}"

# Create route to Internet Gateway
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID \
    --region $REGION

# Associate route table with subnets
aws ec2 associate-route-table \
    --subnet-id $SUBNET1_ID \
    --route-table-id $ROUTE_TABLE_ID \
    --region $REGION

aws ec2 associate-route-table \
    --subnet-id $SUBNET2_ID \
    --route-table-id $ROUTE_TABLE_ID \
    --region $REGION

# Step 5: Create Security Groups
echo -e "\n${YELLOW}Step 5: Creating Security Groups...${NC}"

# EC2 Security Group
EC2_SG_ID=$(aws ec2 create-security-group \
    --group-name EFS-Lab-EC2-SG \
    --description "Security group for EC2 instances in EFS lab" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text)
echo -e "${GREEN}✓ EC2 Security Group Created: $EC2_SG_ID${NC}"

# Get your public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo -e "${GREEN}✓ Your Public IP: $MY_IP${NC}"

# Allow SSH from your IP
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr ${MY_IP}/32 \
    --region $REGION

# EFS Security Group
EFS_SG_ID=$(aws ec2 create-security-group \
    --group-name EFS-Lab-EFS-SG \
    --description "Security group for EFS in lab" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text)
echo -e "${GREEN}✓ EFS Security Group Created: $EFS_SG_ID${NC}"

# Allow NFS (port 2049) from EC2 security group
aws ec2 authorize-security-group-ingress \
    --group-id $EFS_SG_ID \
    --protocol tcp \
    --port 2049 \
    --source-group $EC2_SG_ID \
    --region $REGION

# Step 6: Create Key Pair
echo -e "\n${YELLOW}Step 6: Creating Key Pair...${NC}"
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --region $REGION \
    --query 'KeyMaterial' \
    --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo -e "${GREEN}✓ Key Pair Created: ${KEY_NAME}.pem${NC}"

# Step 7: Get Latest Amazon Linux 2023 AMI
echo -e "\n${YELLOW}Step 7: Finding Latest Amazon Linux 2023 AMI...${NC}"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --region $REGION \
    --output text)
echo -e "${GREEN}✓ AMI ID: $AMI_ID${NC}"

# Step 8: Create EFS File System
echo -e "\n${YELLOW}Step 8: Creating EFS File System...${NC}"
EFS_ID=$(aws efs create-file-system \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --region $REGION \
    --tags Key=Name,Value=EFS-Lab-FileSystem \
    --query 'FileSystemId' \
    --output text)
echo -e "${GREEN}✓ EFS File System Created: $EFS_ID${NC}"

# Wait for EFS to be available
echo -e "${YELLOW}Waiting for EFS to become available...${NC}"
aws efs describe-file-systems \
    --file-system-id $EFS_ID \
    --region $REGION \
    --query 'FileSystems[0].LifeCycleState' \
    --output text

sleep 10

# Step 9: Create EFS Mount Targets
echo -e "\n${YELLOW}Step 9: Creating EFS Mount Targets...${NC}"
MOUNT_TARGET1_ID=$(aws efs create-mount-target \
    --file-system-id $EFS_ID \
    --subnet-id $SUBNET1_ID \
    --security-groups $EFS_SG_ID \
    --region $REGION \
    --query 'MountTargetId' \
    --output text)
echo -e "${GREEN}✓ Mount Target 1 Created: $MOUNT_TARGET1_ID${NC}"

MOUNT_TARGET2_ID=$(aws efs create-mount-target \
    --file-system-id $EFS_ID \
    --subnet-id $SUBNET2_ID \
    --security-groups $EFS_SG_ID \
    --region $REGION \
    --query 'MountTargetId' \
    --output text)
echo -e "${GREEN}✓ Mount Target 2 Created: $MOUNT_TARGET2_ID${NC}"

# Wait for mount targets to be available
echo -e "${YELLOW}Waiting for mount targets to become available (this may take 1-2 minutes)...${NC}"
sleep 60

# Step 10: Create User Data Script for EC2
cat > user-data.sh << 'EOF'
#!/bin/bash
# Update system
yum update -y

# Install NFS utilities
yum install -y amazon-efs-utils nfs-utils

# Create mount directory
mkdir -p /mnt/efs

# Mount EFS (will be replaced with actual EFS ID)
echo "EFS_ID_PLACEHOLDER:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
mount -a

# Create test marker file
echo "EC2 instance $(hostname) mounted EFS successfully at $(date)" > /mnt/efs/mount-info-$(hostname).txt

# Set permissions
chmod 777 /mnt/efs
EOF

# Replace placeholder with actual EFS ID
sed -i "s/EFS_ID_PLACEHOLDER/$EFS_ID/g" user-data.sh

# Step 11: Launch EC2 Instances
echo -e "\n${YELLOW}Step 11: Launching EC2 Instances...${NC}"

INSTANCE1_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $EC2_SG_ID \
    --subnet-id $SUBNET1_ID \
    --user-data file://user-data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EFS-Lab-Instance-1}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)
echo -e "${GREEN}✓ Instance 1 Launched: $INSTANCE1_ID${NC}"

INSTANCE2_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $EC2_SG_ID \
    --subnet-id $SUBNET2_ID \
    --user-data file://user-data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EFS-Lab-Instance-2}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)
echo -e "${GREEN}✓ Instance 2 Launched: $INSTANCE2_ID${NC}"

# Wait for instances to be running
echo -e "\n${YELLOW}Waiting for instances to be running...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE1_ID $INSTANCE2_ID --region $REGION
echo -e "${GREEN}✓ Both instances are now running${NC}"

# Get instance public IPs
INSTANCE1_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE1_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

INSTANCE2_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE2_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

# Step 12: Create Summary Report
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}AWS EFS Lab Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

cat > lab-summary.txt << EOF
AWS EFS Lab - Resource Summary
================================

VPC Details:
- VPC ID: $VPC_ID
- CIDR: $VPC_CIDR

Subnets:
- Subnet 1 ID: $SUBNET1_ID (AZ: $AZ1)
- Subnet 2 ID: $SUBNET2_ID (AZ: $AZ2)

Security Groups:
- EC2 SG: $EC2_SG_ID
- EFS SG: $EFS_SG_ID

EFS File System:
- EFS ID: $EFS_ID
- Mount Target 1: $MOUNT_TARGET1_ID
- Mount Target 2: $MOUNT_TARGET2_ID

EC2 Instances:
- Instance 1 ID: $INSTANCE1_ID
- Instance 1 IP: $INSTANCE1_IP
- Instance 2 ID: $INSTANCE2_ID
- Instance 2 IP: $INSTANCE2_IP

SSH Key:
- Key Name: $KEY_NAME
- Key File: ${KEY_NAME}.pem

Connection Commands:
--------------------
ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE1_IP
ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE2_IP

Testing EFS:
------------
1. Connect to Instance 1:
   ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE1_IP
   
2. Create a test file:
   echo "Hello from Instance 1" | sudo tee /mnt/efs/test-from-instance1.txt
   
3. Connect to Instance 2:
   ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE2_IP
   
4. Verify the file exists:
   cat /mnt/efs/test-from-instance1.txt
   
5. Create another file from Instance 2:
   echo "Hello from Instance 2" | sudo tee /mnt/efs/test-from-instance2.txt
   
6. Go back to Instance 1 and verify:
   cat /mnt/efs/test-from-instance2.txt

Cleanup Command:
----------------
To delete all resources, run:
./cleanup-efs-lab.sh

EOF

cat lab-summary.txt

echo -e "\n${GREEN}✓ Summary saved to: lab-summary.txt${NC}"
echo -e "${YELLOW}Note: Wait 2-3 minutes for user-data script to complete on EC2 instances${NC}"

# Create cleanup script
cat > cleanup-efs-lab.sh << EOF
#!/bin/bash
echo "Cleaning up AWS EFS Lab resources..."

# Terminate EC2 instances
aws ec2 terminate-instances --instance-ids $INSTANCE1_ID $INSTANCE2_ID --region $REGION
echo "Waiting for instances to terminate..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE1_ID $INSTANCE2_ID --region $REGION

# Delete mount targets
aws efs delete-mount-target --mount-target-id $MOUNT_TARGET1_ID --region $REGION
aws efs delete-mount-target --mount-target-id $MOUNT_TARGET2_ID --region $REGION
sleep 30

# Delete EFS file system
aws efs delete-file-system --file-system-id $EFS_ID --region $REGION

# Delete security groups
aws ec2 delete-security-group --group-id $EFS_SG_ID --region $REGION
aws ec2 delete-security-group --group-id $EC2_SG_ID --region $REGION

# Detach and delete internet gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION

# Delete subnets
aws ec2 delete-subnet --subnet-id $SUBNET1_ID --region $REGION
aws ec2 delete-subnet --subnet-id $SUBNET2_ID --region $REGION

# Delete route table
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID --region $REGION

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

# Delete key pair
aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION
rm -f ${KEY_NAME}.pem

echo "Cleanup complete!"
EOF

chmod +x cleanup-efs-lab.sh

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete! Resources are ready.${NC}"
echo -e "${GREEN}========================================${NC}"
