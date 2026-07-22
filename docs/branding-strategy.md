# Colin OS Branding Strategy

## Current Scope

The first branding phase is intentionally conservative. It focuses on branding assets and desktop defaults that can be staged safely into a `live-build` image without introducing brittle packaging logic.

Implemented in this phase:

- Colin OS logo source asset
- Colin OS wallpaper source asset
- Plymouth placeholder logo source asset
- GRUB defaults override
- SDDM defaults override
- KDE Plasma dark-theme defaults for new users
- live-build staging paths for branding files

## Source Layout

- [assets/icons/colinos-logo.svg](/D:/Colin-OS/assets/icons/colinos-logo.svg): source logo
- [assets/wallpapers/colinos-wallpaper.svg](/D:/Colin-OS/assets/wallpapers/colinos-wallpaper.svg): source wallpaper
- [assets/plymouth/colinos-bootmark.svg](/D:/Colin-OS/assets/plymouth/colinos-bootmark.svg): source boot mark
- [configs/branding/brand.env](/D:/Colin-OS/configs/branding/brand.env): brand metadata
- [configs/branding/includes.chroot](/D:/Colin-OS/configs/branding/includes.chroot): files copied directly into the live root filesystem
- [configs/desktop/includes.chroot](/D:/Colin-OS/configs/desktop/includes.chroot): KDE defaults copied into `/etc/skel`

## Design Direction

The visual direction is:

- dark by default
- cool cyan and teal accent colors
- low-noise geometric forms
- developer-oriented rather than consumer-generic

This stays close to the Ubuntu and KDE defaults operationally, while still making Colin OS visually distinct.

## Technical Notes

- GRUB branding currently changes distributor labeling and boot behavior, but does not yet enable a custom background image.
- SDDM currently stays on the stable Breeze theme and only changes the selected theme entry and cursor defaults.
- Plymouth includes a placeholder scripted theme payload, but activation should be validated in the dedicated ISO testing phase before it is treated as final.
- KDE defaults are applied via `/etc/skel`, so they affect newly created users without patching system packages.

## Deferred Branding Work

These items are intentionally postponed:

- final GRUB background artwork
- final SDDM theme implementation
- full KDE theme packaging
- About page integration
- installer branding
- splash animation polish
