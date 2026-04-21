---
layout: post
title: "Migrating to Linux Mint Without a USB Drive, and Why I'm Not Going Back"
date: 2026-04-17
categories: [Linux]
tags:
  - linux
  - gaming
  - linux-mint
  - proton
---

I'd been putting off switching to Linux for years. Not because I didn't want to, I'd been curious about it for a long time, but the timing never felt right and "wipe and reinstall" felt like a weekend I didn't have. What finally pushed me over the edge was crashing out of a competitive Overwatch match mid-game because Windows had quietly decided it was a good time to apply an update and restart. That was it. The decision made itself.

What made this migration more interesting than most is that I did it without a single USB drive.

## The problem with Windows for gaming

Before getting into the how, it's worth explaining the why. Windows gaming had become genuinely wearing, not because the games didn't run, but because of everything surrounding them. Update prompts ignoring active hours. Defender scans choosing the worst possible moments. Background telemetry that couldn't be fully silenced without going elbow-deep in the registry. The kind of overhead that doesn't show up in benchmarks but accumulates into something that makes a system feel hostile to actually using it.

Losing a competitive match to a forced restart was the last straw. I'd been tolerating it for too long, and the tolerance had run out.

## Installing Mint without USB boot media

The standard Linux install process involves downloading an ISO, flashing it to a USB drive, booting from it, and installing. That's the path most guides assume. I didn't have a spare USB drive available, so I had to find another way.

The approach was to use repartitioning to carve out space on the existing Windows drive for a Linux install, alongside a trick to make the ISO itself bootable from disk.

Here's the rough sequence:

**1. Shrink the Windows partition**

Using Windows' built-in Disk Management tool, I shrunk the primary NTFS partition to free up around 100GB of unallocated space. Windows can only shrink a partition so far due to immovable system files. If you hit that ceiling, running `Optimize-Volume` in PowerShell first (or a defrag pass) can help shift some of those files.

**2. Create a small GParted ISO partition**

Before installing Mint itself, I created a small FAT32 partition (around 1GB) and wrote the GParted Live ISO directly onto it using [Ventoy](https://www.ventoy.net/) or by extracting the ISO contents. This becomes important later for the cleanup step.

**3. Install Linux Mint into the unallocated space**

With the ISO extracted and a GRUB entry pointing at it, I could boot into the Mint installer directly from the hard drive. From there, installation was standard: create the root and swap partitions in the free space, install the bootloader to the drive, and let the installer do the rest.

**4. Migrate data from Windows to Linux**

With both operating systems running side by side, I could mount the NTFS Windows partition from Linux and copy across everything I needed. Documents, game save files, SSH keys, dotfiles. NTFS mounts read-write on Linux without any issues, so this was pretty painless.

## Removing Windows and reclaiming the disk

Once I'd been running on Mint for a few days and was confident I hadn't missed anything, it was time to clean up. This is where the small GParted partition earned its place.

Booting into GParted Live, I deleted the Windows partition and the recovery partitions, leaving only the Linux install and the GParted partition itself. I then expanded the Linux root partition to fill the newly freed space. It's a live resize and takes seconds in GParted.

The final step was removing the GParted partition too, merging that last 1GB back into the root filesystem. The whole operation took about fifteen minutes and left a clean, single-OS drive.

## Gaming on Linux with Proton

This was the part I was most uncertain about, and the part that has surprised me the most.

[Proton](https://github.com/ValveSoftware/Proton), Valve's compatibility layer for running Windows games on Linux, has matured a lot. For most games in my library it works transparently. Install the game, launch it, play it. No configuration, no tweaking.

**Final Fantasy XIV** runs excellently. The community maintains [XIVLauncher](https://goatcorp.github.io/), a native Linux-aware launcher that handles Proton configuration automatically and in some respects works better than the official Windows launcher. Performance is on par with what I was seeing on Windows, without all the background process noise.

**Kerbal Space Program** runs natively on Linux, so there's nothing to configure there at all.

The performance story is genuinely better than I expected. For many titles, frame rates are the same as Windows or slightly higher, partly because there's just less competing for CPU time in the background. The games that struggle tend to be ones with aggressive anti-cheat (EAC and BattlEye in kernel mode are the main blockers), but support for those is improving and many titles have already opted into Linux-compatible configurations.

[ProtonDB](https://www.protondb.com/) is worth bookmarking. It's a community-maintained database of game compatibility reports and it's usually the first place I check before buying anything new.

## Was it worth it?

Unreservedly. The system feels lighter and more responsive, boot times are genuinely shorter, and there's none of that low-grade background noise from an OS trying to upsell me on OneDrive or interrupt me at the worst possible moment. For the titles I care about most, the gaming experience is equivalent to Windows, and in some cases noticeably better.

The no-USB route added a few steps that a standard install wouldn't need, but it was a satisfying exercise and meant the whole migration happened without any downtime or dependency on hardware I didn't have. If you've been hesitating about Linux for gaming, Proton's current state makes it a far more realistic choice than it was even two years ago, and the barrier keeps dropping.

---

*Postscript: I have since ordered a USB SD card reader. Just in case.*
