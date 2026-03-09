# AWS EFS Lab - Architecture Diagram Explained

![EFS Architecture](efs.png)

## 🏗️ Architecture Overview

This diagram shows the complete AWS EFS lab architecture with all components and their relationships.

---

## 📦 Component Breakdown

### 1. VPC (Virtual Private Cloud)
**CIDR**: 10.0.0.0/16

```
┌─────────────────────────────────────────┐
│         VPC: 10.0.0.0/16                │
│  (65,536 private IP addresses)          │
└─────────────────────────────────────────┘
```

**What it is**: Your private network in AWS  
**Why needed**: Isolates your resources and provides network control  
**Analogy**: Like your office building - everything inside can communicate privately

---

### 2. Availability Zones (AZs)

```
┌──────────────────┐    ┌──────────────────┐
│   us-east-1a     │    │   us-east-1b     │
│  (Data Center 1) │    │  (Data Center 2) │
└──────────────────┘    └──────────────────┘
```

**What they are**: Physically separate data centers in the same region  
**Why needed**: High availability - if one fails, the other keeps working  
**Real-world**: Like having offices in two different buildings

---

### 3. Subnets

```
Subnet 1: 10.0.1.0/24 (us-east-1a)
  ↳ 256 IP addresses
  ↳ Contains: EC2 Instance 1, EFS Mount Target 1

Subnet 2: 10.0.2.0/24 (us-east-1b)
  ↳ 256 IP addresses
  ↳ Contains: EC2 Instance 2, EFS Mount Target 2
```

**What they are**: Smaller networks inside the VPC  
**Why needed**: Organize resources by AZ and function  
**Analogy**: Different floors in your office building

---

### 4. Internet Gateway (IGW)

```
Internet
   ↕
Internet Gateway
   ↕
VPC (10.0.0.0/16)
```

**What it is**: Gateway that connects VPC to the internet  
**Why needed**: Allows SSH access from your laptop and package downloads  
**Without it**: EC2 instances cannot be reached from outside

---

### 5. Route Table

```
Destination      Target
0.0.0.0/0    →   Internet Gateway
10.0.0.0/16  →   Local (VPC)
```

**What it is**: Rules that direct network traffic  
**Why needed**: Tells subnets how to reach the internet  
**Rule explained**: 
- `0.0.0.0/0` = all internet traffic → goes to IGW
- `10.0.0.0/16` = VPC traffic → stays local

---

### 6. Security Groups

#### EC2 Security Group
```
Inbound Rules:
┌──────────────────────────────────────┐
│ Port 22 (SSH) ← Your IP              │
│ Port 22 (SSH) ← EC2 Instance Connect │
└──────────────────────────────────────┘

Outbound Rules:
┌──────────────────────────────────────┐
│ All Traffic → Anywhere               │
└──────────────────────────────────────┘
```

**What it is**: Firewall for EC2 instances  
**Why needed**: Controls who can SSH into instances  
**Rules explained**:
- Allows SSH from your IP (so you can connect)
- Allows SSH from AWS service (for browser connection)
- Allows all outbound (so EC2 can reach EFS and internet)

#### EFS Security Group
```
Inbound Rules:
┌──────────────────────────────────────┐
│ Port 2049 (NFS) ← EC2 Security Group │
└──────────────────────────────────────┘
```

**What it is**: Firewall for EFS file system  
**Why needed**: Controls which instances can mount EFS  
**Rule explained**: Only EC2 instances with EC2-SG can connect via NFS

---

### 7. EFS File System

```
┌─────────────────────────────────────┐
│   EFS File System (fs-xxxxxxxxx)    │
│                                     │
│   Performance: General Purpose      │
│   Throughput: Bursting              │
│   Encryption: Enabled               │
│   Storage: Elastic (auto-scales)    │
└─────────────────────────────────────┘
```

**What it is**: Network-attached storage that multiple instances can share  
**Why needed**: Provides shared file storage across instances  
**Key features**:
- Automatically scales (no size limit)
- Pay only for what you use
- Accessible from multiple instances simultaneously

