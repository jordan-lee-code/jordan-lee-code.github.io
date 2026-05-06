---
layout: post
title: "Adding Recipes to a Nutrition App, and the Decisions That Didn't Make the Screenshots"
date: 2026-05-07
description: "OpenNutriTracker now has recipes. The interesting parts aren't in the demo: snapshot semantics on edit, multi-source routing on import, the recursion v1 dodged."
categories: [Open Source]
tags:
  - flutter
  - open-source
  - dart
  - mobile
  - data-modelling
---

The Recipes feature went into OpenNutriTracker last week. It's the largest single piece of work I've shipped on the project, by a comfortable margin. The PR is around 7600 lines added, with a 4th navigation tab, a recipe builder, a detail screen, an ingredient picker that reuses the existing food search, aggregated nutrition computation, tags, QR sharing, CSV import, and survival of the existing zip export-import path.

The screenshots and the demo cover the obvious shape of it. The actually interesting decisions are the ones that don't appear in either, because they're invisible until something edge-case happens and then they're load-bearing. This post is about those.

## Snapshot semantics

The first decision is what happens to past diary entries when you edit a recipe.

If you logged 100 grams of "Sunday Lasagne" on Tuesday, and you change the lasagne recipe on Wednesday because you realised you'd forgotten the parmesan, what should Tuesday's diary entry show? The same calorie number it had on Tuesday, or the recalculated number that includes the parmesan you forgot?

There is a real argument for either. Recalculating gives you the most accurate-as-of-now nutrition picture. Snapshotting gives you the most truthful as-of-then picture. They're different goals.

The decision that landed is to snapshot. Past diary entries never change. The intake table already stores its own copy of the meal data through `IntakeDBO.meal`, so the snapshot was free in implementation terms. Only future logs see the updated aggregation. Editing a recipe is forward-only.

The argument for snapshotting is that the user isn't really asking "what is the most up-to-date nutritional view of my history." They're asking "what did I eat on Tuesday." The lasagne they ate on Tuesday is the version of the lasagne that existed on Tuesday, which is the version they cooked, regardless of what they later thought about the recipe. The diary is a record of the past, not a live recompute.

The same logic governs deletion. Deleting a recipe preserves diary intakes. The snapshot is intact, the recipe is gone from the recipes list, and a user who looks at their diary three months later still sees a meaningful entry rather than a ghost where the lasagne used to be. "I ate cake on Tuesday" doesn't stop being true when the cake recipe gets deleted.

If the user genuinely wants to remove the historical entry, the diary screen has its own delete that does that explicitly. Two different actions, two different intents. The data model reflects that.

## Multi-source routing on import

The QR meal sharing feature already existed in the codebase. The original payload format encoded a list of items that all came from the same internal source: cached remote lookups (Open Food Facts or Supabase FDC) or the user's own custom-meal box. Two cases.

Recipes broke that assumption. A shared recipe is itself an item, but it composes ingredients that might be cached remote lookups, the sender's custom-meal templates, or other recipes the sender has built. A shared meal containing a recipe ingredient is, by structure, a multi-source object.

The payload format bumped to v2 to handle this. Each item in a shared meal now carries a source tag: `off`, `fdc`, `custom`, or `recipe`. On the receiving end, the import code routes each item to its appropriate local store. OFF lookups go into the receiver's lookup cache. FDC lookups go into the same cache. Custom items go into the receiver's custom-meal box. Recipes go into the receiver's recipe box, with the full embedded recipe payload so the receiver doesn't need to network for anything to log it.

The thing that makes this routing more interesting than it sounds is that the receiver might not have a recipe box at all if they're on an older app version that doesn't know about recipes. So v1 payloads stay readable from the v2 reader, items default to `source=custom`, and the recipes bucket stays empty. An older sender's payload imports cleanly. A newer sender's payload, received by an older app, would degrade by failing the version check explicitly, throwing a typed exception the UI can show, rather than silently dropping the recipe.

