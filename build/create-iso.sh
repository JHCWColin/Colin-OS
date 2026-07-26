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

resolve_live_build_isolinux_source_dir() {
  local candidate

  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux" \
    "/usr/lib/live/build/bootloaders/isolinux"; do
    if [[ -f "${candidate}/isolinux.bin" && -f "${candidate}/vesamenu.c32" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  printf '%s\n' '${_SOURCE}'
}

resolve_live_build_isolinux_template_dir() {
  local candidate

  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux" \
    "/usr/lib/live/build/bootloaders/isolinux"; do
    if [[ -d "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  printf 'Unable to locate live-build isolinux template directory.\n' >&2
  exit 1
}

find_syslinux_asset() {
  local asset_name="$1"
  local candidate
  local dpkg_package=""
  local dpkg_pattern=""

  case "${asset_name}" in
    isolinux.bin)
      for candidate in \
        "/usr/share/live/build/bootloaders/isolinux/isolinux.bin" \
        "/usr/lib/ISOLINUX/isolinux.bin" \
        "/usr/lib/syslinux/isolinux.bin" \
        "/usr/lib/syslinux/mbr/isolinux.bin"; do
        if [[ -f "${candidate}" ]]; then
          printf '%s\n' "${candidate}"
          return 0
        fi
      done

      dpkg_package="isolinux"
      dpkg_pattern='isolinux\.bin$'
      ;;

    vesamenu.c32)
      for candidate in \
        "/usr/share/live/build/bootloaders/isolinux/vesamenu.c32" \
        "/usr/lib/syslinux/modules/bios/vesamenu.c32" \
        "/usr/lib/syslinux/vesamenu.c32" \
        "/usr/lib/SYSLINUX/vesamenu.c32"; do
        if [[ -f "${candidate}" ]]; then
          printf '%s\n' "${candidate}"
          return 0
        fi
      done

      dpkg_package="syslinux-common"
      dpkg_pattern='vesamenu\.c32$'
      ;;

    *)
      printf 'Unsupported syslinux asset lookup: %s\n' "${asset_name}" >&2
      return 1
      ;;
  esac

  if command -v dpkg >/dev/null 2>&1; then
    local dpkg_path
    dpkg_path="$(dpkg -L "${dpkg_package}" 2>/dev/null | grep -m1 "${dpkg_pattern}" || true)"
    if [[ -n "${dpkg_path}" && -f "${dpkg_path}" ]]; then
      printf '%s\n' "${dpkg_path}"
      return 0
    fi
  fi

  return 1
}

prepare_local_syslinux_bootloader_dir() {
  local template_dir
  local bootloader_dir="${WORKSPACE_DIR}/config/bootloaders/isolinux"
  local candidate

  template_dir="$(resolve_live_build_isolinux_template_dir)"

  rm -rf "${bootloader_dir}"
  mkdir -p "${bootloader_dir}"

  printf 'Preparing local live-build isolinux bootloader dir from: %s\n' "${template_dir}"

  while IFS= read -r -d '' candidate; do
    local base_name
    base_name="$(basename "${candidate}")"

    case "${base_name}" in
      isolinux.bin|vesamenu.c32)
        local asset_path
        asset_path="$(find_syslinux_asset "${base_name}")" || {
          printf 'Unable to locate required syslinux asset for local bootloader dir: %s\n' "${base_name}" >&2
          exit 1
        }
        cp -f "${asset_path}" "${bootloader_dir}/${base_name}"
        ;;

      *)
        if [[ -L "${candidate}" ]]; then
          cp -fL "${candidate}" "${bootloader_dir}/${base_name}"
        else
          cp -f "${candidate}" "${bootloader_dir}/${base_name}"
        fi
        ;;
    esac
  done < <(find "${template_dir}" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -print0)

  if [[ ! -f "${bootloader_dir}/isolinux.bin" ]]; then
    printf 'Local bootloader dir is missing isolinux.bin: %s\n' "${bootloader_dir}" >&2
    exit 1
  fi

  if [[ ! -f "${bootloader_dir}/vesamenu.c32" ]]; then
    printf 'Local bootloader dir is missing vesamenu.c32: %s\n' "${bootloader_dir}" >&2
    exit 1
  fi

  ls -lh "${bootloader_dir}"
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

