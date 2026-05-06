---
layout: post
title: "Three Bugs Behind One Wrong Calorie Number"
date: 2026-05-05
description: "Three independent regressions in OpenNutriTracker converged on one wrong daily calorie number. Each was hard to spot alone. Diagnosis felt like peeling layers."
categories: [Open Source]
tags:
  - flutter
  - open-source
  - dart
  - debugging
  - mobile
---

It was late on a weekday evening when I first noticed that the daily calorie budget on the home screen was wrong, and it was wrong by an amount I could not in good conscience let go. The user I was testing with had entered her real height and weight, picked the activity level she actually does, and the home screen was telling her she could eat 2400 kcal a day, when the formula given her inputs should have produced something closer to 1900. Five hundred calories of error in either direction is the difference between losing weight and gaining it, which is to say the difference between the app helping her and the app quietly working against her, and I felt that gap with a particular sharpness. Whatever was producing that number, the app could not ship to anybody, even in a beta, without me first understanding exactly what it was doing and why.

The thing that made this particular wrong number more interesting than most, once I started peeling at it, was that it was not really one bug at all. It was three completely independent bugs, all converging on the same symptom, sitting in three different layers of the codebase, and none of them were obvious in isolation. The diagnosis ended up being the kind of long debugging session where you keep finding the cause and fixing it and watching the number stay wrong, and slowly realising, with a small sinking feeling each time, that there is another layer underneath the one you just patched. That feeling is unsettling in a particular way that I want to honour properly here, rather than rush past it on my way to the resolution.

## What I was actually trying to do

