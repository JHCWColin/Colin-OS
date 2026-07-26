#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ISO_DIR="${REPO_ROOT}/out/iso"
RELEASE_DIR="${REPO_ROOT}/out/release"

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "${command_name}" >&2
    exit 1
  fi
}

main() {
  local iso_path
  local iso_name
  local archive_base
  local part_glob

  require_command 7z
  require_command sha256sum

  mkdir -p "${RELEASE_DIR}"
  find "${RELEASE_DIR}" -mindepth 1 ! -name '.gitkeep' -delete

  shopt -s nullglob
  local iso_files=("${ISO_DIR}"/*.iso)
  shopt -u nullglob

  if [[ "${#iso_files[@]}" -eq 0 ]]; then
    printf 'No ISO files found in %s\n' "${ISO_DIR}" >&2
    exit 1
  fi

  for iso_path in "${iso_files[@]}"; do
    iso_name="$(basename "${iso_path}")"
    archive_base="${RELEASE_DIR}/${iso_name}.7z"
    part_glob="${archive_base}.*"

    rm -f ${part_glob}
    printf 'Creating split 7z archive for %s\n' "${iso_name}"
    7z a -t7z -mx=9 -v1g "${archive_base}" "${iso_path}"

    if [[ -f "${ISO_DIR}/${iso_name}.sha256" ]]; then
      cp -f "${ISO_DIR}/${iso_name}.sha256" "${RELEASE_DIR}/${iso_name}.sha256"
    else
      sha256sum "${iso_path}" > "${RELEASE_DIR}/${iso_name}.sha256"
    fi

    (
      cd "${RELEASE_DIR}"
      sha256sum "${iso_name}.7z".* > "${iso_name}.7z.sha256"
    )
  done
}

main "$@"
