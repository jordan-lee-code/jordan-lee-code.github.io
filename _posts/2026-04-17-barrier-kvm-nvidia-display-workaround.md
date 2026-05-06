---
layout: post
title: "Splitting Work and Personal Computing with Barrier KVM, and Scripting Around an Nvidia Display Bug"
date: 2026-04-17
description: "Using Barrier KVM to share one keyboard and mouse across my personal PC and work laptop, and scripting around an Nvidia display bug that kept resetting monitor settings."
categories: [Linux]
tags:
  - linux
  - linux-mint
  - nvidia
  - display
  - scripting
  - productivity
---

One of the quiet realities of working from home, especially for those of us who don't have a separate office to retreat to, is that your personal machine and your work setup end up competing for the same desk space and the same hours. The boundary between "I'm working now" and "I'm not" stops being a building you walk out of and starts being whichever machine you're sitting in front of. My solution has been [Barrier](https://github.com/debauchee/barrier), a software KVM that lets me share a single keyboard and mouse across my personal Linux PC and my work laptop, each on their own display, no hardware switch required. More than a productivity setup, it's a way of giving the work-vs-personal boundary back its physical shape.

The setup works beautifully for what it does, but it introduced a problem I hadn't anticipated. Every context switch between work and personal means the monitor configuration needs to change, and thanks to a persistent Nvidia driver bug on Linux, those settings, refresh rate especially, don't survive the transition reliably.

## The setup

My desk has two monitors connected to my personal PC via DisplayPort:

- **DP-0** (left screen, personal primary)
- **DP-2** (right screen, work primary)

Both are 2560x1440 panels running at 165Hz. When I'm working, my work laptop's output goes through the left monitor and my personal computing through the right monitor, so I can do research on my PC without consuming the limited resources of my laptop. When I'm done for the day, both screens come back up with the left as primary.

The Barrier client handles the keyboard and mouse sharing without complaint, which I am quietly grateful for whenever I think about how much friction that piece could otherwise add. The display layout, on the other hand, has been considerably less cooperative, and that is what this post is mostly about.

## The Nvidia bug

The underlying issue is that Nvidia's Linux driver intermittently drops the configured refresh rate and forgets the screen arrangement after almost any display event of consequence, whether that is a reconnect, a mode switch, or anything else that causes the X server to re-evaluate its outputs. Instead of staying at the 165.08Hz I had carefully configured, the displays quietly revert to 60Hz, and the position and primary-screen designation reset along with the refresh rate, so that the entire arrangement falls out of place at once.

None of this is a new problem to anybody who has been using Nvidia drivers on Linux for a while. It has been reported against various driver versions over the years, and the root cause generally comes down to the driver not reliably persisting `xrandr` state through mode changes. Cinnamon compounds it slightly on top of that, because whenever it restarts its compositor, it reads back its saved `monitors.xml` from disk, and that file may itself be stale by the time it gets read.

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

From there the solution grew to cover panel layouts, shutdown and restart prompts, autostart on login, and an interactive profile wizard, and the whole thing is published now as [display-profiles](https://github.com/jordan-lee-code/display-profiles), a generic tool for managing named display profiles on any Linux DE. If you are reading this from your own home desk where work and personal sit on top of each other, and you have been quietly losing time to the same kinds of display nuisances, I hope it spares you the afternoon I lost to figuring it all out.
