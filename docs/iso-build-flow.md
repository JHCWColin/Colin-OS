# Colin OS ISO Build Flow

## Objective

Colin OS uses `live-build` as the primary ISO build system for Ubuntu 24.04 LTS based image generation.

The first implementation goal is:

- reproducible local builds in WSL2 Ubuntu
- reproducible CI builds in GitHub Actions
- clean separation between source files and generated ISO artifacts
- minimal divergence from Ubuntu official package sources

## Why `live-build`

`live-build` is chosen over a Cubic-first workflow because:

- it is non-interactive and scriptable
- it fits GitHub Actions better
- it keeps the build definition inside the repository
- it is easier to review, diff, and maintain over time

`Cubic` remains a valid local experimentation tool, but not the canonical Colin OS build pipeline.

## Build Layers

The Colin OS ISO pipeline is split into five layers:

1. Host environment preparation
2. `live-build` configuration generation
3. Package and filesystem customization
4. ISO assembly
5. Artifact collection and release publishing

## Repository Mapping

The repository will map to `live-build` as follows:

- [build/live-build](/D:/Colin-OS/build/live-build): canonical `live-build` workspace template
- [configs/packages.list](/D:/Colin-OS/configs/packages.list): human-readable flattened package manifest
- [configs/packages](/D:/Colin-OS/configs/packages): layered package sources copied into `build/live-build/config/package-lists/`
- [configs/desktop](/D:/Colin-OS/configs/desktop): KDE defaults and desktop configuration staged through `includes.chroot` and related `live-build` paths
- [configs/branding](/D:/Colin-OS/configs/branding): GRUB, Plymouth, SDDM, and system branding staged through `includes.chroot`, `includes.binary`, and future installer paths
- [assets](/D:/Colin-OS/assets): branding source assets consumed during packaging
- [apps](/D:/Colin-OS/apps): Colin OS custom applications staged into the image during build
- [build](/D:/Colin-OS/build): wrapper scripts and top-level build entrypoints

## Planned `live-build` Layout

```text
build/live-build/
|-- auto/
|-- config/
|   |-- archives/
|   |-- bootloaders/
|   |-- hooks/
|   |-- includes.binary/
|   |-- includes.chroot/
|   |-- includes.installer/
|   `-- package-lists/
```

### Directory Roles

- `auto/`: non-interactive helper entrypoints used by `live-build`
- `config/package-lists/`: generated package list files consumed by `live-build`
- `config/includes.chroot/`: files copied into the live filesystem before squashfs creation
- `config/includes.binary/`: files copied to the ISO filesystem outside the root filesystem
- `config/hooks/`: idempotent hooks for final system adjustments inside the chroot
- `config/archives/`: optional future archive definitions if repository policy changes
- `config/includes.installer/`: reserved for Calamares integration
- `config/bootloaders/`: reserved for GRUB and boot visual customization if needed

## Build Inputs

The ISO build will consume these primary inputs:

- Ubuntu 24.04 LTS package repositories
- Colin OS package manifests
- Colin OS branding assets
- KDE default configuration files
- Colin OS application bundles
- build metadata such as version and Git tag

## Build Outputs

The build pipeline will produce:

- one bootable `*.iso`
- optional checksum files
- optional build metadata text files

Generated outputs must stay outside tracked source directories. The standard output target will be:

- `out/iso/`
- `out/logs/`
- `out/work/`

These paths are already aligned with the repository `.gitignore`.

## Local Build Flow

The intended local build flow in WSL2 Ubuntu is:

1. Install build dependencies
2. Prepare an isolated `live-build` workspace under `build/live-build/`
3. Copy layered package lists into `config/package-lists/`
4. Copy branding, desktop defaults, and app payloads into `config/includes.chroot/`
   In practice this is done by mirroring `includes.*` source trees from `configs/desktop` and `configs/branding`.
5. Run `lb clean`
6. Run `lb config` with Ubuntu 24.04 and `amd64` targeting
7. Run `lb build`
8. Move the resulting ISO into `out/iso/`

## CI Build Flow

The intended GitHub Actions flow on tag creation is:

1. Trigger on Git tag push
2. Check out the repository
3. Install `live-build` and required packaging tools
4. Generate the `live-build` workspace from repository configuration
5. Build the ISO
6. Generate checksums
7. Create or update the GitHub Release for the tag
8. Upload the ISO and checksum artifacts

## Versioning Model

Colin OS release artifacts should derive their version from the Git tag.

Example:

- Git tag: `v0.1.0`
- ISO name: `Colin-OS-v0.1.0-amd64.iso`

This keeps local and CI builds consistent and makes release provenance obvious.

Implementation note:

- On Ubuntu 24.04, the repository `live-build` package does not expose the newer `--image-name` switch. Colin OS therefore renames the generated default `live-image-amd64.hybrid.iso` artifact after `lb build` completes.
- On Ubuntu 24.04, the Ubuntu-mode `live-build` defaults can still emit the obsolete syslinux theme value `ubuntu-oneiric`. Colin OS rewrites the generated `LB_SYSLINUX_THEME` to `live-build` after `lb config` so `lb build` does not request removed packages from the Noble archive.
- On Ubuntu 24.04, the packaged `live-build` syslinux stage can still expect legacy `/root/isolinux/*` paths. Colin OS prepares compatibility symlinks before starting `lb build`, using `live-build` bootloader assets first and `isolinux` or `syslinux` package files as fallbacks.

## WSL2 Host Considerations

For the specified development host:

- CPU: Intel Core i7-12700H
- Thread budget: use up to 20 logical threads where supported
- Storage: keep temporary build directories on the WSL ext4 filesystem, not on mounted Windows paths, when possible
- Cache strategy: allow APT package cache reuse between builds to reduce repeated downloads

Practical implications:

- wrapper scripts should expose configurable parallel job counts
- wrapper scripts should keep workspace cleanup explicit, not implicit
- scripts should support preserving downloaded packages between rebuilds

## Constraints

- no custom kernel maintenance
- no third-party driver bundles
- no mandatory third-party package repositories in the first release
- no large generated artifacts committed to Git

## Deferred Work

The following are intentionally deferred to later implementation steps:

- actual `lb config` command definitions
- build wrapper scripts
- Calamares module integration
- GRUB and Plymouth branding payloads
- Colin OS application packaging
- GitHub Actions workflow implementation

## Decision Summary

- canonical builder: `live-build`
- canonical base: Ubuntu 24.04 LTS
- canonical architecture: `amd64`
- release trigger: Git tag creation
- installer status: placeholder only in the current phase, with the installer stage disabled until Calamares integration exists
