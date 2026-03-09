#!/bin/bash

#############################################
# AWS Account-Wide Resource Scanner
# Scans ALL regions for paid resources (NO deletion)
#############################################

set +e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        AWS Account-Wide Resource Scanner                       ║${NC}"
echo -e "${BLUE}║        (Read-only - No resources will be deleted)              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

# Get all regions
echo -e "\n${YELLOW}Fetching all AWS regions...${NC}"
REGIONS=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)
REGION_COUNT=$(echo $REGIONS | wc -w)
echo -e "${GREEN}✓ Found $REGION_COUNT regions${NC}"

TOTAL_RESOURCES=0
ESTIMATED_COST=0

# Create report file
REPORT_FILE="aws-resources-report-$(date +%Y%m%d-%H%M%S).txt"
echo "AWS Account Resource Scan Report" > $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "========================================" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Scan each region
for REGION in $REGIONS; do
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Region: $REGION${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    echo "" >> $REPORT_FILE
    echo "Region: $REGION" >> $REPORT_FILE
    echo "----------------------------------------" >> $REPORT_FILE
    
    REGION_RESOURCES=0
    
    # EC2 Instances
    echo -e "\n${YELLOW}EC2 Instances:${NC}"
    INSTANCES=$(aws ec2 describe-instances \
        --region $REGION \
        --filters "Name=instance-state-name,Values=running,stopped" \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$INSTANCES" ]; then
        INSTANCE_COUNT=$(echo "$INSTANCES" | wc -l)
        echo -e "${RED}  Found $INSTANCE_COUNT instances${NC}"
        echo "$INSTANCES" | while read line; do
            echo -e "  ${RED}→${NC} $line"
        done
        echo "EC2 Instances: $INSTANCE_COUNT" >> $REPORT_FILE
        echo "$INSTANCES" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + INSTANCE_COUNT))
        ESTIMATED_COST=$((ESTIMATED_COST + INSTANCE_COUNT * 10))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "EC2 Instances: 0" >> $REPORT_FILE
    fi
    
    # RDS Databases
    echo -e "\n${YELLOW}RDS Databases:${NC}"
    RDS=$(aws rds describe-db-instances \
        --region $REGION \
        --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$RDS" ]; then
        RDS_COUNT=$(echo "$RDS" | wc -l)
        echo -e "${RED}  Found $RDS_COUNT databases${NC}"
        echo "$RDS" | while read line; do
            echo -e "  ${RED}→${NC} $line"
        done
        echo "RDS Databases: $RDS_COUNT" >> $REPORT_FILE
        echo "$RDS" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + RDS_COUNT))
        ESTIMATED_COST=$((ESTIMATED_COST + RDS_COUNT * 50))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "RDS Databases: 0" >> $REPORT_FILE
    fi
    
    # EFS File Systems
    echo -e "\n${YELLOW}EFS File Systems:${NC}"
    EFS=$(aws efs describe-file-systems \
        --region $REGION \
        --query 'FileSystems[*].[FileSystemId,Name,SizeInBytes.Value,LifeCycleState]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$EFS" ]; then
        EFS_COUNT=$(echo "$EFS" | wc -l)
        echo -e "${RED}  Found $EFS_COUNT file systems${NC}"
        echo "$EFS" | while read line; do
            echo -e "  ${RED}→${NC} $line"
        done
        echo "EFS File Systems: $EFS_COUNT" >> $REPORT_FILE
        echo "$EFS" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + EFS_COUNT))
        ESTIMATED_COST=$((ESTIMATED_COST + EFS_COUNT * 5))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "EFS File Systems: 0" >> $REPORT_FILE
    fi
    
    # Load Balancers
    echo -e "\n${YELLOW}Load Balancers:${NC}"
    LBS=$(aws elbv2 describe-load-balancers \
        --region $REGION \
        --query 'LoadBalancers[*].[LoadBalancerName,Type,State.Code]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$LBS" ]; then
        LB_COUNT=$(echo "$LBS" | wc -l)
        echo -e "${RED}  Found $LB_COUNT load balancers${NC}"
        echo "$LBS" | while read line; do
            echo -e "  ${RED}→${NC} $line"
        done
        echo "Load Balancers: $LB_COUNT" >> $REPORT_FILE
        echo "$LBS" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + LB_COUNT))
        ESTIMATED_COST=$((ESTIMATED_COST + LB_COUNT * 20))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "Load Balancers: 0" >> $REPORT_FILE
    fi
    
    # NAT Gateways
    echo -e "\n${YELLOW}NAT Gateways:${NC}"
    NATS=$(aws ec2 describe-nat-gateways \
        --region $REGION \
        --filter "Name=state,Values=available" \
        --query 'NatGateways[*].[NatGatewayId,State,VpcId]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$NATS" ]; then
        NAT_COUNT=$(echo "$NATS" | wc -l)
        echo -e "${RED}  Found $NAT_COUNT NAT gateways${NC}"
        echo "$NATS" | while read line; do
            echo -e "  ${RED}→${NC} $line"
        done
        echo "NAT Gateways: $NAT_COUNT" >> $REPORT_FILE
        echo "$NATS" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + NAT_COUNT))
        ESTIMATED_COST=$((ESTIMATED_COST + NAT_COUNT * 35))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "NAT Gateways: 0" >> $REPORT_FILE
    fi
    
    # Elastic IPs
    echo -e "\n${YELLOW}Elastic IPs:${NC}"
    EIPS=$(aws ec2 describe-addresses \
        --region $REGION \
        --query 'Addresses[*].[AllocationId,PublicIp,AssociationId]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$EIPS" ]; then
        EIP_COUNT=$(echo "$EIPS" | wc -l)
        echo -e "${RED}  Found $EIP_COUNT Elastic IPs${NC}"
        echo "$EIPS" | while read line; do
            echo -e "  ${RED}→${NC} $line"
        done
        echo "Elastic IPs: $EIP_COUNT" >> $REPORT_FILE
        echo "$EIPS" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + EIP_COUNT))
        ESTIMATED_COST=$((ESTIMATED_COST + EIP_COUNT * 4))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "Elastic IPs: 0" >> $REPORT_FILE
    fi
    
    # Lambda Functions
    echo -e "\n${YELLOW}Lambda Functions:${NC}"
    LAMBDAS=$(aws lambda list-functions \
        --region $REGION \
        --query 'Functions[*].[FunctionName,Runtime,MemorySize]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$LAMBDAS" ]; then
        LAMBDA_COUNT=$(echo "$LAMBDAS" | wc -l)
        echo -e "${RED}  Found $LAMBDA_COUNT functions${NC}"
        echo "Lambda Functions: $LAMBDA_COUNT" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + LAMBDA_COUNT))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "Lambda Functions: 0" >> $REPORT_FILE
    fi
    
    # EBS Volumes
    echo -e "\n${YELLOW}EBS Volumes:${NC}"
    VOLUMES=$(aws ec2 describe-volumes \
        --region $REGION \
        --query 'Volumes[*].[VolumeId,Size,State,VolumeType]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$VOLUMES" ]; then
        VOLUME_COUNT=$(echo "$VOLUMES" | wc -l)
        echo -e "${RED}  Found $VOLUME_COUNT volumes${NC}"
        echo "EBS Volumes: $VOLUME_COUNT" >> $REPORT_FILE
        REGION_RESOURCES=$((REGION_RESOURCES + VOLUME_COUNT))
    else
        echo -e "${GREEN}  ✓ None${NC}"
        echo "EBS Volumes: 0" >> $REPORT_FILE
    fi
    
    TOTAL_RESOURCES=$((TOTAL_RESOURCES + REGION_RESOURCES))
    
    if [ $REGION_RESOURCES -eq 0 ]; then
        echo -e "\n${GREEN}Region $REGION: Clean ✓${NC}"
    else
        echo -e "\n${YELLOW}Region $REGION: $REGION_RESOURCES resources found${NC}"
    fi
done

# Final Report
echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    SCAN COMPLETE                               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}Summary:${NC}"
echo -e "${GREEN}✓ Scanned $REGION_COUNT regions${NC}"
echo -e "${GREEN}✓ Found $TOTAL_RESOURCES total resources${NC}"
echo -e "${GREEN}✓ Estimated monthly cost: ~\$$ESTIMATED_COST${NC}"

echo "" >> $REPORT_FILE
echo "========================================" >> $REPORT_FILE
echo "Total Resources: $TOTAL_RESOURCES" >> $REPORT_FILE
echo "Estimated Monthly Cost: ~\$$ESTIMATED_COST" >> $REPORT_FILE

echo -e "\n${GREEN}✓ Report saved to: $REPORT_FILE${NC}"

if [ $TOTAL_RESOURCES -gt 0 ]; then
    echo -e "\n${YELLOW}To delete all resources, run:${NC}"
    echo -e "${RED}  ./cleanup-all-regions.sh${NC}"
    echo -e "\n${YELLOW}⚠️  Review the report first!${NC}"
else
    echo -e "\n${GREEN}✓ Your AWS account is clean!${NC}"
fi

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
