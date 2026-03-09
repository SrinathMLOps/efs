# AWS EFS Lab - Complete Automation

This script automates the entire AWS EFS lab setup from VPC creation to testing shared storage between EC2 instances.

## Prerequisites

1. AWS CLI installed and configured
2. AWS credentials with appropriate permissions
3. Bash shell (Linux/Mac/WSL)

## Quick Start

**STEP 1: Cleanup any existing resources**
```bash
chmod +x cleanup-all-efs-resources.sh
./cleanup-all-efs-resources.sh
```

**STEP 2: Run the setup**
```bash
chmod +x aws-efs-lab-setup-v2.sh
./aws-efs-lab-setup-v2.sh
```

**STEP 3: Verify setup**
```bash
chmod +x verify-setup.sh
./verify-setup.sh
```

**STEP 4: Connect to instances**
```bash
chmod +x connect-instances.sh
./connect-instances.sh
```

Or use EC2 Instance Connect in browser (easiest method)

## Available Scripts

- `cleanup-all-efs-resources.sh` - Delete ALL existing EFS lab resources (run first)
- `aws-efs-lab-setup-v2.sh` - Main setup script (improved version)
- `aws-efs-lab-setup.sh` - Original setup script (legacy)
- `verify-setup.sh` - Check if resources are ready
- `connect-instances.sh` - Interactive connection helper
- `cleanup-efs-lab.sh` - Generated after setup to cleanup specific resources

## What This Script Does

1. Creates VPC (10.0.0.0/16) with DNS hostnames enabled
2. Creates 2 subnets in different AZs (us-east-1a, us-east-1b)
3. Sets up Internet Gateway and routing
4. Creates security groups:
   - EC2 SG: Allows SSH from your IP + EC2 Instance Connect
   - EFS SG: Allows NFS (port 2049) from EC2 instances
5. Generates SSH key pair
6. Creates EFS file system with mount targets in both AZs
7. Launches 2 EC2 instances with auto-mount configuration
8. Waits for instances to pass status checks (ready for SSH)
9. Provides connection details and testing instructions

**Key improvements**:
- Adds EC2 Instance Connect IP range to security group
- Waits for status checks to pass before completing
- Enhanced user data script with logging and retry logic
- Verification script to check setup status

## Testing EFS Shared Storage

The script waits for instances to be fully ready. After completion:

### Method 1: EC2 Instance Connect (Browser - Easiest)
1. Go to EC2 Console
2. Select "EFS-Lab-Instance-1"
3. Click **"Connect"** button
4. Choose **"EC2 Instance Connect"**
5. Click **"Connect"** (opens in browser)

### Method 2: SSH from Terminal
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE1_IP>
```

### Method 3: Use Helper Script
```bash
./connect-instances.sh
```

### Verify EFS Mount
```bash
# Check if EFS is mounted
df -h | grep efs

# List files
ls -la /mnt/efs/

# Check user data logs if issues
sudo cat /var/log/user-data.log
```

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

### "Failed to connect to your instance" Error

**Cause**: Instance still initializing or security group issue

**Solution**:
```bash
# Check if instances are ready
./verify-setup.sh

# If status checks not passed, wait 2 more minutes
```

### EFS Not Mounted

**Check mount status**:
```bash
df -h | grep efs
mountpoint /mnt/efs
```

**Manual mount**:
```bash
sudo mount -t efs <EFS_ID>:/ /mnt/efs
```

**Check logs**:
```bash
sudo cat /var/log/user-data.log
```

### Cannot SSH with Key

**Fix permissions**:
```bash
chmod 400 efs-lab-key.pem
```

**Verify key**:
```bash
ssh-keygen -l -f efs-lab-key.pem
```

## Cost Estimate

- 2 x t2.micro EC2: ~$0.02/hour
- EFS storage: ~$0.30/GB/month
- Data transfer: Minimal for testing

Remember to run cleanup script after testing!
