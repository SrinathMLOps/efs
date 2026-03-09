# AWS Cleanup Scripts - Usage Guide

## ⚠️ Important Safety Information

These scripts can delete resources across your entire AWS account. Use with caution!

---

## 🎯 Available Cleanup Scripts

### 1. `scan-all-regions.sh` (SAFE - Read Only)
**Purpose**: Scan all regions for paid resources WITHOUT deleting

**Usage**:
```bash
chmod +x scan-all-regions.sh
./scan-all-regions.sh
```

**What it does**:
- Scans ALL AWS regions
- Lists all paid resources found
- Estimates monthly cost
- Generates detailed report file
- **Does NOT delete anything**

**Output**: Creates `aws-resources-report-YYYYMMDD-HHMMSS.txt`

**Use this FIRST** to see what exists before deleting!

---

### 2. `verify-and-cleanup-all.sh` (SAFE - EFS Lab Only)
**Purpose**: Cleanup EFS lab resources in current region

**Usage**:
```bash
chmod +x verify-and-cleanup-all.sh
./verify-and-cleanup-all.sh
```

**What it does**:
- Checks current region
- Scans for EFS lab resources only
- Shows what it found
- Asks for confirmation
- Deletes only EFS lab resources
- Verifies cleanup

**Scope**: Only EFS-Lab-* tagged resources in one region

---

### 3. `cleanup-all-efs-resources.sh` (SAFE - EFS Lab Only)
**Purpose**: Direct cleanup of EFS lab resources

**Usage**:
```bash
chmod +x cleanup-all-efs-resources.sh
./cleanup-all-efs-resources.sh
```

**What it does**:
- Deletes EFS lab resources immediately
- No confirmation prompts
- Single region only

**Scope**: Only EFS-Lab-* resources

---

### 4. `cleanup-all-regions.sh` (DANGEROUS)
**Purpose**: Delete paid resources in ALL regions

**Usage**:
```bash
chmod +x cleanup-all-regions.sh
./cleanup-all-regions.sh
```

**What it does**:
- Scans ALL regions
- Deletes EC2, RDS, EFS, Load Balancers, NAT Gateways, etc.
- Requires typing 'DELETE-ALL-RESOURCES' to confirm

**⚠️ WARNING**: This deletes resources across your ENTIRE AWS account!

---

### 5. `DANGER-cleanup-all-regions.sh` (VERY DANGEROUS)
**Purpose**: Safety wrapper for account-wide cleanup

**Usage**:
```bash
chmod +x DANGER-cleanup-all-regions.sh
./DANGER-cleanup-all-regions.sh
```

**What it does**:
- Shows danger warning
- Recommends running scan first
- Requires typing 'YES-DELETE-EVERYTHING'
- Calls cleanup-all-regions.sh

**⚠️ WARNING**: Use only if you want to clean entire account!

---

## 🎯 RECOMMENDED WORKFLOW

### For EFS Lab Cleanup:
```bash
# Step 1: Check what exists
./verify-and-cleanup-all.sh

# It will show resources and ask for confirmation
# Type 'y' to delete
```

### For Account-Wide Cleanup:
```bash
# Step 1: Scan first (SAFE)
./scan-all-regions.sh

# Step 2: Review the report
cat aws-resources-report-*.txt

# Step 3: If you want to delete everything
./DANGER-cleanup-all-regions.sh

# Type: YES-DELETE-EVERYTHING
```

---

## 📊 What Each Script Deletes

### `verify-and-cleanup-all.sh` (EFS Lab Only):
- ✅ EC2 instances tagged "EFS-Lab-Instance-*"
- ✅ EFS file systems named "EFS-Lab-FileSystem"
- ✅ VPCs tagged "EFS-Lab-VPC"
- ✅ Security groups named "EFS-Lab-*"
- ✅ Subnets tagged "EFS-Lab-Subnet-*"
- ✅ Internet gateways tagged "EFS-Lab-IGW"
- ✅ Route tables tagged "EFS-Lab-RT"
- ✅ Key pairs named "efs-lab-key"

### `cleanup-all-regions.sh` (Everything):
- ❌ ALL EC2 instances (all regions)
- ❌ ALL RDS databases (all regions)
- ❌ ALL EFS file systems (all regions)
- ❌ ALL Load Balancers (all regions)
- ❌ ALL NAT Gateways (all regions)
- ❌ ALL Elastic IPs (unattached)
- ❌ ALL EBS volumes (unattached)
- ❌ ALL Lambda functions (all regions)
- ❌ ALL ECS clusters (all regions)
- ❌ ALL VPCs (non-default)

**Does NOT delete**:
- S3 buckets (may contain data)
- IAM roles (may be in use)
- CloudFormation stacks
- Route53 zones
- CloudWatch logs

---

## 🛡️ SAFETY FEATURES

### Built-in Protections:
1. **Confirmation prompts** - Must type exact phrase
2. **Scan before delete** - Shows what will be deleted
3. **Verification after** - Confirms cleanup success
4. **Region detection** - Shows which region you're in
5. **Report generation** - Creates audit trail

### What's Protected:
- Default VPCs (not deleted)
- Default security groups (not deleted)
- S3 buckets (not deleted - may have data)
- IAM roles (not deleted - may be in use)
- Attached EBS volumes (not deleted - in use)
- Associated Elastic IPs (not deleted - in use)

