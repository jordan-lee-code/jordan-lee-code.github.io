---
layout: post
title: "When the Science is Binary and the Users Aren't"
date: 2026-05-06
description: "TDEE formulas come in male and female variants. The user base doesn't. What adding non-binary support to a nutrition app actually takes, beyond a third radio button."
categories: [Open Source]
tags:
  - flutter
  - open-source
  - inclusivity
  - design
  - mobile
---

OpenNutriTracker had an open issue called "add non-binary gender option" sitting on the tracker for a long time. Issue #80. The thread had some discussion, a few sketches of UI changes, and no clear path forward, because the actual problem isn't the UI. The actual problem is that every published TDEE formula in the literature comes in male and female variants. There is no third equation to point a third radio button at, and you can't ship the option until you've decided what the option means.

That decision turned out to be most of the work.

## What the formulas actually are

The IOM 2005 equations the app uses (and most calorie apps use, in some form) take a person's weight, height, age, and a Physical Activity factor, and return an estimate of total daily energy expenditure. There are two equations. One is fitted to data from male subjects; one is fitted to data from female subjects. The constants in each equation reflect the physiological averages of the population the equation was derived from. They are not interchangeable. You don't get sensible results by using the male equation with a smaller weight or vice versa.

The literature does not have a non-binary equation. There is research on the metabolic effects of hormone replacement therapy and on the way HRT shifts a person's basal rate over time, but nothing that produces a clean third formula a developer could implement. Which means the moment you add a third UI option, you are making an engineering decision the science hasn't made yet. You are deciding what the app does for the person who selects it.

The wrong way to handle this is to default the third option to the male formula and call it done. That treats non-binary as a polite synonym for "male, but with a different label." It is the path of least code, and it is unkind in a quiet way that would only be noticed by the people it was unkind to.

## The decision that landed

The shape that made it into the app is to compute both formulas and average them, with a hormone-profile picker that lets the user weight the average toward what feels right for their body. The picker offers three choices: estrogen-typical, testosterone-typical, and averaged. None of these claim to be a precise scientific answer. They are the closest a developer can get to the question of what a body actually does, given that the literature has only sampled two of the possibilities.

This is defensible as a design choice because it acknowledges what's actually true. The user knows more about their own body than the formulas do. Letting them weight the average gives them a steering wheel rather than handing them whichever side of the binary fits closest. It also means a user who starts on one profile and changes over time, for whatever reason, can adjust without their app forcing them back into a category they no longer fit.

I want to be honest about what this does and doesn't solve. It doesn't produce a new equation. It doesn't claim the averaged result is more accurate than either binary equation in isolation. What it does is hand the question back to the user, with the math behind it explicit and consistent, rather than picking one of the two existing equations and pretending the choice is invisible.

## What "treating it seriously" turned out to mean

The thing I didn't expect was how much of the work was downstream of the design decision. The PR that added the option was around 1000 lines. The PR that came right after it, fixing the three calorie miscalculation bugs that the new code path exposed, was 700 lines. The fix for those bugs is its own [post]({% post_url 2026-05-05-three-bugs-one-calorie %}), but the deeper observation is the one I want to leave here.

Features that exist for marginalised users tend to get the least-tested code paths. The non-binary case in this app exercised a code path nobody had run in years. The bugs it found weren't introduced by adding the feature; they had been latent for as long as the relevant code had existed. They just hadn't been triggered, because nobody had triggered them. Adding the feature was what surfaced them.

That pattern repeats across software. The right-to-left layout bug that was always there but only got reported when the Arabic localisation shipped. The colour contrast bug that was always there but only got reported when someone with low vision tried to use the dashboard. The features themselves are not what introduced the bugs. The features are what made the bugs visible.

If you take the underlying lesson seriously, the engineering shape of supporting marginalised users isn't just adding the feature. It's also building the test coverage and the failure-mode discipline that means the next bug along the same code path doesn't sit silently for years before someone notices. The PR that fixed the three calorie bugs added numerical regression tests pinning the non-binary TDEE result at every PAL band. If anything in the formulation drifts in the future, the test suite will fail in a way that names the problem clearly. That part of the work is the part that lasts.

## The implicit defaults that hide the bugs

The bugs the calorie work surfaced had a shape worth being explicit about. One was a fallback that returned a hardcoded male profile if no user had been saved yet, instead of throwing. One was a function that picked PA constants based on whether `gender == male`, which evaluated to false for non-binary users and silently routed them to the female constants for the male side of their averaged calculation. One was a fire-and-forget update method that had been there since before the hormone profile existed and didn't await its own write.

What ties them together is that each of them was a default. A default value if the data was missing. A default branch in an if-else. A default fire-and-forget pattern for state changes. None of them were wrong for the cases they were originally written for. They were wrong for the case they weren't written for, and they failed silently rather than visibly.

I think this is the part of inclusivity work that doesn't get discussed enough. The bugs aren't usually in the new feature. The bugs are in the implicit defaults of the existing code, which were correct for the existing users and silently incorrect for the new ones. Removing those defaults, or making them explicit at the call site rather than implicit in the structure, is the work that means future additions don't repeat the same shape.

## What I want to remember from this

The thing I keep returning to is how much of the inclusivity work was technical rather than political. There was no part of this where I had to argue for non-binary users being worth the effort. The argument was settled before I started. What was difficult was the engineering: the formulation, the hormone-profile semantics, the test coverage, the implicit defaults that needed to be made explicit, the silent fallbacks that needed to be made loud. None of that work makes a screenshot. None of it shows up in the demo. All of it is what the difference looks like between a feature that was added because the issue had been open too long, and a feature that was added because the engineering team decided to take the underlying users seriously.

Good design for marginalised users is not a different kind of design. It is design that doesn't take its defaults on faith. The work to support someone the system wasn't originally built for is, almost always, the work of finding what the system assumed and deciding whether the assumption still holds. Which is what good engineering should be doing anyway, for everyone.
