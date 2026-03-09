# 🚀 How to Run AWS EFS Lab

## 📋 Choose Your Method

You have **3 ways** to complete this lab:

1. **Automated Script** (5 minutes) - Recommended for quick setup
2. **Manual Console** (30 minutes) - Best for learning
3. **Hybrid** (15 minutes) - Script + manual verification

---

## METHOD 1: AUTOMATED SCRIPT (RECOMMENDED)

### ⚡ Quick Setup in AWS CloudShell

**Step 1: Open CloudShell**
- Go to AWS Console
- Click terminal icon (>_) at top right
- CloudShell opens at bottom

**Step 2: Clone Repository**
```bash
git clone https://github.com/SrinathMLOps/efs.git
cd efs
```

**Step 3: Make Scripts Executable**
```bash
chmod +x *.sh
```

**Step 4: Cleanup Old Resources (if any)**
```bash
./cleanup-all-efs-resources.sh
```

**Step 5: Run Setup Script**
```bash
./aws-efs-lab-setup-v2.sh
```

**What happens**:
- Creates VPC, subnets, security groups (1 min)
- Creates EFS with mount targets (2 min)
- Launches 2 EC2 instances (1 min)
- Waits for status checks to pass (2 min)
- Displays connection details

**Step 6: Verify Setup**
```bash
./verify-setup.sh
```

**Step 7: View Connection Details**
```bash
cat lab-summary.txt
```

**Step 8: Connect and Test**

Use EC2 Instance Connect (browser):
1. Go to EC2 Console
2. Select "EFS-Lab-Instance-1"
3. Click "Connect" → "EC2 Instance Connect" → "Connect"

Or use SSH:
```bash
ssh -i efs-lab-key.pem ec2-user@<INSTANCE_IP>
```

**Step 9: Test EFS**

On Instance 1:
```bash
df -h | grep efs
echo "Hello from Instance 1" | sudo tee /mnt/efs/test1.txt
```

On Instance 2:
```bash
cat /mnt/efs/test1.txt
echo "Hello from Instance 2" | sudo tee /mnt/efs/test2.txt
```

Back on Instance 1:
```bash
cat /mnt/efs/test2.txt
```

**✅ Success**: If both instances see each other's files!

**Step 10: Cleanup**
```bash
./cleanup-efs-lab.sh
```

**Total Time**: 5-10 minutes

---

## METHOD 2: MANUAL CONSOLE SETUP

### 📖 Complete Manual Guide

**Follow**: `MANUAL-CONSOLE-SETUP.md`

**Steps**:
1. Create VPC (Step 1)
2. Create Internet Gateway (Step 2)
3. Create Subnets (Step 3)
4. Create Route Table (Step 4)
5. Create Security Groups (Step 5)
6. Create Key Pair (Step 6)
7. Create EFS File System (Step 7)
8. Launch EC2 Instance 1 (Step 8)
9. Launch EC2 Instance 2 (Step 9)
10. Get Instance IPs (Step 10)
11. Connect to Instance 1 (Step 11)
12. Verify EFS Mount (Step 12)
13. Create Test Files (Step 13)
14. Connect to Instance 2 (Step 14)
15. Verify Shared Storage (Step 15)
16. Create Files on Instance 2 (Step 16)
17. Verify on Instance 1 (Step 17)
18. Verify Persistent Mount (Step 18)
19. Advanced Testing (Step 19)
20. Monitor EFS (Step 20)
21. Cleanup (Step 21)

**Total Time**: 30-40 minutes

**Best for**: 
- Learning AWS Console
- Understanding each component
- Interview preparation
- Teaching others

---

## METHOD 3: HYBRID APPROACH

### 🔄 Script + Manual Verification

**Step 1: Run Script**
```bash
git clone https://github.com/SrinathMLOps/efs.git
cd efs
chmod +x *.sh
./aws-efs-lab-setup-v2.sh
```

**Step 2: Verify in Console**
- Go to VPC Console → Check VPC, subnets, IGW
- Go to EC2 Console → Check instances, security groups
- Go to EFS Console → Check file system, mount targets

**Step 3: Manual Testing**
- Follow TESTING-GUIDE.md for verification
- Try advanced testing scenarios
- Monitor metrics in console

**Total Time**: 15-20 minutes

**Best for**: 
- Understanding automation
- Verifying script results
- Learning both approaches

---

## 🎯 WHICH METHOD SHOULD YOU CHOOSE?

