---
layout: post
title: "Blue/Green Deployments on a Raspberry Pi, and Why It Earns Its Keep"
date: 2026-05-17
description: "The bubbyway household app runs two Node processes side by side on a Pi behind a local Caddy, with atomic upstream swaps and additive-only SQLite migrations. Why an app two people use needs production-grade deploys, and what the constraints quietly taught me about migrations, caching, and the small operational kindnesses that decide whether software feels trustworthy in everyday use."
categories: [Software]
tags:
  - sveltekit
  - self-hosted
  - raspberry-pi
  - deployment
  - sqlite
  - caddy
  - cloudflare
---

The first version of bubbyway's deploy script was a single `ssh pi "systemctl restart bubbyway"`. It worked perfectly well, in the sense that the new code ran after I had finished pushing it. It also took about thirty seconds, during which the Node process was rebuilding its in-memory state and the app was returning 502s, and the thirty seconds always seemed to land at the moment my partner was trying to log a medicine dose or tick off the chore they had just finished. The friction of an app that interrupts itself in the middle of dinner is a small friction, and it is also the kind of small friction that decides whether software feels trustworthy in everyday use or feels slightly haunted.

I rewrote the deploy a few weeks later. The current shape is blue/green: two systemd-managed Node processes on the Pi, a local Caddy in front of them rewriting its upstream during the swap, Cloudflare Tunnel terminating TLS publicly without anything on the home router being exposed, and a small set of operational constraints around migrations and caching that make the zero-downtime promise actually hold. This post is the walk-through of how it fits together, and the bits of the thinking that took me longer than I expected to arrive at.

## The shape on the Pi

The production deploy lives on a Raspberry Pi 4 in a cupboard. The traffic flow looks like this:

```
internet
  │
  ▼
cloudflare edge (TLS termination)
  │
  ▼  outbound tunnel
cloudflared (on the Pi)
  │
  ▼
caddy on 127.0.0.1:3000
  │
  ▼  proxies to whichever colour is active
bubbyway-blue (port 3001)    bubbyway-green (port 3002)
  │                              │
  └──────────┬───────────────────┘
             ▼
       SQLite database
   /var/lib/bubbyway/bubbyway.db
```

The two Node processes are managed by `bubbyway-blue.service` and `bubbyway-green.service`. Each one is the same SvelteKit build under `@sveltejs/adapter-node`, listening on its own loopback port. The single-line file at `/var/lib/bubbyway/active-color` records which one is currently serving traffic. Caddy reads the file indirectly, in that the deploy script rewrites the Caddyfile's upstream and asks Caddy to reload, and `systemctl reload caddy` is graceful: in-flight requests finish on the old upstream while new requests start landing on the new one. There is no moment where traffic gets dropped on the floor.

`cloudflared` is a Cloudflare Tunnel daemon running on the Pi as its own systemd service. It opens an outbound connection to Cloudflare's edge, registers the household subdomain against the tunnel, and forwards incoming requests to the local Caddy. The benefit of this shape, beyond the obvious one of getting TLS termination for free, is that nothing on the home router has to be exposed. There is no port forwarding rule, no inbound firewall hole, no fragile DDNS update; the entire public-facing surface is a single outbound TCP connection from the Pi to Cloudflare, and the home network's posture is unchanged.

## The deploy, end to end

`scripts/deploy.sh` is a bash script that runs on the laptop. The flow is:

1. Build the SvelteKit app locally with `npm run build`. The Pi does not need Vite or TypeScript; it just needs the compiled adapter-node bundle.
2. Read `/var/lib/bubbyway/active-color` on the Pi to find out which colour is currently serving. The idle colour is the deploy target.
3. Rsync the new build to the idle colour's `/opt/bubbyway-<colour>/` directory, along with the generated Drizzle migrations and the package files.
4. Run `npm ci --omit=dev` on the Pi so native bindings (`better-sqlite3`, `@node-rs/argon2`) compile for the Pi's architecture. The native compile is the slow step; it takes about ninety seconds on a Pi 4.
5. Restart the idle colour's systemd unit. On boot, it applies any pending migrations against the shared database in `/var/lib/bubbyway/bubbyway.db`.
6. Poll the idle colour's `/healthz` endpoint on its loopback port until it returns 200. Up to thirty seconds of polling with a one-second sleep between attempts. If it never comes up, the deploy aborts, the idle colour gets stopped, and the active colour is unchanged.
7. SSH to the Pi and invoke `swap-active.sh <colour> <port>`, which rewrites the Caddyfile's upstream and calls `systemctl reload caddy`.
8. Stop the previously-active colour's systemd unit.
9. Verify the public URL still answers `/healthz` over HTTPS.

The whole sequence takes a couple of minutes on a Pi 4, almost all of which is the `npm ci` native compile. From the point of view of the public URL, there is no downtime at any point. In-flight requests finish on the old colour during the swap; new requests land on the new colour. The only way to notice a deploy is happening from the browser side is to be staring at the network tab when the swap happens, and even then you only see that the response came from a different upstream.