---

## 💡 BEST PRACTICES

### Before Running Cleanup:

1. **Scan first**:
```bash
./scan-all-regions.sh
cat aws-resources-report-*.txt
```

2. **Check AWS Console** - Verify resources manually

3. **Backup important data** - Download any needed files

4. **Take screenshots** - Document what you're deleting

5. **Check billing** - Note current charges

### After Running Cleanup:

1. **Verify in console** - Check resources are gone

2. **Wait 5 minutes** - Some deletions take time

3. **Check billing dashboard** - Verify charges stopped

4. **Review report** - Keep audit trail

---

## 🚨 EMERGENCY STOP

If script is running and you want to stop:

**Press**: `Ctrl + C`

**Note**: Resources already deleted cannot be recovered!

---

## 📋 CLEANUP CHECKLIST

### For EFS Lab:
- [ ] Run `./verify-and-cleanup-all.sh`
- [ ] Confirm deletion when prompted
- [ ] Wait for completion
- [ ] Verify "Region is clean" message

### For Entire Account:
- [ ] Run `./scan-all-regions.sh` first
- [ ] Review report file
- [ ] Backup any important data
- [ ] Run `./DANGER-cleanup-all-regions.sh`
- [ ] Type confirmation phrase
- [ ] Wait for completion (may take 10-15 minutes)
- [ ] Check AWS Console
- [ ] Verify billing dashboard

---

## 🎯 QUICK REFERENCE

| Script | Scope | Safety | Use When |
|--------|-------|--------|----------|
| `scan-all-regions.sh` | All regions | ✅ Safe | Want to see what exists |
| `verify-and-cleanup-all.sh` | Current region | ✅ Safe | Cleanup EFS lab only |
| `cleanup-all-efs-resources.sh` | Current region | ✅ Safe | Quick EFS lab cleanup |
| `cleanup-all-regions.sh` | All regions | ⚠️ Dangerous | Clean entire account |
| `DANGER-cleanup-all-regions.sh` | All regions | ⚠️ Very Dangerous | Nuclear option |

---

## 💰 COST SAVINGS

### Typical Savings After Cleanup:

| Resource | Monthly Cost | After Cleanup |
|----------|--------------|---------------|
| t2.micro EC2 (2) | $16 | $0 |
| RDS db.t3.micro | $25 | $0 |
| NAT Gateway | $35 | $0 |
| Load Balancer | $20 | $0 |
| EFS (1GB) | $0.30 | $0 |
| Elastic IP (unused) | $3.60 | $0 |
| **Total** | **~$100/month** | **$0** |

---

## 🔍 VERIFICATION COMMANDS

### Check if region is clean:
```bash
# EC2 instances
aws ec2 describe-instances --region us-east-1 --query 'Reservations[*].Instances[*].InstanceId'

# EFS file systems
aws efs describe-file-systems --region us-east-1 --query 'FileSystems[*].FileSystemId'

# RDS databases
aws rds describe-db-instances --region us-east-1 --query 'DBInstances[*].DBInstanceIdentifier'

# Load balancers
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].LoadBalancerName'
```

### Check billing:
1. Go to AWS Console → Billing Dashboard
2. Check "Month-to-date costs"
3. View "Cost by service"

---

## 🆘 TROUBLESHOOTING

### Issue: Script says resources remain

**Solution**: Wait 2-3 minutes and run again
```bash
sleep 180
./verify-and-cleanup-all.sh
```

### Issue: Cannot delete VPC

**Cause**: Dependencies still exist (subnets, IGW, etc.)

**Solution**: Script handles this automatically, but if manual:
1. Delete all subnets first
2. Detach and delete IGW
3. Delete security groups
4. Delete route tables
5. Then delete VPC

### Issue: Permission denied

**Cause**: IAM user lacks permissions

**Solution**: Ensure your IAM user has these policies:
- AmazonEC2FullAccess
- AmazonRDSFullAccess
- AmazonElasticFileSystemFullAccess
- ElasticLoadBalancingFullAccess

---

## 📞 SUPPORT

### Before Running Cleanup:
1. Read this guide completely
2. Run scan-all-regions.sh first
3. Review the report
4. Backup important data

### If Something Goes Wrong:
1. Press Ctrl+C to stop
2. Check AWS Console for remaining resources
3. Review script output for errors
4. Run scan again to see current state

---

## ⚠️ FINAL WARNING

**These scripts are powerful tools that can delete your entire AWS infrastructure.**

**Always**:
- ✅ Scan before deleting
- ✅ Review what will be deleted
- ✅ Backup important data
- ✅ Understand what you're doing
- ✅ Use EFS-lab-specific scripts when possible

**Never**:
- ❌ Run on production accounts
- ❌ Run without scanning first
- ❌ Run without understanding impact
- ❌ Run if you're unsure

---

## 🎯 RECOMMENDED USAGE

### For EFS Lab (Safe):
```bash
./verify-and-cleanup-all.sh
```

### For Learning Account (Scan First):
```bash
./scan-all-regions.sh
# Review report
./DANGER-cleanup-all-regions.sh
```

### For Production (DON'T USE THESE SCRIPTS):
Use AWS Organizations, Service Control Policies, and proper resource tagging instead.

---

**Use responsibly! 🛡️**
