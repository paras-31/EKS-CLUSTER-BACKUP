#!/bin/bash

# EKS Cluster Backup Script
# This script exports all Kubernetes resources from your EKS cluster
# Usage: ./backup-all-resources.sh

BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Starting EKS cluster backup to: $BACKUP_DIR"
echo "========================================"

# Get cluster info
echo "Backing up cluster info..."
kubectl cluster-info > "$BACKUP_DIR/00-cluster-info.txt"
kubectl get nodes -o yaml > "$BACKUP_DIR/01-nodes.yaml"

# Get all namespaces
echo "Getting all namespaces..."
kubectl get namespaces -o yaml > "$BACKUP_DIR/02-namespaces.yaml"

# For each namespace, export all resources
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

for ns in $NAMESPACES; do
  echo "Backing up namespace: $ns"
  mkdir -p "$BACKUP_DIR/$ns"
  
  # Export all resources in the namespace
  kubectl get all -n "$ns" -o yaml > "$BACKUP_DIR/$ns/00-all-resources.yaml"
  
  # Export other important resources
  kubectl get configmap -n "$ns" -o yaml > "$BACKUP_DIR/$ns/01-configmaps.yaml"
  kubectl get secrets -n "$ns" -o yaml > "$BACKUP_DIR/$ns/02-secrets.yaml"
  kubectl get pvc -n "$ns" -o yaml > "$BACKUP_DIR/$ns/03-pvc.yaml"
  kubectl get pv -o yaml > "$BACKUP_DIR/$ns/04-pv.yaml"
  kubectl get services -n "$ns" -o yaml > "$BACKUP_DIR/$ns/05-services.yaml"
  kubectl get ingress -n "$ns" -o yaml > "$BACKUP_DIR/$ns/06-ingress.yaml"
  kubectl get networkpolicy -n "$ns" -o yaml > "$BACKUP_DIR/$ns/07-networkpolicy.yaml"
  kubectl get rolebindings -n "$ns" -o yaml > "$BACKUP_DIR/$ns/08-rolebindings.yaml"
  kubectl get roles -n "$ns" -o yaml > "$BACKUP_DIR/$ns/09-roles.yaml"
  kubectl get clusterrolebindings -o yaml > "$BACKUP_DIR/$ns/10-clusterrolebindings.yaml"
  kubectl get clusterroles -o yaml > "$BACKUP_DIR/$ns/11-clusterroles.yaml"
  kubectl get serviceaccounts -n "$ns" -o yaml > "$BACKUP_DIR/$ns/12-serviceaccounts.yaml"
  
done

# Cluster-wide resources
echo "Backing up cluster-wide resources..."
mkdir -p "$BACKUP_DIR/cluster-wide"
kubectl get clusterrolebindings -o yaml > "$BACKUP_DIR/cluster-wide/01-clusterrolebindings.yaml"
kubectl get clusterroles -o yaml > "$BACKUP_DIR/cluster-wide/02-clusterroles.yaml"
kubectl get pv -o yaml > "$BACKUP_DIR/cluster-wide/03-persistentvolumes.yaml"
kubectl get storageclass -o yaml > "$BACKUP_DIR/cluster-wide/04-storageclass.yaml"

# Get helm releases if helm is available
if command -v helm &> /dev/null; then
  echo "Backing up Helm releases..."
  mkdir -p "$BACKUP_DIR/helm"
  helm list --all-namespaces -o json > "$BACKUP_DIR/helm/releases.json"
  
  for release in $(helm list -q); do
    helm get values "$release" > "$BACKUP_DIR/helm/${release}-values.yaml"
  done
fi

# Create a summary
echo "Creating backup summary..."
cat > "$BACKUP_DIR/BACKUP_SUMMARY.txt" << EOF
EKS Cluster Backup Summary
========================
Backup Date: $(date)
Cluster Info: $(kubectl cluster-info 2>/dev/null | head -1)

Namespaces Backed Up:
$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

Resources Included:
- Deployments
- StatefulSets
- DaemonSets
- Services
- Ingresses
- ConfigMaps
- Secrets
- PersistentVolumes
- PersistentVolumeClaims
- RBAC (Roles, RoleBindings, ClusterRoles, ClusterRoleBindings)
- ServiceAccounts
- NetworkPolicies
- StorageClasses

How to Restore:
1. Copy this backup folder to your new account
2. Run: kubectl apply -f cluster-wide/
3. For each namespace folder: kubectl apply -f <namespace-name>/

Note: 
- Review and update any hardcoded values (IPs, domain names, AWS account IDs)
- Some resources might need manual recreation (e.g., IAM roles, RDS databases)
- Secrets are exported; handle securely
EOF

echo "========================================"
echo "Backup completed successfully!"
echo "Backup location: $BACKUP_DIR"
echo "Total files created: $(find "$BACKUP_DIR" -type f | wc -l)"
echo "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"
