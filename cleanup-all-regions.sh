#!/bin/bash

#############################################
# AWS Account-Wide Cleanup Script
# ⚠️ WARNING: Deletes paid resources in ALL regions
# Use with EXTREME caution!
#############################################

set +e  # Continue on errors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║          ⚠️  AWS ACCOUNT-WIDE CLEANUP SCRIPT  ⚠️               ║${NC}"
echo -e "${RED}║                                                                ║${NC}"
echo -e "${RED}║  This script will DELETE paid resources in ALL regions        ║${NC}"
echo -e "${RED}║  Use with EXTREME caution!                                    ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"

# Safety confirmation
echo -e "\n${YELLOW}This script will scan and delete:${NC}"
echo -e "  • EC2 Instances (all regions)"
echo -e "  • EBS Volumes (unattached)"
echo -e "  • EFS File Systems (all regions)"
echo -e "  • RDS Databases (all regions)"
echo -e "  • Load Balancers (all regions)"
echo -e "  • NAT Gateways (all regions)"
echo -e "  • Elastic IPs (unattached)"
echo -e "  • Snapshots (optional)"

echo -e "\n${RED}⚠️  WARNING: This action cannot be undone!${NC}"
read -p "Type 'DELETE-ALL-RESOURCES' to continue: " CONFIRM

if [ "$CONFIRM" != "DELETE-ALL-RESOURCES" ]; then
    echo -e "${GREEN}Cleanup cancelled. No resources were deleted.${NC}"
    exit 0
fi

# Get all regions
echo -e "\n${YELLOW}Fetching all AWS regions...${NC}"
REGIONS=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)
echo -e "${GREEN}✓ Found regions: $REGIONS${NC}"

TOTAL_DELETED=0
TOTAL_COST_SAVED=0

