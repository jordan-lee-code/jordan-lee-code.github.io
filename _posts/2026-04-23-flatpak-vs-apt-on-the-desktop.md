---
layout: post
title: "Flatpak vs apt on the Desktop: Where I've Landed After a Month"
date: 2026-04-23
description: "A month into daily driving Linux Mint: the practical reality of mixing Flatpak and apt, where each earns its place, and where the trade-offs actually bite."
categories: [Linux]
tags:
  - linux
  - linux-mint
  - flatpak
  - packaging
  - desktop
---

When you read about packaging on Linux desktops, the conversation tends toward camps. Flatpak advocates point to sandboxing, version freshness, and portability across distros. apt advocates point to system integration, smaller footprints, and the fact that distro repo software was actually tested on your distro. After a month of daily driving Linux Mint, I'm not in either camp, and the specifics of why are worth writing down.

## Why the debate matters at all

On Mint, the default is apt. The Software Manager points at apt. Everything works. The question of Flatpak doesn't arise unless you go looking for it, which I did, because several tools I use daily are considerably older in the Mint repos than in the Flatpak releases.

Steam is a good example. The apt package in the Mint repos is the legacy bootstrap client rather than the current build, and staying on it means older bundled Proton versions and slower access to hardware compatibility improvements. The Flatpak is the recommended install path and tracks the current release. For most of my system software, version currency doesn't matter. For anything where the runtime environment is part of what you're actually relying on, it does.

## Where Flatpak earns its place

GUI applications where I want a current release and where the sandbox doesn't create friction: Flatpak. Steam, Slack, GIMP, Inkscape, most of what lives in the applications menu and gets launched by a person. The install path is consistent, updates run independently from the system package manager, and a Flatpak update can't pull in a dependency that breaks something else on the system.

The Flathub catalogue is large enough that almost everything I'd want is there, and the version freshness is better than distro repos across the board.

## Where apt earns its place

Development tooling, system utilities, and anything that needs genuine integration with the rest of the system: apt. Python, Go, Node, compilers, command-line tools, packages that other packages depend on. The sandboxing that makes Flatpak sensible for a GUI application is actively counterproductive for tools that need to read the filesystem freely, interact with other processes, or write to system directories.

CLI tools that modify system state, write to `/etc`, or run with elevated privileges should not be Flatpaks. The Flatpak access model is built for applications with clear input/output boundaries. A tool that doesn't have those boundaries doesn't fit the model, and forcing it to fit means spending time on permission overrides you shouldn't need to think about.

## The trade-offs that actually bite

Filesystem access is the one you notice first. Flatpak apps run in a sandbox and can only reach directories they've been explicitly granted permissions for. For a text editor or image tool this is mostly fine. For anything that needs to reach into custom paths or system locations, you need to grant access manually.

[Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal) makes this considerably less painful. It's a GUI for managing Flatpak permissions across all your installed apps: filesystem access, environment variables, device access, and more, all in one place without touching the command line. Most of what the sandbox restricts by default can be opened up in a few clicks, and Flatseal makes it easy to see at a glance what each app has been granted. Without it, permission management is friction. With it, it's mostly a non-issue.

Theming is the second one. GTK Flatpak apps don't automatically pick up your system GTK theme because the sandbox doesn't expose the system theme directory. You can work around it with the `GTK_THEME` environment variable or the Flatpak overrides mechanism, but it's friction that apt packages don't have.

Startup time is marginally slower because the sandbox has to be set up on launch. The gap has narrowed in recent releases and is usually imperceptible on SSDs, but it's real. For apps you open and close dozens of times a day, it's more noticeable than for something you open once in the morning.

## Where I've landed

Flatpak for applications: anything that has a GUI, lives in the dock, and gets launched by a person. apt for everything else. In practice the categories don't overlap, so the two don't conflict.

Insisting on pure Flatpak for everything means fighting the sandbox constantly. Refusing Flatpak entirely means running noticeably old software for some apps. The mixed approach isn't a failure to commit. It's the obvious answer once you've spent enough time with both.
