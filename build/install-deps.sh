#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Please run as root: sudo bash build/install-deps.sh\n' >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  live-build \
  debootstrap \
  xorriso \
  squashfs-tools \
  syslinux \
  syslinux-common \
  grub-pc-bin \
  grub-efi-amd64-bin \
  mtools \
  dosfstools \
  ca-certificates \
  curl \
  wget \
  git \
  rsync \
  gnupg \
  ubuntu-keyring