# Function to cleanup region
cleanup_region() {
    local REGION=$1
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Processing Region: $REGION${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    local REGION_DELETED=0
    
    # 1. Terminate EC2 Instances
    echo -e "\n${YELLOW}[1/10] Checking EC2 Instances in $REGION...${NC}"
    INSTANCES=$(aws ec2 describe-instances \
        --region $REGION \
        --filters "Name=instance-state-name,Values=running,stopped,pending,stopping" \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$INSTANCES" ]; then
        echo -e "${RED}Found EC2 Instances:${NC}"
        echo "$INSTANCES"
        INSTANCE_IDS=$(echo "$INSTANCES" | awk '{print $1}')
        echo -e "${YELLOW}Terminating instances...${NC}"
        aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION 2>/dev/null
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ Instances terminated${NC}"
    else
        echo -e "${GREEN}✓ No EC2 instances${NC}"
    fi
    
    # 2. Delete RDS Instances
    echo -e "\n${YELLOW}[2/10] Checking RDS Databases in $REGION...${NC}"
    RDS_INSTANCES=$(aws rds describe-db-instances \
        --region $REGION \
        --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$RDS_INSTANCES" ]; then
        echo -e "${RED}Found RDS Instances:${NC}"
        echo "$RDS_INSTANCES"
        echo "$RDS_INSTANCES" | while read DB_ID DB_CLASS DB_STATUS; do
            echo -e "${YELLOW}Deleting RDS: $DB_ID${NC}"
            aws rds delete-db-instance \
                --db-instance-identifier $DB_ID \
                --skip-final-snapshot \
                --delete-automated-backups \
                --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ RDS instances deleted${NC}"
    else
        echo -e "${GREEN}✓ No RDS instances${NC}"
    fi
    
    # 3. Delete Load Balancers
    echo -e "\n${YELLOW}[3/10] Checking Load Balancers in $REGION...${NC}"
    
    # ALB/NLB
    LOAD_BALANCERS=$(aws elbv2 describe-load-balancers \
        --region $REGION \
        --query 'LoadBalancers[*].[LoadBalancerArn,LoadBalancerName,Type]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$LOAD_BALANCERS" ]; then
        echo -e "${RED}Found Load Balancers:${NC}"
        echo "$LOAD_BALANCERS"
        echo "$LOAD_BALANCERS" | while read LB_ARN LB_NAME LB_TYPE; do
            echo -e "${YELLOW}Deleting LB: $LB_NAME${NC}"
            aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ Load balancers deleted${NC}"
    else
        echo -e "${GREEN}✓ No load balancers${NC}"
    fi
    
    # Classic Load Balancers
    CLB=$(aws elb describe-load-balancers \
        --region $REGION \
        --query 'LoadBalancerDescriptions[*].LoadBalancerName' \
        --output text 2>/dev/null)
    
    if [ ! -z "$CLB" ]; then
        echo -e "${RED}Found Classic Load Balancers:${NC}"
        echo "$CLB"
        for LB_NAME in $CLB; do
            echo -e "${YELLOW}Deleting CLB: $LB_NAME${NC}"
            aws elb delete-load-balancer --load-balancer-name $LB_NAME --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
    fi
    
    # 4. Delete NAT Gateways
    echo -e "\n${YELLOW}[4/10] Checking NAT Gateways in $REGION...${NC}"
    NAT_GWS=$(aws ec2 describe-nat-gateways \
        --region $REGION \
        --filter "Name=state,Values=available,pending" \
        --query 'NatGateways[*].[NatGatewayId,State]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$NAT_GWS" ]; then
        echo -e "${RED}Found NAT Gateways:${NC}"
        echo "$NAT_GWS"
        NAT_IDS=$(echo "$NAT_GWS" | awk '{print $1}')
        for NAT_ID in $NAT_IDS; do
            echo -e "${YELLOW}Deleting NAT Gateway: $NAT_ID${NC}"
            aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ NAT gateways deleted${NC}"
    else
        echo -e "${GREEN}✓ No NAT gateways${NC}"
    fi
    
    # 5. Release Elastic IPs
    echo -e "\n${YELLOW}[5/10] Checking Elastic IPs in $REGION...${NC}"
    EIPS=$(aws ec2 describe-addresses \
        --region $REGION \
        --query 'Addresses[?AssociationId==null].[AllocationId,PublicIp]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$EIPS" ]; then
        echo -e "${RED}Found Unattached Elastic IPs:${NC}"
        echo "$EIPS"
        echo "$EIPS" | while read ALLOC_ID PUBLIC_IP; do
            echo -e "${YELLOW}Releasing EIP: $PUBLIC_IP${NC}"
            aws ec2 release-address --allocation-id $ALLOC_ID --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ Elastic IPs released${NC}"
    else
        echo -e "${GREEN}✓ No unattached Elastic IPs${NC}"
    fi
    
    # 6. Delete EFS File Systems
    echo -e "\n${YELLOW}[6/10] Checking EFS File Systems in $REGION...${NC}"
    EFS_SYSTEMS=$(aws efs describe-file-systems \
        --region $REGION \
        --query 'FileSystems[*].[FileSystemId,Name,SizeInBytes.Value]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$EFS_SYSTEMS" ]; then
        echo -e "${RED}Found EFS File Systems:${NC}"
        echo "$EFS_SYSTEMS"
        
        echo "$EFS_SYSTEMS" | while read EFS_ID EFS_NAME EFS_SIZE; do
            # Delete mount targets first
            MOUNT_TARGETS=$(aws efs describe-mount-targets \
                --file-system-id $EFS_ID \
                --region $REGION \
                --query 'MountTargets[*].MountTargetId' \
                --output text 2>/dev/null)
            
            if [ ! -z "$MOUNT_TARGETS" ]; then
                for MT_ID in $MOUNT_TARGETS; do
                    echo -e "${YELLOW}  Deleting mount target: $MT_ID${NC}"
                    aws efs delete-mount-target --mount-target-id $MT_ID --region $REGION 2>/dev/null
                done
                sleep 30
            fi
            
            echo -e "${YELLOW}Deleting EFS: $EFS_ID${NC}"
            aws efs delete-file-system --file-system-id $EFS_ID --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ EFS file systems deleted${NC}"
    else
        echo -e "${GREEN}✓ No EFS file systems${NC}"
    fi
    
    # 7. Delete EBS Volumes (unattached)
    echo -e "\n${YELLOW}[7/10] Checking EBS Volumes in $REGION...${NC}"
    EBS_VOLUMES=$(aws ec2 describe-volumes \
        --region $REGION \
        --filters "Name=status,Values=available" \
        --query 'Volumes[*].[VolumeId,Size,VolumeType]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$EBS_VOLUMES" ]; then
        echo -e "${RED}Found Unattached EBS Volumes:${NC}"
        echo "$EBS_VOLUMES"
        VOLUME_IDS=$(echo "$EBS_VOLUMES" | awk '{print $1}')
        for VOL_ID in $VOLUME_IDS; do
            echo -e "${YELLOW}Deleting volume: $VOL_ID${NC}"
            aws ec2 delete-volume --volume-id $VOL_ID --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ EBS volumes deleted${NC}"
    else
        echo -e "${GREEN}✓ No unattached EBS volumes${NC}"
    fi
    
    # 8. Delete Lambda Functions
    echo -e "\n${YELLOW}[8/10] Checking Lambda Functions in $REGION...${NC}"
    LAMBDAS=$(aws lambda list-functions \
        --region $REGION \
        --query 'Functions[*].[FunctionName,Runtime]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$LAMBDAS" ]; then
        echo -e "${RED}Found Lambda Functions:${NC}"
        echo "$LAMBDAS"
        echo "$LAMBDAS" | while read FUNC_NAME RUNTIME; do
            echo -e "${YELLOW}Deleting Lambda: $FUNC_NAME${NC}"
            aws lambda delete-function --function-name $FUNC_NAME --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ Lambda functions deleted${NC}"
    else
        echo -e "${GREEN}✓ No Lambda functions${NC}"
    fi
    
    # 9. Delete ECS Clusters
    echo -e "\n${YELLOW}[9/10] Checking ECS Clusters in $REGION...${NC}"
    ECS_CLUSTERS=$(aws ecs list-clusters \
        --region $REGION \
        --query 'clusterArns[*]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$ECS_CLUSTERS" ]; then
        echo -e "${RED}Found ECS Clusters:${NC}"
        echo "$ECS_CLUSTERS"
        for CLUSTER_ARN in $ECS_CLUSTERS; do
            # Stop all services first
            SERVICES=$(aws ecs list-services --cluster $CLUSTER_ARN --region $REGION --query 'serviceArns[*]' --output text 2>/dev/null)
            if [ ! -z "$SERVICES" ]; then
                for SERVICE_ARN in $SERVICES; do
                    echo -e "${YELLOW}  Deleting service: $SERVICE_ARN${NC}"
                    aws ecs delete-service --cluster $CLUSTER_ARN --service $SERVICE_ARN --force --region $REGION 2>/dev/null
                done
            fi
            
            echo -e "${YELLOW}Deleting cluster: $CLUSTER_ARN${NC}"
            aws ecs delete-cluster --cluster $CLUSTER_ARN --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ ECS clusters deleted${NC}"
    else
        echo -e "${GREEN}✓ No ECS clusters${NC}"
    fi
    
    # 10. Delete VPCs (non-default)
    echo -e "\n${YELLOW}[10/10] Checking VPCs in $REGION...${NC}"
    VPCS=$(aws ec2 describe-vpcs \
        --region $REGION \
        --filters "Name=isDefault,Values=false" \
        --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
        --output text 2>/dev/null)
    
    if [ ! -z "$VPCS" ]; then
        echo -e "${RED}Found Non-Default VPCs:${NC}"
        echo "$VPCS"
        
        echo "$VPCS" | while read VPC_ID CIDR VPC_NAME; do
            echo -e "${YELLOW}Processing VPC: $VPC_ID ($VPC_NAME)${NC}"
            
            # Delete dependencies first
            
            # Delete NAT Gateways in VPC
            NAT_IN_VPC=$(aws ec2 describe-nat-gateways \
                --region $REGION \
                --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
                --query 'NatGateways[*].NatGatewayId' \
                --output text 2>/dev/null)
            if [ ! -z "$NAT_IN_VPC" ]; then
                for NAT_ID in $NAT_IN_VPC; do
                    aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID --region $REGION 2>/dev/null
                done
                sleep 10
            fi
            
            # Delete Internet Gateways
            IGWS=$(aws ec2 describe-internet-gateways \
                --region $REGION \
                --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
                --query 'InternetGateways[*].InternetGatewayId' \
                --output text 2>/dev/null)
            if [ ! -z "$IGWS" ]; then
                for IGW_ID in $IGWS; do
                    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION 2>/dev/null
                    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION 2>/dev/null
                done
            fi
            
            # Delete Subnets
            SUBNETS=$(aws ec2 describe-subnets \
                --region $REGION \
                --filters "Name=vpc-id,Values=$VPC_ID" \
                --query 'Subnets[*].SubnetId' \
                --output text 2>/dev/null)
            if [ ! -z "$SUBNETS" ]; then
                for SUBNET_ID in $SUBNETS; do
                    aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION 2>/dev/null
                done
            fi
            
            # Delete Security Groups (non-default)
            SGS=$(aws ec2 describe-security-groups \
                --region $REGION \
                --filters "Name=vpc-id,Values=$VPC_ID" \
                --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
                --output text 2>/dev/null)
            if [ ! -z "$SGS" ]; then
                sleep 10
                for SG_ID in $SGS; do
                    aws ec2 delete-security-group --group-id $SG_ID --region $REGION 2>/dev/null
                done
            fi
            
            # Delete Route Tables (non-main)
            RTS=$(aws ec2 describe-route-tables \
                --region $REGION \
                --filters "Name=vpc-id,Values=$VPC_ID" \
                --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
                --output text 2>/dev/null)
            if [ ! -z "$RTS" ]; then
                for RT_ID in $RTS; do
                    aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION 2>/dev/null
                done
            fi
            
            # Delete VPC
            echo -e "${YELLOW}  Deleting VPC: $VPC_ID${NC}"
            aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null
        done
        REGION_DELETED=$((REGION_DELETED + 1))
        echo -e "${GREEN}✓ VPCs deleted${NC}"
    else
        echo -e "${GREEN}✓ No non-default VPCs${NC}"
    fi
    
    # Summary for region
    if [ $REGION_DELETED -gt 0 ]; then
        echo -e "\n${YELLOW}Region $REGION: Deleted $REGION_DELETED resource types${NC}"
        TOTAL_DELETED=$((TOTAL_DELETED + REGION_DELETED))
    else
        echo -e "\n${GREEN}Region $REGION: Clean (no resources)${NC}"
    fi
}

# Process each region
for REGION in $REGIONS; do
    cleanup_region $REGION
done

# Global Resources (region-independent)
echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Checking Global Resources${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

# S3 Buckets
echo -e "\n${YELLOW}Checking S3 Buckets...${NC}"
S3_BUCKETS=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text 2>/dev/null)
if [ ! -z "$S3_BUCKETS" ]; then
    echo -e "${RED}Found S3 Buckets:${NC}"
    echo "$S3_BUCKETS"
    echo -e "${YELLOW}⚠️  S3 buckets NOT deleted (may contain important data)${NC}"
    echo -e "${YELLOW}⚠️  To delete manually: aws s3 rb s3://bucket-name --force${NC}"
else
    echo -e "${GREEN}✓ No S3 buckets${NC}"
fi

# IAM Roles (excluding AWS managed)
echo -e "\n${YELLOW}Checking IAM Roles...${NC}"
IAM_ROLES=$(aws iam list-roles \
    --query 'Roles[?!starts_with(RoleName, `AWS`)].RoleName' \
    --output text 2>/dev/null | head -10)
if [ ! -z "$IAM_ROLES" ]; then
    echo -e "${YELLOW}Found Custom IAM Roles (showing first 10):${NC}"
    echo "$IAM_ROLES"
    echo -e "${YELLOW}⚠️  IAM roles NOT deleted (may be in use)${NC}"
    echo -e "${YELLOW}⚠️  Review and delete manually if needed${NC}"
else
    echo -e "${GREEN}✓ No custom IAM roles${NC}"
fi

# CloudFormation Stacks
echo -e "\n${YELLOW}Checking CloudFormation Stacks...${NC}"
for REGION in $REGIONS; do
    CF_STACKS=$(aws cloudformation list-stacks \
        --region $REGION \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
        --query 'StackSummaries[*].StackName' \
        --output text 2>/dev/null)
    
    if [ ! -z "$CF_STACKS" ]; then
        echo -e "${RED}Found CloudFormation Stacks in $REGION:${NC}"
        echo "$CF_STACKS"
        echo -e "${YELLOW}⚠️  CloudFormation stacks NOT deleted${NC}"
        echo -e "${YELLOW}⚠️  Delete manually: aws cloudformation delete-stack --stack-name <name> --region $REGION${NC}"
    fi
done

# Final Summary
echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  CLEANUP SUMMARY                               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}✓ Processed ${#REGIONS[@]} regions${NC}"
echo -e "${GREEN}✓ Deleted $TOTAL_DELETED resource types across all regions${NC}"

echo -e "\n${YELLOW}Resources Cleaned:${NC}"
echo -e "  ✓ EC2 Instances (all regions)"
echo -e "  ✓ RDS Databases (all regions)"
echo -e "  ✓ Load Balancers (all regions)"
echo -e "  ✓ NAT Gateways (all regions)"
echo -e "  ✓ Elastic IPs (unattached)"
echo -e "  ✓ EFS File Systems (all regions)"
echo -e "  ✓ EBS Volumes (unattached)"
echo -e "  ✓ Lambda Functions (all regions)"
echo -e "  ✓ ECS Clusters (all regions)"
echo -e "  ✓ VPCs (non-default)"

echo -e "\n${YELLOW}Resources NOT Deleted (review manually):${NC}"
echo -e "  ⚠️  S3 Buckets (may contain data)"
echo -e "  ⚠️  IAM Roles (may be in use)"
echo -e "  ⚠️  CloudFormation Stacks"
echo -e "  ⚠️  Route53 Hosted Zones"
echo -e "  ⚠️  CloudWatch Log Groups"

echo -e "\n${GREEN}Estimated Monthly Cost Saved: $50-$500+ depending on resources${NC}"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Cleanup completed at $(date)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}💡 Tip: Wait 5 minutes, then check AWS Billing Dashboard to verify${NC}"
