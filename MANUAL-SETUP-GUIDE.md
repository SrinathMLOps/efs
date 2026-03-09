# AWS EFS Lab - Complete Manual Setup Guide

## Prerequisites
- AWS Account with appropriate permissions
- Access to AWS Console
- Basic understanding of networking concepts

---

## STEP 1: CREATE VPC

### Navigate to VPC Service
1. Open AWS Console
2. Search for "VPC" in the search bar
3. Click on "VPC" service

### Create VPC
1. Click **"Create VPC"** button
2. Select **"VPC only"**
3. Configure:
   - **Name tag**: `EFS-Lab-VPC`
   - **IPv4 CIDR block**: `10.0.0.0/16`
   - **IPv6 CIDR block**: No IPv6 CIDR block
   - **Tenancy**: Default
4. Click **"Create VPC"**
5. **Note down the VPC ID** (e.g., vpc-xxxxxxxxx)

### Enable DNS Hostnames
1. Select your newly created VPC
2. Click **"Actions"** → **"Edit VPC settings"**
3. Check **"Enable DNS hostnames"**
4. Click **"Save"**

**Why this matters**: DNS hostnames allow EC2 instances to resolve EFS DNS names

---

## STEP 2: CREATE INTERNET GATEWAY

### Create IGW
1. In VPC Dashboard, click **"Internet Gateways"** (left sidebar)
2. Click **"Create internet gateway"**
3. Configure:
   - **Name tag**: `EFS-Lab-IGW`
4. Click **"Create internet gateway"**
5. **Note down IGW ID**

### Attach IGW to VPC
1. Select the IGW you just created
2. Click **"Actions"** → **"Attach to VPC"**
3. Select **"EFS-Lab-VPC"**
4. Click **"Attach internet gateway"**

**Why this matters**: IGW allows EC2 instances to access the internet for updates and package installation

---

## STEP 3: CREATE SUBNETS

### Create Subnet 1
1. In VPC Dashboard, click **"Subnets"** (left sidebar)
2. Click **"Create subnet"**
3. Configure:
   - **VPC ID**: Select `EFS-Lab-VPC`
   - **Subnet name**: `EFS-Lab-Subnet-1`
   - **Availability Zone**: `us-east-1a`
   - **IPv4 CIDR block**: `10.0.1.0/24`
4. Click **"Create subnet"**
5. **Note down Subnet 1 ID**

### Create Subnet 2
1. Click **"Create subnet"** again
2. Configure:
   - **VPC ID**: Select `EFS-Lab-VPC`
   - **Subnet name**: `EFS-Lab-Subnet-2`
   - **Availability Zone**: `us-east-1b`
   - **IPv4 CIDR block**: `10.0.2.0/24`
3. Click **"Create subnet"**
4. **Note down Subnet 2 ID**

### Enable Auto-assign Public IP (for both subnets)
1. Select **Subnet 1**
2. Click **"Actions"** → **"Edit subnet settings"**
3. Check **"Enable auto-assign public IPv4 address"**
4. Click **"Save"**
5. **Repeat for Subnet 2**

**Why this matters**: Public IPs allow you to SSH into EC2 instances from your laptop

---

## STEP 4: CREATE ROUTE TABLE

### Create Route Table
1. In VPC Dashboard, click **"Route Tables"** (left sidebar)
2. Click **"Create route table"**
3. Configure:
   - **Name**: `EFS-Lab-RT`
   - **VPC**: Select `EFS-Lab-VPC`
4. Click **"Create route table"**
5. **Note down Route Table ID**

### Add Internet Route
1. Select your route table
2. Click **"Routes"** tab (bottom panel)
3. Click **"Edit routes"**
4. Click **"Add route"**
5. Configure:
   - **Destination**: `0.0.0.0/0`
   - **Target**: Select "Internet Gateway" → Select your `EFS-Lab-IGW`
6. Click **"Save changes"**

