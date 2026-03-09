# 🎯 START HERE - AWS EFS Lab

## 👋 Welcome!

This is your complete AWS EFS learning package. Everything you need is here.

---

## ⚡ FASTEST WAY TO RUN (30 seconds)

### In AWS CloudShell:

```bash
git clone https://github.com/SrinathMLOps/efs.git && cd efs && chmod +x run-complete-lab.sh && ./run-complete-lab.sh
```

**That's it!** The script will:
1. Check your current AWS region
2. Clean up any old resources
3. Create all new resources
4. Verify everything is ready
5. Show you how to connect and test

**Time**: 5-7 minutes total

---

## 📚 DOCUMENTATION MAP

### 🚀 Getting Started
1. **START-HERE.md** ← You are here
2. **HOW-TO-RUN.md** - Choose your method (automated/manual/hybrid)

### 🎓 Learning Path
3. **ARCHITECTURE-EXPLAINED.md** - Understand the architecture (read first!)
4. **MANUAL-CONSOLE-SETUP.md** - 21-step manual guide (best for learning)
5. **TESTING-GUIDE.md** - How to test and verify EFS
6. **QUICK-REFERENCE.md** - Command cheat sheet

### 📖 Reference
7. **README.md** - Repository overview
8. **efs.png** - Architecture diagram

---

## 🎯 CHOOSE YOUR PATH

### Path 1: I Want to Learn (30-40 minutes)
**Best for**: Interviews, understanding AWS, teaching others

1. Read **ARCHITECTURE-EXPLAINED.md** (understand the design)
2. Follow **MANUAL-CONSOLE-SETUP.md** (create everything manually)
3. Use **TESTING-GUIDE.md** (verify it works)
4. Take notes and screenshots

**You'll learn**: Every component, why it exists, how it connects

---

### Path 2: I Want Quick Results (5 minutes)
**Best for**: Quick demo, testing EFS, time-constrained

1. Run: `./run-complete-lab.sh`
2. Connect to instances (browser or SSH)
3. Test: Create file on Instance 1, read on Instance 2
4. Cleanup: `./cleanup-efs-lab.sh`

**You'll learn**: EFS works, shared storage concept

---

### Path 3: I Want Both (15 minutes)
**Best for**: Understanding automation, DevOps learning

1. Run: `./run-complete-lab.sh` (automated)
2. Open AWS Console and verify each resource
3. Read **ARCHITECTURE-EXPLAINED.md** while resources create
4. Follow **TESTING-GUIDE.md** for verification

**You'll learn**: Automation + manual verification skills

---

## 🔧 AVAILABLE SCRIPTS

### Main Workflows:
- `run-complete-lab.sh` - **Complete workflow** (check→clean→setup→verify)
- `aws-efs-lab-setup-v2.sh` - Setup only (improved version)

### Utilities:
- `check-current-region.sh` - Check which AWS region you're in
- `verify-and-cleanup-all.sh` - Interactive cleanup with verification
- `cleanup-all-efs-resources.sh` - Direct cleanup (no prompts)
- `verify-setup.sh` - Check if setup is complete
- `connect-instances.sh` - Easy connection menu

### Testing:
- `test-efs-from-instance.sh` - Run on EC2 to test EFS

### Cleanup:
- `cleanup-efs-lab.sh` - Generated after setup (specific resources)

---

## 🎬 QUICK START COMMANDS

### Option 1: Complete Workflow (Recommended)
```bash
git clone https://github.com/SrinathMLOps/efs.git
cd efs
chmod +x run-complete-lab.sh
./run-complete-lab.sh
```

### Option 2: Step by Step
```bash
git clone https://github.com/SrinathMLOps/efs.git
cd efs
chmod +x *.sh

# Check region
./check-current-region.sh

# Cleanup old resources
./verify-and-cleanup-all.sh

# Setup new resources
./aws-efs-lab-setup-v2.sh

# Verify ready
./verify-setup.sh

# View details
cat lab-summary.txt
```

### Option 3: Manual Console
Open **MANUAL-CONSOLE-SETUP.md** and follow 21 steps

---

## ✅ WHAT YOU'LL ACCOMPLISH

After completing this lab, you will:

1. ✅ Understand AWS VPC networking
2. ✅ Know how to configure security groups
3. ✅ Create and configure EFS file systems
4. ✅ Set up multi-AZ architecture
5. ✅ Verify shared storage across instances
6. ✅ Explain EFS in interviews
7. ✅ Have hands-on AWS experience

---

## 🎯 SUCCESS CRITERIA

Your lab is successful when:

✅ Both EC2 instances are running (2/2 status checks)  
✅ EFS is mounted on both at /mnt/efs  
✅ File created on Instance 1 appears on Instance 2  
✅ File created on Instance 2 appears on Instance 1  
✅ You can explain the architecture  

---

## 📖 DOCUMENTATION GUIDE