patch_live_build_syslinux_helpers() {
  local replacement_dir
  local candidate
  local search_dir
  local patched=0

  replacement_dir="$(resolve_live_build_isolinux_source_dir)"

  for search_dir in \
    "/usr/lib/live/build" \
    "/usr/share/live/build"; do
    [[ -d "${search_dir}" ]] || continue

    while IFS= read -r -d '' candidate; do
      if [[ "$(basename "${candidate}")" == "lb_binary_syslinux" ]] && grep -q 'binary/live/vmlinuz-' "${candidate}"; then
        sed -i 's|binary/live/|binary/casper/|g' "${candidate}"
        printf 'Patched live-build casper kernel path helper: %s\n' "${candidate}"
        patched=1
      fi

      if grep -q '/root/isolinux' "${candidate}"; then
        sed -i "s|/root/isolinux|${replacement_dir//|/\\|}|g" "${candidate}"
        printf 'Patched live-build syslinux helper: %s\n' "${candidate}"
        patched=1
      fi
    done < <(find "${search_dir}" -type f \( -name '*syslinux*' -o -name '*isolinux*' \) -print0)
  done

  if [[ "${patched}" -eq 0 ]]; then
    return 0
  fi

  for search_dir in \
    "/usr/lib/live/build" \
    "/usr/share/live/build"; do
    [[ -d "${search_dir}" ]] || continue

    while IFS= read -r -d '' candidate; do
      if [[ "$(basename "${candidate}")" == "lb_binary_syslinux" ]] && grep -q 'binary/live/vmlinuz-' "${candidate}"; then
        printf 'live-build syslinux helper still contains binary/live kernel paths: %s\n' "${candidate}" >&2
        exit 1
      fi

      if grep -q '/root/isolinux' "${candidate}"; then
        printf 'live-build syslinux helper still contains /root/isolinux: %s\n' "${candidate}" >&2
        exit 1
      fi
    done < <(find "${search_dir}" -type f \( -name '*syslinux*' -o -name '*isolinux*' \) -print0)
  done
}

prepare_syslinux_compat_paths() {
  local host_compat_dir="/root/isolinux"
  local chroot_compat_dir="${WORKSPACE_DIR}/config/includes.chroot/root/isolinux"
  mkdir -p "${host_compat_dir}" "${chroot_compat_dir}"

  printf 'Searching for syslinux/isolinux files...\n'

  # Find isolinux.bin
  local isolinux_bin_found=0
  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux/isolinux.bin" \
    "/usr/lib/ISOLINUX/isolinux.bin" \
    "/usr/lib/syslinux/isolinux.bin" \
    "/usr/lib/syslinux/mbr/isolinux.bin"; do
    if [[ -f "${candidate}" ]]; then
      printf 'Found isolinux.bin at: %s\n' "${candidate}"
      cp -f "${candidate}" "${host_compat_dir}/isolinux.bin"
      cp -f "${candidate}" "${chroot_compat_dir}/isolinux.bin"
      isolinux_bin_found=1
      break
    fi
  done

  # If still not found, use dpkg to locate it
  if [[ "${isolinux_bin_found}" -eq 0 ]]; then
    printf 'Standard paths failed, searching via dpkg...\n'
    local dpkg_path
    dpkg_path="$(dpkg -L isolinux 2>/dev/null | grep -m1 'isolinux\.bin$' || true)"
    if [[ -n "${dpkg_path}" && -f "${dpkg_path}" ]]; then
      printf 'Found isolinux.bin via dpkg at: %s\n' "${dpkg_path}"
      cp -f "${dpkg_path}" "${host_compat_dir}/isolinux.bin"
      cp -f "${dpkg_path}" "${chroot_compat_dir}/isolinux.bin"
      isolinux_bin_found=1
    fi
  fi

  # Find vesamenu.c32
  local vesamenu_found=0
  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux/vesamenu.c32" \
    "/usr/lib/syslinux/modules/bios/vesamenu.c32" \
    "/usr/lib/syslinux/vesamenu.c32" \
    "/usr/lib/SYSLINUX/vesamenu.c32"; do
    if [[ -f "${candidate}" ]]; then
      printf 'Found vesamenu.c32 at: %s\n' "${candidate}"
      cp -f "${candidate}" "${host_compat_dir}/vesamenu.c32"
      cp -f "${candidate}" "${chroot_compat_dir}/vesamenu.c32"
      vesamenu_found=1
      break
    fi
  done

  # If still not found, use dpkg to locate it
  if [[ "${vesamenu_found}" -eq 0 ]]; then
    printf 'Standard paths failed, searching via dpkg...\n'
    local dpkg_path
    dpkg_path="$(dpkg -L syslinux-common 2>/dev/null | grep -m1 'vesamenu\.c32$' || true)"
    if [[ -n "${dpkg_path}" && -f "${dpkg_path}" ]]; then
      printf 'Found vesamenu.c32 via dpkg at: %s\n' "${dpkg_path}"
      cp -f "${dpkg_path}" "${host_compat_dir}/vesamenu.c32"
      cp -f "${dpkg_path}" "${chroot_compat_dir}/vesamenu.c32"
      vesamenu_found=1
    fi
  fi

  # Copy all other necessary syslinux modules
  local source_dir=""
  for candidate in \
    "/usr/share/live/build/bootloaders/isolinux" \
    "/usr/lib/syslinux/modules/bios" \
    "/usr/lib/ISOLINUX"; do
    if [[ -d "${candidate}" ]]; then
      printf 'Copying additional modules from: %s\n' "${candidate}"
      source_dir="${candidate}"
      while IFS= read -r -d '' path; do
        local basename_file
        basename_file="$(basename "${path}")"
        # Skip if already copied
        [[ -f "${host_compat_dir}/${basename_file}" ]] && continue
        cp -f "${path}" "${host_compat_dir}/${basename_file}"
        cp -f "${path}" "${chroot_compat_dir}/${basename_file}"
      done < <(find "${candidate}" -maxdepth 1 -type f \( -name '*.c32' -o -name '*.bin' \) -print0)
      break
    fi
  done

  # Final verification
  if [[ ! -f "${host_compat_dir}/isolinux.bin" ]]; then
    printf 'ERROR: isolinux.bin not found after exhaustive search.\n' >&2
    printf 'Searched paths:\n' >&2
    printf '  - /usr/share/live/build/bootloaders/isolinux/\n' >&2
    printf '  - /usr/lib/ISOLINUX/\n' >&2
    printf '  - /usr/lib/syslinux/\n' >&2
    printf '  - dpkg -L isolinux\n' >&2
    printf '\nAvailable files in /usr/lib:\n' >&2
    find /usr/lib -name 'isolinux.bin' 2>/dev/null || printf '  (none found)\n' >&2
    exit 1
  fi

  if [[ ! -f "${host_compat_dir}/vesamenu.c32" ]]; then
    printf 'ERROR: vesamenu.c32 not found after exhaustive search.\n' >&2
    printf 'Searched paths:\n' >&2
    printf '  - /usr/share/live/build/bootloaders/isolinux/\n' >&2
    printf '  - /usr/lib/syslinux/modules/bios/\n' >&2
    printf '  - /usr/lib/syslinux/\n' >&2
    printf '  - dpkg -L syslinux-common\n' >&2
    printf '\nAvailable files in /usr/lib:\n' >&2
    find /usr/lib -name 'vesamenu.c32' 2>/dev/null || printf '  (none found)\n' >&2
    exit 1
  fi

  printf 'Successfully prepared syslinux compatibility paths:\n'
  printf '  - %s/isolinux.bin\n' "${host_compat_dir}"
  printf '  - %s/vesamenu.c32\n' "${host_compat_dir}"
  ls -lh "${host_compat_dir}"
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
  patch_live_build_syslinux_helpers
  prepare_local_syslinux_bootloader_dir
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
