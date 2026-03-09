#!/bin/bash

#############################################
# AWS Region Checker
# Detects and displays current AWS region
#############################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   AWS Region Detection${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# Method 1: AWS CLI configuration
echo -e "\n${YELLOW}Method 1: AWS CLI Configuration${NC}"
CLI_REGION=$(aws configure get region 2>/dev/null)
if [ ! -z "$CLI_REGION" ]; then
    echo -e "${GREEN}✓ CLI Region: $CLI_REGION${NC}"
else
    echo -e "${YELLOW}⚠ No region configured in AWS CLI${NC}"
fi

# Method 2: Environment Variable
echo -e "\n${YELLOW}Method 2: Environment Variable${NC}"
if [ ! -z "$AWS_DEFAULT_REGION" ]; then
    echo -e "${GREEN}✓ AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION${NC}"
else
    echo -e "${YELLOW}⚠ AWS_DEFAULT_REGION not set${NC}"
fi

# Method 3: EC2 Metadata (if running on EC2/CloudShell)
echo -e "\n${YELLOW}Method 3: EC2 Metadata Service${NC}"
METADATA_REGION=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)
if [ ! -z "$METADATA_REGION" ]; then
    echo -e "${GREEN}✓ Metadata Region: $METADATA_REGION${NC}"
else
    echo -e "${YELLOW}⚠ Not running on EC2/CloudShell${NC}"
fi

# Method 4: Query AWS
echo -e "\n${YELLOW}Method 4: AWS API Query${NC}"
API_REGION=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].RegionName' --output text 2>/dev/null)
if [ ! -z "$API_REGION" ] && [ "$API_REGION" != "None" ]; then
    echo -e "${GREEN}✓ API Region: $API_REGION${NC}"
else
    echo -e "${YELLOW}⚠ Could not query AWS API${NC}"
fi

# Determine final region
FINAL_REGION=""
if [ ! -z "$CLI_REGION" ]; then
    FINAL_REGION=$CLI_REGION
elif [ ! -z "$METADATA_REGION" ]; then
    FINAL_REGION=$METADATA_REGION
elif [ ! -z "$AWS_DEFAULT_REGION" ]; then
    FINAL_REGION=$AWS_DEFAULT_REGION
elif [ ! -z "$API_REGION" ]; then
    FINAL_REGION=$API_REGION
else
    FINAL_REGION="us-east-1"
fi

# Display final result
echo -e "\n${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}Current AWS Region: ${YELLOW}$FINAL_REGION${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# Show region details
echo -e "\n${YELLOW}Region Details:${NC}"
REGION_NAME=$(aws ec2 describe-regions --region-names $FINAL_REGION --query 'Regions[0].RegionName' --output text 2>/dev/null)
if [ ! -z "$REGION_NAME" ] && [ "$REGION_NAME" != "None" ]; then
    echo -e "${GREEN}✓ Region Name: $REGION_NAME${NC}"
    
    # Get availability zones
    AZS=$(aws ec2 describe-availability-zones --region $FINAL_REGION --query 'AvailabilityZones[*].ZoneName' --output text 2>/dev/null)
    if [ ! -z "$AZS" ]; then
        echo -e "${GREEN}✓ Availability Zones:${NC}"
        for AZ in $AZS; do
            echo -e "  ${GREEN}→${NC} $AZ"
        done
    fi
fi

# Check if region is supported for EFS
echo -e "\n${YELLOW}Checking EFS availability in $FINAL_REGION...${NC}"
EFS_TEST=$(aws efs describe-file-systems --region $FINAL_REGION --query 'FileSystems[0].FileSystemId' --output text 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ EFS is available in this region${NC}"
else
    echo -e "${RED}✗ EFS may not be available in this region${NC}"
fi

# Export region for other scripts
echo -e "\n${YELLOW}To use this region in scripts:${NC}"
echo -e "${GREEN}export AWS_DEFAULT_REGION=$FINAL_REGION${NC}"

echo -e "\n${BLUE}════════════════════════════════════════${NC}"
