---
layout: post
title: "When Your App Lives Off Two APIs That Don't Always Answer"
date: 2026-05-04
description: "Two free public APIs power every food lookup in OpenNutriTracker. Both are flaky enough that retry, cache, and custom-meal fallback need to be a layered system."
categories: [Open Source]
tags:
  - flutter
  - open-source
  - dart
  - mobile
  - networking
  - caching
---

You're standing in the supermarket. You scan a barcode and the app spins for a few seconds before giving up. You scan it again, and again it fails. The third attempt resolves. The product was always there in Open Food Facts, the API just didn't answer the first two times. That's the failure mode most nutrition scanners in this category have, and it's the one that quietly makes people stop using them.

OpenNutriTracker resolves every food lookup against two free public sources: Open Food Facts for branded products and a Supabase-hosted mirror of the USDA Food Data Central database for raw and minimally processed foods. Both are free, both are excellent, and both fall over often enough that the app has no choice but to plan around it.

A handful of recent PRs were about turning that planning into an actual layered system. Retry, then cache, then a custom-meal fallback that survives even when the network is gone entirely. None of it on its own is particularly clever. The interesting part is the order they sit in, and what each layer is for.

## A retry helper that learned not to be loud

The first piece is the simplest. The barcode scan flow already had a private `_withRetry` helper buried in `import_meal_scanner_screen.dart`, used to retry the camera-driven scan once if it failed. That helper got pulled out into `lib/core/utils/retry_util.dart` and applied to the search and barcode lookups themselves: three attempts, exponential backoff at 1s, 2s, and 4s, with the 404 case skipped because a barcode the API definitively doesn't know is not going to start being known on attempt three.

The smaller change in the same PR matters more than it looks. Sentry capture used to fire on the first network exception, before any retry had a chance to succeed. That meant transient failures, the kind that resolve on attempt two, generated noise in the error stream that nobody was going to act on. Capture moved to after all attempts are exhausted. The error log is now a list of things that actually went wrong, not a list of things that nearly went wrong.

There was also a small pre-existing bug worth mentioning, because it's the kind of thing that gets missed for years until you read the code carefully. `fetchBarcodeResults` was throwing `ProductNotFoundException` rather than `ProductNotFoundException()`. The class itself, not an instance of it. Dart let that compile because `Future.error` accepts anything, and it produced an exception that looked correct in the trace until you looked twice. Fixed in passing.

## The cache that fills itself

There was an open issue (#319) proposing a different shape for the offline problem: bundle a subset of the Open Food Facts database, around 230 MB, into the app, and let the user search it locally. Workable in principle. Operationally a different conversation. Someone has to host the subset, someone has to update it, the binary size doubles, and most of what gets bundled will never be looked at by any given user.

The shape that landed (PR #352) is the inverse. Every successful network call writes its result to a new `RemoteSearchCacheDataSource`, keyed by the same identifier the API returned. Every subsequent search consults the cache before going remote. The cache fills naturally, with exactly the items the user actually looks up, and nothing they don't.

The storage cost in practice is the kind of number that ends a conversation. A median user logging around ten items a day for six months sees about 500 to 1500 unique items in the cache, taking somewhere between 0.3 and 0.9 MB on disk. A heavy user who scans curiously rather than just logging meals might hit 3 MB after six months. That's against the 230 MB the bundled-subset design needed, before you factor in the hosting and update cost.

There's a settings tile that surfaces the count and on-disk size in human units, with a clear-cache button that's disabled when there's nothing to clear. Custom meals are explicitly not touched by the clear, because they're the user's own templates and the cache is for remote lookups. Mixing the two would have made the button a much more dangerous thing to press.

## The fallback that runs even when the network is dead

The third layer is the smallest in code and the easiest to take for granted. When a search fails entirely, the user used to see nothing. The remote source returned an error, the cache had nothing for the query, and the screen showed an empty state. The custom meals the user had built themselves, sitting in a local Hive box that had nothing to do with the network, were nowhere on the screen.

PR #350 changed the search logic so the custom-meal box is queried first, before the remote lookup, and its results are kept regardless of whether the remote source succeeds. If the network is dead, the user still sees their own templates. If the network is fine, the user sees their templates first, then the fresh remote results, then (deduplicated against the fresh results) the cached results from previous searches.

That ordering is deliberate and worth being explicit about. The custom-meal box is the user's own work, so it goes first. Recent intake history is what the user is most likely to be logging again, so it goes second. Fresh remote results are the source of truth when available. Cached remote results are the fallback for when fresh isn't available, and the dedup helper makes fresh win on collisions so the user always sees the latest data when the network is online.

## What this combination feels like to use

The interesting thing about layered fallbacks is how invisible they are when they work. A user who has never had a search fail doesn't notice that there are three layers underneath the results. A user who is logging a meal in a basement carpark with no signal opens the app, taps a custom meal, and gets exactly the same experience they'd have at home. A user whose Supabase FDC instance is having a bad afternoon sees their previous lookups instead of an empty screen. The app doesn't tell them anything has gone wrong because nothing visible has gone wrong.

That's the goal, but it's worth saying out loud. Resilience is not a feature users notice. It's the absence of the failure modes that would otherwise have made them stop using the app. The work that went into these three PRs is the work that means a barcode scan in a supermarket doesn't make someone scan three times before giving up and switching to MyFitnessPal.

The thing I keep coming back to is how cheap the resilience is, in absolute terms. The retry helper is fewer than a hundred lines, including tests. The cache is a Hive box and a dedup helper. The custom-meal-first ordering is a couple of lines in the search bloc. The cumulative effect is the difference between an app that is technically functional and an app that is reliable enough to keep using when the world is being uncooperative. That ratio of effort to outcome is unusually good, and it's the kind of thing I want to default to building from now on.
