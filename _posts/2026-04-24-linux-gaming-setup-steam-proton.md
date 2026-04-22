---
layout: post
title: "My Linux Gaming Setup: Steam, Proton, and a Controller That Works"
date: 2026-04-24
description: "The exact setup I use for gaming on Linux Mint: Flatpak Steam, Proton-GE, MangoHud, and getting a controller working without headaches."
categories: [Linux]
tags:
  - linux
  - linux-mint
  - gaming
  - proton
  - steam
  - controller
---

I wrote about [the Proton experience in general](/linux/2026/04/22/linux-gaming-proton-2026) two days ago: what works, what the anti-cheat wall looks like, and whether the switch is worth it. This is the practical companion. The exact commands, the specific friction I hit, and what the setup actually looks like day to day.

## Steam

Flatpak Steam rather than the apt package. The Flatpak build is more current and avoids the library conflicts that can make the apt version awkward on non-Ubuntu-derived systems.

```bash
flatpak install flathub com.valvesoftware.Steam
```

Launch it, log in, let it scan the library. First-time setup is straightforward.

## Proton for everything

In Steam Settings, under Compatibility, switch on "Enable Steam Play for all other titles." Set the default Proton version to the current stable release. This covers most of the library without per-game configuration.

## Proton-GE

Proton-GE adds patches not yet in Valve's official builds. Worth using as the default rather than official Proton.

```bash
flatpak install flathub net.davidotek.pupgui2
```

Open ProtonUp-Qt, click Add Version, install the current GE release (formatted as `GE-ProtonX-Y`). Once installed, it appears as a Proton version option in each game's Properties under Compatibility. I've set GE as my system-wide default and switch back to official Proton only when something specific breaks.

## MangoHud

An in-game overlay showing framerate, frametime, GPU temperature, CPU load, and VRAM usage. Useful when something feels off and you want numbers rather than guesses.

```bash
sudo apt install mangohud
```

To enable per game, add to Properties, General, Launch Options:

```
MANGOHUD=1 %command%
```

Works for Proton titles as well as native Linux builds.

## Controller

I expected this to be the painful part. It wasn't. The Xbox controller I use was detected immediately over USB, and Bluetooth pairing worked through the Cinnamon Bluetooth settings panel without any extra packages. No xpad configuration, no udev rules, nothing manual.

In Steam Settings, under Controller, enable Steam Input for your controller type. This lets Steam manage button mapping at the application layer, which helps for games with no native controller support or games that expect a specific controller layout.

For one game I ran into that expected Xbox 360 buttons in a specific configuration, Steam's controller configurator handled it without leaving Steam. I haven't needed to touch jstest or anything system-level.

## Friction I actually hit

**External drive libraries:** The Flatpak sandbox doesn't automatically see drives outside its default paths. If you want to store games on an external or secondary drive, you need to grant Steam access to it. Two ways to do this:

Via the command line:

```bash
flatpak override --user com.valvesoftware.Steam --filesystem=/path/to/your/drive
```

Or via [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal), which gives you a GUI for managing Flatpak permissions. Open it, select Steam, and add the drive path under Filesystem. Either approach has the same effect.

Without this, Steam can navigate to the path in the file dialog but fails to create a library there. The error message isn't particularly helpful, which makes this one annoying to diagnose the first time.

**Shader compilation stutter:** The first play session through a new game involves hitching as the shader cache builds. It's gone on subsequent sessions, but it can feel like something's broken when you first hit it. It isn't.

**Per-game Proton overrides:** One game I tried crashed at launch on official Proton. Switching to Proton-GE in that game's Properties fixed it immediately. When something isn't working, checking whether the GE build handles it is always worth a try before going further.
