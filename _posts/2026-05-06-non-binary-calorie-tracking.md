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

OpenNutriTracker had an open issue called "add non-binary gender option" sitting on the tracker for a long time, filed as issue #80, with some discussion across the thread, a few sketches of UI changes, and no clear path forward toward actually landing it. I read through the thread one quiet weekend morning, with my tea going cold next to me, before I started any of the work, because I wanted to feel out the shape of what people had already tried and what was still in the way. The reason the path was unclear, when I sat with it, is that the real problem with this feature was never the UI in the first place. The real problem is that every published TDEE formula in the literature comes in male and female variants only, with no third equation a developer could point a third radio button at, which means you cannot ship the option to your users until you have first sat down and decided carefully what the option is going to mean for the people who select it.

That decision, as it turned out, was where almost all of the work of the feature actually lived. I am still surprised, looking back, by how much of a feature can hide inside what looks like a single design choice on the page.

## What the formulas actually are

The IOM 2005 equations the app uses (and most calorie apps use, in some form) take a person's weight, height, age, and a Physical Activity factor, and return an estimate of total daily energy expenditure. There are two equations. One is fitted to data from male subjects; one is fitted to data from female subjects. The constants in each equation reflect the physiological averages of the population the equation was derived from. They are not interchangeable. You don't get sensible results by using the male equation with a smaller weight or vice versa.

The literature does not have a non-binary equation. There is research on the metabolic effects of hormone replacement therapy and on the way HRT shifts a person's basal rate over time, but nothing that produces a clean third formula a developer could implement. Which means the moment you add a third UI option, you are making an engineering decision the science hasn't made yet. You are deciding what the app does for the person who selects it.

The wrong way to handle this, the way I want to name plainly because I think it matters that we name it plainly, is to default the third option to the male formula and call it done. That treats non-binary as a polite synonym for "male, but with a different label." It is the path of least code, and it is unkind in a quiet way that would only ever be noticed by the people it was unkind to, which is exactly the shape of the harm I most want this app to avoid.

## The decision that landed

The shape that made it into the app is to compute both formulas and average them, with a hormone-profile picker that lets the user weight the average toward what feels right for their body. The picker offers three choices: estrogen-typical, testosterone-typical, and averaged. None of these claim to be a precise scientific answer. They are the closest a developer can get to the question of what a body actually does, given that the literature has only sampled two of the possibilities.

This is defensible as a design choice because it acknowledges what's actually true. The person using the app knows more about their own body than the formulas do. Letting them weight the average gives them a steering wheel rather than handing them whichever side of the binary fits closest. It also means somebody who starts on one profile and changes over time, for whatever reason, can adjust without their app forcing them back into a category they no longer fit.

I want to be honest about what this does and doesn't solve. It doesn't produce a new equation. It doesn't claim the averaged result is more accurate than either binary equation in isolation. What it does is hand the question back to the person it actually concerns, with the math behind it explicit and consistent, rather than picking one of the two existing equations and pretending the choice is invisible.

## What "treating it seriously" turned out to mean

The thing I didn't expect was how much of the work was downstream of the design decision. The PR that added the option was around 1000 lines. The PR that came right after it, fixing the three calorie miscalculation bugs that the new code path exposed, was 700 lines. The fix for those bugs is its own [post]({% post_url 2026-05-05-three-bugs-one-calorie %}), but the deeper observation is the one I want to leave here.

Features that exist for marginalised users tend to get the least-tested code paths. The non-binary case in this app exercised a code path nobody had run in years. The bugs it found weren't introduced by adding the feature; they had been latent for as long as the relevant code had existed. They just hadn't been triggered, because nobody had triggered them. Adding the feature was what surfaced them.

That pattern repeats itself across software in shapes that anyone who has been doing this work for any length of time will recognise. The right-to-left layout bug that was always there in the codebase, but only got reported the day the Arabic localisation finally shipped. The colour contrast bug that had been sitting in the dashboard for years, but only got reported when someone with low vision tried to actually use it. The features themselves are not what introduces those bugs into the codebase; what the features do is make the bugs visible to the people who would otherwise have stayed quietly excluded by them.

If you take the underlying lesson seriously, the engineering shape of supporting marginalised users involves a great deal more than just adding the feature. It also involves building the test coverage and the failure-mode discipline that means the next bug along the same code path does not sit silently in the codebase for years before somebody notices it. The PR that fixed the three calorie bugs added numerical regression tests pinning the non-binary TDEE result at every PAL band, so that if anything in the formulation drifts in the future, the test suite will fail in a way that names the problem clearly rather than letting the wrong number reach a person's home screen. That part of the work, the slow careful test-writing part, is the part that goes on protecting people long after the original feature has stopped being the most recent thing anyone touched.

## The implicit defaults that hide the bugs

The bugs the calorie work surfaced had a shape worth being explicit about, because the shape is what tells you where to look the next time. The first was a fallback that returned a hardcoded male profile whenever no user had been saved yet, rather than throwing the error that would have made the missing-user state impossible to ignore. The second was a function that picked PA constants based on whether `gender == male`, which evaluated to false for non-binary users and silently routed them to the female constants for the male side of their averaged calculation, so that the wrong half of the average was being computed against the wrong constant. The third was a fire-and-forget update method that had been there in the codebase since long before the hormone profile feature existed and never bothered to await its own write into Hive.

What ties all three together is that each of them was, in its own way, a default that the surrounding code relied on without ever stating that it was relying on it. A default value when the data was missing. A default branch in an if-else that simply happened to be the female branch. A default fire-and-forget pattern for state changes that worked for everything else the codebase had ever needed to do. None of those defaults were wrong for the cases they had originally been written for; they were wrong for the case they had never been written for, and the deeper problem was that they failed silently rather than visibly when that case finally turned up.

This is the part of inclusivity work that I think does not get discussed nearly enough, because it is less rhetorically satisfying than the design conversation. The bugs are almost never inside the new feature itself. The bugs are inside the implicit defaults of the existing code, the ones that were correct for the existing users and silently incorrect for the new ones. The work of removing those defaults, or of making them explicit at the call site rather than leaving them implicit in the structure, is the work that means the next addition along the same code path does not repeat the same painful shape.

## What I want to remember from this

The thing I keep returning to, when I look back at the whole arc of this work, is how much of the inclusivity piece turned out to be technical rather than political. There was no point in this process where I had to argue for non-binary users being worth the effort the feature would cost; the argument was settled before I started, and the people around me had already made their peace with it. What was actually difficult was the engineering of the thing, in all the unglamorous places where engineering tends to be difficult: the formulation of the third option, the semantics of the hormone-profile picker, the test coverage for the new code paths, the implicit defaults that needed to be made explicit, the silent fallbacks that needed to be made loud. None of that work makes a good screenshot, and none of it shows up in the demo, and all of it is what the difference actually looks like between a feature that gets added because the issue had been open too long, and a feature that gets added because the engineering team decided to take the underlying users seriously.

Good design for marginalised users is not a different kind of design from good design generally; it is simply design that does not take its defaults on faith and does not assume the system as written already accommodates everyone it ought to. The work of supporting someone the system was not originally built for is, almost always, the patient work of finding what the system has been quietly assuming and then deciding, slowly and on the merits, whether that assumption still holds. Which is, in the end, what I want good engineering to be doing for everyone, all the time, and not only when somebody finally has to ask.

I am still thinking about what this work meant, and I do not have a tidy summary of it yet, but I wanted to put what I have here. If you are someone who has ever opened an app, found yourself missing from its options, and quietly closed it again, I see you, and I hope the small care that went into this feature reaches you in some form, in this app or another, on the evening you most need it to.
