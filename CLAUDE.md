# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

KompassOS is a custom Fedora Silverblue (Aurora/KDE) image built with [Blue-Build](https://blue-build.org). There is no local build command — the image is built entirely via GitHub Actions CI using the Blue-Build GitHub Action. Changes are made to YAML recipe/module files, shell scripts, justfiles, and system configuration files, then pushed to trigger a CI build.

## Build System

**CI builds** are triggered automatically on push (excluding `**.md` changes) or manually via `workflow_dispatch`. The workflow (`.github/workflows/build.yml`) builds three image variants in a matrix:
- `recipe-dx-hwe.yml` — standard HWE (Hardware Enablement)
- `recipe-dx-hwe-nvidia.yml` — Nvidia open drivers variant
- `recipe-dx-surface.yml` — Microsoft Surface variant

All three share common module files via `from-file:` includes.

**Dev branch**: pushes to `dev` trigger a reduced matrix — only `recipe-dx-hwe-nvidia.yml` builds, for faster CI feedback during testing. The `dev` branch is periodically reset to `main` (`git reset --hard origin/main && git push --force origin dev`). Never use `dev` builds in production.

**To test a justfile locally** (on a running KompassOS system):
```
just --justfile files/justfiles/<name>.just --choose
```

## Repository Structure

```
recipes/          # Blue-Build recipe and module YAML files
  recipe-*.yml          # Top-level image recipes (one per variant)
  common-files.yml      # Shared: files module + justfiles list
  common-scripts.yml    # Shared: build-time shell scripts + signing
  common-dnf.yml        # Shared: RPM package installs and repos
  common-finalize.yml   # Shared: flatpaks, initramfs, cleanup

files/            # All content copied into the image
  system/               # Overlaid onto / at build time (via files module)
    etc/                # System config files (profile.d, sddm, login.defs)
    usr/lib/            # systemd units, ujust library scripts
    usr/share/          # Wallpapers, Plymouth theme, distrobox configs, icons
  justfiles/            # ujust recipes exposed to end users (*.just)
  scripts/              # Build-time bash scripts run by the script module
  dnf/                  # Custom .repo files for DNF

modules/          # Empty — custom modules would go here (currently unused)
```

## Key Architectural Patterns

**ujust integration**: All `files/justfiles/*.just` files are included via the `justfiles` Blue-Build module. They source `/usr/lib/ujust/ujust.sh` (which provides color variables and helpers) and use `gum confirm` for interactive prompts. Group tags like `[group('Apps')]` or `[group('System')]` organize them in the ujust TUI.

**Distrobox for non-native apps**: Apps that can't be installed natively (e.g. Canon CUPS drivers, Claude Desktop) are shipped as distrobox container definitions under `files/system/usr/share/kompassos/distrobox/`, with corresponding `.just` files to set them up.

**System file overlay**: Anything placed under `files/system/` is copied verbatim into the image root. This is the mechanism for dropping config files, systemd units, Plymouth themes, and branding assets.

**login.defs placement**: `login.defs` lives at `files/system/usr/etc/login.defs` (not `etc/`) so it survives the rechunking step during CI — rechunk wipes `/etc` but preserves `/usr/etc`.

**Build-time scripts** in `files/scripts/` run as root during image construction. They must be idempotent. The `z_cleanup.sh` script always runs last (via `common-finalize.yml`) to remove build artifacts.

## Adding New Content

- **New justfile recipe**: Add `<name>.just` to `files/justfiles/` and add the filename to the `include:` list in `recipes/common-files.yml`.
- **New RPM package**: Add to the appropriate `dnf` block in `recipes/common-dnf.yml`. If it needs a custom repo, add the `.repo` file to `files/dnf/` and reference it in the `repos.files:` list.
- **New system config file**: Place it under `files/system/` mirroring the target path in the OS root.
- **New build-time script**: Add to `files/scripts/` and reference it in `recipes/common-scripts.yml` (or `common-finalize.yml` for post-steps).
- **New flatpak**: Add the Flatpak app ID to the `install:` list in the `default-flatpaks` block in `recipes/common-finalize.yml`.

## Image Variants & Base Images

| Recipe | Base image | Notes |
|--------|-----------|-------|
| `recipe-dx-hwe.yml` | `ghcr.io/ublue-os/aurora-dx:stable` | Standard |
| `recipe-dx-hwe-nvidia.yml` | `ghcr.io/ublue-os/aurora-dx-nvidia-open:stable` | Nvidia open kernel modules |
| `recipe-dx-surface.yml` | `ghcr.io/ublue-os/aurora-dx:latest` | Adds linux-surface kernel before common modules |
