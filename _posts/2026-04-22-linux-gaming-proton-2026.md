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

The clear line where things stop working cleanly is kernel-level anti-cheat. EasyAntiCheat and BattlEye both support Proton in principle, but only when the developer of the game has explicitly enabled it for their title, and many of them have not yet done so for reasons that vary from studio to studio. Games that verify their integrity from a kernel driver simply will not run on Linux at all, because the check that the driver performs happens below the layer Proton operates at, and there is no workaround for that gap that I have been able to find.

If most of your playtime is currently spent in competitive multiplayer games with aggressive anti-cheat protection, the Linux story is still limited in specific and frustrating ways that nobody should pretend otherwise about. If your library skews predominantly toward single-player titles instead, the picture is genuinely good in a way I would not have predicted before I made the switch.

## Proton-GE

Valve's official Proton builds are stable and conservative. Proton-GE, maintained independently by GloriousEggroll, includes patches and fixes that are either still upstream or won't be merged into Valve's build. Some games that don't work on official Proton work on GE. Some run noticeably better, particularly with video codec support.

The install path is ProtonUp-Qt (`flatpak install flathub net.davidotek.pupgui2`), which handles managing GE versions alongside official ones. Once a GE release is installed, it appears as a compatibility layer option in each game's properties. Worth having even if you don't use it as the default, because when you hit a game that doesn't work on official Proton it's the first thing to try.

## Performance

I had prepared myself for a meaningful performance deficit compared to Windows, on the basis of benchmarks from three or four years ago that suggested the gap was substantial. The actual overhead, when I came to measure it on my own hardware, turned out to be considerably smaller than those older numbers suggested it would be, because the DirectX-to-Vulkan translation layer has matured a great deal in the years since those benchmarks were taken.

On my own setup, 1440p at 165Hz holds consistently for the titles I actually play with any regularity. There is some shader compilation stutter on the first run of each game while the cache is building itself, which is genuinely annoying for the first half-hour or so and then quietly disappears once the cache is populated. Subsequent sessions of the same game are smooth in a way that makes it easy to forget the first run ever felt rough, and it is worth knowing to expect that pattern rather than thinking something is wrong with the system the first time it happens.

## Whether it's worth it

For my use case, yes, and I want to say that with the small quiet certainty I have grown into about it. I am not a competitive multiplayer player, so the anti-cheat gap does not affect most of what I play on a given evening. The switch to Linux was primarily about reclaiming control over my own machine, and gaming being substantially intact through that switch is the part I had genuinely expected to have to give up.

A month in, with no Windows to fall back on, the library I can run performs better than I expected, and the library I cannot is smaller than I feared. There is a particular kind of relief in finishing a play session and not having to brace for whatever Windows had been queueing up underneath me while I was busy, and I noticed that relief in my body before I noticed it in my head. Whatever else Linux has cost me, it has given me back evenings that do not end with an unwanted reboot, and I am still a little surprised by how much that small thing has come to matter.

If you are sitting with the same hesitation I had a month ago, with a controller nearby and a question mark over whether your library will follow you across the switch, I cannot promise you it will work for every title you love. I can promise you that the gap is smaller than the older internet would have you believe, and that the evenings on the other side of the switch have been gentler than I had let myself hope for.