| Read This | When | Why |
|-----------|------|-----|
| START-HERE.md | First | Choose your path |
| HOW-TO-RUN.md | Before running | Understand methods |
| ARCHITECTURE-EXPLAINED.md | Before/during | Understand design |
| MANUAL-CONSOLE-SETUP.md | For manual setup | Step-by-step guide |
| TESTING-GUIDE.md | After setup | Verify it works |
| QUICK-REFERENCE.md | During testing | Quick commands |

---

## 🐛 TROUBLESHOOTING

### Issue: Scripts not found
```bash
cd efs
git pull origin main
ls -la
```

### Issue: Permission denied
```bash
chmod +x *.sh
```

### Issue: Wrong region
```bash
./check-current-region.sh
export AWS_DEFAULT_REGION=us-east-1
```

### Issue: Resources already exist
```bash
./verify-and-cleanup-all.sh
```

### Issue: Cannot connect to EC2
```bash
./verify-setup.sh
# Wait 2 more minutes if not ready
```

---

## 💡 PRO TIPS

1. **Use CloudShell** - No setup needed, AWS CLI pre-configured
2. **Check region first** - Run `./check-current-region.sh`
3. **Clean before setup** - Run `./verify-and-cleanup-all.sh`
4. **Wait for status checks** - Don't rush connections (2/2 checks)
5. **Use browser connection** - EC2 Instance Connect is easiest
6. **Keep terminals open** - Switch between instances for testing
7. **Cleanup after** - Avoid AWS charges

---

## 🎓 LEARNING OBJECTIVES

### Beginner Level:
- Understand what EFS is
- Know the difference between EFS and EBS
- Create basic AWS resources
- Connect to EC2 instances

### Intermediate Level:
- Design multi-AZ architecture
- Configure security groups properly
- Understand NFS protocol
- Automate with scripts

### Advanced Level:
- Explain high availability design
- Troubleshoot connectivity issues
- Optimize EFS performance
- Implement in production

---

## 🎤 INTERVIEW PREPARATION

After this lab, you can answer:

- "Explain AWS EFS and when to use it"
- "What's the difference between EFS and EBS?"
- "How do you set up multi-AZ storage?"
- "What is a mount target?"
- "How does EFS security work?"
- "Walk me through an EFS architecture"

See **ARCHITECTURE-EXPLAINED.md** for detailed interview answers.

---

## 📊 TIME ESTIMATES

| Method | Time | Best For |
|--------|------|----------|
| One-command complete | 5-7 min | Quick demo |
| Automated script | 5-10 min | Testing EFS |
| Manual console | 30-40 min | Learning AWS |
| Hybrid approach | 15-20 min | Understanding both |

---

## 🎯 NEXT STEPS

### Right Now:
1. Choose your path above
2. Run the commands
3. Test EFS shared storage
4. Cleanup resources

### After Lab:
1. Try different regions
2. Add third availability zone
3. Test with containers (ECS/EKS)
4. Implement in real project

---

## 📞 NEED HELP?

### Check Documentation:
- **HOW-TO-RUN.md** - Running instructions
- **TESTING-GUIDE.md** - Testing procedures
- **ARCHITECTURE-EXPLAINED.md** - Architecture details

### Run Diagnostics:
```bash
./check-current-region.sh      # Check region
./verify-and-cleanup-all.sh    # Check resources
./verify-setup.sh              # Check if ready
```

### Check Logs:
```bash
# On EC2 instance
sudo cat /var/log/user-data.log
```

---

## 🎉 READY TO START?

### Fastest Way:
```bash
git clone https://github.com/SrinathMLOps/efs.git && cd efs && chmod +x run-complete-lab.sh && ./run-complete-lab.sh
```

### Learning Way:
Open **MANUAL-CONSOLE-SETUP.md** and follow step-by-step

**Choose your path and begin! 🚀**

---

## 📦 WHAT'S IN THIS REPO

```
efs/
├── START-HERE.md                    ← You are here
├── HOW-TO-RUN.md                    ← Choose your method
├── MANUAL-CONSOLE-SETUP.md          ← 21-step manual guide
├── TESTING-GUIDE.md                 ← Testing procedures
├── QUICK-REFERENCE.md               ← Command cheat sheet
├── ARCHITECTURE-EXPLAINED.md        ← Architecture deep dive
├── README.md                        ← Repository overview
├── efs.png                          ← Architecture diagram
├── run-complete-lab.sh              ← One-command workflow
├── aws-efs-lab-setup-v2.sh          ← Main setup script
├── verify-and-cleanup-all.sh        ← Interactive cleanup
├── check-current-region.sh          ← Region checker
├── verify-setup.sh                  ← Setup verifier
├── connect-instances.sh             ← Connection helper
├── test-efs-from-instance.sh        ← EC2 testing script
└── cleanup-all-efs-resources.sh     ← Direct cleanup
```

**Everything you need for AWS EFS mastery! 🎓**
