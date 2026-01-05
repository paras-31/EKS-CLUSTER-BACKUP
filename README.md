# EKS Cluster Backup Guide

## Overview
This backup solution helps you export all Kubernetes resources from your EKS cluster before account deletion. You can then restore them to a new AWS account.

## Backup Scripts

### 1. Full Backup (Recommended)
```bash
chmod +x backup-all-resources.sh
./backup-all-resources.sh
```

**What it backs up:**
- All namespaces and their resources
- Deployments, StatefulSets, DaemonSets
- Services, Ingresses, LoadBalancers
- ConfigMaps, Secrets
- PersistentVolumes, PersistentVolumeClaims, StorageClasses
- RBAC (Roles, RoleBindings, ClusterRoles, ClusterRoleBindings)
- ServiceAccounts
- NetworkPolicies
- Helm releases (if available)

**Output:** Creates a timestamped directory with organized backup files

### 2. Quick Backup (Single File)
```bash
chmod +x quick-backup.sh
./quick-backup.sh
```

**Output:** Creates a single YAML file with all resources

## Step-by-Step Backup Instructions

### Step 1: Run the Backup
```bash
cd /path/to/EKS-BACKUP
./backup-all-resources.sh
```

### Step 2: Store the Backup
- Copy the backup directory to a safe location (GitHub, S3, external drive)
- Example: `git add backup-*/ && git commit -m "EKS cluster backup before account deletion"`

### Step 3: Verification (Optional but Recommended)
```bash
# Verify backup contents
ls -la backup-YYYYMMDD-HHMMSS/
find backup-YYYYMMDD-HHMMSS/ -type f | wc -l  # Count files
du -sh backup-YYYYMMDD-HHMMSS/                  # Check size
```

## Restoration Instructions (For New Account)

### Prerequisites
- New AWS account set up
- EKS cluster created in new account
- kubectl configured to point to new cluster
- AWS credentials configured

### Step 1: Restore Cluster-Wide Resources
```bash
kubectl apply -f backup-YYYYMMDD-HHMMSS/cluster-wide/
```

### Step 2: Restore Namespaces and Resources
```bash
# Restore each namespace
kubectl apply -f backup-YYYYMMDD-HHMMSS/cluster-wide/namespaces.yaml

# For each namespace
for ns in backup-YYYYMMDD-HHMMSS/*/; do
  namespace=$(basename "$ns")
  kubectl apply -f "$ns"
done
```

### Step 3: Manual Steps Required
These resources need manual recreation and cannot be automated:

1. **AWS IAM Roles & Policies**
   - ServiceAccount IAM role bindings (IRSA)
   - Pod execution roles
   - Update the IAM role ARNs in ServiceAccounts

2. **External Resources**
   - RDS Databases
   - S3 Buckets
   - DynamoDB Tables
   - ElastiCache Clusters
   - Update connection strings in ConfigMaps/Secrets

3. **LoadBalancer Services**
   - AWS Load Balancers will get new ARNs
   - Update DNS records pointing to new LoadBalancer IPs

4. **Secrets with AWS References**
   - Recreate secrets with new AWS resource ARNs
   - Re-encrypt if using KMS

5. **EBS Volumes**
   - Snapshots won't transfer between accounts
   - Create new volumes or use snapshots from source account

## Important Considerations

### ⚠️ Security
- **Secrets are included in backup**: Handle with care!
- Store backup in secure location (encrypted storage, private GitHub, etc.)
- Don't commit secrets to public repositories
- Consider using sealed-secrets or external-secrets for production

### Account ID References
After restoration, search and replace:
- Old AWS Account ID → New AWS Account ID
- Old VPC IDs → New VPC IDs
- Old IAM role ARNs → New IAM role ARNs

### Quick Find & Replace Script
```bash
OLD_ACCOUNT_ID="111111111111"
NEW_ACCOUNT_ID="222222222222"
BACKUP_DIR="backup-YYYYMMDD-HHMMSS"

find "$BACKUP_DIR" -name "*.yaml" -exec sed -i '' "s/$OLD_ACCOUNT_ID/$NEW_ACCOUNT_ID/g" {} \;
```

## Backup Content Checklist

- [ ] Namespaces backed up
- [ ] All Deployments saved
- [ ] Services and Ingresses saved
- [ ] ConfigMaps and Secrets saved
- [ ] PersistentVolumes and PersistentVolumeClaims saved
- [ ] RBAC roles and bindings saved
- [ ] Helm charts saved (if applicable)
- [ ] Cluster-wide resources saved
- [ ] Backup stored in safe location
- [ ] Backup tested/verified

## Troubleshooting

### Backup fails with permission denied
```bash
# Make scripts executable
chmod +x backup-all-resources.sh quick-backup.sh
```

### kubectl commands not found
```bash
# Install/update kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Backup too large
```bash
# Exclude certain namespaces
# Edit the script and modify the namespace loop
```

## Additional Resources

- [Kubernetes Official Backup Documentation](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-cluster/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Velero - Automated Backup Tool](https://velero.io/)

## Need More Help?

For production workloads, consider using:
- **Velero**: Automated Kubernetes backup and disaster recovery
- **AWS Backup**: Integrated backup solution for AWS resources
- **Kasten by Veeam**: Enterprise backup for Kubernetes

---
**Last Updated:** $(date)
**Script Version:** 1.0
