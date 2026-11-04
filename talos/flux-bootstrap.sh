#!/usr/bin/env bash
set -euo pipefail

# CNI
helm install kube-ovn \
  oci://ghcr.io/kubeovn/charts/kube-ovn-v2 \
  --version v1.16.17 \
  --namespace kube-system \
  --create-namespace \
  --values ../infrastructure/kube-ovn-v2/values.yaml \
  --wait

# CSI
helm repo add openebs-zfslocalpv https://openebs.github.io/zfs-localpv
helm repo update

helm install zfs-localpv \
  openebs-zfslocalpv/zfs-localpv \
  --version v2.11.1 \
  --namespace openebs \
  --create-namespace \
  --values ../infrastructure/openebs/controller/values.yaml \
  --wait

# Flux SSH
kubectl create namespace flux-system \
  --dry-run=client \
  -o yaml | kubectl apply -f -

kubectl create secret generic flux-git-auth \
  --namespace flux-system \
  --from-file=identity="$HOME/.ssh/id_ed25519_flux"

# Flux Age
kubectl create secret generic sops-age \
  --namespace flux-system \
  --from-file=age.agekey="$HOME/.config/sops/age/mgmt.txt"

# Flux Operator
helm install flux-operator \
    oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --version v0.60.0 \
  --namespace flux-system \
  --create-namespace \
  --wait

# Flux Instance
kubectl apply -f flux-instance.yaml
