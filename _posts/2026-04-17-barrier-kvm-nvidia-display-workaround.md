---
layout: post
title: "Splitting Work and Personal Computing with Barrier KVM, and Scripting Around an Nvidia Display Bug"
date: 2026-04-17
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

The setup works beautifully for what it does, but it introduced a problem I hadn't anticipated. Every context switch between work and personal means the monitor configuration needs to change, and thanks to a persistent Nvidia driver bug on Linux, those settings, refresh rate especially, don't survive the transition reliably.

## The setup

My desk has two monitors connected to my personal PC via DisplayPort:

- **DP-0** (left screen, personal primary)
- **DP-2** (right screen, work primary)

Both are 2560x1440 panels running at 165Hz. When I'm working, my work laptop's output goes through the left monitor and my personal computing through the right monitor, so I can do research on my PC without consuming the limited resources of my laptop. When I'm done for the day, both screens come back up with the left as primary.

The Barrier client handles the keyboard and mouse sharing without complaint. The display layout, less so.

## The Nvidia bug

The issue is that Nvidia's Linux driver intermittently drops the configured refresh rate and forgets the screen arrangement after display events. Reconnects, mode switches, anything that causes the X server to re-evaluate the outputs. Instead of staying at 165.08Hz, displays revert to 60Hz. The position and primary screen also reset.

This isn't a new problem. It's been reported against various driver versions and generally comes down to the driver not reliably persisting `xrandr` state through mode changes. Cinnamon compounds it slightly because when it restarts its compositor, it reads back its saved `monitors.xml`, which may itself be stale.

## The fix

Since this is a repeatable problem with a known fix (`xrandr`), the answer was to script it. The core of each profile is a short xrandr invocation. Work mode turns DP-0 off and puts everything on DP-2:

```bash
xrandr \
    --output DP-0 --off \
    --output DP-2 --mode 2560x1440 --rate 165.08 --primary
```

Personal mode brings both screens up with DP-0 primary:

```bash
xrandr \
    --output DP-0 --mode 2560x1440 --rate 165.08 --primary \
    --output DP-2 --mode 2560x1440 --rate 165.08 --right-of DP-0
```

From there the solution grew to cover panel layouts, shutdown and restart prompts, autostart on login, and an interactive profile wizard. The full thing is published as [display-profiles](https://github.com/jordan-lee-code/display-profiles) - a generic tool for managing named display profiles on any Linux DE.
