#!/usr/bin/env bash

set -euo pipefail

kubectl delete xrd --all
kubectl delete managed --all
kubectl delete provider --all
helm uninstall crossplane --namespace crossplane-system
