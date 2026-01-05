#!/bin/bash

# Export a specific namespace
# Usage: ./export-specific-namespace.sh <namespace-name>

if [ -z "$1" ]; then
  echo "Usage: $0 <namespace-name>"
  echo "Example: $0 monitoring"
  echo ""
  echo "Available namespaces:"
  kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
  exit 1
fi

NAMESPACE="$1"
EXPORT_DIR="export-$NAMESPACE-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$EXPORT_DIR"

echo "Exporting namespace: $NAMESPACE to $EXPORT_DIR"

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo "ERROR: Namespace '$NAMESPACE' not found!"
  exit 1
fi

# Export all resources
echo "Exporting all resources..."
kubectl get all -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/01-all-resources.yaml"

echo "Exporting ConfigMaps..."
kubectl get configmap -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/02-configmaps.yaml"

echo "Exporting Secrets..."
kubectl get secrets -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/03-secrets.yaml"

echo "Exporting PersistentVolumeClaims..."
kubectl get pvc -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/04-pvc.yaml"

echo "Exporting Services..."
kubectl get services -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/05-services.yaml"

echo "Exporting Ingresses..."
kubectl get ingress -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/06-ingress.yaml"

echo "Exporting NetworkPolicies..."
kubectl get networkpolicy -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/07-networkpolicy.yaml"

echo "Exporting RBAC..."
kubectl get rolebindings -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/08-rolebindings.yaml"
kubectl get roles -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/09-roles.yaml"
kubectl get serviceaccounts -n "$NAMESPACE" -o yaml > "$EXPORT_DIR/10-serviceaccounts.yaml"

echo ""
echo "Export completed!"
echo "Directory: $EXPORT_DIR"
echo "Files created: $(find "$EXPORT_DIR" -type f | wc -l)"
echo "Total size: $(du -sh "$EXPORT_DIR" | cut -f1)"
