# Colin OS

Colin OS is a personal Linux distribution project based on Ubuntu 24.04 LTS, designed for software development, AI application development, Electron development, Kotlin development, web development, and content creation.

The project target is a stable, maintainable, and reproducible desktop operating system with KDE Plasma, Ubuntu ecosystem compatibility, and GitHub Actions based ISO automation.

## Project Goals

- Base system: Ubuntu 24.04 LTS
- Architecture: `x86_64`
- Desktop environment: KDE Plasma
- Build strategy: `live-build`
- Installer strategy: Calamares placeholder integration in the first phase
- Package policy: prefer Ubuntu official repositories
- Driver policy: use Ubuntu official kernel drivers and firmware only
- Release automation: build and publish ISO on Git tag creation

## Design Principles

- Maximize compatibility with the Ubuntu official ecosystem
- Avoid kernel forks and third-party driver maintenance
- Keep the repository clean and suitable for GitHub collaboration
- Make the build process reproducible in WSL2 Ubuntu and GitHub Actions
- Separate source files from generated build artifacts

## Repository Layout

```text
Colin-OS/
|-- README.md
|-- LICENSE
|-- .gitignore
|-- build/
|-- configs/
|   |-- desktop/
|   `-- branding/
|-- scripts/
|-- packages/
|-- assets/
|   |-- wallpapers/
|   |-- icons/
|   `-- plymouth/
|-- apps/
|   |-- ColinWelcome/
|   |-- ColinSettings/
|   |-- ColinUpdateCenter/
|   `-- ColinToolbox/
|-- docs/
`-- .github/
    `-- workflows/
```

## Planned Delivery Order

The repository will be built incrementally in the following order:

1. Initialize the repository structure
2. Create the main project documentation
3. Define package lists
4. Design the ISO build flow
5. Implement build scripts
6. Add branding customization
7. Add Colin OS app scaffolds
8. Add GitHub Actions automation
9. Test ISO build workflow

## Current Status

This repository currently contains:

- the initial project skeleton
- the top-level project definition
- the first official-repository package manifest
- the `live-build` pipeline layout
- the first build script implementation
- the first branding and desktop-default placeholder layer
- the first Colin OS application framework
- the first GitHub Actions ISO build workflow

The next implementation step is:

`Step 9: test the ISO build workflow.`

## Planned Build Environment

- Host OS: Windows 11
- Build environment: WSL2 Ubuntu
- Target hardware:
  - Intel Core i7-12700H
  - Intel Iris Xe Graphics
  - NVMe SSD
  - Wi-Fi
  - Bluetooth
  - Audio

## Notes

- `live-build` is selected as the primary ISO automation path because it is scriptable and CI friendly.
- Calamares integration is intentionally kept as a placeholder in the first phase to reduce early maintenance complexity.
- Third-party repositories are not a first-phase requirement because package sourcing should prefer official Ubuntu repositories.
- The package manifest is intentionally aligned with Ubuntu 24.04 official repository availability, which excludes `VS Code` and `fastfetch` from the first ISO baseline.
- The ISO pipeline structure is now defined around a repository-managed `live-build` workspace under `build/live-build/`.
