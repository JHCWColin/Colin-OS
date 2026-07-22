#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${REPO_ROOT}/out/work/live-build"
ISO_DIR="${REPO_ROOT}/out/iso"
LOG_DIR="${REPO_ROOT}/out/logs"
BUILD_ENV_FILE="${WORKSPACE_DIR}/build.env"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "${command_name}" >&2
    exit 1
  fi
}

load_build_env() {
  if [[ ! -f "${BUILD_ENV_FILE}" ]]; then
    printf 'Build environment file not found: %s\n' "${BUILD_ENV_FILE}" >&2
    printf 'Run build/package.sh first or use build/build.sh.\n' >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "${BUILD_ENV_FILE}"
}

apply_syslinux_theme_workaround() {
  local syslinux_theme="${COLIN_SYSLINUX_THEME:-live-build}"
  local config_file

  for config_file in \
    "${WORKSPACE_DIR}/config/common" \
    "${WORKSPACE_DIR}/config/binary"; do
    [[ -f "${config_file}" ]] || continue

    if grep -q '^LB_SYSLINUX_THEME=' "${config_file}"; then
      sed -i "s/^LB_SYSLINUX_THEME=.*/LB_SYSLINUX_THEME=\"${syslinux_theme//\//\\/}\"/" "${config_file}"
    else
      printf '\nLB_SYSLINUX_THEME="%s"\n' "${syslinux_theme}" >> "${config_file}"
    fi
  done
}

prepare_syslinux_compat_paths() {
  local host_compat_dir="/root/isolinux"
  local chroot_compat_dir="${WORKSPACE_DIR}/config/includes.chroot/root/isolinux"
  mkdir -p "${host_compat_dir}" "${chroot_compat_dir}"

  local source_dir=""
  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux" \
    "/usr/lib/ISOLINUX" \
    "/usr/lib/syslinux/modules/bios"; do
    if [[ -d "${candidate}" ]]; then
      source_dir="${candidate}"
      break
    fi
  done

  if [[ -n "${source_dir}" ]]; then
    while IFS= read -r -d '' path; do
      cp -f "${path}" "${host_compat_dir}/$(basename "${path}")"
      cp -f "${path}" "${chroot_compat_dir}/$(basename "${path}")"
    done < <(find "${source_dir}" -maxdepth 1 -type f -print0)
  fi

  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux/isolinux.bin" \
    "/usr/lib/ISOLINUX/isolinux.bin" \
    "/usr/lib/syslinux/isolinux.bin"; do
    if [[ -f "${candidate}" ]]; then
      cp -f "${candidate}" "${host_compat_dir}/isolinux.bin"
      cp -f "${candidate}" "${chroot_compat_dir}/isolinux.bin"
      break
    fi
  done

  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux/vesamenu.c32" \
    "/usr/lib/syslinux/modules/bios/vesamenu.c32" \
    "/usr/lib/syslinux/vesamenu.c32"; do
    if [[ -f "${candidate}" ]]; then
      cp -f "${candidate}" "${host_compat_dir}/vesamenu.c32"
      cp -f "${candidate}" "${chroot_compat_dir}/vesamenu.c32"
      break
    fi
  done

  if [[ ! -f "${host_compat_dir}/isolinux.bin" || ! -f "${host_compat_dir}/vesamenu.c32" ]]; then
    printf 'Unable to resolve syslinux compatibility files on the host.\n' >&2
    printf 'Checked live-build bootloader assets, isolinux, and syslinux package paths.\n' >&2
    exit 1
  fi
}

reset_saved_lb_config() {
  rm -rf \
    "${WORKSPACE_DIR}/config/bootstrap" \
    "${WORKSPACE_DIR}/config/chroot" \
    "${WORKSPACE_DIR}/config/binary" \
    "${WORKSPACE_DIR}/config/source" \
    "${WORKSPACE_DIR}/config/common"
}

main() {
  require_command lb
  require_command sha256sum

  load_build_env

  mkdir -p "${ISO_DIR}" "${LOG_DIR}"

  local image_name="Colin-OS-${COLIN_VERSION}-amd64"
  local build_log="${LOG_DIR}/lb-build-${COLIN_VERSION}.log"
  local iso_path="${WORKSPACE_DIR}/live-image-amd64.hybrid.iso"
  local output_iso="${ISO_DIR}/${image_name}.iso"
  local checksum_file="${ISO_DIR}/${image_name}.sha256"

  pushd "${WORKSPACE_DIR}" >/dev/null

  lb clean --purge | tee "${LOG_DIR}/lb-clean-${COLIN_VERSION}.log"
  reset_saved_lb_config

  lb config \
    --mode ubuntu \
    --distribution noble \
    --architectures amd64 \
    --archive-areas "main restricted universe multiverse" \
    --binary-images iso-hybrid \
    --debian-installer false \
    --bootappend-live "boot=live components quiet splash username=colin hostname=colinos" \
    --linux-flavours generic \
    --mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
    --mirror-binary "http://archive.ubuntu.com/ubuntu/" \
    --mirror-chroot "http://archive.ubuntu.com/ubuntu/" \
    --apt-recommends true \
    --checksums sha256 \
    --cache true \
    --cache-packages true \
    --cache-stages false \
    --iso-application "Colin OS" \
    --iso-publisher "Colin OS Project" \
    --iso-volume "${image_name}" \
    | tee "${LOG_DIR}/lb-config-${COLIN_VERSION}.log"

  apply_syslinux_theme_workaround
  prepare_syslinux_compat_paths

  lb build 2>&1 | tee "${build_log}"

  if [[ ! -f "${iso_path}" ]]; then
    popd >/dev/null
    printf 'Expected ISO not found at %s\n' "${iso_path}" >&2
    exit 1
  fi

  mv -f "${iso_path}" "${output_iso}"
  popd >/dev/null

  (
    cd "${ISO_DIR}"
    sha256sum "$(basename "${output_iso}")" > "$(basename "${checksum_file}")"
  )

  printf 'Created ISO: %s\n' "${output_iso}"
  printf 'Created checksum: %s\n' "${checksum_file}"
}

main "$@"
