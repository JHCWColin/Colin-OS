#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Please run as root: sudo bash build/install-deps.sh\n' >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

resolve_live_build_isolinux_source_dir() {
  local candidate

  for candidate in \
    /usr/share/live/build/bootloaders/isolinux \
    /usr/lib/live/build/bootloaders/isolinux; do
    if [[ -f "${candidate}/isolinux.bin" && -f "${candidate}/vesamenu.c32" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  printf '%s\n' '${_SOURCE}'
}

patch_live_build_syslinux() {
  local replacement_dir
  local candidate
  local search_dir
  local patched=0

  replacement_dir="$(resolve_live_build_isolinux_source_dir)"

  for search_dir in \
    /usr/lib/live/build \
    /usr/share/live/build; do
    [[ -d "${search_dir}" ]] || continue

    while IFS= read -r -d '' candidate; do
      if grep -q '/root/isolinux' "${candidate}"; then
        sed -i "s|/root/isolinux|${replacement_dir//|/\\|}|g" "${candidate}"
        printf 'Patched live-build syslinux path handling in %s\n' "${candidate}"
        patched=1
      fi
    done < <(find "${search_dir}" -type f \( -name '*syslinux*' -o -name '*isolinux*' \) -print0)
  done

  if [[ "${patched}" -eq 0 ]]; then
    return 0
  fi

  for search_dir in \
    /usr/lib/live/build \
    /usr/share/live/build; do
    [[ -d "${search_dir}" ]] || continue

    while IFS= read -r -d '' candidate; do
      if grep -q '/root/isolinux' "${candidate}"; then
        printf 'live-build syslinux helper still contains /root/isolinux: %s\n' "${candidate}" >&2
        exit 1
      fi
    done < <(find "${search_dir}" -type f \( -name '*syslinux*' -o -name '*isolinux*' \) -print0)
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
