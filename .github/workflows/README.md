# GitHub Actions Workflows

## EKS Backup Workflow

This workflow automatically backs up your EKS cluster resources on a schedule.

### Setup Instructions

#### 1. Add Required Secrets to GitHub Repository

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

- **AWS_ACCESS_KEY_ID**: Your AWS access key
- **AWS_SECRET_ACCESS_KEY**: Your AWS secret key
- **AWS_REGION**: Your AWS region (e.g., us-east-1)
- **EKS_CLUSTER_NAME**: Your EKS cluster name

#### 2. How to Get AWS Credentials

```bash
# Create IAM user with EKS access
aws iam create-user --user-name eks-backup-bot

# Attach policy
aws iam attach-user-policy \
  --user-name eks-backup-bot \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSReadOnlyAccess

# Create access keys
aws iam create-access-key --user-name eks-backup-bot
```

### Features

✅ **Automatic Scheduling** - Runs daily at 2 AM UTC (customize in `.cron` field)
✅ **Manual Trigger** - Can be triggered manually from GitHub Actions tab
✅ **Auto-Commit** - Commits backup to repository automatically
✅ **Artifact Storage** - Stores backup as GitHub artifact (30 days retention)
✅ **Error Handling** - Notifications on failure

### Schedule Options

Edit the `cron` schedule in `eks-backup.yml`:

```yaml
schedule:
  - cron: '0 2 * * *'  # Daily at 2 AM UTC
  # - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM UTC
  # - cron: '0 2 1 * *'  # Monthly on 1st at 2 AM UTC
```

Cron format: `minute hour day month day-of-week`

### Manual Trigger

1. Go to GitHub → Actions tab
2. Select "EKS Cluster Backup" workflow
3. Click "Run workflow"
4. Select branch (main)
5. Click "Run workflow"

### Viewing Results

#### Check Logs
- GitHub → Actions tab → Latest run → Logs

#### Download Backup Artifact
- GitHub → Actions tab → Latest run → Artifacts
- Download `eks-backup` zip file

#### View Committed Backup
- GitHub → Commits
- Look for "Automated EKS backup" commits

### Cost Considerations

- **GitHub Actions**: 2,000 free minutes/month on public repos
- **Daily backups**: ~30 runs/month = minimal usage
- **Storage**: 500 MB free artifact storage

### Security Best Practices

⚠️ **Important:**

1. **Use IAM User** - Create dedicated IAM user for backup (not root account)
2. **Minimal Permissions** - Only grant EKS read access
3. **Rotate Credentials** - Regularly rotate AWS access keys
4. **Private Repository** - Keep repo private to protect backup data
5. **Secrets Management** - Never commit AWS credentials to code
6. **Backup Secrets** - Backup includes Kubernetes secrets; handle securely

### Example Policy for IAM User

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
```

### Troubleshooting

**Error: "aws eks update-kubeconfig failed"**
- Check AWS credentials in secrets
- Verify EKS_CLUSTER_NAME is correct
- Ensure cluster exists in specified region

**Error: "kubectl not found"**
- Workflow automatically installs kubectl
- Check internet connectivity in runner

**Backup not committed**
- Check if backup directory was created
- Verify git configuration
- Check write permissions

### Customization

#### Change Backup Directory
Edit in `eks-backup.yml`:
```yaml
- name: Run backup script
  run: |
    cd your-backup-directory  # Change this
    chmod +x backup-all-resources.sh
    ./backup-all-resources.sh
```

#### Add Slack Notifications
```yaml
- name: Notify Slack
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

#### Filter Namespaces
Modify `backup-all-resources.sh` to exclude certain namespaces:
```bash
EXCLUDE_NAMESPACES="kube-system kube-public kube-node-lease"
```

### Next Steps

1. ✅ Add secrets to GitHub
2. ✅ Verify workflow file is in `.github/workflows/`
3. ✅ Trigger workflow manually to test
4. ✅ Check logs for any errors
5. ✅ Schedule will run automatically daily

---
**Need help?** Check GitHub Actions documentation: https://docs.github.com/en/actions