### Associate Subnets
1. Click **"Subnet associations"** tab
2. Click **"Edit subnet associations"**
3. Select **both subnets** (Subnet-1 and Subnet-2)
4. Click **"Save associations"**

**Why this matters**: Route table directs traffic from subnets to the internet via IGW

---

## STEP 5: CREATE SECURITY GROUPS

### Create EC2 Security Group
1. In VPC Dashboard, click **"Security Groups"** (left sidebar)
2. Click **"Create security group"**
3. Configure:
   - **Security group name**: `EFS-Lab-EC2-SG`
   - **Description**: `Security group for EC2 instances`
   - **VPC**: Select `EFS-Lab-VPC`

4. **Inbound rules** - Click "Add rule":
   - **Type**: SSH
   - **Protocol**: TCP
   - **Port**: 22
   - **Source**: My IP (automatically detects your IP)
   - **Description**: `SSH from my laptop`

5. **Outbound rules**: Leave default (All traffic allowed)
6. Click **"Create security group"**
7. **Note down EC2 Security Group ID** (sg-xxxxxxxxx)

### Create EFS Security Group
1. Click **"Create security group"** again
2. Configure:
   - **Security group name**: `EFS-Lab-EFS-SG`
   - **Description**: `Security group for EFS file system`
   - **VPC**: Select `EFS-Lab-VPC`

3. **Inbound rules** - Click "Add rule":
   - **Type**: NFS
   - **Protocol**: TCP
   - **Port**: 2049
   - **Source**: Custom → Select `EFS-Lab-EC2-SG` (type "sg-" to search)
   - **Description**: `NFS from EC2 instances`

4. **Outbound rules**: Leave default
5. Click **"Create security group"**
6. **Note down EFS Security Group ID**

**Why this matters**: 
- EC2 SG allows SSH access from your laptop
- EFS SG allows NFS traffic (port 2049) only from EC2 instances
- This creates secure communication between EC2 and EFS

---

## STEP 6: CREATE KEY PAIR

1. In EC2 Dashboard, click **"Key Pairs"** (left sidebar under Network & Security)
2. Click **"Create key pair"**
3. Configure:
   - **Name**: `efs-lab-key`
   - **Key pair type**: RSA
   - **Private key file format**: `.pem` (for SSH)
4. Click **"Create key pair"**
5. **Save the downloaded .pem file** securely
6. **Set permissions** (if using Linux/Mac):
   ```bash
   chmod 400 efs-lab-key.pem
   ```

**Why this matters**: Key pair is required to SSH into EC2 instances securely

---

## STEP 7: CREATE EFS FILE SYSTEM

### Navigate to EFS Service
1. Search for "EFS" in AWS Console
2. Click on "EFS" service

