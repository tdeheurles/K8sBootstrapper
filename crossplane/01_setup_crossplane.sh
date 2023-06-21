#!/usr/bin/env bash

set -euo pipefail

namespace="crossplane-system"

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm upgrade crossplane --install \
    --namespace="${namespace}" --create-namespace \
    crossplane-stable/crossplane \
    -f crossplane_helm_settings.yaml

echo "wait deployment to be ready"
kubectl wait deployment crossplane -n "${namespace}" --for=condition=Available=true --timeout=600s
kubectl wait deployment crossplane-rbac-manager -n "${namespace}" --for=condition=Available=true --timeout=600s
