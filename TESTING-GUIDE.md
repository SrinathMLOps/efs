# AWS EFS Lab - Complete Testing Guide

## Your Instance Details
```
Instance 1 IP: 44.193.223.78
Instance 2 IP: 3.91.178.93
Key File: efs-lab-key.pem
```

---

## STEP-BY-STEP TESTING PROCEDURE

### STEP 1: Connect to Instance 1

**From CloudShell or Local Terminal:**
```bash
ssh -i efs-lab-key.pem ec2-user@44.193.223.78
```

**First time connection**: Type `yes` when asked about host authenticity

**Alternative (Browser):**
1. Go to EC2 Console
2. Select "EFS-Lab-Instance-1"
3. Click "Connect" → "EC2 Instance Connect" → "Connect"

---

### STEP 2: Verify EFS is Mounted on Instance 1

**Check if EFS is mounted:**
```bash
df -h | grep efs
```

**Expected Output:**
```
fs-xxxxxxxxx.efs.us-east-1.amazonaws.com:/  8.0E     0  8.0E   0% /mnt/efs
```

**Check mount point:**
```bash
mountpoint /mnt/efs
```

**Expected Output:**
```
/mnt/efs is a mountpoint
```

**List EFS contents:**
```bash
ls -la /mnt/efs/
```

**Expected Output:**
```
total 8
drwxrwxrwx 2 root root 6144 Mar  9 10:30 .
drwxr-xr-x 3 root root   17 Mar  9 10:25 ..
-rw-r--r-- 1 root root   65 Mar  9 10:30 mount-info-ip-10-0-1-xxx.txt
```

**✅ VERIFICATION**: If you see the EFS mount and mount-info file, EFS is working on Instance 1

---

### STEP 3: Create Test File on Instance 1

**Create a simple test file:**
```bash
echo "Hello from Instance 1" | sudo tee /mnt/efs/test-from-instance1.txt
```

**Expected Output:**
```
Hello from Instance 1
```

**Create a directory with multiple files:**
```bash
sudo mkdir -p /mnt/efs/shared-data
echo "File 1 content" | sudo tee /mnt/efs/shared-data/file1.txt
echo "File 2 content" | sudo tee /mnt/efs/shared-data/file2.txt
echo "File 3 content" | sudo tee /mnt/efs/shared-data/file3.txt
```

**Create a file with timestamp:**
```bash
echo "Created by Instance 1 at $(date)" | sudo tee /mnt/efs/timestamp-instance1.txt
```

**List all files created:**
```bash
ls -lR /mnt/efs/
```

**Expected Output:**
```
/mnt/efs/:
total 12
drwxr-xr-x 2 root root 6144 Mar  9 10:35 shared-data
-rw-r--r-- 1 root root   24 Mar  9 10:32 test-from-instance1.txt
-rw-r--r-- 1 root root   45 Mar  9 10:33 timestamp-instance1.txt
-rw-r--r-- 1 root root   65 Mar  9 10:30 mount-info-ip-10-0-1-xxx.txt

/mnt/efs/shared-data:
total 12
-rw-r--r-- 1 root root 16 Mar  9 10:35 file1.txt
-rw-r--r-- 1 root root 16 Mar  9 10:35 file2.txt
-rw-r--r-- 1 root root 16 Mar  9 10:35 file3.txt
```

**✅ VERIFICATION**: Files are created and stored in EFS

---

### STEP 4: Connect to Instance 2

**Open a NEW terminal/CloudShell tab** (keep Instance 1 connection open)

**From CloudShell or Local Terminal:**
```bash
ssh -i efs-lab-key.pem ec2-user@3.91.178.93
```

**Alternative (Browser):**
1. Go to EC2 Console
2. Select "EFS-Lab-Instance-2"
3. Click "Connect" → "EC2 Instance Connect" → "Connect"

---

### STEP 5: Verify EFS is Mounted on Instance 2

**Check if EFS is mounted:**
```bash
df -h | grep efs
```

**Expected Output:**
```
fs-xxxxxxxxx.efs.us-east-1.amazonaws.com:/  8.0E     0  8.0E   0% /mnt/efs
```

**✅ VERIFICATION**: Same EFS filesystem ID as Instance 1

---

### STEP 6: Verify Shared Storage - Read Files from Instance 1

**List all files:**
```bash
ls -lR /mnt/efs/
```

**Expected Output:**
```
You should see ALL files created from Instance 1:
- test-from-instance1.txt
- timestamp-instance1.txt
- shared-data/ directory with file1.txt, file2.txt, file3.txt
- mount-info files from both instances
```

**Read the test file created from Instance 1:**
```bash
cat /mnt/efs/test-from-instance1.txt
```

**Expected Output:**
```
Hello from Instance 1
```

**Read the timestamp file:**
```bash
cat /mnt/efs/timestamp-instance1.txt
```

**Read files from shared-data directory:**
```bash
cat /mnt/efs/shared-data/file1.txt
cat /mnt/efs/shared-data/file2.txt
cat /mnt/efs/shared-data/file3.txt
```

**🎉 SUCCESS INDICATOR**: If you can read files created from Instance 1, EFS shared storage is working!

---

### STEP 7: Create Test File on Instance 2

**Create test file:**
```bash
echo "Hello from Instance 2" | sudo tee /mnt/efs/test-from-instance2.txt
```

**Create timestamp file:**
```bash
echo "Created by Instance 2 at $(date)" | sudo tee /mnt/efs/timestamp-instance2.txt
```

**Create additional files:**
```bash
echo "Instance 2 data" | sudo tee /mnt/efs/shared-data/file-from-instance2.txt
```

**List all files:**
```bash
ls -lR /mnt/efs/
```

**Expected Output:**
```
You should now see files from BOTH instances
```

---