---

### 8. EFS Mount Targets

```
Mount Target 1 (us-east-1a)
  ↳ IP: 10.0.1.x
  ↳ DNS: fs-xxx.efs.us-east-1.amazonaws.com
  ↳ Connects: Instance 1 → EFS

Mount Target 2 (us-east-1b)
  ↳ IP: 10.0.2.x
  ↳ DNS: fs-xxx.efs.us-east-1.amazonaws.com
  ↳ Connects: Instance 2 → EFS
```

**What they are**: Network endpoints in each AZ  
**Why needed**: Allow EC2 to connect to EFS locally within their AZ  
**Benefit**: Low latency + high availability

---

### 9. EC2 Instances

```
Instance 1 (us-east-1a)
  ↳ Public IP: 44.193.223.78
  ↳ Private IP: 10.0.1.x
  ↳ Mount: /mnt/efs → EFS

Instance 2 (us-east-1b)
  ↳ Public IP: 3.91.178.93
  ↳ Private IP: 10.0.2.x
  ↳ Mount: /mnt/efs → EFS
```

**What they are**: Virtual servers running Amazon Linux 2023  
**Why two**: To prove EFS shared storage works across multiple instances  
**Mount point**: Both mount EFS at `/mnt/efs`

---

## 🔄 Data Flow Diagram

### SSH Connection Flow
```
Your Laptop
    ↓ (SSH port 22)
Internet
    ↓
Internet Gateway
    ↓
Route Table
    ↓
Subnet
    ↓ (EC2 Security Group allows port 22)
EC2 Instance
```

### EFS Mount Flow
```
EC2 Instance 1 (us-east-1a)
    ↓ (NFS port 2049)
Mount Target 1 (us-east-1a)
    ↓ (EFS Security Group allows from EC2-SG)
EFS File System
    ↑ (NFS port 2049)
Mount Target 2 (us-east-1b)
    ↑
EC2 Instance 2 (us-east-1b)
```

### File Sharing Flow
```
Instance 1: echo "test" > /mnt/efs/file.txt
    ↓
Mount Target 1
    ↓
EFS Storage (file.txt saved)
    ↓
Mount Target 2
    ↓
Instance 2: cat /mnt/efs/file.txt
    ↓
Output: "test"
```

---

## 🎯 Why This Architecture?

### Multi-AZ Deployment
```
Scenario: us-east-1a fails (power outage)
Result: Instance 2 in us-east-1b still works
Benefit: High availability
```

### Shared Storage
```
Without EFS:
Instance 1 → EBS Volume 1 (isolated)
Instance 2 → EBS Volume 2 (isolated)
Problem: Cannot share files

With EFS:
Instance 1 ↘
            EFS (shared)
Instance 2 ↗
Solution: All instances access same files
```

### Security Layers
```
Layer 1: VPC (network isolation)
Layer 2: Security Groups (firewall rules)
Layer 3: NFS protocol (authenticated access)
Layer 4: Encryption at rest (data protection)
```

---

## 🔍 Component Interactions

### When Instance 1 Creates a File:

1. **User runs**: `echo "test" | sudo tee /mnt/efs/file.txt`
2. **Linux kernel**: Recognizes /mnt/efs is NFS mount
3. **NFS client**: Sends write request to mount target
4. **Mount Target 1**: Receives request (port 2049)
5. **EFS Service**: Writes file to distributed storage
6. **Replication**: File immediately available to all mount targets
7. **Mount Target 2**: Can now serve this file
8. **Instance 2**: Reads file via its mount target

**Time**: Milliseconds (real-time sync)

---

## 📈 Scalability

### Adding More Instances:
```
Current: 2 instances
Can scale to: 1000s of instances
All accessing: Same EFS filesystem
No changes needed: Just mount the same EFS ID
```

