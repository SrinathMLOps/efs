#!/bin/bash

#############################################
# AWS EFS Lab - Complete Automation Script v2
# Fixed for EC2 Instance Connect and proper timing
#############################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AWS EFS Lab - Automated Setup v2${NC}"
echo -e "${BLUE}Region: $REGION${NC}"
echo -e "${BLUE}========================================${NC}"

# Step 1: Create VPC
echo -e "\n${YELLOW}[1/15] Creating VPC...${NC}"
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
echo -e "${GREEN}✓ DNS hostnames enabled${NC}"

# Step 2: Create Internet Gateway
echo -e "\n${YELLOW}[2/15] Creating Internet Gateway...${NC}"
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
echo -e "${GREEN}✓ IGW attached to VPC${NC}"

# Step 3: Create Subnets
echo -e "\n${YELLOW}[3/15] Creating Subnets...${NC}"
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
echo -e "${GREEN}✓ Auto-assign public IP enabled on both subnets${NC}"

# Step 4: Create Route Table
echo -e "\n${YELLOW}[4/15] Creating Route Table...${NC}"
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
echo -e "${GREEN}✓ Internet route added${NC}"

# Associate route table with subnets
aws ec2 associate-route-table \
    --subnet-id $SUBNET1_ID \
    --route-table-id $ROUTE_TABLE_ID \
    --region $REGION

aws ec2 associate-route-table \
    --subnet-id $SUBNET2_ID \
    --route-table-id $ROUTE_TABLE_ID \
    --region $REGION
echo -e "${GREEN}✓ Route table associated with subnets${NC}"

# Step 5: Create Security Groups
echo -e "\n${YELLOW}[5/15] Creating Security Groups...${NC}"

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

# Allow SSH from EC2 Instance Connect service (for browser-based connection)
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 18.206.107.24/29 \
    --region $REGION

echo -e "${GREEN}✓ SSH access configured for your IP and EC2 Instance Connect${NC}"

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
echo -e "${GREEN}✓ NFS access configured from EC2 instances${NC}"

# Step 6: Create Key Pair
echo -e "\n${YELLOW}[6/15] Creating Key Pair...${NC}"
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --region $REGION \
    --query 'KeyMaterial' \
    --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo -e "${GREEN}✓ Key Pair Created: ${KEY_NAME}.pem${NC}"

# Step 7: Get Latest Amazon Linux 2023 AMI
echo -e "\n${YELLOW}[7/15] Finding Latest Amazon Linux 2023 AMI...${NC}"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --region $REGION \
    --output text)
echo -e "${GREEN}✓ AMI ID: $AMI_ID${NC}"

# Step 8: Create EFS File System
echo -e "\n${YELLOW}[8/15] Creating EFS File System...${NC}"
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
sleep 15

# Step 9: Create EFS Mount Targets
echo -e "\n${YELLOW}[9/15] Creating EFS Mount Targets...${NC}"
MOUNT_TARGET1_ID=$(aws efs create-mount-target \
    --file-system-id $EFS_ID \
    --subnet-id $SUBNET1_ID \
    --security-groups $EFS_SG_ID \
    --region $REGION \
    --query 'MountTargetId' \
    --output text)
echo -e "${GREEN}✓ Mount Target 1 Created: $MOUNT_TARGET1_ID (AZ: $AZ1)${NC}"

MOUNT_TARGET2_ID=$(aws efs create-mount-target \
    --file-system-id $EFS_ID \
    --subnet-id $SUBNET2_ID \
    --security-groups $EFS_SG_ID \
    --region $REGION \
    --query 'MountTargetId' \
    --output text)
echo -e "${GREEN}✓ Mount Target 2 Created: $MOUNT_TARGET2_ID (AZ: $AZ2)${NC}"

# Wait for mount targets to be available
echo -e "${YELLOW}Waiting for mount targets to become available (90 seconds)...${NC}"
sleep 90
echo -e "${GREEN}✓ Mount targets should now be available${NC}"

# Step 10: Create User Data Script for EC2
echo -e "\n${YELLOW}[10/15] Preparing User Data Script...${NC}"
cat > user-data.sh << 'EOF'
#!/bin/bash
# Log all output for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== User Data Script Started at $(date) ==="

# Update system
echo "Updating system packages..."
yum update -y

# Install NFS utilities
echo "Installing EFS utilities..."
yum install -y amazon-efs-utils nfs-utils

# Create mount directory
echo "Creating mount directory..."
mkdir -p /mnt/efs

# Wait for network and EFS mount target
echo "Waiting for EFS mount target to be ready..."
sleep 60

