#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./build/build.sh [version]

Description:
  Main Colin OS build entrypoint. It prepares the live-build workspace
  and then assembles the ISO.

Environment variables:
  COLIN_VERSION   Override release version. Defaults to Git tag or 0.1.0-dev.
  COLIN_CLEAN     Set to 0 to skip workspace cleanup. Default: 1
  COLIN_JOBS      Parallel job hint for compatible tools. Default: detected CPU count
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

VERSION_ARG="${1:-}"
if [[ -n "${VERSION_ARG}" ]]; then
  export COLIN_VERSION="${VERSION_ARG}"
fi

if [[ -z "${COLIN_JOBS:-}" ]]; then
  if command -v nproc >/dev/null 2>&1; then
    export COLIN_JOBS="$(nproc)"
  else
    export COLIN_JOBS="4"
  fi
fi

export COLIN_CLEAN="${COLIN_CLEAN:-1}"

bash "${SCRIPT_DIR}/package.sh"
bash "${SCRIPT_DIR}/create-iso.sh"