## The constraint that does the most work

The discipline that makes any of this work, more than any other single piece of the design, is **additive-only migrations**. Because both colours read and write the same SQLite database, a migration that drops or renames a column would break the colour that has not been updated yet. The old colour is still serving requests until the swap completes, and those requests are still issuing SELECTs and UPDATEs against the columns the old code knows about. If the new colour's boot step has dropped a column the old code is still selecting, the old colour starts erroring on its next request and the swap window stops being graceful.

Every schema change in bubbyway is expressible as an additive step. New columns can be added freely because the old code does not select them. New tables can be added because the old code does not query them. Renames and drops have to be split across two deploys: the first one stops the new code from reading the old column, and the second one drops the column once both colours have been running on the new code through at least one deploy. The discipline is small and a bit annoying when you are halfway through a refactor and want to clean up a vestigial column in one go, and it pays for itself every time the deploy slides through without anyone noticing.

The drizzle generated migrations live in `drizzle/` and apply at boot of the newly-started colour, via the migrate step in `src/lib/server/db.ts`. There is no separate migrate command in the deploy script. The migrations are part of the boot path, which means a migration that fails on the new colour shows up as a failed health check, which means the deploy aborts and the old colour keeps serving. That property took me longer than I would like to admit to arrive at, because the first version of the migration flow ran the migrations separately, before the new colour started, and a failed migration there had no clean recovery path. Putting the migrations on the boot path made the failure mode honest: if the new code cannot start, the deploy refuses to swap, and the database is unchanged from the old colour's point of view.

## Why SQLite, on a Pi, for this

The choice of SQLite for an app two people use is mostly the choice of "there is no separate database process to operate, and the file is small enough to back up atomically several times a day". `better-sqlite3` opens the database file in WAL mode, which means the readers and writers do not block each other in the way they would with the default journal mode. Two Node processes sharing the same database file in WAL mode is a perfectly happy arrangement, because the WAL file is shared and the locking semantics are designed for exactly this.

The atomic `.backup` command is the part that lets the backup story stay simple. `bubbyway-backup.timer` fires every day at half past three in the morning, runs `sqlite3 bubbyway.db ".backup /var/backups/bubbyway/daily/<date>/db.sqlite"`, gzips the result, and rotates to keep seven dailies, four weeklies, and six monthlies. The `.backup` command takes a consistent snapshot of the database without blocking writers, which means I do not have to put the app into maintenance mode at half past three to take a backup, and the snapshot is internally consistent even if a transaction is mid-commit when it fires. A separate laptop-side timer rsyncs the Pi's backups to a folder on the laptop, so the data has a second home that survives the Pi catching fire.

## A small detail I am quietly proud of

The service worker only caches immutable assets. Never HTML. That single decision, set in `static/sw.js`, is the difference between a PWA that serves stale authenticated content after a deploy and one that does not. iOS in particular is enthusiastic about caching the app's HTML shell, and an iOS PWA that has cached the pre-deploy shell will keep serving the old code from its cache for hours, regardless of what the server thinks the current version is. The fix is to refuse to cache HTML at the service worker layer, which forces the browser to fetch the shell from the network on every load, which means the deploy is visible to the user the next time they open the app.

The same logic applies to `Cache-Control: no-cache, must-revalidate` headers that `hooks.server.ts` sets on every HTML response. The combination of those two policies, the SW one and the response header one, is what lets a deploy actually reach the user's browser within the time it takes them to pull the app open again. Without it, you can do the most graceful zero-downtime deploy on the server side imaginable and still have your users seeing yesterday's bugs because the browser quietly preferred its local copy.

## Why production-grade deploys for a household app

The honest answer has two parts and I want to name both of them. The first part is that it was good practice. Operating an app that has uptime expectations is a skill that does not develop without using it, and a household app that I genuinely rely on is a softer place to practise the discipline than a system at work where the blast radius is larger. The blue/green pattern, the Caddy upstream swap, the additive migration constraint, the boot-path migration runner: all of those are patterns I have implemented in larger systems and wanted the small-scale satisfaction of building one from scratch in a system I owned end to end.

The second part is the part the first part is in service of. My partner uses bubbyway every day, several times a day. The chores they tick off, the medicines they log, the appointments they check, the shopping list they edit while walking through the supermarket: all of those are interactions that happen in a household-time texture that does not have room for a thirty-second deploy window in the middle of dinner. The small operational care of zero-downtime deploys is one of the ways the app keeps a promise I want it to keep, which is that it is there when they need it, and it does not interrupt itself for reasons that have nothing to do with what they were trying to do.

The patterns are small. The constraints are small. The amount of code that implements blue/green on a Pi is a few hundred lines of bash and one short Caddyfile and a couple of systemd units, and the discipline around additive migrations is a habit I have to keep more than a tool I can install. The benefit, when it lands, is a thing nobody notices, which is exactly the kind of benefit I find myself wanting the app to keep delivering.
