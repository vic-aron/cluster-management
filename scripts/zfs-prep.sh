#!/usr/bin/env bash
set -euo pipefail

# Packages
sudo apt-get update
sudo apt-get install -y zfs

# Zpools
## NVME RAID
zpool create \
  -o ashift=12 \
  -o autotrim=on \
  -o autoexpand=on \
  -o autoreplace=off \
  -o failmode=wait \
  -O dnodesize=auto \
  -O compression=lz4 \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  -O mountpoint=none \
  tank mirror \
  /dev/disk/by-id/nvme-CT1000P5PSSD8_23374344D313 \
  /dev/disk/by-id/nvme-CT1000P5PSSD8_233743452905

## HDD RAID
sudo zpool create \
  -o ashift=12 \
  -o autotrim=off \
  -o autoexpand=on \
  -o autoreplace=off \
  -o failmode=wait \
  -O dnodesize=auto \
  -O compression=lz4 \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  -O mountpoint=/extank \
  extank raidz1 \
  /dev/disk/by-id/ata-HDD1 \
  /dev/disk/by-id/ata-HDD2 \
  /dev/disk/by-id/ata-HDD3 \
  /dev/disk/by-id/ata-HDD4

# Encryption keys
sudo install -d -m 700 /root/.zfs

for key in kubernetes media backups share; do
    file="/root/.zfs/${key}.key"

    if [[ ! -e "$file" ]]; then
        sudo dd if=/dev/urandom of="$file" bs=32 count=1 status=none
        sudo chmod 400 "$file"
    else
        echo "Key already exists: $file – skip creation"
    fi
done

# Parent datasets
## NVME datasets
sudo zfs create \
  -o encryption=aes-256-gcm \
  -o keyformat=raw \
  -o keylocation=file:///root/.zfs/kubernetes.key \
  -o mountpoint=/tank/kubernetes \
  -o quota=1TB \
  -o recordsize=128K \
  tank/kubernetes

## HDD datasets
sudo zfs create \
  -o encryption=aes-256-gcm \
  -o keyformat=raw \
  -o keylocation=file:///root/.zfs/media.key \
  -o mountpoint=/extank/media \
  -o quota=4TB \
  extank/media

sudo zfs create \
  -o encryption=aes-256-gcm \
  -o keyformat=raw \
  -o keylocation=file:///root/.zfs/backups.key \
  -o mountpoint=/extank/backups \
  -o quota=500GB \
  extank/backups

sudo zfs create \
  -o encryption=aes-256-gcm \
  -o keyformat=raw \
  -o keylocation=file:///root/.zfs/share.key \
  -o mountpoint=/extank/share \
  -o quota=50GB \
  extank/share

# Child datasets
## HDD child datasets
sudo zfs create \
  -o recordsize=1M \
  extank/media/movies

sudo zfs create \
  -o recordsize=1M \
  extank/media/series

sudo zfs create \
  -o recordsize=128K \
  extank/media/music

sudo zfs create \
  -o recordsize=128K \
  extank/backups/etcd

sudo zfs create \
  -o recordsize=128K \
  extank/backups/persistentvolumes

sudo zfs create \
  -o recordsize=128K \
  extank/share/sftp
