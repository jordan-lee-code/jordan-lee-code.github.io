---
layout: post
title: "Reading Wireless Peripheral Battery Levels on Linux"
date: 2026-05-03
description: "How I built Cinnamon panel applets for two wireless peripherals that don't expose battery anywhere on Linux: the Logitech A20 X headset and Yunzii B87 keyboard."
categories: [Linux]
tags:
  - linux
  - cinnamon
  - hardware
  - python
  - hid
---

I have two wireless peripherals on my desk that work fine on Linux: a Logitech A20 X headset and a Yunzii B87 keyboard. Audio, the mute button, typing, all of it functions without any proprietary software. The one thing neither of them does is tell me the battery level. The dongle for each device doesn't surface it through PulseAudio, ALSA, or anywhere else the desktop can see it. You find out the charge is low when it cuts out.

I wanted a small indicator in the Cinnamon panel for each. Neither project had any Linux support to reference, so I started poking at the hardware.

## The Logitech A20 X: Reading a Firmware Debug Log

The A20 X dongle (USB ID `046d:0b35`) enumerates as a HID device. HID devices communicate through interrupt reports that stream automatically, and feature reports that you poll on demand. Watching interrupt traffic with `hid-recorder` while turning the headset on and off didn't show anything useful. Feature reports were the other avenue.

Feature report `0x07` came back with 62 bytes of structured data: not a status register, but a rolling firmware debug log. Entries follow a consistent format: `0x05` as a framing byte, a type byte, a length byte, `0x00` as padding, and then the payload. Once I had that structure, finding the battery entries was a matter of matching values to the headset's actual charge. Entry type `0x5D` with a payload starting `0x03` contains the battery percentage and a charging status byte. The same entry type carries firmware text messages too, including "LE connected" and "LE disconnected", which tell you whether the headset has an active BLE link with the dongle at all.

The log is only written after a BLE reconnect. Everything downstream depends on that.

Charging has two detection paths on the A20 X. The BLE battery notification includes a status byte at reconnect time: `0x00` means charging, anything else means on battery. The second path covers the USB data cable: when you plug the headset into a data-capable port, a second HID device appears at `046d:0b2e`, and its presence in `/dev/hidraw*` confirms the cable is in.

## The Yunzii B87: A Vendor Command Interface

The Yunzii dongle (USB ID `056d:c077`) exposes two hidraw interfaces. The first is the standard 8-byte keyboard input. The second is a 64-byte vendor interface for extended commands, and battery lives there.

The protocol is an active query: write `[0x0a, 0x05, 0x00 × 62]` to `hidraw1` and read the 64-byte response. Battery percentage sits at `byte[14]`. `byte[15]` holds the voltage divided by ten, so `0x2a` means 4.2V. I found this by writing a `--discover` mode that sweeps sub-commands `0x00` through `0x1f` and prints any non-trivial responses. Once you know which command returns data, a `select`-based read loop with a short timeout is all it takes.

The limitation is the same as the Logitech: the dongle caches whatever the keyboard reported at its last connection. Polling the interface repeatedly during a long session returns the same reading. Power-cycling the keyboard forces a fresh handshake and a new value.

Charging detection follows exactly the same wired-device pattern. When a USB-C data cable is plugged in, a second HID device appears at `28e9:30ad`. If it's accessible, the cable is in. Charge-only cables don't enumerate that device and aren't detectable.

## Caching and Staleness

Both projects cache the last known reading to `~/.cache/` as timestamped JSON, serving it until something fresher comes in or seven days pass. The applet tooltip shows the reading age so "47% (13 min ago)" is more honest than a bare number.

The Yunzii applet goes one step further: if the cached reading is more than 30 minutes old and the keyboard isn't on charge, it appends a `?` to the label and drops the colour to grey. It's a best guess that the keyboard might be off or out of range, but it's a more useful hint than letting an old number look current.

The A20 X applet handles disconnect differently, because the firmware log makes it explicit. If the last BLE event is a disconnect with no reconnect following it, the script records that state and the applet shows "off" rather than a stale percentage.

## The Applets

Both `applet.js` files follow the same structure: run the Python script on a timer, parse stdout, update a colour-coded label in the panel. The output protocol is the same for both: `PCT AGE_SECS CHARGING` for a reading, `DISCONNECTED` when the device isn't found, or `ERROR: reason` for anything else.

Colour coding: green above 50%, yellow between 20% and 50%, red at or below 20%. A `notify-send` critical alert fires when either device crosses 20% going downward while on battery, and only on the crossing. Clicking the applet triggers an immediate refresh.

When charging, both show `⚡` instead of a percentage. The reading at the time you plug in reflects the last reconnect, which could be hours ago, and putting a stale number next to a charging indicator felt more dishonest than just leaving it out.

## Installation

Both follow the same pattern:

```bash
# Logitech A20 X
git clone https://github.com/jordan-lee-code/logitech-headset-battery.git
cd logitech-headset-battery && bash install.sh

# Yunzii B87
git clone https://github.com/jordan-lee-code/yunzii-applet.git
cd yunzii-applet && bash install.sh
```

Each install script symlinks the repo directory into `~/.local/share/cinnamon/applets/`, so updating is just a `git pull`. Enable either applet by right-clicking the panel, opening Applets, and adding it.

Udev rules are needed for both. The dongle itself is covered by systemd-logind via `TAG+="uaccess"`, but the wired charging device needs a group rule. Add yourself to `plugdev` if you aren't already in it, then log out and back in:

```bash
sudo usermod -aG plugdev $USER
```

Then install the rules and reload:

```bash
# A20 X
sudo cp 99-logitech-a20x.rules /etc/udev/rules.d/

# Yunzii B87
sudo cp 99-yunzii-b87.rules /etc/udev/rules.d/

sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=hidraw
```

On first load, both applets may show `--` until the device has connected to its dongle. Give it a few seconds after turning the peripheral on, then click the applet to refresh.

Both repositories are on GitHub: [jordan-lee-code/logitech-headset-battery](https://github.com/jordan-lee-code/logitech-headset-battery) and [jordan-lee-code/yunzii-applet](https://github.com/jordan-lee-code/yunzii-applet).

## What's Next: A Unified Framework

Writing these two applets back to back made the shared structure impossible to ignore. The output protocol, the caching format, the wired charging detection, the applet's colour coding and notification logic: none of it changes between a headset and a keyboard. What changes is one function: how you ask the dongle for the battery level.

That's a satisfying thing to notice, and it points somewhere. My plan is a small shared framework where the device-specific reader is just a plugin: a Python module that knows the vendor IDs, knows how to find the right hidraw interface, and knows how to get a percentage out of it. Everything else lives once in a shared core and doesn't need to be copied into every new project.

A single configurable Cinnamon applet could then support any compatible peripheral just by pointing at the right device module. Adding a third peripheral would mean writing one small Python file and a udev rule, rather than forking an entire repository and renaming everything.

The two projects together make the shape of the framework clear in a way that one alone couldn't have. The Logitech work showed that passive log reading and active querying can both feed the same downstream protocol without the applet caring which approach the hardware uses. The Yunzii work confirmed the wired-device charging pattern was solid enough to standardise rather than treat as a one-off. Neither of those things was obvious before building both.

I'll write about it when it exists.
