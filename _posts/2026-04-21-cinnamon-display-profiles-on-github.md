---
layout: post
title: "cinnamon-display-profiles: All the Display Switching Scripts in One Place"
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

Over the past few days I've written two posts about fighting the Nvidia driver bug that keeps dropping display settings on Linux Mint: [the initial display switching scripts](/2026/04/18/barrier-kvm-nvidia-display-workaround/) and [adding per-profile Cinnamon panel layouts](/2026/04/19/cinnamon-panel-layouts-per-display-mode/). What started as a couple of `xrandr` one-liners has grown into something worth putting in a proper repo.

The collection is now on GitHub: [jordan-lee-code/cinnamon-display-profiles](https://github.com/jordan-lee-code/cinnamon-display-profiles).

## What grew out of those posts

The original scripts handled the core problem: apply the right `xrandr` config, set the correct primary screen, lock in 165Hz. That covered the display bug.

Then I wanted the panel layout to switch alongside the monitors. Working on one screen means a single panel in the centre. Working on two means panels spread across both. Cinnamon stores all of this in dconf, so `display-save-layout.sh` snapshots the current panel config to a shell script of `dconf write` calls. The display switching scripts restore it on each mode change.

The next gap was persistence across reboots. `xrandr` settings are runtime-only, so switching to work mode, shutting down, and coming back the next day would put everything back to the Nvidia driver's best guess. The fix was a Zenity dialog at shutdown and restart asking which profile to use next, saving the answer to `~/.config/display-mode`, and an autostart entry that reads it and calls the right script on every login.

Finally, opening a terminal every time felt wrong when the whole point was a one-click workflow. The Cinnamenu sidebar buttons now call the shutdown and restart scripts directly, and there are start menu entries for switching profiles without rebooting.

## What's in the repo

```
cinnamon-display-profiles/
├── bin/
│   ├── display-work.sh
│   ├── display-personal.sh
│   ├── display-apply-saved.sh
│   ├── display-save-layout.sh
│   ├── display-shutdown.sh
│   └── display-restart.sh
├── desktop/
│   ├── display-work.desktop
│   ├── display-personal.desktop
│   ├── display-shutdown.desktop
│   └── display-apply.desktop
├── install.sh
└── README.md
```

`install.sh` copies the scripts to `~/bin/`, drops the desktop entries into `~/.local/share/applications/`, and installs the autostart entry. The README covers how to change the monitor output names and resolution to match your own setup, the panel layout snapshot workflow, and the optional Cinnamenu sidebar patch.

## Using it

```bash
git clone https://github.com/jordan-lee-code/cinnamon-display-profiles.git
cd cinnamon-display-profiles
bash install.sh
```

Then edit `~/bin/display-work.sh` and `~/bin/display-personal.sh` to replace `DP-0` and `DP-2` with your actual output names (`xrandr | grep connected` will show them), adjust the resolution if needed, and save your panel layouts:

```bash
display-save-layout.sh personal
display-work.sh
# arrange panel on single screen
display-save-layout.sh work
```

From that point, `display-work.sh` and `display-personal.sh` handle everything in one step: outputs, refresh rate, panel layout, Cinnamon reload. Shutdown and restart prompt for the next profile and restore it automatically on login.

## Why share it

Nvidia display bugs on Linux are a known long-running annoyance. The `xrandr` fix is well documented, but the autostart restore, dconf panel snapshots, and DE integration pieces are scattered enough that I spent time piecing them together. If this saves someone that time, it's worth having it in a public repo.

The scripts are written for my specific setup (Linux Mint, Cinnamon, Cinnamenu, two 1440p DisplayPort monitors) but the approach generalises. Swap out the output names, resolution, and applet paths and it should work for most Cinnamon setups with the same class of problem.
