#!/usr/bin/env bash

set -euo pipefail

kubectl create ns argocd || true
kubectl apply \
  -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch configmap/argocd-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"accounts.provider-argocd":"apiKey"}}'

kubectl patch configmap/argocd-rbac-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"policy.csv":"g, provider-argocd, role:admin"}}'

ARGOCD_ADMIN_SECRET=$(kubectl view-secret argocd-initial-admin-secret -n argocd -q)
kubectl -n argocd port-forward svc/argocd-server 8443:443 &
sleep 3
ARGOCD_ADMIN_TOKEN=$(curl -s -X POST -k -H "Content-Type: application/json" --data '{"username":"admin","password":"'$ARGOCD_ADMIN_SECRET'"}' https://localhost:8443/api/v1/session | jq -r .token)
ARGOCD_PROVIDER_USER="provider-argocd"
ARGOCD_TOKEN=$(curl -s -X POST -k -H "Authorization: Bearer $ARGOCD_ADMIN_TOKEN" -H "Content-Type: application/json" https://localhost:8443/api/v1/account/$ARGOCD_PROVIDER_USER/token | jq -r .token)
kubectl create secret generic argocd-credentials \
  -n crossplane-system \
  --from-literal=authToken="$ARGOCD_TOKEN"

kubectl apply -f ./argocd-manifests

echo "-----------------------------------------"
echo "ARGOCD_ADMIN_SECRET=$ARGOCD_ADMIN_SECRET"
echo "-----------------------------------------"
