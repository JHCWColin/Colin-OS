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

  printf 'Patching live-build syslinux helpers (replacement dir: %s)...\n' "${replacement_dir}"

  for search_dir in \
    /usr/lib/live/build \
    /usr/share/live/build; do
    [[ -d "${search_dir}" ]] || continue

    while IFS= read -r -d '' candidate; do
      if [[ "$(basename "${candidate}")" == "lb_binary_iso" ]] && grep -q 'Check_package chroot/usr/bin/isohybrid syslinux' "${candidate}"; then
        sed -i 's|Check_package chroot/usr/bin/isohybrid syslinux|Check_package chroot/usr/bin/isohybrid syslinux-utils|g' "${candidate}"
        printf 'Patched live-build isohybrid package mapping in %s\n' "${candidate}"
        patched=1
      fi

      if [[ "$(basename "${candidate}")" == "lb_binary_syslinux" ]] && grep -q 'binary/live/vmlinuz-' "${candidate}"; then
        sed -i 's|binary/live/|binary/casper/|g' "${candidate}"
        printf 'Patched live-build casper kernel path handling in %s\n' "${candidate}"
        patched=1
      fi

      if grep -q '/root/isolinux' "${candidate}"; then
        sed -i "s|/root/isolinux|${replacement_dir//|/\\|}|g" "${candidate}"
        printf 'Patched live-build syslinux path handling in %s\n' "${candidate}"
        patched=1
      fi
    done < <(find "${search_dir}" -type f \( -name '*syslinux*' -o -name '*isolinux*' \) -print0)
  done

  if [[ "${patched}" -eq 0 ]]; then
    printf 'No live-build syslinux helpers required patching.\n'
    return 0
  fi

  # Verify patching was successful
  for search_dir in \
    /usr/lib/live/build \
    /usr/share/live/build; do
    [[ -d "${search_dir}" ]] || continue

    while IFS= read -r -d '' candidate; do
      if [[ "$(basename "${candidate}")" == "lb_binary_iso" ]] && grep -q 'Check_package chroot/usr/bin/isohybrid syslinux' "${candidate}"; then
        printf 'WARNING: live-build ISO helper still maps isohybrid to syslinux: %s\n' "${candidate}" >&2
        printf 'This may break iso-hybrid builds inside chroot.\n' >&2
      fi

      if [[ "$(basename "${candidate}")" == "lb_binary_syslinux" ]] && grep -q 'binary/live/vmlinuz-' "${candidate}"; then
        printf 'WARNING: live-build syslinux helper still contains binary/live kernel paths: %s\n' "${candidate}" >&2
        printf 'This may break Ubuntu/casper ISO builds.\n' >&2
      fi

      if grep -q '/root/isolinux' "${candidate}"; then
        printf 'WARNING: live-build syslinux helper still contains /root/isolinux: %s\n' "${candidate}" >&2
        printf 'This may cause build failures.\n' >&2
      fi
    done < <(find "${search_dir}" -type f \( -name '*syslinux*' -o -name '*isolinux*' -o -name 'lb_binary_iso' \) -print0)
  done
}

verify_syslinux_installation() {
  printf '\nVerifying syslinux/isolinux installation...\n'

  printf 'Checking for isolinux.bin:\n'
  if dpkg -L isolinux 2>/dev/null | grep -i 'isolinux\.bin'; then
    printf '  ✓ Found via isolinux package\n'
  else
    printf '  ✗ Not found in isolinux package\n'
  fi

  printf 'Checking for vesamenu.c32:\n'
  if dpkg -L syslinux-common 2>/dev/null | grep -i 'vesamenu\.c32'; then
    printf '  ✓ Found via syslinux-common package\n'
  else
    printf '  ✗ Not found in syslinux-common package\n'
  fi

  printf '\nSearching filesystem for these files:\n'
  find /usr -name 'isolinux.bin' 2>/dev/null || printf '  (no isolinux.bin found)\n'
  find /usr -name 'vesamenu.c32' 2>/dev/null || printf '  (no vesamenu.c32 found)\n'
  printf '\n'
}

