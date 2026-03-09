#!/bin/bash
set +e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect region
REGION=$(aws configure get region 2>/dev/null)
[ -z "$REGION" ] && REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)
[ -z "$REGION" ] && REGION="us-east-1"

echo -e "${RED}⚠️  DELETE ALL RESOURCES IN REGION: $REGION${NC}"
read -p "Type 'DELETE' to confirm: " CONFIRM
[ "$CONFIRM" != "DELETE" ] && echo "Cancelled" && exit 0

echo -e "${YELLOW}Deleting resources in $REGION...${NC}"

# Terminate EC2
INSTANCES=$(aws ec2 describe-instances --region $REGION --filters "Name=instance-state-name,Values=running,stopped,pending" --query 'Reservations[*].Instances[*].InstanceId' --output text)
[ ! -z "$INSTANCES" ] && aws ec2 terminate-instances --instance-ids $INSTANCES --region $REGION && echo -e "${GREEN}✓ EC2 terminated${NC}"

# Delete RDS
RDS=$(aws rds describe-db-instances --region $REGION --query 'DBInstances[*].DBInstanceIdentifier' --output text)
if [ ! -z "$RDS" ]; then
    for DB in $RDS; do
        aws rds delete-db-instance --db-instance-identifier $DB --skip-final-snapshot --region $REGION 2>/dev/null
    done
    echo -e "${GREEN}✓ RDS deleted${NC}"
fi

# Delete Load Balancers
LBS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[*].LoadBalancerArn' --output text)
[ ! -z "$LBS" ] && for LB in $LBS; do aws elbv2 delete-load-balancer --load-balancer-arn $LB --region $REGION; done && echo -e "${GREEN}✓ LBs deleted${NC}"

# Delete NAT Gateways
NATS=$(aws ec2 describe-nat-gateways --region $REGION --filter "Name=state,Values=available" --query 'NatGateways[*].NatGatewayId' --output text)
[ ! -z "$NATS" ] && for NAT in $NATS; do aws ec2 delete-nat-gateway --nat-gateway-id $NAT --region $REGION; done && echo -e "${GREEN}✓ NAT GWs deleted${NC}"

# Release Elastic IPs
EIPS=$(aws ec2 describe-addresses --region $REGION --query 'Addresses[?AssociationId==null].AllocationId' --output text)
[ ! -z "$EIPS" ] && for EIP in $EIPS; do aws ec2 release-address --allocation-id $EIP --region $REGION; done && echo -e "${GREEN}✓ EIPs released${NC}"

# Delete EFS
sleep 30
EFS=$(aws efs describe-file-systems --region $REGION --query 'FileSystems[*].FileSystemId' --output text)
if [ ! -z "$EFS" ]; then
    for EFS_ID in $EFS; do
        MTS=$(aws efs describe-mount-targets --file-system-id $EFS_ID --region $REGION --query 'MountTargets[*].MountTargetId' --output text)
        [ ! -z "$MTS" ] && for MT in $MTS; do aws efs delete-mount-target --mount-target-id $MT --region $REGION; done
        sleep 45
        aws efs delete-file-system --file-system-id $EFS_ID --region $REGION
    done
    echo -e "${GREEN}✓ EFS deleted${NC}"
fi

# Delete EBS Volumes
VOLS=$(aws ec2 describe-volumes --region $REGION --filters "Name=status,Values=available" --query 'Volumes[*].VolumeId' --output text)
[ ! -z "$VOLS" ] && for VOL in $VOLS; do aws ec2 delete-volume --volume-id $VOL --region $REGION; done && echo -e "${GREEN}✓ EBS deleted${NC}"

# Delete Lambda
LAMBDAS=$(aws lambda list-functions --region $REGION --query 'Functions[*].FunctionName' --output text)
[ ! -z "$LAMBDAS" ] && for FUNC in $LAMBDAS; do aws lambda delete-function --function-name $FUNC --region $REGION; done && echo -e "${GREEN}✓ Lambdas deleted${NC}"

# Delete VPCs
sleep 20
VPCS=$(aws ec2 describe-vpcs --region $REGION --filters "Name=isDefault,Values=false" --query 'Vpcs[*].VpcId' --output text)
if [ ! -z "$VPCS" ]; then
    for VPC in $VPCS; do
        IGWS=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC" --query 'InternetGateways[*].InternetGatewayId' --output text)
        [ ! -z "$IGWS" ] && for IGW in $IGWS; do aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC --region $REGION; aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION; done
        
        SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC" --query 'Subnets[*].SubnetId' --output text)
        [ ! -z "$SUBNETS" ] && for SUBNET in $SUBNETS; do aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION 2>/dev/null; done
        
        sleep 10
        SGS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
        [ ! -z "$SGS" ] && for SG in $SGS; do aws ec2 delete-security-group --group-id $SG --region $REGION 2>/dev/null; done
        
        RTS=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text)
        [ ! -z "$RTS" ] && for RT in $RTS; do aws ec2 delete-route-table --route-table-id $RT --region $REGION 2>/dev/null; done
        
        aws ec2 delete-vpc --vpc-id $VPC --region $REGION 2>/dev/null
    done
    echo -e "${GREEN}✓ VPCs deleted${NC}"
fi

echo -e "\n${GREEN}✓ Cleanup complete for region: $REGION${NC}"