### Choose Automated Script if:
- ✅ You want quick setup
- ✅ You're comfortable with CLI
- ✅ You want to test EFS quickly
- ✅ You'll repeat this lab multiple times

### Choose Manual Console if:
- ✅ You're new to AWS
- ✅ You want to learn each component
- ✅ You're preparing for interviews
- ✅ You want to understand the "why" behind each step

### Choose Hybrid if:
- ✅ You want best of both worlds
- ✅ You want to verify automation
- ✅ You're learning DevOps/IaC
- ✅ You want to compare manual vs automated

---

## 📂 FILE GUIDE

### Setup Scripts:
- `aws-efs-lab-setup-v2.sh` - Main automated setup (USE THIS)
- `aws-efs-lab-setup.sh` - Legacy version
- `cleanup-all-efs-resources.sh` - Delete all EFS lab resources
- `cleanup-efs-lab.sh` - Generated after setup for specific cleanup

### Helper Scripts:
- `verify-setup.sh` - Check if resources are ready
- `connect-instances.sh` - Interactive connection menu
- `test-efs-from-instance.sh` - Run on EC2 to test EFS

### Documentation:
- `README.md` - Overview and quick start
- `MANUAL-CONSOLE-SETUP.md` - Complete manual guide (21 steps)
- `TESTING-GUIDE.md` - Detailed testing procedures
- `QUICK-REFERENCE.md` - Command cheat sheet
- `ARCHITECTURE-EXPLAINED.md` - Architecture deep dive
- `HOW-TO-RUN.md` - This file

### Diagram:
- `efs.png` - Architecture diagram

---

## 🐛 TROUBLESHOOTING

### Issue: Scripts not found in CloudShell

**Solution**:
```bash
cd efs
git pull origin main
ls -la
```

### Issue: Permission denied on scripts

**Solution**:
```bash
chmod +x *.sh
```

### Issue: Cannot connect to EC2

**Solution**:
```bash
# Wait for status checks
./verify-setup.sh

# If not ready, wait 2 more minutes
```

### Issue: EFS not mounted

**Solution**:
```bash
# On EC2 instance
sudo cat /var/log/user-data.log
sudo mount -t efs fs-xxxxxxxxx:/ /mnt/efs
```

---

## ✅ SUCCESS CRITERIA

Your lab is successful when:

1. ✅ Both EC2 instances are running with 2/2 status checks
2. ✅ EFS is mounted on both instances at /mnt/efs
3. ✅ File created on Instance 1 is visible on Instance 2
4. ✅ File created on Instance 2 is visible on Instance 1
5. ✅ Both instances show same file count
6. ✅ You can explain the architecture

---

## 📞 GETTING HELP

### Check Documentation:
1. **MANUAL-CONSOLE-SETUP.md** - Step-by-step manual guide
2. **TESTING-GUIDE.md** - Testing and verification
3. **ARCHITECTURE-EXPLAINED.md** - Architecture details
4. **QUICK-REFERENCE.md** - Quick commands

### Run Verification:
```bash
./verify-setup.sh
```

### Check Logs:
```bash
# On EC2 instance
sudo cat /var/log/user-data.log
```

---

## 🎓 LEARNING PATH

### Beginner:
1. Read ARCHITECTURE-EXPLAINED.md
2. Follow MANUAL-CONSOLE-SETUP.md
3. Take notes on each step
4. Complete TESTING-GUIDE.md

### Intermediate:
1. Run automated script
2. Verify in console
3. Try advanced testing
4. Modify script for different regions

### Advanced:
1. Add third AZ
2. Implement private subnets
3. Add NAT Gateway
4. Enable CloudWatch monitoring
5. Automate with Terraform/CloudFormation

---

## 💡 TIPS FOR SUCCESS

1. **Use us-east-1 region** - Script is configured for this
2. **Wait for status checks** - Don't rush connections
3. **Note all resource IDs** - Helps with troubleshooting
4. **Keep terminals open** - Switch between instances
5. **Check logs if issues** - User data logs are helpful
6. **Cleanup after testing** - Avoid unnecessary charges

---

## 🎯 NEXT STEPS AFTER LAB

### Expand Your Knowledge:
- Try EFS with containers (ECS/EKS)
- Implement EFS lifecycle policies
- Test EFS performance modes
- Set up EFS backups
- Configure EFS access points

### Build Real Projects:
- WordPress with EFS for media
- Shared development environment
- Container persistent storage
- Machine learning data pipeline

---

**Ready to start? Pick your method above and begin!**
