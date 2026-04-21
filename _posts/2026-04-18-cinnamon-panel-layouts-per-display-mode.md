---
layout: post
title: "Per-Mode Panel Layouts in Cinnamon Using dconf Snapshots"
date: 2026-04-18
categories: [Linux]
tags:
  - linux
  - linux-mint
  - cinnamon
  - display
  - scripting
  - productivity
---

Once the [display mode switching](/linux/2026/04/17/barrier-kvm-nvidia-display-workaround) was working reliably, the next thing that started to bother me was the panel layout. Going from two screens to one and back meant the Cinnamon panel arrangement was left stranded in whatever state it happened to be: a single centred panel when two screens were up, or a sprawling two-panel setup squashed onto one monitor.

Fortunately, Cinnamon stores all panel configuration in dconf, which makes the solution pleasingly clean: snapshot each layout once, restore the right one when switching modes.

## How Cinnamon stores panel config

The relevant keys all sit under `/org/cinnamon/` in dconf:

- `panels-enabled` - which panels exist, which monitor they're on, and their position (top/bottom). Format: `['id:monitor_index:position', ...]`
- `panels-height` - height in pixels per panel
- `panels-autohide`, `panels-hide-delay`, `panels-show-delay` - autohide settings
- `enabled-applets` - which applets are loaded and on which panel. Format: `['panel_id:zone:order:applet_uuid:instance_id', ...]`
- `next-applet-id` - the counter used when adding new applets

The monitor index in `panels-enabled` is zero-based and only reflects currently connected monitors, which is the kind of detail that will silently break your snapshots if you miss it. With two screens active, DP-0 is index 0 and DP-2 is index 1. With only DP-2 active, it becomes index 0. The work layout snapshot needs to reference monitor 0 even though it's physically the right-hand screen.

## Snapshotting and restoring

Saving a layout means reading each dconf key and writing a restore script of `dconf write` calls. The restore script runs on each profile switch, and `cinnamon --replace` picks up the new values and redraws the panel. Without that restart, the dconf values update but the running compositor doesn't reread them until the next login.

The workflow is straightforward: switch to a profile, arrange the panel as needed, snapshot it. From that point, switching profiles carries the panel layout with it.

A typical personal layout snapshot looks like:

```bash
dconf write /org/cinnamon/panels-enabled "['1:0:bottom', '2:1:bottom']"
dconf write /org/cinnamon/panels-height "['1:40', '2:40']"
dconf write /org/cinnamon/enabled-applets "['panel1:left:0:Cinnamenu@json:17', \
  'panel1:left:1:grouped-window-list@cinnamon.org:16', \
  'panel1:right:0:collapsible-systray@feuerfuchs.eu:24', \
  'panel1:right:4:calendar@cinnamon.org:13']"
```

And the work layout with a single panel on monitor 0:

```bash
dconf write /org/cinnamon/panels-enabled "['1:0:bottom']"
dconf write /org/cinnamon/panels-height "['1:40']"
dconf write /org/cinnamon/enabled-applets "['panel1:left:0:Cinnamenu@json:17', \
  'panel1:left:1:grouped-window-list@cinnamon.org:16', \
  'panel1:right:0:collapsible-systray@feuerfuchs.eu:24', \
  'panel1:right:4:calendar@cinnamon.org:13']"
```

Combined with the xrandr switching from the previous post, switching modes carries monitors, refresh rate, and panel layout in one step.

This panel snapshotting is now part of [display-profiles](https://github.com/jordan-lee-code/display-profiles), where it lives as a Cinnamon-specific hook. Other DEs can be supported by adding a `hooks/<de>/` directory with equivalent save and restart scripts.
