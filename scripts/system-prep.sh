#!/usr/bin/env bash
set -euo pipefail

# System
sudo tee /etc/sysctl.d/99-local.conf > /dev/null <<'EOF'
# Kubernetes networking
net.ipv4.ip_forward = 1

# VM writeback
## Background writeback: 4 GiB
vm.dirty_background_bytes = 4294967296

## Process throttling: 8 GiB
vm.dirty_bytes = 8589934592
EOF

sudo sysctl --load /etc/sysctl.d/99-local.conf