# Configure EFS mount in fstab
echo "Configuring EFS mount in /etc/fstab..."
echo "EFS_ID_PLACEHOLDER:/ /mnt/efs efs defaults,_netdev,tls 0 0" >> /etc/fstab

# Mount EFS with retry logic
echo "Attempting to mount EFS..."
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    mount -a
    
    if mountpoint -q /mnt/efs; then
        echo "✓ EFS mounted successfully"
        chmod 777 /mnt/efs
        echo "EC2 instance $(hostname) mounted EFS successfully at $(date)" > /mnt/efs/mount-info-$(hostname).txt
        echo "=== User Data Script Completed Successfully at $(date) ==="
        exit 0
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Mount attempt $RETRY_COUNT failed, waiting 30 seconds..."
        sleep 30
    fi
done

echo "ERROR: Failed to mount EFS after $MAX_RETRIES attempts"
echo "=== User Data Script Completed with Errors at $(date) ==="
exit 1
EOF

# Replace placeholder with actual EFS ID
sed -i "s/EFS_ID_PLACEHOLDER/$EFS_ID/g" user-data.sh
echo -e "${GREEN}✓ User data script prepared${NC}"

# Step 11: Launch EC2 Instances
echo -e "\n${YELLOW}[11/15] Launching EC2 Instance 1...${NC}"
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

echo -e "\n${YELLOW}[12/15] Launching EC2 Instance 2...${NC}"
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

# Step 12: Wait for instances to be running
echo -e "\n${YELLOW}[13/15] Waiting for instances to be running...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE1_ID $INSTANCE2_ID --region $REGION
echo -e "${GREEN}✓ Both instances are now running${NC}"

# Step 13: Wait for status checks to pass
echo -e "\n${YELLOW}[14/15] Waiting for status checks to pass...${NC}"
echo -e "${YELLOW}This takes 2-3 minutes. Please be patient...${NC}"
aws ec2 wait instance-status-ok --instance-ids $INSTANCE1_ID $INSTANCE2_ID --region $REGION
echo -e "${GREEN}✓ Both instances passed all status checks (2/2)${NC}"
echo -e "${GREEN}✓ Instances are ready for SSH connection${NC}"

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

# Step 14: Create Summary Report
echo -e "\n${YELLOW}[15/15] Generating Summary Report...${NC}"

cat > lab-summary.txt << EOF
╔════════════════════════════════════════════════════════════════╗
║          AWS EFS Lab - Resource Summary                        ║
╚════════════════════════════════════════════════════════════════╝

📍 REGION: $REGION

🌐 VPC DETAILS:
   VPC ID: $VPC_ID
   CIDR: $VPC_CIDR

🔌 NETWORK:
   Subnet 1: $SUBNET1_ID (AZ: $AZ1, CIDR: $SUBNET1_CIDR)
   Subnet 2: $SUBNET2_ID (AZ: $AZ2, CIDR: $SUBNET2_CIDR)
   Internet Gateway: $IGW_ID
   Route Table: $ROUTE_TABLE_ID

🔒 SECURITY GROUPS:
   EC2 SG: $EC2_SG_ID
     ↳ Allows SSH (22) from your IP: $MY_IP
     ↳ Allows SSH (22) from EC2 Instance Connect
   
   EFS SG: $EFS_SG_ID
     ↳ Allows NFS (2049) from EC2 Security Group

💾 EFS FILE SYSTEM:
   EFS ID: $EFS_ID
   DNS Name: $EFS_ID.efs.$REGION.amazonaws.com
   Mount Target 1: $MOUNT_TARGET1_ID (AZ: $AZ1)
   Mount Target 2: $MOUNT_TARGET2_ID (AZ: $AZ2)
   Performance Mode: General Purpose
   Throughput Mode: Bursting
   Encryption: Enabled

🖥️  EC2 INSTANCES:
   Instance 1:
     ID: $INSTANCE1_ID
     Public IP: $INSTANCE1_IP
     AZ: $AZ1
     Mount Point: /mnt/efs
   
   Instance 2:
     ID: $INSTANCE2_ID
     Public IP: $INSTANCE2_IP
     AZ: $AZ2
     Mount Point: /mnt/efs

🔑 SSH KEY:
   Key Name: $KEY_NAME
   Key File: ${KEY_NAME}.pem
   Permissions: 400 (read-only)

╔════════════════════════════════════════════════════════════════╗
║                    CONNECTION METHODS                          ║
╚════════════════════════════════════════════════════════════════╝

