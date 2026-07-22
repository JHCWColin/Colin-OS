# Colin OS Apps Framework

## Chosen Stack

The first Colin OS application layer uses:

- Python 3
- PyQt6 from Ubuntu 24.04 official repositories
- plain desktop entry launchers

This is the most pragmatic fit for the current project constraints:

- official repository availability
- low packaging friction
- strong compatibility with KDE based desktops
- lower runtime cost than Electron

## Application Set

- [apps/ColinWelcome](/D:/Colin-OS/apps/ColinWelcome): first-run onboarding
- [apps/ColinSettings](/D:/Colin-OS/apps/ColinSettings): settings shell
- [apps/ColinUpdateCenter](/D:/Colin-OS/apps/ColinUpdateCenter): update entry point
- [apps/ColinToolbox](/D:/Colin-OS/apps/ColinToolbox): developer diagnostics
- [apps/common/colinos_app](/D:/Colin-OS/apps/common/colinos_app): shared runtime helpers

## Current Framework Boundaries

The shared framework currently handles:

- brand metadata loading from `/etc/colinos/brand.env`
- shared dark-theme Qt styling
- a common card-based main window layout
- lightweight system command helpers

Each application keeps its own entrypoint and behavior logic so it can later become an independently packaged component if needed.

## Desktop Integration

Desktop launchers are staged via:

- [configs/desktop/includes.chroot/usr/share/applications](/D:/Colin-OS/configs/desktop/includes.chroot/usr/share/applications)
- [configs/desktop/includes.chroot/usr/local/bin](/D:/Colin-OS/configs/desktop/includes.chroot/usr/local/bin)

The welcome application is also staged as an autostart entry through:

- [configs/desktop/includes.chroot/etc/xdg/autostart/colin-welcome.desktop](/D:/Colin-OS/configs/desktop/includes.chroot/etc/xdg/autostart/colin-welcome.desktop)

The application itself writes a user-level sentinel file so it only acts as a first-run experience.

Executable permissions for the staged launcher scripts are enforced during image build by:

- [configs/desktop/hooks/0100-desktop-permissions.hook.chroot](/D:/Colin-OS/configs/desktop/hooks/0100-desktop-permissions.hook.chroot)

## Update Center Strategy

The first Update Center implementation intentionally does not replace Ubuntu package management.

Instead it:

- launches `plasma-discover` into update mode when available
- exposes PackageKit refresh as a lightweight maintenance action
- documents the equivalent CLI fallback commands

This keeps the first release operationally conservative.
