#!/usr/bin/env bash

set -euo pipefail

# aws provider config
kubectl create secret \
  generic aws-secret \
  -n crossplane-system \
  --from-file=creds=./aws-credentials.txt || true

kubectl apply -f ./providers
for provider in \
  provider-family-aws \
  provider-aws-s3 \
  provider-aws-dynamodb \
  provider-kubernetes
do
  echo -e "\nwait provider ${provider} to be ready"
  kubectl wait "provider/${provider}" --for=condition=Healthy=true --timeout=600s
done

cat <<EOF | kubectl apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF

SA=$(kubectl -n crossplane-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g')
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"

cat <<EOF | kubectl apply -f -
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: InjectedIdentity
EOF
