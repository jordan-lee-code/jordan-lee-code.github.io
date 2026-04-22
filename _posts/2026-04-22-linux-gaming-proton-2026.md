---
layout: post
title: "Gaming on Linux in 2026: What the Proton Experience Actually Looks Like"
date: 2026-04-22
description: "A month in, this is what running Steam games via Proton on Linux Mint actually looks like: what works, what doesn't, and whether the trade-off is worth it."
categories: [Linux]
tags:
  - linux
  - linux-mint
  - gaming
  - proton
  - steam
---

The short version of what I expected when I switched to Linux was that gaming would be the sacrifice. Windows is gone from the drive entirely, so there's no fallback partition to boot into when something doesn't work. A month in, the actual trade-off is different, and smaller, than I anticipated.

Proton has been around since 2018 and the compatibility story has improved considerably. The honest way to put it is that most of my library just works, and the games that don't are blocked by anti-cheat rather than by anything Proton itself gets wrong.

## What works

Steam on Linux means Steam via Flatpak on most modern distros. `flatpak install flathub com.valvesoftware.Steam` and you're running. The Flatpak isolates it from system libraries, which avoids the dependency conflicts that used to make Steam installations fragile on non-Ubuntu-derived systems.

Enabling Proton for everything is one toggle: in Steam Settings, under Compatibility, switch on Steam Play for all titles and set the default Proton version. From that point, every title in your library has a Proton runtime available.

The ProtonDB ratings are the most useful signal for any specific title. [protondb.com](https://www.protondb.com/) aggregates user reports into platinum, gold, silver, and bronze. Platinum means it runs without tweaks. Gold means minor adjustments. The ratings are crowdsourced, but accurate enough that I check them before buying anything I'm uncertain about.

Most single-player games from major studios, most indie titles, and anything that doesn't aggressively verify it's running on genuine Windows hardware runs well. Sometimes surprisingly well.

## What doesn't

The clear line is kernel-level anti-cheat. EasyAntiCheat and BattlEye both support Proton in principle, but only if the developer enables it, and many haven't. Games that verify their integrity from a kernel driver simply won't work: the check happens below the layer Proton operates at. There's no workaround.

If most of your playtime is in competitive multiplayer games with aggressive anti-cheat, the Linux story is still limited in specific and frustrating ways. If it's predominantly single-player, the picture is genuinely good.

## Proton-GE

Valve's official Proton builds are stable and conservative. Proton-GE, maintained independently by GloriousEggroll, includes patches and fixes that are either still upstream or won't be merged into Valve's build. Some games that don't work on official Proton work on GE. Some run noticeably better, particularly with video codec support.

The install path is ProtonUp-Qt (`flatpak install flathub net.davidotek.pupgui2`), which handles managing GE versions alongside official ones. Once a GE release is installed, it appears as a compatibility layer option in each game's properties. Worth having even if you don't use it as the default, because when you hit a game that doesn't work on official Proton it's the first thing to try.

## Performance

I was prepared for a meaningful performance deficit compared to Windows. The actual overhead is smaller than benchmarks from three or four years ago suggested it would be, because the DirectX-to-Vulkan translation layer has matured considerably.

On my setup, 1440p at 165Hz holds consistently for the titles I play. There's shader compilation stutter on first run while the cache builds, which is annoying and then disappears. Subsequent sessions are smooth. It's worth knowing to expect it rather than thinking something is wrong the first time it happens.

## Whether it's worth it

For my use case, yes. I'm not a competitive multiplayer player, so the anti-cheat gap doesn't affect most of what I play. The switch to Linux was primarily about reclaiming control over my own machine, and gaming being substantially intact is the part I expected to have to give up.

A month in, with no Windows to fall back on, the library I can run performs better than I expected. The library I can't is smaller than I feared.