Backward compatibility on a shared-data feature outlives most of the app's other compatibility surfaces. A QR code generated today might be scanned six months from now, by which point both apps have updated. Or it might be scanned six months from now by an app that hasn't updated since the day the code was generated. Both directions need to handle the version skew without losing data or producing the wrong nutrition numbers, which is the kind of constraint that makes the format design more careful than it would be otherwise.

## The recursion problem v1 dodged

A recipe is a list of ingredients. An ingredient can be a remote food, a custom meal, or another recipe. The "another recipe" case is the one that creates a problem.

If a user makes a "pasta with sauce" recipe that contains a "tomato sauce" recipe as an ingredient, and they later edit the tomato sauce recipe, what happens to the pasta recipe? Snapshotting (the rule from the previous section) says the pasta recipe shouldn't change retroactively. But the tomato sauce inside the pasta recipe is, in the user's mental model, the same tomato sauce. They probably expect the pasta calorie count to update.

This collides with the snapshot rule from earlier. The tension can be resolved either way, but resolving it requires answering a few harder questions. What if the inner recipe is deleted? What if it's renamed? What if the user wants to override the inner recipe's nutrition for this specific outer recipe? What if the recursion depth is more than two levels? What about cycles?

The decision for v1 was to exclude recipes-inside-recipes entirely. The ingredient picker has a flag, `includeRecipesInResults: false`, that filters recipes out when picking ingredients. A recipe can only contain remote foods and custom meals. The recursion question doesn't have to be answered, because the recursion can't happen.

This is the kind of decision that's hard to write because it feels like a limitation. It is a limitation. It's also the right call for v1, because the design questions it dodges are big enough to be a separate piece of work, and shipping the simpler version sooner means real users get to tell us whether they actually wanted the recursive case before we commit to a particular answer for it.

The "1 ml ≈ 1 g" approximation in the recipe builder is the same shape of decision. For most ingredients (water, milk, juice) the approximation is exact or near-exact. For oil it's off by about 8%. Documenting it in the helper text and shipping is closer to what users actually need than postponing the feature until a full density table is implemented. v1 simplifications are not technical debt if they're documented and bounded; they're the price of shipping at all.

## Logging a recipe by serving

The smaller decision worth being explicit about is how a user logs "one slice of cake" rather than "138 grams of cake."

A recipe optionally carries a `servingsCount` field. If the user sets it to 8, the converted MealEntity that gets logged exposes a "serving" unit alongside the gram unit. The existing meal-detail screen already has a unit dropdown that handles arbitrary units, so logging "1 of 8 servings" worked without writing a new UI; the dropdown picked it up and computed the right gram amount automatically.

This is the kind of detail that makes the difference between a feature that does the thing and a feature that does the thing the way users actually want to do it. People don't measure their dinner in grams. They measure it in slices, bowls, plates, halves, thirds. The conversion to grams happens in the data layer, but the UX has to let them think in the units they actually use, or they stop logging and the app's whole purpose collapses.

## What the work was actually like

The thing I keep coming back to about this PR is how much of it was old work being reused. The QR sharing path already existed. The food search already existed. The meal-detail screen already existed. The custom-meal data layer already existed. Most of what shipped wasn't new code, it was new code that knew how to compose the existing pieces. The new code that did get written, particularly the nutrition aggregation and the multi-source routing, is small relative to the surface of the feature.

That ratio is one of the things I find most satisfying about working in a codebase that already has its primitives in good shape. The work feels disproportionately productive because most of it is composition rather than construction. The QR sharing post talks about the constraint pushing the design; the recipes work was the inverse case, where there was a lot of headroom because the constraints had already been dealt with elsewhere. Both feel productive in different ways, and both depend on someone having done the slow patient work of building the primitives in the first place.

The decisions worth recording are the ones that lasted. Snapshot semantics on edit and delete. Multi-source routing with a typed source tag. Recursion deliberately deferred to v2 with the door left open. Backward compatibility on the wire format that survives version skew in both directions. Those are the decisions a future contributor will inherit, long after the screenshots have gone out of date. The screenshots are what the user sees. These are what the code is.