### Adding More AZs:
```
Current: 2 AZs (us-east-1a, us-east-1b)
Can add: us-east-1c, us-east-1d, etc.
Process: Create subnet + mount target in new AZ
```

---

## 🏢 Real-World Architecture Examples

### Example 1: Web Application
```
Load Balancer
    ↓
┌─────────┬─────────┬─────────┐
│ Web     │ Web     │ Web     │
│ Server 1│ Server 2│ Server 3│
└────┬────┴────┬────┴────┬────┘
     └─────────┼─────────┘
               ↓
          EFS Storage
       (uploaded files)
```

### Example 2: Kubernetes Cluster
```
EKS Cluster
    ↓
┌─────────┬─────────┬─────────┐
│ Pod 1   │ Pod 2   │ Pod 3   │
│ (AZ-1a) │ (AZ-1b) │ (AZ-1c) │
└────┬────┴────┬────┴────┬────┘
     └─────────┼─────────┘
               ↓
    EFS Persistent Volume
    (shared config/data)
```

### Example 3: Machine Learning
```
Training Cluster
    ↓
┌─────────┬─────────┬─────────┐
│ GPU     │ GPU     │ GPU     │
│ Node 1  │ Node 2  │ Node 3  │
└────┬────┴────┬────┴────┬────┘
     └─────────┼─────────┘
               ↓
        EFS Storage
    (training dataset)
```

---

## 🔐 Security Best Practices

### What We Did (Lab):
- ✅ Encryption at rest enabled
- ✅ Security groups restrict access
- ✅ SSH only from specific IPs
- ✅ NFS only from EC2 instances

### Production Additions:
- Use private subnets (no public IPs)
- Add NAT Gateway for outbound internet
- Enable EFS encryption in transit (TLS)
- Use IAM roles for EC2 instances
- Enable VPC Flow Logs
- Add CloudWatch alarms
- Enable AWS Backup

---

## 📊 Performance Characteristics

### General Purpose Mode (What We Used):
- **Latency**: Low (single-digit milliseconds)
- **Throughput**: Bursting (scales with storage size)
- **Use case**: Web serving, content management, home directories

### Max I/O Mode (Alternative):
- **Latency**: Slightly higher
- **Throughput**: Higher aggregate throughput
- **Use case**: Big data, media processing, genomics

### Throughput Modes:
- **Bursting** (we used): Scales with storage size
- **Provisioned**: Fixed throughput regardless of size
- **Elastic**: Automatically scales up/down based on workload

---

## 🎓 Interview Questions You Can Answer

**Q: Explain the architecture you built**  
A: See "Interview Talking Points" section above

**Q: Why two availability zones?**  
A: For high availability. If us-east-1a fails, instances in us-east-1b continue working with EFS.

**Q: What is a mount target?**  
A: A network endpoint in each AZ that allows EC2 instances to connect to EFS using NFS protocol.

**Q: Why port 2049?**  
A: It's the standard port for NFS (Network File System) protocol that EFS uses.

**Q: How does security work?**  
A: Security groups act as firewalls. EC2-SG allows SSH in, EFS-SG allows NFS from EC2-SG only.

**Q: What happens if I add a third instance?**  
A: Just launch it in any subnet, mount the same EFS ID, and it immediately accesses all shared files.

**Q: EFS vs EBS?**  
A: EBS is block storage for one instance (like a hard drive). EFS is network file storage for multiple instances (like Google Drive).

---

## 🔄 How the Script Automates This

The `aws-efs-lab-setup-v2.sh` script does all 21 manual steps automatically:

| Manual Step | Script Command | Time Saved |
|-------------|----------------|------------|
| Create VPC | `aws ec2 create-vpc` | 2 min |
| Create IGW | `aws ec2 create-internet-gateway` | 2 min |
| Create Subnets | `aws ec2 create-subnet` (x2) | 4 min |
| Create Route Table | `aws ec2 create-route-table` | 3 min |
| Create Security Groups | `aws ec2 create-security-group` (x2) | 5 min |
| Create Key Pair | `aws ec2 create-key-pair` | 1 min |
| Create EFS | `aws efs create-file-system` | 2 min |
| Create Mount Targets | `aws efs create-mount-target` (x2) | 3 min |
| Launch EC2 Instances | `aws ec2 run-instances` (x2) | 5 min |
| Configure & Wait | Automated waits | 5 min |
| **Total** | **Automated** | **32 min saved** |

