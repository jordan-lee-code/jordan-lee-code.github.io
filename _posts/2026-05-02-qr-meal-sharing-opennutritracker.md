---
layout: post
title: "Fitting a Meal Into a QR Code"
date: 2026-05-02
description: "QR codes can hold more data than you'd think. But 'technically fits' and 'scans reliably on a real phone' are different questions, and the gap drove every interesting decision."
categories: [Open Source]
tags:
  - flutter
  - open-source
  - dart
  - mobile
  - qr-code
---

OpenNutriTracker is the nutrition logging app I use. It's open source, well-built, and missing one thing that mattered to me practically: I cook for my partner, who needs to track calories but can't always look up each ingredient themselves. The workflow I wanted was simple: I log the meal as I cook it, they import it on their phone. There was no way to do that without one of us recreating every item by hand, and that was enough friction that I eventually stopped waiting for someone else to close it.

The obvious approach was a QR code. Scan it, import the meal, done. It took about ten minutes of staring at the raw data structure for a three-item dinner before I started wondering whether it would scan reliably in practice.

## The payload problem

A QR code in binary mode can hold up to roughly 2953 bytes at Version 40. A three-item meal serialised as readable JSON lands somewhere between 1.5 and 2KB, so it technically fits. The problem is that a Version 25+ QR code is dense enough that cameras need to resolve fine detail to read it cleanly. On a real phone, at arm's length, scanning a high-density code is unreliable in a way that a lower-density code is not. Fitting the data and scanning the result are different problems.

A modest meal in this app carries a lot of data per item: a name, a brand, a unit, a serving amount, and seven separate nutrient values (energy, carbs, fat, protein, sugars, saturated fat, fibre). Add two image URL fields for the thumbnail and the full image, and a single item has 13 fields. The goal was to get a typical meal small enough to land in a QR version that scans reliably on ordinary hardware.

The compression pipeline is `UTF-8 bytes → gzip → base64url`. Gzip is effective on repetitive JSON structure. The base64url step is not actually needed for the QR code itself (`qr_flutter` renders from binary data directly), but it is needed for the paste fallback, where the encoded string has to survive being copied and pasted as text. Standard base64 uses `+` and `=`, which cause problems in text contexts. Base64url avoids that, and keeping one encoding for both paths means one decoder.

## From maps to arrays

The first version of the payload format used abbreviated JSON map keys per item:

```json
{"v": 1, "items": [{"n": "Oats", "br": null, "u": "g", "a": 100, "ec": 389, "cb": 66, "ft": 7, "pr": 17}]}
```

Even with single-character keys, the overhead adds up. Every item pays for its key strings. With 13 fields per item and multiple items per meal, the total key overhead is non-trivial before compression.

The v2 format drops the keys entirely:

```json
[2, [["Oats", null, "g", 100, 389, 66, 7, 17, null, null, null, null, null]]]
```

Field order is fixed by position: `[name, brands, unit, amount, ec, cb, ft, pr, sg, sf, fb, thumbUrl, imgUrl]`. The decoder knows where everything is. There are no keys to parse.

This is less readable in raw form, but gzip then has fewer repeated byte sequences to work around. The combination brings a typical meal well inside a scannable threshold.

There is also a small numerical optimisation: nutrient values that are whole numbers are emitted as integers rather than floats. The `_compact` method in the payload class strips the trailing `.0` from any double that rounds cleanly. It saves a few bytes per field across 13 fields per item. Not dramatic on its own, but it compounds with everything else.

Backward compatibility matters here because shared codes outlive app updates. Someone shares a meal encoded in v2, the recipient has an older version that only knows v1: the import needs to not silently fail. The decoder handles both formats. It first tries to decode the input as gzip+base64url, falls back to treating it as raw JSON if that fails, then checks whether the decoded value is a `List` (v2) or a `Map` (v1). Both are decoded correctly; only v2 is written. Explicit version checks throw a `SharedMealParseException` for anything claiming a version the current code doesn't know about.

## The paste fallback

Not everyone has a working camera. Tablets often do not. Emulators rarely do. Some Android configurations make camera permissions awkward to grant. A feature that requires a scan to import is a feature that silently fails for a class of users, and that is not a good property to have.

The import screen has a keyboard icon in the app bar. It opens a dialog that accepts the raw base64url string directly. The decoder does not care how the string arrived; the paste path and the scanner path hand off to the same function.

There is something practical about this beyond the accessibility case. The encoded string is opaque to a human but it transfers cleanly over a chat message, a note, or a shared document. If two people want to synchronise meal plans across devices they don't have next to each other, they can do it without physically aligning cameras. It's not a use case I designed around specifically, but the architecture makes it free.

## Working in someone else's codebase

The field set in the v2 array maps directly onto the fields the app's own `IntakeEntity` model exposes. That was not accidental. I read the data model before designing the payload so I wasn't inventing field names or guessing what the app would and wouldn't have at import time. The payload format is a projection of the app's internal model, which keeps the serialisation and deserialisation code clean.

The localization system required updating six language files for every new user-facing string: English, German, Czech, Italian, Turkish, and Ukrainian. The app uses `.arb` files with a generated `l10n.dart` layer, and the tooling enforces that all languages are present before a build succeeds. I had eleven new strings to add. That is sixty-six individual entries across the arb files and their corresponding generated message files, all for UI copy that a user sees for about two seconds at a time.

It is the right policy. Hardcoded English strings in a multilingual app are a debt that accrues silently until someone files a bug. But it is slow, and the arb format is not the most pleasant thing to work in at volume.

`SharedMealParseException` follows the exception shape the rest of the codebase uses. The app had a consistent pattern: typed exception classes with a `message` field, thrown from domain logic, caught at the presentation layer. Adding a new exception type meant matching that shape rather than throwing raw strings or introducing a divergent error handling style. The goal with any open source contribution is that your additions look as though they were always there.

---

The QR size ceiling turned out to be the most generative constraint in the feature. The compression pipeline, the shift from maps to arrays, the version field, the paste fallback: none of those decisions exist without the ceiling pushing back. You think you're adding a share button and you end up thinking about payload encoding, schema versioning, and graceful degradation. That tends to be where the interesting work is.