METHOD 1: EC2 Instance Connect (Browser - EASIEST)
──────────────────────────────────────────────────
1. Go to: https://console.aws.amazon.com/ec2
2. Click on "Instances"
3. Select "EFS-Lab-Instance-1" or "EFS-Lab-Instance-2"
4. Click "Connect" button (top right)
5. Choose "EC2 Instance Connect" tab
6. Click "Connect"

METHOD 2: SSH from Local Terminal
──────────────────────────────────
ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE1_IP
ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE2_IP

METHOD 3: SSH from AWS CloudShell
──────────────────────────────────
1. Open CloudShell (terminal icon in AWS Console)
2. Upload ${KEY_NAME}.pem file
3. Run: chmod 400 ${KEY_NAME}.pem
4. Run: ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE1_IP

╔════════════════════════════════════════════════════════════════╗
║                  TESTING EFS SHARED STORAGE                    ║
╚════════════════════════════════════════════════════════════════╝

STEP 1: Connect to Instance 1 (use any method above)

STEP 2: Verify EFS is mounted
──────────────────────────────
df -h | grep efs
ls -la /mnt/efs/

Expected output: Should show EFS mounted and mount-info files

STEP 3: Create test file on Instance 1
───────────────────────────────────────
echo "Hello from Instance 1 - \$(date)" | sudo tee /mnt/efs/test1.txt
sudo mkdir -p /mnt/efs/shared-data
echo "Shared content" | sudo tee /mnt/efs/shared-data/file.txt

STEP 4: Connect to Instance 2 (open new terminal/browser tab)

STEP 5: Verify shared storage on Instance 2
────────────────────────────────────────────
ls -la /mnt/efs/
cat /mnt/efs/test1.txt

Expected: You should see the file created from Instance 1!

STEP 6: Create file on Instance 2
──────────────────────────────────
echo "Hello from Instance 2 - \$(date)" | sudo tee /mnt/efs/test2.txt

STEP 7: Go back to Instance 1 and verify
─────────────────────────────────────────
cat /mnt/efs/test2.txt

Expected: You should see the file created from Instance 2!

🎉 If both instances can see each other's files, EFS is working!

╔════════════════════════════════════════════════════════════════╗
║                      TROUBLESHOOTING                           ║
╚════════════════════════════════════════════════════════════════╝

If EFS not mounted:
───────────────────
sudo cat /var/log/user-data.log
sudo mount -t efs $EFS_ID:/ /mnt/efs

Check mount status:
───────────────────
mountpoint /mnt/efs
df -h | grep efs

Manual mount command:
─────────────────────
sudo mount -t efs -o tls $EFS_ID:/ /mnt/efs

╔════════════════════════════════════════════════════════════════╗
║                         CLEANUP                                ║
╚════════════════════════════════════════════════════════════════╝

When done testing, run:
./cleanup-efs-lab.sh

This will delete all resources and stop AWS charges.

IMPORTANT: Don't forget to cleanup to avoid unnecessary costs!

EOF

cat lab-summary.txt

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${BLUE}📋 Summary saved to: lab-summary.txt${NC}"
echo -e "\n${GREEN}🚀 INSTANCES ARE READY FOR CONNECTION!${NC}"
echo -e "\n${YELLOW}Quick Start:${NC}"
echo -e "1. Go to EC2 Console → Select instance → Click 'Connect'"
echo -e "2. Or SSH: ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE1_IP"
echo -e "\n${YELLOW}⏱️  Note: User data script needs 1-2 more minutes to mount EFS${NC}"
echo -e "${YELLOW}Run './verify-setup.sh' to check if EFS is mounted${NC}"

# Create cleanup script
cat > cleanup-efs-lab.sh << CLEANUP_EOF
#!/bin/bash
echo "Cleaning up AWS EFS Lab resources..."

# Terminate EC2 instances
aws ec2 terminate-instances --instance-ids $INSTANCE1_ID $INSTANCE2_ID --region $REGION
echo "Waiting for instances to terminate..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE1_ID $INSTANCE2_ID --region $REGION

# Delete mount targets
aws efs delete-mount-target --mount-target-id $MOUNT_TARGET1_ID --region $REGION
aws efs delete-mount-target --mount-target-id $MOUNT_TARGET2_ID --region $REGION
echo "Waiting for mount targets to be deleted..."
sleep 45

# Delete EFS file system
aws efs delete-file-system --file-system-id $EFS_ID --region $REGION

# Delete security groups
sleep 10
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

echo "✓ Cleanup complete!"
CLEANUP_EOF

chmod +x cleanup-efs-lab.sh

echo -e "\n${GREEN}========================================${NC}"
