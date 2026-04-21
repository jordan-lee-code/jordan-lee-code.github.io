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

Once the [display mode switching](/2026/04/17/barrier-kvm-nvidia-display-workaround/) was working reliably, the next thing that started to bother me was the panel layout. Going from two screens to one and back meant the Cinnamon panel arrangement was left stranded in whatever state it happened to be: a single centred panel when two screens were up, or a sprawling two-panel setup squashed onto one monitor.

Fortunately, Cinnamon stores all panel configuration in dconf, which makes the solution pleasingly clean: snapshot each layout once, restore the right one when switching modes.

## How Cinnamon stores panel config

The relevant keys all sit under `/org/cinnamon/` in dconf:

- `panels-enabled` - which panels exist, which monitor they're on, and their position (top/bottom). Format: `['id:monitor_index:position', ...]`
- `panels-height` - height in pixels per panel
- `panels-autohide`, `panels-hide-delay`, `panels-show-delay` - autohide settings
- `enabled-applets` - which applets are loaded and on which panel. Format: `['panel_id:zone:order:applet_uuid:instance_id', ...]`
- `next-applet-id` - the counter used when adding new applets

The monitor index in `panels-enabled` is zero-based and only reflects currently connected monitors, which is the kind of detail that will silently break your snapshots if you miss it. With two screens active, DP-0 is index 0 and DP-2 is index 1. With only DP-2 active, it becomes index 0. The work layout snapshot needs to reference monitor 0 even though it's physically the right-hand screen.

## Saving a layout

A small save script reads each key with `dconf read` and writes a restore script of `dconf write` calls:

```bash
#!/bin/bash
MODE="${1:-}"
if [[ "$MODE" != "work" && "$MODE" != "personal" ]]; then
    echo "Usage: display-save-layout.sh work|personal" >&2
    exit 1
fi

SAVE_FILE="$HOME/.config/cinnamon-panels-${MODE}.sh"
echo "#!/bin/bash" > "$SAVE_FILE"

for key in panels-enabled panels-height panels-autohide panels-hide-delay \
           panels-show-delay enabled-applets next-applet-id; do
    val=$(dconf read /org/cinnamon/$key)
    [[ -n "$val" ]] && echo "dconf write /org/cinnamon/$key '$val'" >> "$SAVE_FILE"
done

chmod +x "$SAVE_FILE"
echo "Saved $MODE panel layout to $SAVE_FILE"
```

This produces a file like `~/.config/cinnamon-panels-personal.sh` containing the exact dconf writes needed to restore that layout.

## Restoring a layout on mode switch

The display switching scripts (`display-work.sh` and `display-personal.sh`) already handle xrandr. Adding panel restoration is a few lines at the end of each:

```bash
if [ -f "$HOME/.config/cinnamon-panels-work.sh" ]; then
    bash "$HOME/.config/cinnamon-panels-work.sh"
    nohup cinnamon --replace >/dev/null 2>&1 &
    disown
fi
```

The `cinnamon --replace` picks up the new dconf values and redraws the panel. Without it, the dconf values update but the running compositor doesn't reread them until the next login.

## The setup workflow

The first time:

1. While in personal mode (both screens up), run `display-save-layout.sh personal` to snapshot the current layout.
2. Run `display-work.sh` to switch to single-screen mode.
3. Arrange the panel as needed for work - move it, add or remove applets, whatever's useful.
4. Run `display-save-layout.sh work` to snapshot the work layout.

From that point, `display-work.sh` and `display-personal.sh` handle both the xrandr config and the panel layout in one step. The autostart entry that calls `display-apply-saved.sh` on login means the right layout is in place from the moment the session starts.

## What the snapshots look like

A typical personal layout snapshot:

```bash
dconf write /org/cinnamon/panels-enabled "['1:0:bottom', '2:1:bottom']"
dconf write /org/cinnamon/panels-height "['1:40', '2:40']"
dconf write /org/cinnamon/panels-autohide "['1:false', '2:false']"
dconf write /org/cinnamon/enabled-applets "['panel1:left:0:Cinnamenu@json:17', \
  'panel1:left:1:grouped-window-list@cinnamon.org:16', \
  'panel1:right:0:collapsible-systray@feuerfuchs.eu:24', \
  'panel1:right:4:calendar@cinnamon.org:13']"
```

And the corresponding work layout, with only one panel on monitor 0:

```bash
dconf write /org/cinnamon/panels-enabled "['1:0:bottom']"
dconf write /org/cinnamon/panels-height "['1:40']"
dconf write /org/cinnamon/panels-autohide "['1:false']"
dconf write /org/cinnamon/enabled-applets "['panel1:left:0:Cinnamenu@json:17', \
  'panel1:left:1:grouped-window-list@cinnamon.org:16', \
  'panel1:right:0:collapsible-systray@feuerfuchs.eu:24', \
  'panel1:right:4:calendar@cinnamon.org:13']"
```

The applets stay the same - only the panel count and monitor assignment changes. If you want different applets per mode, just configure them before running the save script.

## Re-snapshotting after changes

If you later change the panel layout in either mode - add an applet, resize the panel, enable autohide - just run `display-save-layout.sh work` or `display-save-layout.sh personal` again to update the snapshot. The save script overwrites the previous file.

Combined with the display switching from the previous post, switching between work and personal is now a single menu click that carries everything with it: monitors, refresh rate, and panel layout, all in one motion. It's the kind of small automation that, once it's in place, makes the previous state feel quietly absurd.

These scripts have since been cleaned up, genericised for any DE, and published as [display-profiles](https://github.com/jordan-lee-code/display-profiles) - with a profile wizard, output discovery, and named profiles rather than hardcoded work and personal modes.
