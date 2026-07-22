# Colin OS Package Strategy

## Baseline

Colin OS targets Ubuntu 24.04 LTS (`noble`) and prefers Ubuntu official repositories for the first release.

This policy is intended to keep the ISO:

- stable
- legally simple to redistribute
- easier to maintain long term
- compatible with GitHub Actions based automated builds

## Package Selection Structure

The package configuration is split into:

- [configs/packages.list](/D:/Colin-OS/configs/packages.list): flattened package manifest for quick review
- [configs/packages/base.list](/D:/Colin-OS/configs/packages/base.list): KDE Plasma desktop session and core tools
- [configs/packages/hardware.list](/D:/Colin-OS/configs/packages/hardware.list): official firmware, audio, networking, and Bluetooth support
- [configs/packages/development.list](/D:/Colin-OS/configs/packages/development.list): developer toolchain
- [configs/packages/productivity.list](/D:/Colin-OS/configs/packages/productivity.list): browser and creative software
- [configs/packages/system-tools.list](/D:/Colin-OS/configs/packages/system-tools.list): monitoring, storage, and archive tools
- [configs/packages/installer-placeholder.list](/D:/Colin-OS/configs/packages/installer-placeholder.list): placeholder installer dependency

This split keeps the package set maintainable and maps cleanly to a later `live-build` implementation.

## Important Decisions

### KDE package choice

`kde-plasma-desktop` is used instead of a full `kubuntu-desktop` style metapackage because it provides a Plasma desktop baseline with less unwanted payload and more control over Colin OS branding and defaults.

### Java package choice

`openjdk-21-jdk` is selected because Ubuntu 24.04 ships OpenJDK 21 as the current long-term supported Java development stack.

### Node.js package choice

`nodejs` and `npm` are kept on Ubuntu official packages only. This means the first Colin OS release prioritizes repository consistency over the newest Node.js LTS branch.

### Colin OS app runtime choice

`python3-pyqt6` is included from Ubuntu 24.04 official repositories so the first Colin OS application layer can remain lightweight, official-repository-only, and KDE friendly.

### Installer package choice

`calamares` is included only as a placeholder package target at this stage. Full installer integration, modules, branding, and workflow validation will be implemented later.

## Deferred Items

The following requested items are intentionally not included in the first official-repository-only package manifest:

- VS Code
- fastfetch

Reason:

- `VS Code` is not provided by Ubuntu official repositories for Ubuntu 24.04 LTS.
- `fastfetch` is not available in Ubuntu 24.04 LTS (`noble`); it appears in later Ubuntu releases instead.

For the first ISO, the repository policy is considered more important than exact tool parity with third-party package ecosystems.

## Future Policy Options

If Colin OS later relaxes the repository policy, there are two safe expansion paths:

1. Keep the base ISO official-only and let Colin Welcome offer optional post-install setup.
2. Add an explicit opt-in third-party source layer for tools such as VS Code and newer Node.js releases.
