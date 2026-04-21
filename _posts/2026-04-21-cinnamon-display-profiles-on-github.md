---
layout: post
title: "display-profiles: Generic Display Switching with Named Profiles"
date: 2026-04-21
tags:
  - linux
  - linux-mint
  - nvidia
  - cinnamon
  - display
  - scripting
  - productivity
  - open-source
---

Over the past few days I've written two posts about fighting the Nvidia driver bug that keeps dropping display settings on Linux Mint: [the initial display switching scripts](/2026/04/17/barrier-kvm-nvidia-display-workaround/) and [adding per-profile Cinnamon panel layouts](/2026/04/18/cinnamon-panel-layouts-per-display-mode/). What started as a couple of `xrandr` one-liners has grown into something more general purpose.

The repo is on GitHub: [jordan-lee-code/display-profiles](https://github.com/jordan-lee-code/display-profiles).

## What grew out of those posts

The original scripts handled the core problem: apply the right `xrandr` config, set the correct primary screen, lock in 165Hz. That covered the display bug.

Then I wanted the panel layout to switch alongside the monitors. Working on one screen means a single panel in the centre. Working on two means panels spread across both. Cinnamon stores all of this in dconf, so `display-save-layout.sh` snapshots the current panel config to a shell script of `dconf write` calls, restored automatically on each profile switch.

The next gap was persistence across reboots. `xrandr` settings are runtime-only, so switching to work mode, shutting down, and coming back the next day would put everything back to the Nvidia driver's best guess. The fix was a Zenity dialog at shutdown and restart asking which profile to use next, saving the answer to `~/.config/display-mode`, and an autostart entry that reads it and calls the right script on every login.

## Genericising it

The original scripts had Cinnamon and my specific monitor config baked in throughout. Anyone else using them would need to edit multiple files to change output names, resolution, or DE. That's not a great experience, so the repo went through a refactor before publishing.

The core is now DE-agnostic. All Cinnamon-specific logic lives in `hooks/cinnamon/` - a `save-panels.sh` that takes a profile directory as an argument and snapshots dconf into it, and a `restart-de.sh` that calls `cinnamon --replace`. Adding support for another DE means adding a `hooks/<de>/` directory with the same two files. The DE is detected from `$XDG_CURRENT_DESKTOP`.

Profiles are no longer hardcoded. They're stored in `~/.config/display-profiles/<name>/` and contain three files: `xrandr.sh` (the generated xrandr command), an optional `panel-layout.sh` (written by the save hook), and a `meta` file with the name, description, and creation date. The shutdown and restart scripts list whatever profiles exist in that directory, so adding a new profile makes it appear in the menu automatically.

## What's in the repo

```
display-profiles/
├── lib/
│   └── common.sh              # DE detection, profile listing, zenity/terminal selector
├── bin/
│   ├── display-setup.sh       # discover outputs and list saved profiles
│   ├── display-new-profile.sh # interactive profile creation wizard
│   ├── display-switch.sh      # apply a named profile
│   ├── display-save-layout.sh # snapshot current DE panel config into a profile
│   ├── display-apply-saved.sh # apply last saved profile (autostart)
│   ├── display-shutdown.sh    # prompt for next profile, power off
│   ├── display-restart.sh     # prompt for next profile, reboot
│   ├── display-work.sh        # compatibility wrapper for display-switch.sh work
│   └── display-personal.sh    # compatibility wrapper for display-switch.sh personal
├── hooks/
│   └── cinnamon/
│       ├── save-panels.sh
│       └── restart-de.sh
├── desktop/
│   ├── display-shutdown.desktop
│   └── display-apply.desktop
├── install.sh
└── README.md
```

`install.sh` symlinks the scripts into `~/bin/` so edits in the repo take effect immediately without reinstalling. The desktop files use a `%%HOME%%` placeholder that `install.sh` substitutes at install time, so they work for any user without hardcoding a path.

## Using it

```bash
git clone https://github.com/jordan-lee-code/display-profiles.git
cd display-profiles
bash install.sh
```

Then run the setup script to see what outputs are available and at what modes:

```bash
display-setup.sh
```

And create profiles interactively:

```bash
display-new-profile.sh
```

The wizard asks for a profile name, walks through each connected output (enable/disable, resolution, refresh rate), then sets the primary and positions the remaining screens.

Positioning works with absolute pixel coordinates rather than xrandr's relative flags, which is the only way to express layouts that aren't simple side-by-side arrangements. For each unplaced output the wizard builds a numbered list of options against every screen already placed: left, right, above, below, centered-above, centered-below. Once two or more screens are positioned, centered-above-all and centered-below-all are added, placing the new output centered over the full bounding box of the existing layout. After all outputs are placed, coordinates are normalised so the minimum x and y are both zero.

Before saving, the wizard shows an ASCII block diagram of the layout and a pixel coordinate summary so you can confirm it looks right.

The generated `xrandr.sh` uses `--pos` for absolute placement and is plain bash, easy to read and edit by hand if needed.

From that point, switching is one command:

```bash
display-switch.sh work
display-switch.sh gaming
```

Shutdown and restart pick up any profiles in `~/.config/display-profiles/` automatically, no config needed.

## Why share it

Nvidia display bugs on Linux are a known long-running annoyance. The `xrandr` fix is well documented, but the autostart restore, dconf panel snapshots, and DE integration pieces are scattered. The profile wizard also addresses something that's genuinely fiddly to get right by hand - building a correct multi-monitor `xrandr` invocation with positions and refresh rates across multiple outputs.

My setup is Linux Mint with Cinnamon and two 1440p DisplayPort monitors, but the core works on any DE. If you're on GNOME or XFCE and want panel layout support, adding a hook directory is all it takes.
