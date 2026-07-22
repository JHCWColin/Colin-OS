#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${REPO_ROOT}/build/live-build"
WORK_ROOT="${REPO_ROOT}/out/work"
WORKSPACE_DIR="${WORK_ROOT}/live-build"
ISO_DIR="${REPO_ROOT}/out/iso"
LOG_DIR="${REPO_ROOT}/out/logs"
PACKAGE_SOURCE_DIR="${REPO_ROOT}/configs/packages"
PACKAGE_TARGET_DIR="${WORKSPACE_DIR}/config/package-lists"
CHROOT_INCLUDE_DIR="${WORKSPACE_DIR}/config/includes.chroot"
BINARY_INCLUDE_DIR="${WORKSPACE_DIR}/config/includes.binary"
INSTALLER_INCLUDE_DIR="${WORKSPACE_DIR}/config/includes.installer"
DESKTOP_SOURCE_DIR="${REPO_ROOT}/configs/desktop"
BRANDING_SOURCE_DIR="${REPO_ROOT}/configs/branding"
ASSETS_SOURCE_DIR="${REPO_ROOT}/assets"
APPS_SOURCE_DIR="${REPO_ROOT}/apps"
DESKTOP_CHROOT_SOURCE_DIR="${DESKTOP_SOURCE_DIR}/includes.chroot"
DESKTOP_BINARY_SOURCE_DIR="${DESKTOP_SOURCE_DIR}/includes.binary"
DESKTOP_INSTALLER_SOURCE_DIR="${DESKTOP_SOURCE_DIR}/includes.installer"
DESKTOP_HOOK_SOURCE_DIR="${DESKTOP_SOURCE_DIR}/hooks"
BRANDING_CHROOT_SOURCE_DIR="${BRANDING_SOURCE_DIR}/includes.chroot"
BRANDING_BINARY_SOURCE_DIR="${BRANDING_SOURCE_DIR}/includes.binary"
BRANDING_INSTALLER_SOURCE_DIR="${BRANDING_SOURCE_DIR}/includes.installer"
BRANDING_HOOK_SOURCE_DIR="${BRANDING_SOURCE_DIR}/hooks"

resolve_version() {
  if [[ -n "${COLIN_VERSION:-}" ]]; then
    printf '%s\n' "${COLIN_VERSION}"
    return
  fi

  if command -v git >/dev/null 2>&1 && git -C "${REPO_ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
    git -C "${REPO_ROOT}" describe --tags --exact-match
    return
  fi

  printf '%s\n' "0.1.0-dev"
}

copy_tree_contents() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ ! -d "${source_dir}" ]]; then
    return
  fi

  mkdir -p "${target_dir}"

  while IFS= read -r -d '' path; do
    local relative
    relative="${path#${source_dir}/}"

    if [[ "${relative}" == ".gitkeep" ]]; then
      continue
    fi

    if [[ -d "${path}" ]]; then
      mkdir -p "${target_dir}/${relative}"
    else
      mkdir -p "$(dirname "${target_dir}/${relative}")"
      cp -f "${path}" "${target_dir}/${relative}"
    fi
  done < <(find "${source_dir}" -mindepth 1 -print0)
}

