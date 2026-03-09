# AWS EFS Lab - Manual Console Setup Guide

## 📋 Overview

This guide shows you how to create AWS EFS resources **manually through the AWS Console** (no scripts). Each step corresponds to what the automation script does.

**Time Required**: 30-40 minutes  
**Region**: US East (N. Virginia) - us-east-1  
**Cost**: ~$0.02/hour (remember to cleanup!)

---

## 🎯 What You'll Build

![EFS Architecture](efs.png)

**Architecture Components**:
- 1 VPC with 2 subnets across 2 Availability Zones
- 2 EC2 instances (one in each subnet)
- 1 EFS file system with 2 mount targets
- Security groups for EC2 and EFS
- Internet Gateway for SSH access

**Goal**: Prove that EFS provides shared storage by creating files on one instance and reading them from another.

---

## 📝 Resource Tracking Sheet

As you create resources, note down these IDs:

```
VPC ID: ________________
Subnet 1 ID: ________________ (us-east-1a)
Subnet 2 ID: ________________ (us-east-1b)
Internet Gateway ID: ________________
Route Table ID: ________________
EC2 Security Group ID: ________________
EFS Security Group ID: ________________
EFS File System ID: ________________
Mount Target 1 ID: ________________
Mount Target 2 ID: ________________
Instance 1 ID: ________________
Instance 1 Public IP: ________________
Instance 2 ID: ________________
Instance 2 Public IP: ________________
Key Pair Name: efs-lab-key
```

---

## STEP 1: CREATE VPC

