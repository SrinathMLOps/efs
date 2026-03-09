#!/bin/bash

#############################################
# AWS EFS Lab - Quick Connection Helper
# Provides easy commands to connect to instances
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "lab-summary.txt" ]; then
    echo -e "${RED}Error: lab-summary.txt not found. Run aws-efs-lab-setup.sh first.${NC}"
    exit 1
fi

INSTANCE1_IP=$(grep "Instance 1 IP:" lab-summary.txt | awk '{print $4}')
INSTANCE2_IP=$(grep "Instance 2 IP:" lab-summary.txt | awk '{print $4}')
INSTANCE1_ID=$(grep "Instance 1 ID:" lab-summary.txt | awk '{print $4}')
INSTANCE2_ID=$(grep "Instance 2 ID:" lab-summary.txt | awk '{print $4}')
KEY_FILE="efs-lab-key.pem"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AWS EFS Lab - Connection Helper${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Choose connection method:${NC}"
echo -e "1. SSH to Instance 1"
echo -e "2. SSH to Instance 2"
echo -e "3. Open Instance 1 in browser (EC2 Instance Connect)"
echo -e "4. Open Instance 2 in browser (EC2 Instance Connect)"
echo -e "5. Show connection commands"
echo -e "6. Exit"

read -p "Enter choice [1-6]: " choice

case $choice in
    1)
        echo -e "${GREEN}Connecting to Instance 1...${NC}"
        ssh -i $KEY_FILE ec2-user@$INSTANCE1_IP
        ;;
    2)
        echo -e "${GREEN}Connecting to Instance 2...${NC}"
        ssh -i $KEY_FILE ec2-user@$INSTANCE2_IP
        ;;
    3)
        echo -e "${GREEN}Opening Instance 1 in browser...${NC}"
        echo -e "Go to: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#ConnectToInstance:instanceId=$INSTANCE1_ID"
        ;;
    4)
        echo -e "${GREEN}Opening Instance 2 in browser...${NC}"
        echo -e "Go to: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#ConnectToInstance:instanceId=$INSTANCE2_ID"
        ;;
    5)
        echo -e "\n${GREEN}Connection Commands:${NC}"
        echo -e "\n${YELLOW}Instance 1:${NC}"
        echo -e "ssh -i $KEY_FILE ec2-user@$INSTANCE1_IP"
        echo -e "\n${YELLOW}Instance 2:${NC}"
        echo -e "ssh -i $KEY_FILE ec2-user@$INSTANCE2_IP"
        echo -e "\n${YELLOW}After connecting, verify EFS:${NC}"
        echo -e "df -h | grep efs"
        echo -e "ls -la /mnt/efs/"
        ;;
    6)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac
