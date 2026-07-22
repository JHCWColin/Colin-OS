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
    --image-name "${image_name}" \
    | tee "${LOG_DIR}/lb-config-${COLIN_VERSION}.log"

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
