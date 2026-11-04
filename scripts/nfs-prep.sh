#!/usr/bin/env bash
set -euo pipefail

# Packages
sudo apt-get update
sudo apt-get install -y nfs-common nfs-server

# Exports
sudo tee /etc/exports > /dev/null <<'EOF'
/extank/media/movies  10.212.212.0/24(ro,sync,no_subtree_check,root_squash)
/extank/media/series  10.212.212.0/24(ro,sync,no_subtree_check,root_squash)
/extank/media/music   10.212.212.0/24(ro,sync,no_subtree_check,root_squash)
/extank/backups/etcd   10.212.212.0/24(rw,sync,no_subtree_check,root_squash)
/extank/backups/persistentvolumes   10.212.212.0/24(rw,sync,no_subtree_check,root_squash)
EOF

sudo systemctl enable --now nfs-server
sudo exportfs -ra
