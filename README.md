# AWS EFS Lab - Complete Automation

This script automates the entire AWS EFS lab setup from VPC creation to testing shared storage between EC2 instances.

## Prerequisites

1. AWS CLI installed and configured
2. AWS credentials with appropriate permissions
3. Bash shell (Linux/Mac/WSL)

## Quick Start

```bash
# Make script executable
chmod +x aws-efs-lab-setup.sh

# Run the setup
./aws-efs-lab-setup.sh
```

## What This Script Does

1. Creates VPC (10.0.0.0/16)
2. Creates 2 subnets in different AZs
3. Sets up Internet Gateway and routing
4. Creates security groups (EC2 and EFS)
5. Generates SSH key pair
6. Creates EFS file system with mount targets
7. Launches 2 EC2 instances with auto-mount configuration
8. Provides connection details and testing instructions

## Testing EFS Shared Storage

After setup completes (wait 2-3 minutes for instances to initialize):

### Connect to Instance 1
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE1_IP>
```

### Create test file
```bash
echo "Hello from Instance 1" | sudo tee /mnt/efs/test1.txt
ls -l /mnt/efs/
```

### Connect to Instance 2
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE2_IP>
```

### Verify shared storage
```bash
cat /mnt/efs/test1.txt  # Should show "Hello from Instance 1"
echo "Hello from Instance 2" | sudo tee /mnt/efs/test2.txt
```

### Back to Instance 1
```bash
cat /mnt/efs/test2.txt  # Should show "Hello from Instance 2"
```

## Cleanup

To delete all resources and avoid charges:

```bash
./cleanup-efs-lab.sh
```

## Architecture

```
VPC (10.0.0.0/16)
├── Subnet 1 (us-east-1a)
│   ├── EC2 Instance 1
│   └── EFS Mount Target 1
├── Subnet 2 (us-east-1b)
│   ├── EC2 Instance 2
│   └── EFS Mount Target 2
└── EFS File System (shared storage)
```

## Key Concepts Demonstrated

- VPC networking and subnets
- Multi-AZ deployment for high availability
- Security group configuration (SSH and NFS)
- EFS mount targets and NFS protocol
- Shared storage across multiple EC2 instances
- Persistent mounting via /etc/fstab

## Troubleshooting

If mount fails:
```bash
# Check if EFS utils are installed
rpm -qa | grep amazon-efs-utils

# Check mount status
df -h | grep efs

# Manual mount
sudo mount -t efs <EFS_ID>:/ /mnt/efs
```

## Cost Estimate

- 2 x t2.micro EC2: ~$0.02/hour
- EFS storage: ~$0.30/GB/month
- Data transfer: Minimal for testing

Remember to run cleanup script after testing!
