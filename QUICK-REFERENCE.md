# AWS EFS Lab - Quick Reference Card

## 🚀 How to Run This Lab

### In AWS CloudShell:

```bash
# 1. Clone repository
git clone https://github.com/SrinathMLOps/efs.git
cd efs

# 2. Make scripts executable
chmod +x *.sh

# 3. Cleanup old resources (if any)
./cleanup-all-efs-resources.sh

# 4. Run setup (takes 4-5 minutes)
./aws-efs-lab-setup-v2.sh

# 5. Verify setup is ready
./verify-setup.sh

# 6. View connection details
cat lab-summary.txt
```

---

## 🔗 Connection Commands

### Your Instance IPs:
```
Instance 1: 44.193.223.78
Instance 2: 3.91.178.93
```

### SSH Commands:
```bash
# Connect to Instance 1
ssh -i efs-lab-key.pem ec2-user@44.193.223.78

# Connect to Instance 2
ssh -i efs-lab-key.pem ec2-user@3.91.178.93
```

### Browser Connection:
1. EC2 Console → Instances
2. Select instance → Click "Connect"
3. EC2 Instance Connect → Connect

---

## ✅ Testing EFS Shared Storage

### On Instance 1:
```bash
# Verify mount
df -h | grep efs

# Create test file
echo "Hello from Instance 1" | sudo tee /mnt/efs/test-from-instance1.txt

# Create directory
sudo mkdir -p /mnt/efs/shared-data

# Create multiple files
echo "Data 1" | sudo tee /mnt/efs/shared-data/file1.txt
echo "Data 2" | sudo tee /mnt/efs/shared-data/file2.txt

# List everything
ls -lR /mnt/efs/
```

### On Instance 2:
```bash
# Verify mount
df -h | grep efs

# Read file from Instance 1
cat /mnt/efs/test-from-instance1.txt

# Should output: "Hello from Instance 1"

# List all files
ls -lR /mnt/efs/

# Create file from Instance 2
echo "Hello from Instance 2" | sudo tee /mnt/efs/test-from-instance2.txt

# Create more files
echo "Instance 2 data" | sudo tee /mnt/efs/shared-data/file-from-instance2.txt
```

### Back on Instance 1:
```bash
# Read file created by Instance 2
cat /mnt/efs/test-from-instance2.txt

# Should output: "Hello from Instance 2"

# List all files (should see files from both instances)
ls -lR /mnt/efs/
```

---

## ✅ What to Verify

| Check | Command | Expected Result |
|-------|---------|-----------------|
| EFS mounted | `df -h \| grep efs` | Shows EFS filesystem |
| Mount point valid | `mountpoint /mnt/efs` | "is a mountpoint" |
| Files from Instance 1 | `ls /mnt/efs/` on Instance 2 | See test-from-instance1.txt |
| Files from Instance 2 | `ls /mnt/efs/` on Instance 1 | See test-from-instance2.txt |
| Same file count | `ls /mnt/efs/ \| wc -l` on both | Same number |
| Can write | `echo "test" \| sudo tee /mnt/efs/test.txt` | File created |
| Can read | `cat /mnt/efs/test.txt` | Shows content |

---

## 🔍 Verification Commands

### Check EFS mount status:
```bash
df -h | grep efs
mountpoint /mnt/efs
mount | grep efs
```

### Check user data logs:
```bash
sudo cat /var/log/user-data.log
```

### Check EFS connectivity:
```bash
ping -c 3 fs-xxxxxxxxx.efs.us-east-1.amazonaws.com
```

### Check file count:
```bash
ls /mnt/efs/ | wc -l
```

### Check storage usage:
```bash
du -sh /mnt/efs/
```

---

## 🧹 Cleanup

### When done testing:
```bash
# Exit from EC2 instances
exit

# In CloudShell
cd ~/efs
./cleanup-efs-lab.sh
```

### Or cleanup everything:
```bash
./cleanup-all-efs-resources.sh
```

---

## 🎯 Success Criteria

Your lab is successful if:

✅ Both instances can mount EFS at /mnt/efs
✅ File created on Instance 1 appears on Instance 2
✅ File created on Instance 2 appears on Instance 1
✅ Both instances show same file count
✅ Changes are visible in real-time
✅ Mount persists after reboot (check /etc/fstab)

---

## 📊 What This Proves

| Concept | Proof |
|---------|-------|
| Shared Storage | Both instances access same files |
| Multi-AZ | Instances in different AZs share data |
| Network Protocol | Uses NFS over port 2049 |
| Real-time Sync | Changes appear immediately |
| Persistence | Data survives instance restarts |
| Scalability | Can add more instances easily |

---

## 💡 Interview Answer Template

**"Explain your EFS lab experience"**

"I set up an EFS lab with two EC2 instances in different availability zones. I created a VPC with subnets in us-east-1a and us-east-1b, configured security groups to allow NFS traffic on port 2049, and created an EFS file system with mount targets in both AZs.

I launched two EC2 instances and mounted the same EFS filesystem on both at /mnt/efs. To verify shared storage, I created a file on Instance 1 and successfully read it from Instance 2, then created a file on Instance 2 and read it from Instance 1.

This demonstrated that EFS provides shared network storage across multiple instances and availability zones, making it ideal for applications that need shared file access like web servers, container storage, or content management systems."

---

## 📁 File Structure After Lab

```
/mnt/efs/
├── mount-info-ip-10-0-1-xxx.txt    (from Instance 1)
├── mount-info-ip-10-0-2-xxx.txt    (from Instance 2)
├── test-from-instance1.txt          (created by Instance 1)
├── test-from-instance2.txt          (created by Instance 2)
├── timestamp-instance1.txt
├── timestamp-instance2.txt
└── shared-data/
    ├── file1.txt
    ├── file2.txt
    ├── file3.txt
    └── file-from-instance2.txt
```

---

## 🎓 Key Takeaways

1. **EFS = Shared Storage**: Multiple servers access same files
2. **NFS Protocol**: Port 2049 must be open in security groups
3. **Mount Targets**: One per AZ for high availability
4. **Real-time Sync**: Changes appear instantly across all instances
5. **Persistent**: Configured in /etc/fstab for auto-mount on boot

---

**Need help? Check TESTING-GUIDE.md for detailed explanations**