The work that surfaced all of this was adding non-binary gender support, an open issue on the project (#80) that had been sitting without a clear path forward. The app's TDEE calculation uses the IOM 2005 formulas, which come in male and female variants. To support a third option you have to make a decision about what those formulas mean for someone who isn't either of the two cases they're written for.

The decision I landed on was to compute both formulas and average them, with a hormone-profile picker that lets the user weight the average toward estrogen-typical, testosterone-typical, or genuinely averaged. This is defensible against the literature without forcing a binary on someone the literature didn't account for. I wrote the code, tested it on Linux desktop with my own profile, and the home screen showed the wrong number.

## Bug one: the onboarding race

The first thing I checked was whether the home screen was reading the user record correctly, and it turned out that it was reading something, just not the right something. The number it was reading was 80 kg, 180 cm, male, active, maintain, none of which matched anything I had just typed into the onboarding flow. Those values were the hardcoded fallback the app uses whenever `getUserData()` is called before any user has been saved, and the home screen had been handed them as though they were real.

The chain from the onboarding form down to Hive goes through five layers, with `OnboardingBloc.saveOnboardingData` calling `AddUserUsecase`, which calls `UserRepository`, which calls `UserDataSource`, which calls the underlying Hive box. Every single one of those layers was declared `async`, and every single one of them was returning to its caller before the layer below it had actually finished its work. The whole chain was, in effect, telling each caller that the work was done while the work was still happening underneath.

What was happening, more precisely, was that `Navigator.pushReplacementNamed` in `onboarding_screen.dart` fired the moment the bloc method returned, and the bloc method had returned because nothing inside its body was being awaited. The home screen mounted, queried `getUserData()`, found nothing in Hive yet, and was handed back the dummy fallback as a polite-looking substitute. The user's real data landed in Hive a moment later, but by then the home had already calculated TDEE against the dummy values and the screen had already been painted with the wrong number.

The fix is unsatisfyingly mechanical, in the sense that fixing it required only adding `await` at every layer of the chain, with six separate places needing the keyword. None of those six layers were doing anything wrong on their own; they simply were not sequenced into a single chain that resolved in the order it ought to have resolved. There is something quietly humbling about a five-layer bug whose fix is a six-character keyword, and I want to record that here.

The interesting part of this fix, when I sit with it now, is not the awaits themselves but what I did immediately after them, which was to delete the dummy fallback altogether. `UserDataSource.getUserData()` now throws `StateError` if the box is empty, rather than silently returning a body shape filled with hardcoded values. The reasoning is that any future code path that ends up calling `getUserData` before onboarding has finished is a real bug, not a graceful-degradation case, and the right thing to do with a real bug is to make it loud rather than quiet. Throwing makes the bug visible immediately, while returning a dummy hides it for as long as the dummy happens to round-trip cleanly through the rest of the app, which is exactly what had happened here.

A silent fallback is comfortable right up until the moment it is not, and removing it forces every caller to handle the actual condition the data layer is in, which is what every caller should have been doing all along. I felt a small loving relief when that change went in, the kind you feel when you tighten a part of a system that you knew, somewhere underneath the technical layer, was going to bite somebody eventually.

## Bug two: keying off `gender == male`

After the onboarding race was fixed, the home screen was finally reading the correct user record, and the number was still wrong, only differently wrong this time, with a smaller error margin of around 100 kcal rather than the original five hundred.

The TDEE calculation for the non-binary case averages two formulas. Each formula needs a Physical Activity factor (PA) corresponding to the user's PAL band and the formula gender. The function returning the PA constant looked like this:

```dart
double getPAValueFromPALValue(double palValue, UserGenderEntity gender) {
  if (gender == UserGenderEntity.male) {
    // male PA constants per band
  } else {
    // female PA constants per band
  }
}
```

That works for binary inputs. For the non-binary case, the calling code was running the male IOM formula and asking for a PA constant by passing `gender == male`, which evaluated to false because the user's gender was non-binary, which returned the female PA constant. The male half of the average was being computed with the wrong half's PA factor.

The bug was invisible at sedentary because the male and female PA constants are both 1.0 at PAL band 1.0 to 1.39. It was visible at every other PAL band because those constants diverge: 1.14 versus 1.12 at lowActive, 1.27 versus 1.25 at active, 1.45 versus 1.54 at veryActive. For a non-binary user at the veryActive PAL band, the average TDEE was being computed against 1.45 plus 1.54 instead of 1.27 plus 1.54, which is exactly the magnitude of the residual error I was seeing.

The fix added a new function, `getPAValueForFormula({palValue, isMaleFormula})`, that takes an explicit boolean flag rather than reading the user's gender. The call sites for the male and female formulas pass `true` and `false` respectively. The function can no longer be misled by what the user's gender happens to evaluate to. It's also a function that cannot be silently re-broken by adding a future fourth gender option, because the formula gender is now explicit at the call site rather than being inferred.

This is the same shape of fix as removing the dummy fallback, in that both replace an implicit-and-inferred default with an explicit decision the caller has to make at the point of the call. Implicit defaults are, in my experience, the most common mechanism by which silent bugs are kept silent in a codebase, and one of the things this whole exercise has reminded me of is how much quieter the code becomes when those defaults are made loud.

## Bug three: fire-and-forget

After both fixes, fresh onboarding produced the right number. The bug that still wasn't fixed was changing the hormone profile after onboarding. If you opened the calculations dialog or the profile page, picked a different hormone profile, and tapped save, the home kcal didn't update. If you killed the app and reopened it, the hormone profile sometimes reset back to what it had been.

`ProfileBloc.updateUser` was declared as returning `void`. Both call sites, in `calculations_dialog._openCaloriesProfileDialog` and `profile_page._showCaloriesProfileDialog`, were calling it and then immediately doing other work. The other work included triggering a recalculation of the home kcal against what the bloc thought the user looked like, which was the previous version because the new version hadn't reached Hive yet. And on the cold-restart case, the app sometimes shut down before the unawaited future had a chance to complete, which is why the hormone profile occasionally reset.

The fix is mechanical in the same way bug one was: change `updateUser` to return `Future<void>` rather than plain `void`, and `await` it at both of the call sites that previously fired and forgot. The shape of the underlying problem is identical to bug one, in that nothing was being awaited that needed to be, and the same small discipline of actually awaiting the thing the layer below was promising to do is what makes both fixes hold.

## The pattern across all three

What unsettles me about this triple, looking back at it now, is that every individual bug was reasonable in the context it had originally been written into. Returning a dummy when no user exists yet was a defensive choice meant to keep the app running through edge cases. Keying PA constants off the user's gender was an entirely natural shape for the binary case the formulas had been designed against. Declaring an update method as `void` matches a perfectly common Flutter pattern for fire-and-forget side effects, and the code that did it was following the same convention as half a dozen other update methods in the codebase. None of these patterns were obviously wrong at the moment they were written, and none of them had been a problem until non-binary support arrived and exercised every layer of the code in a way the binary case never had.

That is the part I most want to remember from this. Adding a feature that exercises a new code path does not introduce new bugs into a codebase, although it might look that way from the outside. What it actually does is expose the bugs that have been there all along, sitting quietly inside code that was never tested against the case the new feature represents. The features that the people who have been waiting longest for them finally get are very often the ones that pull at every loose thread the codebase had been hiding underneath itself.

The defensive thing the codebase wants from me now, in light of all of this, is fewer silent fallbacks across the board. The dummy is gone, the implicit gender check is gone, and the fire-and-forget update is gone, and none of them turned out to be load-bearing in any way that mattered when I removed them. What they were instead was a particular kind of comfort code, the sort that lets bugs stay invisible by paving over the conditions where they would otherwise show themselves, and removing that comfort code is the part of the fix that matters longer than the await statements ever will.

The new tests that landed alongside this fix pin numerical TDEE values for the non-binary case at every PAL band, so that if any of those numbers move in the future, we will know about it on the very next test run rather than learning it from somebody noticing the home screen telling her she can eat five hundred calories a day she actually cannot. The point of the tests is not really the specific numbers themselves; the point is that the next person whose calorie budget depends on this particular code path does not have to be the one who finds out it has drifted.

That is the version of care I most want to be writing into the codebase now, and the version of the codebase I most want to leave behind for whoever maintains it next. I am still thinking about how three bugs that were each individually reasonable could compound into one wrong number with such confidence, and I do not have a tidy answer for it, but I wanted to put the thinking down here while it was still fresh. If you have ever been the person who found a bug like this in something you depend on, in any system, I hope this post is the kind of thing that quietly says: somebody is paying attention, and the next time it happens, the test suite will catch it before you do.