### STEP 8: Go Back to Instance 1 and Verify

**Switch back to Instance 1 terminal**

**List all files:**
```bash
ls -lR /mnt/efs/
```

**Read file created from Instance 2:**
```bash
cat /mnt/efs/test-from-instance2.txt
```

**Expected Output:**
```
Hello from Instance 2
```

**Read timestamp from Instance 2:**
```bash
cat /mnt/efs/timestamp-instance2.txt
```

**Read the new file in shared-data:**
```bash
cat /mnt/efs/shared-data/file-from-instance2.txt
```

**Expected Output:**
```
Instance 2 data
```

**🎉 FINAL SUCCESS**: If Instance 1 can read files created by Instance 2, EFS is fully working!

---

## WHAT TO VERIFY (CHECKLIST)

### ✅ On Instance 1:
- [ ] EFS is mounted at /mnt/efs
- [ ] Can create files in /mnt/efs
- [ ] Can create directories in /mnt/efs
- [ ] Can read files created by Instance 2

### ✅ On Instance 2:
- [ ] EFS is mounted at /mnt/efs
- [ ] Can see files created by Instance 1
- [ ] Can create new files
- [ ] Can read and write to same directories

### ✅ Shared Storage Proof:
- [ ] File created on Instance 1 is visible on Instance 2
- [ ] File created on Instance 2 is visible on Instance 1
- [ ] Both instances show same file count
- [ ] Both instances can modify same files

---

## ADVANCED TESTING (OPTIONAL)

### Test 1: Concurrent File Creation

**On Instance 1:**
```bash
for i in {1..5}; do 
    echo "Instance1-File-$i" | sudo tee /mnt/efs/instance1-$i.txt
done
```

**On Instance 2:**
```bash
for i in {1..5}; do 
    echo "Instance2-File-$i" | sudo tee /mnt/efs/instance2-$i.txt
done
```

**On both instances:**
```bash
ls /mnt/efs/ | wc -l
```

**Expected**: Both should show the same file count

---

### Test 2: Large File Transfer

**On Instance 1:**
```bash
sudo dd if=/dev/zero of=/mnt/efs/largefile.dat bs=1M count=100
```

This creates a 100MB file

**On Instance 2:**
```bash
ls -lh /mnt/efs/largefile.dat
```

**Expected**: Should show 100M file size

---

### Test 3: File Permissions

**On Instance 1:**
```bash
echo "Permission test" | sudo tee /mnt/efs/permtest.txt
sudo chmod 644 /mnt/efs/permtest.txt
ls -l /mnt/efs/permtest.txt
```

**On Instance 2:**
```bash
ls -l /mnt/efs/permtest.txt
```

**Expected**: Same permissions on both instances

---

### Test 4: Real-time Sync

**On Instance 1:**
```bash
watch -n 1 'ls -la /mnt/efs/ | tail -5'
```

**On Instance 2 (in another terminal):**
```bash
for i in {1..10}; do 
    echo "Realtime-$i" | sudo tee /mnt/efs/realtime-$i.txt
    sleep 2
done
```

**Expected**: Instance 1 should show files appearing in real-time

---

## TROUBLESHOOTING

### Issue: EFS not mounted

**Check user data logs:**
```bash
sudo cat /var/log/user-data.log
```

**Manual mount:**
```bash
sudo mount -t efs fs-xxxxxxxxx:/ /mnt/efs
```

**Check if EFS utils installed:**
```bash
rpm -qa | grep amazon-efs-utils
```

---

### Issue: Permission denied

**Fix permissions:**
```bash
sudo chmod 777 /mnt/efs
```

---

### Issue: Files not syncing

**Check mount on both instances:**
```bash
df -h | grep efs
```

**Verify same EFS ID:**
```bash
mount | grep efs
```

Both should show the same `fs-xxxxxxxxx` ID

---

## CLEANUP AFTER TESTING

**When you're done:**

```bash
# Exit from EC2 instances
exit

# In CloudShell, run cleanup
cd ~/efs
./cleanup-efs-lab.sh
```

This deletes all resources and stops AWS charges.

---

## SUMMARY OF WHAT YOU PROVED

✅ **EFS is shared storage** - Multiple EC2 instances access the same files
✅ **Multi-AZ availability** - Instances in different AZs share storage
✅ **Real-time sync** - Changes appear immediately on all instances
✅ **Persistent storage** - Data survives instance reboots
✅ **Network File System** - Uses NFS protocol over port 2049

---

## INTERVIEW TALKING POINTS

**Q: What did you verify in this lab?**
A: I verified that EFS provides shared network storage across multiple EC2 instances in different availability zones. Files created on one instance were immediately visible on another instance, proving EFS works as distributed storage.

**Q: How is EFS different from EBS?**
A: EBS is block storage attached to a single EC2 instance, like a hard drive. EFS is network file storage that multiple instances can mount simultaneously, like a shared network drive.

**Q: What protocol does EFS use?**
A: EFS uses NFS (Network File System) protocol on port 2049. That's why we needed to allow port 2049 in the security group.

**Q: Why did we create mount targets in different AZs?**
A: For high availability. If one AZ fails, instances in other AZs can still access EFS through their local mount targets, ensuring business continuity.

**Q: What happens if one instance deletes a file?**
A: The file is immediately deleted from EFS and disappears from all other instances, because they all share the same storage.

---

## REAL-WORLD USE CASES YOU CAN MENTION

1. **Web Applications**: Multiple web servers share uploaded images/files
2. **Container Storage**: Kubernetes pods share persistent volumes
3. **Content Management**: WordPress sites share media library
4. **Machine Learning**: Training nodes access shared datasets
5. **Development**: Team shares code repositories and build artifacts

---

**Lab Complete! You now have hands-on EFS experience.**