### Navigate to VPC Service
1. Open **AWS Console** (https://console.aws.amazon.com)
2. Ensure you're in **US East (N. Virginia)** region (top right)
3. Search for **"VPC"** in the search bar
4. Click **"VPC"** service

### Create VPC
1. Click **"Create VPC"** button (orange button)
2. Select **"VPC only"** (not VPC and more)
3. Configure:
   - **Name tag**: `EFS-Lab-VPC`
   - **IPv4 CIDR block**: `10.0.0.0/16`
   - **IPv6 CIDR block**: No IPv6 CIDR block
   - **Tenancy**: Default
4. Click **"Create VPC"**
5. ✅ **Note the VPC ID** (vpc-xxxxxxxxx)

### Enable DNS Hostnames
1. Select your **EFS-Lab-VPC** (checkbox)
2. Click **"Actions"** dropdown → **"Edit VPC settings"**
3. ✅ Check **"Enable DNS hostnames"**
4. Click **"Save"**

**Why**: DNS hostnames allow EC2 to resolve EFS DNS names like `fs-xxx.efs.us-east-1.amazonaws.com`

**Script Equivalent**:
```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
```

---

## STEP 2: CREATE INTERNET GATEWAY

### Create IGW
1. In VPC Dashboard, click **"Internet Gateways"** (left sidebar)
2. Click **"Create internet gateway"**
3. Configure:
   - **Name tag**: `EFS-Lab-IGW`
4. Click **"Create internet gateway"**
5. ✅ **Note the IGW ID** (igw-xxxxxxxxx)

### Attach IGW to VPC
1. You'll see a green banner with **"Attach to a VPC"** button
2. Click **"Attach to a VPC"**
3. Select **"EFS-Lab-VPC"** from dropdown
4. Click **"Attach internet gateway"**
5. Status should change to **"Attached"**

**Why**: Internet Gateway allows EC2 instances to access the internet for SSH and package installation

**Script Equivalent**:
```bash
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
```

---

## STEP 3: CREATE SUBNETS

### Create Subnet 1
1. In VPC Dashboard, click **"Subnets"** (left sidebar)
2. Click **"Create subnet"**
3. Configure:
   - **VPC ID**: Select **"EFS-Lab-VPC"**
   - **Subnet name**: `EFS-Lab-Subnet-1`
   - **Availability Zone**: **us-east-1a**
   - **IPv4 CIDR block**: `10.0.1.0/24`
4. Click **"Create subnet"**
5. ✅ **Note Subnet 1 ID** (subnet-xxxxxxxxx)

### Create Subnet 2
1. Click **"Create subnet"** again
2. Configure:
   - **VPC ID**: Select **"EFS-Lab-VPC"**
   - **Subnet name**: `EFS-Lab-Subnet-2`
   - **Availability Zone**: **us-east-1b**
   - **IPv4 CIDR block**: `10.0.2.0/24`
3. Click **"Create subnet"**
4. ✅ **Note Subnet 2 ID**

### Enable Auto-assign Public IP
**For Subnet 1**:
1. Select **EFS-Lab-Subnet-1** (checkbox)
2. Click **"Actions"** → **"Edit subnet settings"**
3. ✅ Check **"Enable auto-assign public IPv4 address"**
4. Click **"Save"**

**For Subnet 2**:
1. Select **EFS-Lab-Subnet-2**
2. Click **"Actions"** → **"Edit subnet settings"**
3. ✅ Check **"Enable auto-assign public IPv4 address"**
4. Click **"Save"**

**Why**: Public IPs allow you to SSH into instances from your laptop

**Script Equivalent**:
```bash
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
```

---

## STEP 4: CREATE ROUTE TABLE

### Create Route Table
1. In VPC Dashboard, click **"Route Tables"** (left sidebar)
2. Click **"Create route table"**
3. Configure:
   - **Name**: `EFS-Lab-RT`
   - **VPC**: Select **"EFS-Lab-VPC"**
4. Click **"Create route table"**
5. ✅ **Note Route Table ID** (rtb-xxxxxxxxx)

### Add Internet Route
1. Select **EFS-Lab-RT** (checkbox)
2. Click **"Routes"** tab (bottom panel)
3. Click **"Edit routes"**
4. Click **"Add route"**
5. Configure:
   - **Destination**: `0.0.0.0/0`
   - **Target**: Select **"Internet Gateway"** → Select **"EFS-Lab-IGW"**
6. Click **"Save changes"**

### Associate Subnets
1. Click **"Subnet associations"** tab
2. Click **"Edit subnet associations"**
3. ✅ Select **both subnets** (EFS-Lab-Subnet-1 and EFS-Lab-Subnet-2)
4. Click **"Save associations"**

**Why**: Route table directs outbound traffic from subnets to the internet via IGW

**Script Equivalent**:
```bash
aws ec2 create-route-table --vpc-id $VPC_ID
aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $RT_ID
```

---

## STEP 5: CREATE SECURITY GROUPS

### Create EC2 Security Group
1. In VPC Dashboard, click **"Security Groups"** (left sidebar)
2. Click **"Create security group"**
3. Configure:
   - **Security group name**: `EFS-Lab-EC2-SG`
   - **Description**: `Security group for EC2 instances`
   - **VPC**: Select **"EFS-Lab-VPC"**

4. **Inbound rules** - Click **"Add rule"**:
   
   **Rule 1 - SSH from your IP**:
   - **Type**: SSH
   - **Protocol**: TCP
   - **Port**: 22
   - **Source**: My IP (automatically detects)
   - **Description**: `SSH from my laptop`
   
   **Rule 2 - SSH from EC2 Instance Connect**:
   - Click **"Add rule"** again
   - **Type**: SSH
   - **Protocol**: TCP
   - **Port**: 22
   - **Source**: Custom → `18.206.107.24/29`
   - **Description**: `SSH from EC2 Instance Connect`

5. **Outbound rules**: Leave default (All traffic)
6. Click **"Create security group"**
7. ✅ **Note EC2 Security Group ID** (sg-xxxxxxxxx)

### Create EFS Security Group
1. Click **"Create security group"** again
2. Configure:
   - **Security group name**: `EFS-Lab-EFS-SG`
   - **Description**: `Security group for EFS file system`
   - **VPC**: Select **"EFS-Lab-VPC"**

3. **Inbound rules** - Click **"Add rule"**:
   - **Type**: NFS
   - **Protocol**: TCP
   - **Port**: 2049
   - **Source**: Custom → Start typing "sg-" and select **"EFS-Lab-EC2-SG"**
   - **Description**: `NFS from EC2 instances`

4. **Outbound rules**: Leave default
5. Click **"Create security group"**
6. ✅ **Note EFS Security Group ID**

**Why**: 
- EC2 SG allows SSH (port 22) from your IP and EC2 Instance Connect
- EFS SG allows NFS (port 2049) only from EC2 instances
- This creates secure communication

**Script Equivalent**:
```bash
aws ec2 create-security-group --group-name EFS-Lab-EC2-SG --vpc-id $VPC_ID
aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 22 --cidr $MY_IP/32
aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 22 --cidr 18.206.107.24/29
aws ec2 create-security-group --group-name EFS-Lab-EFS-SG --vpc-id $VPC_ID
aws ec2 authorize-security-group-ingress --group-id $EFS_SG_ID --protocol tcp --port 2049 --source-group $EC2_SG_ID
```

---

## STEP 6: CREATE KEY PAIR

1. In EC2 Dashboard, click **"Key Pairs"** (left sidebar under Network & Security)
2. Click **"Create key pair"**
3. Configure:
   - **Name**: `efs-lab-key`
   - **Key pair type**: RSA
   - **Private key file format**: `.pem`
4. Click **"Create key pair"**
5. **Browser will download** `efs-lab-key.pem` file
6. ✅ **Save this file securely** - you cannot download it again!

### Set Permissions (if using Linux/Mac/CloudShell)
```bash
chmod 400 efs-lab-key.pem
```

**Why**: Key pair is required for SSH authentication to EC2 instances

**Script Equivalent**:
```bash
aws ec2 create-key-pair --key-name efs-lab-key --query 'KeyMaterial' --output text > efs-lab-key.pem
chmod 400 efs-lab-key.pem
```

---

## STEP 7: CREATE EFS FILE SYSTEM

### Navigate to EFS Service
1. Search for **"EFS"** in AWS Console
2. Click **"EFS"** service

### Create File System
1. Click **"Create file system"** (orange button)
2. Click **"Customize"** (don't use quick create)

### Page 1: File System Settings
1. Configure:
   - **Name**: `EFS-Lab-FileSystem`
   - **Storage class**: Standard
   - **Automatic backups**: ❌ Uncheck (for lab only)
   - **Lifecycle management**: None
   - **Performance mode**: General Purpose
   - **Throughput mode**: Bursting
   - **Encryption**: ✅ Enable encryption at rest
   - **KMS key**: aws/elasticfilesystem (default)
2. Click **"Next"**

### Page 2: Network Settings
1. **VPC**: Select **"EFS-Lab-VPC"**

2. **Mount targets** - Configure 2 mount targets:
   
   **Mount Target 1**:
   - **Availability zone**: us-east-1a
   - **Subnet ID**: Select **"EFS-Lab-Subnet-1"**
   - **Security groups**: ❌ Remove "default", ✅ Add **"EFS-Lab-EFS-SG"**
   
   **Mount Target 2**:
   - **Availability zone**: us-east-1b
   - **Subnet ID**: Select **"EFS-Lab-Subnet-2"**
   - **Security groups**: ❌ Remove "default", ✅ Add **"EFS-Lab-EFS-SG"**

3. Click **"Next"**

### Page 3: File System Policy
1. Leave blank (no policy needed for lab)
2. Click **"Next"**

### Page 4: Review and Create
1. Review all settings
2. Click **"Create"**
3. ✅ **Note the EFS File System ID** (fs-xxxxxxxxx)

**Wait 2-3 minutes** for:
- EFS state to become **"Available"**
- Mount targets to become **"Available"**

**Why**: 
- Mount targets are network endpoints in each AZ
- EC2 instances connect to mount targets to access EFS
- Multi-AZ provides high availability

**Script Equivalent**:
```bash
aws efs create-file-system --performance-mode generalPurpose --encrypted
aws efs create-mount-target --file-system-id $EFS_ID --subnet-id $SUBNET1_ID --security-groups $EFS_SG_ID
aws efs create-mount-target --file-system-id $EFS_ID --subnet-id $SUBNET2_ID --security-groups $EFS_SG_ID
```

---

## STEP 8: LAUNCH EC2 INSTANCE 1

### Navigate to EC2
1. Search for **"EC2"** in AWS Console
2. Click **"Instances"** (left sidebar)
3. Click **"Launch instances"** (orange button)

### Configure Instance 1
1. **Name and tags**:
   - **Name**: `EFS-Lab-Instance-1`

2. **Application and OS Images (AMI)**:
   - Select **"Amazon Linux 2023 AMI"**
   - Architecture: **64-bit (x86)**
   - Keep default (latest version)

3. **Instance type**: 
   - Select **"t2.micro"** (free tier eligible)

4. **Key pair (login)**:
   - Select **"efs-lab-key"** (created in Step 6)

5. **Network settings** - Click **"Edit"**:
   - **VPC**: Select **"EFS-Lab-VPC"**
   - **Subnet**: Select **"EFS-Lab-Subnet-1"** (us-east-1a)
   - **Auto-assign public IP**: **Enable**
   - **Firewall (security groups)**: 
     - Select **"Select existing security group"**
     - Choose **"EFS-Lab-EC2-SG"**

6. **Configure storage**: 
   - Leave default (8 GB gp3)

7. **Advanced details** - Click to expand:
   - Scroll down to **"User data"** text box
   - Paste this script (replace `fs-xxxxxxxxx` with YOUR EFS ID):

```bash
#!/bin/bash
exec > >(tee /var/log/user-data.log)
exec 2>&1
echo "Starting user data at $(date)"
yum update -y
yum install -y amazon-efs-utils nfs-utils
mkdir -p /mnt/efs
sleep 60
echo "fs-xxxxxxxxx:/ /mnt/efs efs defaults,_netdev,tls 0 0" >> /etc/fstab
mount -a
if mountpoint -q /mnt/efs; then
    chmod 777 /mnt/efs
    echo "Instance 1 mounted EFS at $(date)" > /mnt/efs/instance1-info.txt
fi
echo "User data completed at $(date)"
```

8. Click **"Launch instance"**
9. ✅ **Note Instance 1 ID** (i-xxxxxxxxx)

**Wait for**:
- Instance State: **Running**
- Status checks: **2/2 checks passed** (takes 2-3 minutes)

**Script Equivalent**:
```bash
aws ec2 run-instances --image-id $AMI_ID --instance-type t2.micro --key-name efs-lab-key \
  --security-group-ids $EC2_SG_ID --subnet-id $SUBNET1_ID --user-data file://user-data.sh
```

---

## STEP 9: LAUNCH EC2 INSTANCE 2

### Launch Second Instance
1. Click **"Launch instances"** again
2. **Name**: `EFS-Lab-Instance-2`
3. **AMI**: **Amazon Linux 2023 AMI**
4. **Instance type**: **t2.micro**
5. **Key pair**: **efs-lab-key**
6. **Network settings** - Click **"Edit"**:
   - **VPC**: **EFS-Lab-VPC**
   - **Subnet**: **EFS-Lab-Subnet-2** (us-east-1b) ⚠️ Different subnet!
   - **Auto-assign public IP**: **Enable**
   - **Security group**: **EFS-Lab-EC2-SG**
7. **User data** (replace `fs-xxxxxxxxx` with YOUR EFS ID):

```bash
#!/bin/bash
exec > >(tee /var/log/user-data.log)
exec 2>&1
echo "Starting user data at $(date)"
yum update -y
yum install -y amazon-efs-utils nfs-utils
mkdir -p /mnt/efs
sleep 60
echo "fs-xxxxxxxxx:/ /mnt/efs efs defaults,_netdev,tls 0 0" >> /etc/fstab
mount -a
if mountpoint -q /mnt/efs; then
    chmod 777 /mnt/efs
    echo "Instance 2 mounted EFS at $(date)" > /mnt/efs/instance2-info.txt
fi
echo "User data completed at $(date)"
```

8. Click **"Launch instance"**
9. ✅ **Note Instance 2 ID**

**Wait for**:
- Instance State: **Running**
- Status checks: **2/2 checks passed**

**Why different subnets**: Demonstrates multi-AZ capability of EFS

---

## STEP 10: GET INSTANCE PUBLIC IPs

1. Go to **EC2 Dashboard** → **"Instances"**
2. Select **"EFS-Lab-Instance-1"**
3. In the **Details** tab (bottom), find **"Public IPv4 address"**
4. ✅ **Copy and note Instance 1 IP** (e.g., 44.193.223.78)
5. Select **"EFS-Lab-Instance-2"**
6. ✅ **Copy and note Instance 2 IP** (e.g., 3.91.178.93)

**These IPs are needed for SSH connection**

---

## STEP 11: CONNECT TO INSTANCE 1

### Method 1: EC2 Instance Connect (Browser - Easiest)
1. In EC2 Console, select **"EFS-Lab-Instance-1"**
2. Click **"Connect"** button (top right)
3. Choose **"EC2 Instance Connect"** tab
4. Username: `ec2-user` (default)
5. Click **"Connect"**
6. Browser opens a terminal session

### Method 2: SSH from CloudShell
1. Click CloudShell icon (>_) in AWS Console top bar
2. Upload `efs-lab-key.pem` file (Actions → Upload file)
3. Run:
```bash
chmod 400 efs-lab-key.pem
ssh -i efs-lab-key.pem ec2-user@44.193.223.78
```

### Method 3: SSH from Local Terminal
```bash
ssh -i efs-lab-key.pem ec2-user@44.193.223.78
```

**First connection**: Type `yes` when asked about host authenticity

---

## STEP 12: VERIFY EFS MOUNT ON INSTANCE 1

### Check if EFS is mounted
```bash
df -h | grep efs
```

**Expected Output**:
```
fs-xxxxxxxxx.efs.us-east-1.amazonaws.com:/  8.0E  0  8.0E  0% /mnt/efs
```

### Check mount point
```bash
mountpoint /mnt/efs
```

**Expected Output**: `/mnt/efs is a mountpoint`

### List EFS contents
```bash
ls -la /mnt/efs/
```

**Expected Output**:
```
total 8
drwxrwxrwx 2 root root 6144 Mar  9 10:30 .
drwxr-xr-x 3 root root   17 Mar  9 10:25 ..
-rw-r--r-- 1 root root   50 Mar  9 10:30 instance1-info.txt
```

### View the info file
```bash
cat /mnt/efs/instance1-info.txt
```

**✅ SUCCESS**: If you see the EFS mount and info file, EFS is working on Instance 1!

### If EFS not mounted, check logs:
```bash
sudo cat /var/log/user-data.log
```

---

## STEP 13: CREATE TEST FILES ON INSTANCE 1

### Create simple test file
```bash
echo "Hello from Instance 1" | sudo tee /mnt/efs/test-from-instance1.txt
```

**Expected Output**: `Hello from Instance 1`

### Create directory with multiple files
```bash
sudo mkdir -p /mnt/efs/shared-data
echo "File 1 content" | sudo tee /mnt/efs/shared-data/file1.txt
echo "File 2 content" | sudo tee /mnt/efs/shared-data/file2.txt
echo "File 3 content" | sudo tee /mnt/efs/shared-data/file3.txt
```

### Create timestamp file
```bash
echo "Created by Instance 1 at $(date)" | sudo tee /mnt/efs/timestamp-instance1.txt
```

### List all files
```bash
ls -lR /mnt/efs/
```

**Expected Output**:
```
/mnt/efs/:
total 16
-rw-r--r-- 1 root root   50 Mar  9 10:30 instance1-info.txt
drwxr-xr-x 2 root root 6144 Mar  9 10:35 shared-data
-rw-r--r-- 1 root root   24 Mar  9 10:32 test-from-instance1.txt
-rw-r--r-- 1 root root   45 Mar  9 10:33 timestamp-instance1.txt

/mnt/efs/shared-data:
total 12
-rw-r--r-- 1 root root 16 Mar  9 10:35 file1.txt
-rw-r--r-- 1 root root 16 Mar  9 10:35 file2.txt
-rw-r--r-- 1 root root 16 Mar  9 10:35 file3.txt
```

**✅ VERIFICATION**: Files are created and stored in EFS

**Keep this terminal open** - you'll come back to it later

---

## STEP 14: CONNECT TO INSTANCE 2

### Open NEW Terminal/Browser Tab

**Method 1: EC2 Instance Connect (Browser)**:
1. Go to EC2 Console
2. Select **"EFS-Lab-Instance-2"**
3. Click **"Connect"** → **"EC2 Instance Connect"** → **"Connect"**

**Method 2: SSH**:
```bash
ssh -i efs-lab-key.pem ec2-user@3.91.178.93
```

---

## STEP 15: VERIFY SHARED STORAGE ON INSTANCE 2

### Check if EFS is mounted
```bash
df -h | grep efs
```

**Expected**: Same EFS filesystem ID as Instance 1

### List all files
```bash
ls -lR /mnt/efs/
```

**Expected Output**:
```
You should see ALL files created from Instance 1:
- instance1-info.txt
- instance2-info.txt
- test-from-instance1.txt
- timestamp-instance1.txt
- shared-data/ directory with file1.txt, file2.txt, file3.txt
```

### Read file created from Instance 1
```bash
cat /mnt/efs/test-from-instance1.txt
```

**Expected Output**: `Hello from Instance 1`

### Read timestamp
```bash
cat /mnt/efs/timestamp-instance1.txt
```

### Read files from shared directory
```bash
cat /mnt/efs/shared-data/file1.txt
cat /mnt/efs/shared-data/file2.txt
cat /mnt/efs/shared-data/file3.txt
```

**🎉 SUCCESS INDICATOR**: If you can read files created from Instance 1, EFS shared storage is working!

---

## STEP 16: CREATE TEST FILES ON INSTANCE 2

### Create test file
```bash
echo "Hello from Instance 2" | sudo tee /mnt/efs/test-from-instance2.txt
```

### Create timestamp
```bash
echo "Created by Instance 2 at $(date)" | sudo tee /mnt/efs/timestamp-instance2.txt
```

### Add file to shared directory
```bash
echo "Instance 2 data" | sudo tee /mnt/efs/shared-data/file-from-instance2.txt
```

### List all files
```bash
ls -lR /mnt/efs/
```

**Expected**: Now you see files from BOTH instances

---

## STEP 17: VERIFY ON INSTANCE 1

### Switch back to Instance 1 terminal

### List all files
```bash
ls -lR /mnt/efs/
```

**Expected**: You should see NEW files created by Instance 2

### Read file created from Instance 2
```bash
cat /mnt/efs/test-from-instance2.txt
```

**Expected Output**: `Hello from Instance 2`

### Read timestamp from Instance 2
```bash
cat /mnt/efs/timestamp-instance2.txt
```

### Read new file in shared-data
```bash
cat /mnt/efs/shared-data/file-from-instance2.txt
```

**Expected Output**: `Instance 2 data`

**🎉 FINAL SUCCESS**: If Instance 1 can read files created by Instance 2, EFS is fully working!

---

## STEP 18: VERIFY PERSISTENT MOUNT

### Check /etc/fstab configuration
```bash
cat /etc/fstab
```

**Expected Output** (should contain):
```
fs-xxxxxxxxx:/ /mnt/efs efs defaults,_netdev,tls 0 0
```

**Why**: This line ensures EFS mounts automatically after reboot

### Test reboot (Optional)
```bash
sudo reboot
```

**Wait 1-2 minutes**, then reconnect:
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE_IP>
```

### Verify mount after reboot
```bash
df -h | grep efs
ls /mnt/efs/
```

**Expected**: EFS is still mounted and all files are there

---

## STEP 19: ADVANCED TESTING (OPTIONAL)

### Test 1: Concurrent File Creation

**On Instance 1**:
```bash
for i in {1..5}; do 
    echo "Instance1-File-$i" | sudo tee /mnt/efs/instance1-$i.txt
done
```

**On Instance 2**:
```bash
for i in {1..5}; do 
    echo "Instance2-File-$i" | sudo tee /mnt/efs/instance2-$i.txt
done
```

**On both instances**:
```bash
ls /mnt/efs/ | wc -l
```

**Expected**: Same file count on both

### Test 2: Large File Transfer
```bash
sudo dd if=/dev/zero of=/mnt/efs/largefile.dat bs=1M count=100
```

Creates 100MB file - verify on other instance:
```bash
ls -lh /mnt/efs/largefile.dat
```

### Test 3: Real-time Monitoring

**On Instance 1**:
```bash
watch -n 1 'ls -la /mnt/efs/ | tail -10'
```

**On Instance 2** (create files):
```bash
for i in {1..10}; do 
    echo "Realtime-$i" | sudo tee /mnt/efs/realtime-$i.txt
    sleep 2
done
```

**Expected**: Instance 1 shows files appearing in real-time

---

## STEP 20: MONITOR EFS IN CONSOLE

### View EFS Metrics
1. Go to **EFS Console**
2. Select **"EFS-Lab-FileSystem"**
3. Click **"Monitoring"** tab

**Metrics to observe**:
- **Total storage**: Shows how much data is stored
- **Metered IO**: Read/write operations count
- **Throughput**: Data transfer rate (MB/s)
- **Connections**: Number of connected clients (should show 2)

### Check storage usage from CLI
```bash
du -sh /mnt/efs/
```

---

## STEP 21: CLEANUP (IMPORTANT!)

### ⚠️ Delete resources in this EXACT order to avoid errors:

### 1. Terminate EC2 Instances
1. Go to **EC2 Console** → **"Instances"**
2. Select **both instances** (EFS-Lab-Instance-1 and EFS-Lab-Instance-2)
3. Click **"Instance state"** → **"Terminate instance"**
4. Click **"Terminate"** to confirm
5. **Wait** until both show **"Terminated"** state (2-3 minutes)

### 2. Delete EFS Mount Targets
1. Go to **EFS Console**
2. Select **"EFS-Lab-FileSystem"**
3. Click **"Network"** tab
4. Click **"Manage"** button
5. Click **"Remove"** for **both mount targets**
6. Click **"Save"**
7. **Wait 2-3 minutes** for mount targets to be deleted

### 3. Delete EFS File System
1. In EFS Console, select **"EFS-Lab-FileSystem"**
2. Click **"Delete"**
3. Type the **file system ID** to confirm (fs-xxxxxxxxx)
4. Click **"Confirm"**

### 4. Delete Security Groups
1. Go to **VPC Console** → **"Security Groups"**
2. Select **"EFS-Lab-EFS-SG"**
3. Click **"Actions"** → **"Delete security groups"**
4. Click **"Delete"**
5. Select **"EFS-Lab-EC2-SG"**
6. Click **"Actions"** → **"Delete security groups"**
7. Click **"Delete"**

### 5. Delete Subnets
1. Go to **"Subnets"**
2. Select **both subnets** (EFS-Lab-Subnet-1 and EFS-Lab-Subnet-2)
3. Click **"Actions"** → **"Delete subnet"**
4. Click **"Delete"**

### 6. Detach and Delete Internet Gateway
1. Go to **"Internet Gateways"**
2. Select **"EFS-Lab-IGW"**
3. Click **"Actions"** → **"Detach from VPC"**
4. Select **"EFS-Lab-VPC"** and click **"Detach internet gateway"**
5. Click **"Actions"** → **"Delete internet gateway"**
6. Click **"Delete internet gateway"**

### 7. Delete Route Table
1. Go to **"Route Tables"**
2. Select **"EFS-Lab-RT"**
3. Click **"Actions"** → **"Delete route table"**
4. Click **"Delete"**

### 8. Delete VPC
1. Go to **"Your VPCs"**
2. Select **"EFS-Lab-VPC"**
3. Click **"Actions"** → **"Delete VPC"**
4. Type `delete` to confirm
5. Click **"Delete"**

### 9. Delete Key Pair
1. Go to **EC2 Console** → **"Key Pairs"**
2. Select **"efs-lab-key"**
3. Click **"Actions"** → **"Delete"**
4. Type `Delete` to confirm
5. Click **"Delete"**
6. **Delete the .pem file** from your computer

**✅ Cleanup Complete!** All resources deleted, no more charges.

---

## 📊 WHAT YOU PROVED

| Concept | How You Proved It |
|---------|-------------------|
| **Shared Storage** | Files created on Instance 1 appeared on Instance 2 |
| **Multi-AZ** | Instances in different AZs (1a, 1b) shared same data |
| **Network Protocol** | Used NFS on port 2049 |
| **Real-time Sync** | Changes appeared immediately on both instances |
| **Persistence** | Mount configured in /etc/fstab survives reboots |
| **High Availability** | Each AZ has its own mount target |

---

## 🎓 INTERVIEW TALKING POINTS

**"Walk me through your EFS lab"**

"I manually created an EFS lab environment in AWS. First, I set up the networking layer with a VPC, two subnets in different availability zones (us-east-1a and us-east-1b), an internet gateway, and route tables for internet access.

Then I configured security - created two security groups: one for EC2 allowing SSH on port 22, and one for EFS allowing NFS traffic on port 2049 from the EC2 security group.

I created an EFS file system with mount targets in both availability zones for high availability. Then launched two EC2 instances, one in each subnet, and configured them to automatically mount the EFS filesystem at /mnt/efs using the user data script.

To verify shared storage, I created a file on Instance 1 and successfully read it from Instance 2, then created a file on Instance 2 and read it from Instance 1. This proved that EFS provides real-time shared storage across multiple instances and availability zones."

---

## 🔑 KEY TAKEAWAYS

1. **EFS = Network File System**: Multiple servers access same files simultaneously
2. **Port 2049**: NFS protocol requires this port open in security groups
3. **Mount Targets**: One per AZ for high availability and low latency
4. **Multi-AZ**: If one AZ fails, other instances still access EFS
5. **/etc/fstab**: Makes mount persistent across reboots
6. **Security Groups**: Act as firewalls controlling access
7. **User Data**: Automates instance configuration at launch

---

## 📚 ADDITIONAL RESOURCES

- **TESTING-GUIDE.md**: Detailed testing procedures and verification steps
- **QUICK-REFERENCE.md**: Quick command reference and cheat sheet
- **README.md**: Automated script usage
- **efs.png**: Architecture diagram explanation

---

## ✅ COMPLETION CHECKLIST

- [ ] VPC created with DNS hostnames enabled
- [ ] Internet Gateway attached to VPC
- [ ] 2 Subnets created in different AZs
- [ ] Route table configured with internet route
- [ ] EC2 Security Group allows SSH (port 22) from your IP and EC2 Instance Connect
- [ ] EFS Security Group allows NFS (port 2049) from EC2 SG
- [ ] Key pair created and downloaded
- [ ] EFS file system created and available
- [ ] 2 Mount targets created (one per AZ) and available
- [ ] 2 EC2 instances launched with user data
- [ ] Both instances show 2/2 status checks passed
- [ ] SSH connection successful to both instances
- [ ] EFS mounted on both instances at /mnt/efs
- [ ] Files created on Instance 1 visible on Instance 2
- [ ] Files created on Instance 2 visible on Instance 1
- [ ] All resources cleaned up after lab

**🎉 Lab Complete! You now have hands-on AWS EFS experience.**

---

## 💰 COST BREAKDOWN

| Resource | Cost | Duration |
|----------|------|----------|
| 2 x t2.micro EC2 | $0.0116/hour each | Lab duration |
| EFS Storage | $0.30/GB/month | Minimal (few KB) |
| Data Transfer | Free (same region) | N/A |
| **Total Lab Cost** | **< $0.10** | If cleaned up within 2 hours |

**Important**: Always cleanup resources after testing to avoid charges!

---

**Next Steps**: See TESTING-GUIDE.md for advanced testing scenarios and troubleshooting.
