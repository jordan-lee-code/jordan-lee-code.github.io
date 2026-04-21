---
layout: post
title: "Splitting Work and Personal Computing with Barrier KVM - and Scripting Around an Nvidia Display Bug"
date: 2026-04-18
categories: [Linux]
tags:
  - linux
  - linux-mint
  - nvidia
  - display
  - scripting
  - productivity
---

One of the realities of working from home is that your personal machine and your work setup inevitably end up competing for the same desk space. My solution has been [Barrier](https://github.com/debauchee/barrier), a software KVM that lets me share a single keyboard and mouse across my personal Linux PC and my work laptop, each on their own display, no hardware switch required.

The setup works well, but it introduced a problem I hadn't anticipated. Every time I switch contexts between work and personal use, my monitor configuration needs to change. And thanks to a persistent Nvidia driver bug on Linux, those settings (refresh rate especially) don't survive reliably across the switch.

## The setup

My desk has two monitors connected to my personal PC via DisplayPort:

- **DP-0** - left screen, personal primary
- **DP-2** - right screen, work primary

Both are 2560x1440 panels running at 165Hz. When I'm working, my work laptop's output goes through the left monitor and my personal computing through the right monitor, so I can do research on my PC without consuming the limited resources of my laptop. When I'm done for the day, both screens come back up with the left as primary.

The Barrier client handles the keyboard and mouse sharing seamlessly. The display layout, less so.

## The Nvidia bug

The issue is that Nvidia's Linux driver intermittently drops the configured refresh rate and forgets the screen arrangement after display events. Reconnects, mode switches, anything that causes the X server to re-evaluate the outputs. Instead of staying at 165.08Hz, displays revert to 60Hz. The position and primary screen also reset.

This isn't a new problem. It's been reported against various driver versions and generally comes down to the driver not reliably persisting `xrandr` state through mode changes. Cinnamon compounds it slightly because when it restarts its compositor, it reads back its saved `monitors.xml`, which may itself be stale.

## The scripting solution

Since this is a repeatable problem with a known fix (`xrandr`), the answer was to script it. I ended up with four scripts in `~/bin/`:

**`display-work.sh`** turns DP-0 off and sets DP-2 as the sole display at 165Hz:

```bash
xrandr \
    --output DP-0 --off \
    --output DP-2 --mode 2560x1440 --rate 165.08 --primary
```

**`display-personal.sh`** brings both screens up with DP-0 primary on the left:

```bash
xrandr \
    --output DP-0 --mode 2560x1440 --rate 165.08 --primary \
    --output DP-2 --mode 2560x1440 --rate 165.08 --right-of DP-0
```

**`display-shutdown.sh`** and **`display-restart.sh`** show a Zenity dialog asking which mode to use next time, save the answer to `~/.config/display-mode`, then call `systemctl poweroff` or `systemctl reboot`.

**`display-apply-saved.sh`** reads `~/.config/display-mode` and calls the appropriate script. This runs on every login via an autostart entry, so the right layout is applied automatically regardless of whether the previous session ended with a shutdown or restart.

## Hooking into Cinnamenu

The shutdown and restart buttons in Cinnamenu's sidebar are defined in `sidebar.js` inside the applet directory. Replacing their callbacks with `Util.spawnCommandLine()` calls pointing at the custom scripts was straightforward, and it also gave me the chance to add a Restart button, which Cinnamenu doesn't include by default:

```javascript
// Shutdown
() => {
    this.appThis.menu.close();
    Util.spawnCommandLine('/home/jordan/bin/display-shutdown.sh');
}

// Restart (added)
() => {
    this.appThis.menu.close();
    Util.spawnCommandLine('/home/jordan/bin/display-restart.sh');
}
```

Now every shutdown and restart prompts for the next display mode before acting. The start menu also has standalone "Work Displays" and "Personal Displays" entries for switching on the fly without rebooting.

## The result

Switching between work and personal is now two clicks: open the menu, pick the display mode. The 165Hz refresh rate and correct screen layout are applied consistently on every login, and the Nvidia driver's forgetfulness is no longer something I have to think about. The script just reapplies what should have been there anyway.

It's a more involved workaround than should be necessary for something as basic as a static display configuration, but on Linux that's sometimes the deal. Once it's scripted, it stays solved.