### Create File System
1. Click **"Create file system"**
2. Click **"Customize"** (don't use quick create)

### File System Settings (Page 1)
1. Configure:
   - **Name**: `EFS-Lab-FileSystem`
   - **Storage class**: Standard
   - **Automatic backups**: Disabled (for lab purposes)
   - **Lifecycle management**: None
   - **Performance mode**: General Purpose
   - **Throughput mode**: Bursting
   - **Encryption**: Enable encryption at rest (recommended)
2. Click **"Next"**

### Network Settings (Page 2)
1. **VPC**: Select `EFS-Lab-VPC`
2. **Mount targets**:
   
   **Mount Target 1:**
   - **Availability zone**: us-east-1a
   - **Subnet ID**: Select `EFS-Lab-Subnet-1`
   - **Security groups**: Remove default, add `EFS-Lab-EFS-SG`
   
   **Mount Target 2:**
   - **Availability zone**: us-east-1b
   - **Subnet ID**: Select `EFS-Lab-Subnet-2`
   - **Security groups**: Remove default, add `EFS-Lab-EFS-SG`

3. Click **"Next"**

### File System Policy (Page 3)
1. Leave as default (no policy)
2. Click **"Next"**

### Review and Create (Page 4)
1. Review all settings
2. Click **"Create"**
3. **Note down EFS File System ID** (fs-xxxxxxxxx)

**Wait 2-3 minutes** for EFS to become "Available"

**Why mount targets matter**: Each AZ needs a mount target so EC2 instances in that AZ can connect to EFS locally (low latency)

---

## STEP 8: LAUNCH EC2 INSTANCE 1

### Navigate to EC2
1. Search for "EC2" in AWS Console
2. Click **"Instances"** (left sidebar)
3. Click **"Launch instances"**

### Configure Instance 1
1. **Name**: `EFS-Lab-Instance-1`

2. **Application and OS Images (AMI)**:
   - Select **"Amazon Linux 2023 AMI"**
   - Architecture: 64-bit (x86)

3. **Instance type**: `t2.micro` (free tier eligible)

4. **Key pair**: Select `efs-lab-key`

5. **Network settings** - Click "Edit":
   - **VPC**: Select `EFS-Lab-VPC`
   - **Subnet**: Select `EFS-Lab-Subnet-1` (us-east-1a)
   - **Auto-assign public IP**: Enable
   - **Firewall (security groups)**: Select existing → `EFS-Lab-EC2-SG`

6. **Configure storage**: Leave default (8 GB gp3)

7. **Advanced details** - Expand this section:
   - Scroll down to **"User data"** text box
   - Paste this script:

```bash
#!/bin/bash
yum update -y
yum install -y amazon-efs-utils nfs-utils
mkdir -p /mnt/efs
echo "fs-xxxxxxxxx:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 /mnt/efs
echo "Instance 1 mounted EFS at $(date)" > /mnt/efs/instance1-info.txt
```

**IMPORTANT**: Replace `fs-xxxxxxxxx` with your actual EFS ID from Step 7

8. Click **"Launch instance"**
9. **Note down Instance 1 ID and wait for it to be "Running"**

---

## STEP 9: LAUNCH EC2 INSTANCE 2

### Launch Second Instance
1. Click **"Launch instances"** again
2. **Name**: `EFS-Lab-Instance-2`

3. **Application and OS Images (AMI)**:
   - Select **"Amazon Linux 2023 AMI"**

4. **Instance type**: `t2.micro`

5. **Key pair**: Select `efs-lab-key`

6. **Network settings** - Click "Edit":
   - **VPC**: Select `EFS-Lab-VPC`
   - **Subnet**: Select `EFS-Lab-Subnet-2` (us-east-1b)
   - **Auto-assign public IP**: Enable
   - **Firewall (security groups)**: Select existing → `EFS-Lab-EC2-SG`

7. **Configure storage**: Leave default

8. **Advanced details** → **"User data"**:

```bash
#!/bin/bash
yum update -y
yum install -y amazon-efs-utils nfs-utils
mkdir -p /mnt/efs
echo "fs-xxxxxxxxx:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 /mnt/efs
echo "Instance 2 mounted EFS at $(date)" > /mnt/efs/instance2-info.txt
```

**IMPORTANT**: Replace `fs-xxxxxxxxx` with your actual EFS ID

9. Click **"Launch instance"**
10. **Wait for both instances to be "Running" and pass status checks (2/2)**

---

## STEP 10: GET EC2 PUBLIC IPs

1. Go to **EC2 Dashboard** → **"Instances"**
2. Select **Instance 1**
3. Copy the **"Public IPv4 address"** (e.g., 54.123.45.67)
4. Select **Instance 2**
5. Copy the **"Public IPv4 address"**

**Note these IPs down** - you'll need them for SSH

---

## STEP 11: CONNECT TO INSTANCE 1

### Using SSH (Linux/Mac/Windows WSL)
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE1_PUBLIC_IP>
```

### Using Windows PowerShell
```powershell
ssh -i efs-lab-key.pem ec2-user@<INSTANCE1_PUBLIC_IP>
```

### Using AWS Console (EC2 Instance Connect)
1. Select Instance 1
2. Click **"Connect"** button
3. Choose **"EC2 Instance Connect"**
4. Click **"Connect"**

**First time connection**: Type `yes` when asked about host authenticity

---

## STEP 12: VERIFY EFS MOUNT ON INSTANCE 1

### Check if EFS is mounted
```bash
df -h | grep efs
```

**Expected output**:
```
fs-xxxxxxxxx.efs.us-east-1.amazonaws.com:/  8.0E     0  8.0E   0% /mnt/efs
```

### Check mount directory
```bash
ls -la /mnt/efs/
```

**Expected output**: Should show `instance1-info.txt` file

### View the file
```bash
cat /mnt/efs/instance1-info.txt
```

**Why this works**: User data script automatically mounted EFS during boot

---

## STEP 13: CREATE TEST FILE ON INSTANCE 1

### Create a test file
```bash
echo "Hello from Instance 1 - $(date)" | sudo tee /mnt/efs/test-from-instance1.txt
```

### Create a directory
```bash
sudo mkdir -p /mnt/efs/shared-data
```

### Create multiple files
```bash
echo "File 1 content" | sudo tee /mnt/efs/shared-data/file1.txt
echo "File 2 content" | sudo tee /mnt/efs/shared-data/file2.txt
echo "File 3 content" | sudo tee /mnt/efs/shared-data/file3.txt
```

### List all files
```bash
ls -lR /mnt/efs/
```

**What you're doing**: Writing data to EFS network storage from Instance 1

---

## STEP 14: CONNECT TO INSTANCE 2

### Open a NEW terminal/session
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE2_PUBLIC_IP>
```

**Or use EC2 Instance Connect** from AWS Console

---

## STEP 15: VERIFY SHARED STORAGE ON INSTANCE 2

### Check EFS mount
```bash
df -h | grep efs
```

### List files in EFS
```bash
ls -lR /mnt/efs/
```

**Expected output**: You should see ALL files created from Instance 1:
- `instance1-info.txt`
- `instance2-info.txt`
- `test-from-instance1.txt`
- `shared-data/` directory with file1.txt, file2.txt, file3.txt

### Read the file created from Instance 1
```bash
cat /mnt/efs/test-from-instance1.txt
```

**Expected output**: `Hello from Instance 1 - [timestamp]`

**🎉 SUCCESS**: If you can see files from Instance 1, EFS shared storage is working!

---

## STEP 16: CREATE TEST FILE ON INSTANCE 2

### Create test file
```bash
echo "Hello from Instance 2 - $(date)" | sudo tee /mnt/efs/test-from-instance2.txt
```

### Create more files
```bash
echo "Instance 2 data" | sudo tee /mnt/efs/shared-data/file-from-instance2.txt
```

### List all files
```bash
ls -lR /mnt/efs/
```

---

## STEP 17: VERIFY ON INSTANCE 1

### Go back to Instance 1 terminal

### List files
```bash
ls -lR /mnt/efs/
```

### Read file created from Instance 2
```bash
cat /mnt/efs/test-from-instance2.txt
```

**Expected output**: `Hello from Instance 2 - [timestamp]`

### Read the new file
```bash
cat /mnt/efs/shared-data/file-from-instance2.txt
```

**🎉 SUCCESS**: Both instances can read and write to the same shared storage!

---

## STEP 18: VERIFY PERSISTENT MOUNT

### Check /etc/fstab
```bash
cat /etc/fstab
```

**Expected output**: Should contain line like:
```
fs-xxxxxxxxx:/ /mnt/efs efs defaults,_netdev 0 0
```

### Test reboot persistence (Optional)
```bash
sudo reboot
```

**Wait 1-2 minutes**, then SSH back in:
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE_IP>
```

### Verify mount after reboot
```bash
df -h | grep efs
ls /mnt/efs/
```

**Why this matters**: /etc/fstab ensures EFS mounts automatically after reboot

---

## STEP 19: ADVANCED TESTING (OPTIONAL)

### Test concurrent writes
**On Instance 1**:
```bash
for i in {1..10}; do echo "Instance1-$i" | sudo tee /mnt/efs/concurrent-test-$i.txt; done
```

**On Instance 2**:
```bash
for i in {11..20}; do echo "Instance2-$i" | sudo tee /mnt/efs/concurrent-test-$i.txt; done
```

**On both instances**:
```bash
ls /mnt/efs/ | grep concurrent
```

### Test file locking
**On Instance 1**:
```bash
echo "Initial content" | sudo tee /mnt/efs/lock-test.txt
```

**On both instances simultaneously**:
```bash
sudo nano /mnt/efs/lock-test.txt
```

Try editing from both - NFS handles file locking

### Check EFS performance
```bash
sudo dd if=/dev/zero of=/mnt/efs/testfile bs=1M count=100
```

This writes 100MB file to test throughput

---

## STEP 20: MONITOR EFS METRICS

### View EFS Metrics in Console
1. Go to **EFS Console**
2. Select your file system
3. Click **"Monitoring"** tab
4. View metrics:
   - **Total storage**: How much data is stored
   - **Metered IO**: Read/write operations
   - **Throughput**: Data transfer rate
   - **Connections**: Number of connected clients

### Check from CLI
```bash
# On EC2 instance
df -h /mnt/efs/
du -sh /mnt/efs/*
```

---

## STEP 21: UNDERSTANDING EFS PRICING

### What you're charged for:
1. **Storage**: $0.30 per GB-month (Standard class)
2. **Data transfer**: Free within same AZ
3. **Requests**: Included in storage price

### Check current usage:
```bash
du -sh /mnt/efs/
```

**Lab cost estimate**: Less than $0.10 if cleaned up within a few hours

---

## STEP 22: CLEANUP (IMPORTANT!)

### Delete in this exact order to avoid dependency errors:

### 1. Terminate EC2 Instances
1. Go to **EC2 Console** → **"Instances"**
2. Select **both instances**
3. Click **"Instance state"** → **"Terminate instance"**
4. Confirm termination
5. **Wait until state shows "Terminated"**

### 2. Delete EFS Mount Targets
1. Go to **EFS Console**
2. Select your file system
3. Click **"Network"** tab
4. For each mount target:
   - Click **"Manage"**
   - Click **"Remove"** for each mount target
   - Click **"Save"**
5. **Wait 2-3 minutes** for mount targets to be deleted

### 3. Delete EFS File System
1. Select your file system
2. Click **"Delete"**
3. Type the file system ID to confirm
4. Click **"Confirm"**

### 4. Delete Security Groups
1. Go to **VPC Console** → **"Security Groups"**
2. Select `EFS-Lab-EFS-SG`
3. Click **"Actions"** → **"Delete security groups"**
4. Confirm deletion
5. Select `EFS-Lab-EC2-SG`
6. Click **"Actions"** → **"Delete security groups"**
7. Confirm deletion

### 5. Delete Subnets
1. Go to **"Subnets"**
2. Select **both subnets**
3. Click **"Actions"** → **"Delete subnet"**
4. Confirm deletion

### 6. Detach and Delete Internet Gateway
1. Go to **"Internet Gateways"**
2. Select your IGW
3. Click **"Actions"** → **"Detach from VPC"**
4. Confirm detachment
5. Click **"Actions"** → **"Delete internet gateway"**
6. Confirm deletion

### 7. Delete Route Table
1. Go to **"Route Tables"**
2. Select `EFS-Lab-RT`
3. Click **"Actions"** → **"Delete route table"**
4. Confirm deletion

### 8. Delete VPC
1. Go to **"Your VPCs"**
2. Select `EFS-Lab-VPC`
3. Click **"Actions"** → **"Delete VPC"**
4. Confirm deletion

### 9. Delete Key Pair
1. Go to **EC2 Console** → **"Key Pairs"**
2. Select `efs-lab-key`
3. Click **"Actions"** → **"Delete"**
4. Confirm deletion
5. **Delete the .pem file from your computer**

---

## TROUBLESHOOTING

### Issue: Cannot SSH to EC2
**Solution**:
- Check security group allows SSH from your IP
- Verify instance has public IP
- Check key pair permissions: `chmod 400 efs-lab-key.pem`

### Issue: EFS not mounted
**Solution**:
```bash
# Check if mount target is available
sudo mount -t efs fs-xxxxxxxxx:/ /mnt/efs

# Check security group allows NFS (port 2049)
# Verify EFS security group has inbound rule from EC2 SG
```

### Issue: Permission denied on /mnt/efs
**Solution**:
```bash
sudo chmod 777 /mnt/efs
```

### Issue: Mount target creation failed
**Solution**:
- Ensure subnets are in different AZs
- Check EFS security group is correctly configured
- Wait a few minutes and try again

---

## PRODUCTION BEST PRACTICES

### 1. Multi-AZ Deployment
- Always create mount targets in multiple AZs
- Ensures high availability if one AZ fails

### 2. Security
- Use private subnets for production
- Restrict security groups to specific CIDR ranges
- Enable encryption at rest and in transit

### 3. Performance
- Use **Max I/O** mode for high-throughput workloads
- Use **Provisioned Throughput** for consistent performance
- Enable **Lifecycle Management** to move old files to IA storage class

### 4. Backup
- Enable automatic backups
- Use AWS Backup for centralized backup management

### 5. Monitoring
- Set CloudWatch alarms for:
  - Storage usage
  - Throughput limits
  - Connection count

---

## INTERVIEW QUESTIONS & ANSWERS

**Q: Why use EFS instead of EBS?**
A: EBS is block storage attached to one EC2 instance. EFS is network file storage shared across multiple instances, perfect for shared application data, content management, and container storage.

**Q: What is the difference between mount targets?**
A: Mount targets are network endpoints in each AZ. They allow EC2 instances to connect to EFS locally within their AZ for low latency and high availability.

**Q: Why port 2049?**
A: Port 2049 is the standard port for NFS (Network File System) protocol, which EFS uses for file sharing.

**Q: Can EFS work across regions?**
A: No, EFS is regional. But you can use AWS DataSync or EFS-to-EFS replication for cross-region scenarios.

**Q: What happens if one AZ fails?**
A: EC2 instances in other AZs continue accessing EFS through their local mount targets. This is why multi-AZ deployment is critical.

---

## SUMMARY CHECKLIST

- [ ] VPC created with DNS hostnames enabled
- [ ] Internet Gateway attached to VPC
- [ ] 2 Subnets created in different AZs
- [ ] Route table configured with internet route
- [ ] EC2 Security Group allows SSH (port 22)
- [ ] EFS Security Group allows NFS (port 2049) from EC2 SG
- [ ] Key pair created and downloaded
- [ ] EFS file system created
- [ ] 2 Mount targets created (one per AZ)
- [ ] 2 EC2 instances launched with user data
- [ ] SSH connection successful to both instances
- [ ] EFS mounted on both instances
- [ ] Files created on Instance 1 visible on Instance 2
- [ ] Files created on Instance 2 visible on Instance 1
- [ ] All resources cleaned up after lab

---

## REAL-WORLD USE CASES

### 1. Web Application Shared Storage
- Multiple web servers share uploaded files
- User uploads go to EFS
- All servers can serve the same files

### 2. Container Storage (ECS/EKS)
- Kubernetes pods share persistent volumes
- StatefulSets use EFS for data persistence
- Multiple containers access same configuration files

### 3. Content Management Systems
- WordPress media library on EFS
- Multiple EC2 instances serve the same content
- Auto-scaling without data sync issues

### 4. Machine Learning
- Training data stored on EFS
- Multiple training nodes access same dataset
- Model checkpoints shared across instances

### 5. Development Environments
- Shared code repositories
- Team collaboration on same files
- CI/CD pipelines access shared artifacts

---

**Lab Complete! You now understand AWS EFS from basics to production deployment.**