write_package_lists() {
  mkdir -p "${PACKAGE_TARGET_DIR}"
  find "${PACKAGE_TARGET_DIR}" -mindepth 1 ! -name '.gitkeep' -delete

  local source_file
  for source_file in "${PACKAGE_SOURCE_DIR}"/*.list; do
    [[ -e "${source_file}" ]] || continue

    local base_name
    base_name="$(basename "${source_file}" .list)"
    cp -f "${source_file}" "${PACKAGE_TARGET_DIR}/${base_name}.list.chroot"
  done
}

write_metadata() {
  local version="$1"
  local metadata_dir="${CHROOT_INCLUDE_DIR}/etc/colinos"
  local app_root="${CHROOT_INCLUDE_DIR}/opt/colinos"

  mkdir -p "${metadata_dir}" "${app_root}/apps" "${app_root}/assets" "${app_root}/branding"

  cat > "${metadata_dir}/release" <<EOF
COLIN_NAME=Colin OS
COLIN_ID=ColinOS
COLIN_VERSION=${version}
COLIN_BASE=ubuntu
COLIN_CODENAME=noble
COLIN_ARCH=amd64
EOF

  if [[ -f "${BRANDING_SOURCE_DIR}/brand.env" ]]; then
    cp -f "${BRANDING_SOURCE_DIR}/brand.env" "${metadata_dir}/brand.env"
    cp -f "${BRANDING_SOURCE_DIR}/brand.env" "${app_root}/branding/brand.env"
  fi
}

stage_branding_assets() {
  local wallpapers_dir="${CHROOT_INCLUDE_DIR}/usr/share/backgrounds/colinos"
  local icons_dir="${CHROOT_INCLUDE_DIR}/usr/share/icons/hicolor/scalable/apps"
  local pixmaps_dir="${CHROOT_INCLUDE_DIR}/usr/share/pixmaps"
  local plymouth_dir="${CHROOT_INCLUDE_DIR}/usr/share/plymouth/themes/colinos"

  mkdir -p "${wallpapers_dir}" "${icons_dir}" "${pixmaps_dir}" "${plymouth_dir}"

  if [[ -f "${ASSETS_SOURCE_DIR}/wallpapers/colinos-wallpaper.svg" ]]; then
    cp -f "${ASSETS_SOURCE_DIR}/wallpapers/colinos-wallpaper.svg" "${wallpapers_dir}/colinos-wallpaper.svg"
  fi

  if [[ -f "${ASSETS_SOURCE_DIR}/icons/colinos-logo.svg" ]]; then
    cp -f "${ASSETS_SOURCE_DIR}/icons/colinos-logo.svg" "${icons_dir}/colinos.svg"
    cp -f "${ASSETS_SOURCE_DIR}/icons/colinos-logo.svg" "${pixmaps_dir}/colinos.svg"
  fi

  if [[ -f "${ASSETS_SOURCE_DIR}/plymouth/colinos-bootmark.svg" ]]; then
    cp -f "${ASSETS_SOURCE_DIR}/plymouth/colinos-bootmark.svg" "${plymouth_dir}/colinos-bootmark.svg"
  fi
}

stage_live_build_inputs() {
  copy_tree_contents "${DESKTOP_CHROOT_SOURCE_DIR}" "${CHROOT_INCLUDE_DIR}"
  copy_tree_contents "${DESKTOP_BINARY_SOURCE_DIR}" "${BINARY_INCLUDE_DIR}"
  copy_tree_contents "${DESKTOP_INSTALLER_SOURCE_DIR}" "${INSTALLER_INCLUDE_DIR}"
  copy_tree_contents "${DESKTOP_HOOK_SOURCE_DIR}" "${WORKSPACE_DIR}/config/hooks"

  copy_tree_contents "${BRANDING_CHROOT_SOURCE_DIR}" "${CHROOT_INCLUDE_DIR}"
  copy_tree_contents "${BRANDING_BINARY_SOURCE_DIR}" "${BINARY_INCLUDE_DIR}"
  copy_tree_contents "${BRANDING_INSTALLER_SOURCE_DIR}" "${INSTALLER_INCLUDE_DIR}"
  copy_tree_contents "${BRANDING_HOOK_SOURCE_DIR}" "${WORKSPACE_DIR}/config/hooks"
}

fix_permissions() {
  local file

  for file in \
    "${WORKSPACE_DIR}/config/hooks/"*.hook.chroot \
    "${CHROOT_INCLUDE_DIR}/usr/local/bin/colin-welcome" \
    "${CHROOT_INCLUDE_DIR}/usr/local/bin/colin-settings" \
    "${CHROOT_INCLUDE_DIR}/usr/local/bin/colin-update-center" \
    "${CHROOT_INCLUDE_DIR}/usr/local/bin/colin-toolbox"; do
    [[ -e "${file}" ]] || continue
    chmod 0755 "${file}"
  done
}

main() {
  local version
  version="$(resolve_version)"

  mkdir -p "${WORK_ROOT}" "${ISO_DIR}" "${LOG_DIR}"

  if [[ "${COLIN_CLEAN:-1}" == "1" ]]; then
    rm -rf "${WORKSPACE_DIR}"
  fi

  mkdir -p "${WORKSPACE_DIR}"
  copy_tree_contents "${TEMPLATE_DIR}" "${WORKSPACE_DIR}"

  mkdir -p "${PACKAGE_TARGET_DIR}" "${CHROOT_INCLUDE_DIR}" "${BINARY_INCLUDE_DIR}" "${INSTALLER_INCLUDE_DIR}"
  write_package_lists
  write_metadata "${version}"
  stage_live_build_inputs
  stage_branding_assets
  copy_tree_contents "${ASSETS_SOURCE_DIR}" "${CHROOT_INCLUDE_DIR}/opt/colinos/assets"
  copy_tree_contents "${APPS_SOURCE_DIR}" "${CHROOT_INCLUDE_DIR}/opt/colinos/apps"
  fix_permissions

  cat > "${WORKSPACE_DIR}/build.env" <<EOF
COLIN_VERSION=${version}
COLIN_JOBS=${COLIN_JOBS:-4}
WORKSPACE_DIR=${WORKSPACE_DIR}
ISO_DIR=${ISO_DIR}
LOG_DIR=${LOG_DIR}
EOF

  printf 'Prepared live-build workspace at %s\n' "${WORKSPACE_DIR}"
  printf 'Resolved Colin OS version: %s\n' "${version}"
}

main "$@"
