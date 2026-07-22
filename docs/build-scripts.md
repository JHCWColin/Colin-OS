# Colin OS Build Scripts

## Overview

Colin OS currently uses three top-level build scripts:

- [build/build.sh](/D:/Colin-OS/build/build.sh): main entrypoint
- [build/package.sh](/D:/Colin-OS/build/package.sh): prepares the `live-build` workspace
- [build/create-iso.sh](/D:/Colin-OS/build/create-iso.sh): runs `live-build` and exports the ISO

The scripts are written for Ubuntu shell execution inside WSL2 or a native Ubuntu environment.

Because the repository may be edited from Windows, the build pipeline does not rely on Git preserving executable mode bits for shell scripts. The top-level entrypoint invokes child scripts with `bash`, and the packaging step reapplies executable permissions for staged helper scripts and `live-build` hooks.

## Script Roles

### `build/build.sh`

This is the single-command entrypoint for routine use.

It:

1. resolves the build version
2. sets a parallel job hint
3. prepares the workspace
4. builds the ISO

### `build/package.sh`

This script converts repository source files into a disposable `live-build` workspace at:

- `out/work/live-build`

It performs these actions:

- copies the `build/live-build` template into the disposable workspace
- converts `configs/packages/*.list` into `config/package-lists/*.list.chroot`
- stages `configs/desktop/includes.*` and `configs/branding/includes.*` into native `live-build` paths
- stages Colin OS assets and app payloads
- writes Colin OS release metadata into the image filesystem

### `build/create-iso.sh`

This script executes:

- `lb clean --purge`
- `lb config`
- `lb build`

It then moves the generated ISO into:

- `out/iso/`

It also writes checksums and build logs into:

- `out/iso/`
- `out/logs/`

## Expected Host Dependencies

At minimum, the build host needs:

- `live-build`
- `debootstrap`
- `xorriso`
- `squashfs-tools`
- `grub-pc-bin`
- `grub-efi-amd64-bin`
- `mtools`
- `dosfstools`
- `curl`
- `wget`
- `git`
- `sha256sum`

Additional packages may be added later once Calamares and branding hooks are implemented.

For convenience, the repository now includes:

- [build/install-deps.sh](/D:/Colin-OS/build/install-deps.sh)

## Usage

Standard build:

```bash
./build/build.sh
```

Build with an explicit version:

```bash
./build/build.sh v0.1.0
```

Prepare workspace only:

```bash
./build/package.sh
```

Build ISO from an already prepared workspace:

```bash
./build/create-iso.sh
```

Keep the previous workspace instead of wiping it first:

```bash
COLIN_CLEAN=0 ./build/build.sh
```

Override detected parallelism:

```bash
COLIN_JOBS=20 ./build/build.sh
```

## Output Layout

Generated files are intentionally kept outside tracked source paths:

```text
out/
|-- iso/
|-- logs/
`-- work/
```

This ensures the Git repository remains clean while still keeping local build outputs easy to inspect.

## Current Limitations

- The scripts assume Ubuntu 24.04 compatible `live-build` tooling is already installed.
- Calamares is still only a package placeholder and the ISO build currently disables the installer stage until real integration is implemented.
- Desktop branding and Colin OS app payloads are staged generically because the actual content is not implemented yet.
- The build assumes the branding assets remain SVG-first placeholders until the ISO validation phase confirms all boot and login surfaces consume them correctly.