prepare_syslinux_compat_paths() {
  local host_compat_dir="/root/isolinux"
  local candidate
  local source_dir=""

  mkdir -p "${host_compat_dir}"

  printf 'Preparing /root/isolinux compatibility files...\n'

  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux/isolinux.bin" \
    "/usr/lib/ISOLINUX/isolinux.bin" \
    "/usr/lib/syslinux/isolinux.bin" \
    "/usr/lib/syslinux/mbr/isolinux.bin"; do
    if [[ -f "${candidate}" ]]; then
      printf '  Found isolinux.bin at: %s\n' "${candidate}"
      cp -f "${candidate}" "${host_compat_dir}/isolinux.bin"
      break
    fi
  done

  if [[ ! -f "${host_compat_dir}/isolinux.bin" ]]; then
    printf '  Standard paths failed, searching via dpkg...\n'
    local dpkg_path
    dpkg_path="$(dpkg -L isolinux 2>/dev/null | grep -m1 'isolinux\.bin$' || true)"
    if [[ -n "${dpkg_path}" && -f "${dpkg_path}" ]]; then
      printf '  Found isolinux.bin via dpkg at: %s\n' "${dpkg_path}"
      cp -f "${dpkg_path}" "${host_compat_dir}/isolinux.bin"
    fi
  fi

  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux/vesamenu.c32" \
    "/usr/lib/syslinux/modules/bios/vesamenu.c32" \
    "/usr/lib/syslinux/vesamenu.c32" \
    "/usr/lib/SYSLINUX/vesamenu.c32"; do
    if [[ -f "${candidate}" ]]; then
      printf '  Found vesamenu.c32 at: %s\n' "${candidate}"
      cp -f "${candidate}" "${host_compat_dir}/vesamenu.c32"
      break
    fi
  done

  if [[ ! -f "${host_compat_dir}/vesamenu.c32" ]]; then
    printf '  Standard paths failed, searching via dpkg...\n'
    local dpkg_path
    dpkg_path="$(dpkg -L syslinux-common 2>/dev/null | grep -m1 'vesamenu\.c32$' || true)"
    if [[ -n "${dpkg_path}" && -f "${dpkg_path}" ]]; then
      printf '  Found vesamenu.c32 via dpkg at: %s\n' "${dpkg_path}"
      cp -f "${dpkg_path}" "${host_compat_dir}/vesamenu.c32"
    fi
  fi

  for source_dir in \
    "/usr/share/live/build/bootloaders/isolinux" \
    "/usr/lib/syslinux/modules/bios" \
    "/usr/lib/ISOLINUX"; do
    if [[ -d "${source_dir}" ]]; then
      while IFS= read -r -d '' candidate; do
        local base_name
        base_name="$(basename "${candidate}")"
        [[ -f "${host_compat_dir}/${base_name}" ]] && continue
        cp -f "${candidate}" "${host_compat_dir}/${base_name}"
      done < <(find "${source_dir}" -maxdepth 1 -type f \( -name '*.c32' -o -name '*.bin' \) -print0)
      break
    fi
  done

  if [[ ! -f "${host_compat_dir}/isolinux.bin" ]]; then
    printf 'ERROR: isolinux.bin not staged in %s\n' "${host_compat_dir}" >&2
    exit 1
  fi

  if [[ ! -f "${host_compat_dir}/vesamenu.c32" ]]; then
    printf 'ERROR: vesamenu.c32 not staged in %s\n' "${host_compat_dir}" >&2
    exit 1
  fi

  printf 'Compatibility files staged in %s\n' "${host_compat_dir}"
}

apt-get update
# Install the bootloader assets first so live-build's package scripts can see /root/isolinux.
apt-get install -y \
  isolinux \
  syslinux \
  syslinux-utils \
  syslinux-common

verify_syslinux_installation
prepare_syslinux_compat_paths

apt-get install -y \
  live-build \
  debootstrap \
  xorriso \
  squashfs-tools \
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

verify_syslinux_installation
patch_live_build_syslinux
