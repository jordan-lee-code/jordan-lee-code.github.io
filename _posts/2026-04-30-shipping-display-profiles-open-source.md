---
layout: post
title: "Shipping display-profiles: What I Learned From Releasing My First Open Source Tool"
date: 2026-04-30
description: "From a personal workaround to open source release: what the gap between 'works for me' and 'works for anyone' looks like, and what I'd do differently."
categories: [Linux]
tags:
  - linux
  - open-source
  - scripting
  - productivity
---

I published display-profiles last week. It's a display-switching tool that started as a set of personal scripts for working around an Nvidia driver bug, grew to cover panel layout persistence, and eventually became something I thought someone else might find useful. Releasing it taught me more than I expected about the distance between code that works for me and code that works for anyone.

## What "works for me" actually means

When the scripts were personal, a lot of things were implicit. Monitor output names were hardcoded to my specific DisplayPort connections. Cinnamon was assumed throughout because that's what I run. The home directory path was hardcoded in several places. The number of display profiles was fixed at two because I only ever needed two.

None of this was carelessness. It's the natural shape of code written for a single environment where the author controls every variable. The problem is that none of those assumptions are visible until someone else runs it on something different.

Before publishing, I had to audit every implicit assumption in the codebase and decide whether to generalise it, document it, or remove it. Generalising was usually right. Hardcoded paths became variables. Monitor names became profile-driven configuration derived from what the user defines during setup. The number of profiles became however many directories exist under `~/.config/display-profiles/`.

## The DE plugin interface

The original scripts had Cinnamon-specific logic scattered throughout. `dconf write` calls lived alongside `xrandr` invocations. The `cinnamon --replace` restart lived in the main switch function.

For the release I extracted all DE-specific logic into a `hooks/cinnamon/` directory with a defined interface: `save-panels.sh` takes a profile directory and snapshots dconf into it; `restart-de.sh` does whatever restarts the DE. The main scripts call the hooks if they exist and skip gracefully if they don't. Adding support for another desktop environment means adding a `hooks/<de>/` directory with the same two files.

This is the change I would have made first if I'd known I was going to publish. Writing the DE abstraction before writing the Cinnamon implementation would have been cleaner than extracting it after. The current structure works, but the seams from the refactor are visible if you look.

## Writing a README that actually helps

The first README I wrote assumed the reader already knew what `xrandr` was, why you'd want named profiles rather than just running commands directly, and what the Nvidia driver bug was. It jumped straight to the installation steps.

The README the project shipped with explains the problem first. It describes the display switching use case, explains why persistence across reboots requires more than a bare `xrandr` invocation, and walks through what happens during profile creation before the installation section. The installation and usage steps stayed concise, but they're preceded by enough context that a reader who doesn't already know the problem space understands why the tool exists.

Writing a good README is harder than writing the code, because the reader's state of knowledge is entirely unknown. The code can make assumptions about the machine state because those are controlled. The README can't assume anything, and the gap between what the author knows and what the reader needs is easy to misjudge.

## CI for a shell scripting project

What does useful CI look like for a project that's entirely shell scripts? Shellcheck runs on all scripts and catches a meaningful class of real bugs: unquoted variables, missing exit codes, bad substitutions, word splitting issues. An install smoketest runs the installer and verifies the expected symlinks and desktop files end up where they should.

```yaml
- name: Run shellcheck
  uses: ludeeus/action-shellcheck@master

- name: Smoke test install
  run: bash install.sh && [ -x ~/bin/display-switch.sh ]
```

That's nearly the whole CI workflow. Small projects don't need complex CI, and adding more than what's actually useful is its own kind of overhead.

## The resistance to publishing

There was a stretch before I published where I kept finding reasons not to. It's too specific to my hardware. The README isn't ready. The DE plugin interface isn't clean enough. The coordinate normalisation has an edge case I haven't fully tested.

Some of those were real. Most were the kind of pre-emptive self-editing that keeps useful things private indefinitely. The Nvidia display bug on Linux is a known and persistent frustration. The `xrandr` fix is documented but the persistence and panel layout pieces are scattered across forum posts and partial solutions. Having them in one place with a setup wizard is useful even if the tool isn't perfect.

Publishing it was the right call. The README is good enough. The code is the right shape for what it does. That's sufficient.

There's a version of quality control that's actually quality control, and there's a version that's indefinite deferral dressed up as standards. Knowing which one you're doing is most of the work.
