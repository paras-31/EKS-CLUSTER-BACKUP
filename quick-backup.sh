#!/bin/bash

# Quick EKS Backup - Minimal version
# Exports all resources to a single comprehensive YAML file

BACKUP_FILE="eks-backup-$(date +%Y%m%d-%H%M%S).yaml"

echo "Creating quick backup: $BACKUP_FILE"

# Create header
cat > "$BACKUP_FILE" << 'EOF'
# EKS Cluster Backup
# Generated on: 
EOF

date >> "$BACKUP_FILE"

# Export all resources from all namespaces
echo "# Exporting all resources..." >> "$BACKUP_FILE"
kubectl get all -A -o yaml >> "$BACKUP_FILE"

echo "# Exporting ConfigMaps..." >> "$BACKUP_FILE"
kubectl get configmap -A -o yaml >> "$BACKUP_FILE"

echo "# Exporting Secrets..." >> "$BACKUP_FILE"
kubectl get secrets -A -o yaml >> "$BACKUP_FILE"

echo "# Exporting PersistentVolumeClaims..." >> "$BACKUP_FILE"
kubectl get pvc -A -o yaml >> "$BACKUP_FILE"

echo "# Exporting PersistentVolumes..." >> "$BACKUP_FILE"
kubectl get pv -o yaml >> "$BACKUP_FILE"

echo "# Exporting Ingresses..." >> "$BACKUP_FILE"
kubectl get ingress -A -o yaml >> "$BACKUP_FILE"

echo "# Exporting NetworkPolicies..." >> "$BACKUP_FILE"
kubectl get networkpolicy -A -o yaml >> "$BACKUP_FILE"

echo "# Exporting RBAC..." >> "$BACKUP_FILE"
kubectl get clusterrolebindings -o yaml >> "$BACKUP_FILE"
kubectl get clusterroles -o yaml >> "$BACKUP_FILE"
kubectl get rolebindings -A -o yaml >> "$BACKUP_FILE"
kubectl get roles -A -o yaml >> "$BACKUP_FILE"

echo "# Exporting StorageClasses..." >> "$BACKUP_FILE"
kubectl get storageclass -o yaml >> "$BACKUP_FILE"

echo "Backup completed!"
echo "File: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