**Script runs in**: 4-5 minutes  
**Manual takes**: 30-40 minutes  
**Time saved**: 25-35 minutes

---

## 📸 Understanding the Diagram (efs.png)

### Visual Elements Explained:

**If your diagram shows**:

1. **VPC Box**: The outer boundary containing everything
2. **Two Columns**: Represent two availability zones
3. **Subnet Boxes**: Smaller boxes inside VPC
4. **EC2 Icons**: Server/computer icons in each subnet
5. **EFS Icon**: Storage/disk icon (usually orange)
6. **Arrows**: Show data flow and connections
7. **Security Group Icons**: Shield/lock icons
8. **Mount Target Icons**: Connection points between EC2 and EFS

### Color Coding (typical):
- **Blue**: Networking (VPC, subnets, IGW)
- **Orange**: Compute (EC2 instances)
- **Green**: Storage (EFS)
- **Red**: Security (security groups)

### Connection Lines:
- **Solid lines**: Direct connections
- **Dashed lines**: Network paths
- **Arrows**: Direction of traffic flow

---

## 🎯 Key Concepts Visualized

### Concept 1: Multi-AZ High Availability
```
┌─────────────────┐         ┌─────────────────┐
│   AZ-1a         │         │   AZ-1b         │
│                 │         │                 │
│  EC2 Instance 1 │         │  EC2 Instance 2 │
│       ↓         │         │       ↓         │
│  Mount Target 1 │         │  Mount Target 2 │
└────────┬────────┘         └────────┬────────┘
         └──────────┬──────────────┘
                    ↓
              EFS Storage
```

**If AZ-1a fails**: Instance 2 in AZ-1b continues working

### Concept 2: Shared Storage
```
Instance 1 writes:
  echo "data" > /mnt/efs/file.txt
       ↓
  Mount Target 1
       ↓
  EFS Storage (file.txt)
       ↓
  Mount Target 2
       ↓
Instance 2 reads:
  cat /mnt/efs/file.txt
  Output: "data"
```

### Concept 3: Security Layers
```
Internet → IGW → Route Table → Subnet
                                  ↓
                          EC2 Security Group (port 22 allowed)
                                  ↓
                             EC2 Instance
                                  ↓
                          EFS Security Group (port 2049 allowed)
                                  ↓
                             EFS Storage
```

---

## 📝 How to Use This Architecture

### For Learning:
1. Study each component
2. Understand why it's needed
3. Follow manual setup guide
4. Explain to someone else

### For Interviews:
1. Draw this architecture on whiteboard
2. Explain each component
3. Describe data flow
4. Discuss high availability

### For Production:
1. Add more AZs (3+ recommended)
2. Use private subnets
3. Add NAT Gateway
4. Enable monitoring
5. Set up backups

---

## 🚀 Quick Start Commands

### To build this automatically:
```bash
git clone https://github.com/SrinathMLOps/efs.git
cd efs
chmod +x aws-efs-lab-setup-v2.sh
./aws-efs-lab-setup-v2.sh
```

### To build manually:
Follow **MANUAL-CONSOLE-SETUP.md** step-by-step

### To test:
Follow **TESTING-GUIDE.md** or **QUICK-REFERENCE.md**

---

## 📚 Related Documentation

- **MANUAL-CONSOLE-SETUP.md**: Step-by-step console instructions
- **TESTING-GUIDE.md**: How to verify EFS is working
- **QUICK-REFERENCE.md**: Command cheat sheet
- **README.md**: Script usage and overview

---

**Understanding this architecture is key to AWS networking and storage concepts!**
