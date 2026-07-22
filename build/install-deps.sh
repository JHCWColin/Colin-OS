#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Please run as root: sudo bash build/install-deps.sh\n' >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

patch_live_build_syslinux() {
  local candidate

  for candidate in \
    /usr/lib/live/build/lb_binary_syslinux \
    /usr/lib/live/build/binary_syslinux; do
    [[ -f "${candidate}" ]] || continue

    if grep -q '/root/isolinux' "${candidate}"; then
      sed -i 's|/root/isolinux|${_SOURCE}|g' "${candidate}"
      printf 'Patched live-build syslinux path handling in %s\n' "${candidate}"
    fi
  done
}

apt-get update
apt-get install -y \
  live-build \
  debootstrap \
  xorriso \
  squashfs-tools \
  isolinux \
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

patch_live_build_syslinux
