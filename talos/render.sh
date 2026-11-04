#!/usr/bin/env bash
set -euo pipefail

talosctl gen secrets -o secrets.yaml
chmod 600 secrets.yaml

talosctl gen config \
  management-cluster \
  https://10.212.212.10:6443 \
  --version "v1alpha1" \
  --talos-version "v1.14.5" \
  --kubernetes-version "v1.37.1" \
  --install-image factory.talos.dev/metal-installer-secureboot/863b1b95844901950f94fd66fa38136b5bf447151b3e143648b711a6e0caf44a:v1.14.5 \
  --additional-sans kube.home.arpa \
  --with-secrets secrets.yaml \
  --with-docs=false \
  --with-examples=false \
  --with-cluster-discovery=false \
  --config-patch @patches/common/discoveryidentity.yaml \
  --config-patch @patches/common/discoveryservice.yaml \
  --config-patch @patches/common/kubeprism.yaml \
  --config-patch @patches/common/kubespan.yaml \
  --output-types controlplane,talosconfig \
  --output .

talosctl machineconfig patch controlplane.yaml \
  --patch @patches/nodes/cp-0/hostname.yaml \
  --patch @patches/nodes/cp-0/network.yaml \
  --patch @patches/nodes/cp-0/storage.yaml \
  --patch @patches/nodes/cp-0/dns.yaml \
  --patch @patches/nodes/cp-0/ntp.yaml \
  --patch @patches/nodes/cp-0/sysctl.yaml \
  --patch @patches/nodes/cp-0/flannel.yaml \
  --patch @patches/nodes/cp-0/volume.yaml \
  --patch @patches/nodes/cp-0/kubeovn.yaml \
  --patch @patches/nodes/cp-0/zfs.yaml \
  --patch @patches/nodes/cp-0/kubenode.yaml \
  --output rendered/cp-0.yaml

talosctl validate \
  --config rendered/cp-0.yaml \
  --mode metal

cp talosconfig "$HOME/.talos/config" -f
talosctl config endpoint 10.212.212.10
talosctl config node 10.212.212.10
