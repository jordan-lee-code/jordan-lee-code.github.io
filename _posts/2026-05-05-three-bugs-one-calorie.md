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

The daily calorie budget on the home screen was wrong.

Not by a small amount. The user I was testing with had entered her real height and weight, picked the activity level she actually does, and the home screen was telling her she could eat 2400 kcal a day. The formula, given her inputs, should have come out around 1900. Five hundred calories of error in either direction is the difference between losing weight and gaining it. Whatever was producing that number, the app couldn't ship to anyone without it being right.

The thing that made this particular wrong number more interesting than most is that it wasn't one bug. It was three completely independent bugs, all converging on the same symptom, in three different layers of the codebase. None of them were obvious in isolation. The diagnosis ended up being the kind of debugging session where you keep finding the cause, fixing it, watching the number stay wrong, and realising there's another layer underneath the one you just patched.

## What I was actually trying to do

The work that surfaced all of this was adding non-binary gender support, an open issue on the project (#80) that had been sitting without a clear path forward. The app's TDEE calculation uses the IOM 2005 formulas, which come in male and female variants. To support a third option you have to make a decision about what those formulas mean for someone who isn't either of the two cases they're written for.

The decision I landed on was to compute both formulas and average them, with a hormone-profile picker that lets the user weight the average toward estrogen-typical, testosterone-typical, or genuinely averaged. This is defensible against the literature without forcing a binary on someone the literature didn't account for. I wrote the code, tested it on Linux desktop with my own profile, and the home screen showed the wrong number.

## Bug one: the onboarding race

The first thing I checked was whether the home screen was reading the user record correctly. It was reading something. The number it was reading was 80 kg, 180 cm, male, active, maintain. None of those were what I'd just typed into the onboarding flow. They were the hardcoded fallback the app uses if `getUserData()` is called before any user has been saved.

The chain from the onboarding form to Hive goes through five layers. `OnboardingBloc.saveOnboardingData` calls `AddUserUsecase`, which calls `UserRepository`, which calls `UserDataSource`, which calls the underlying Hive box. Every single one of those layers was declared `async` and every single one of them was returning before the layer below it had finished. Nobody was actually awaiting anything.

What was happening was that `Navigator.pushReplacementNamed` in `onboarding_screen.dart` fired the moment the bloc method returned. The bloc method had returned because nothing in its body was being awaited. The home screen mounted, queried `getUserData()`, found nothing in Hive yet, and got back the dummy fallback. The user's real data landed in Hive a moment later, but by then the home had already calculated TDEE against the dummy and the screen had been painted.

The fix is unsatisfyingly mechanical. Add `await` at every layer of the chain. There were six places it had to go. None of them were doing anything wrong individually, they just weren't sequenced.

The interesting part of this fix isn't the awaits. It's what I did next, which was delete the dummy fallback. `UserDataSource.getUserData()` now throws `StateError` if the box is empty, rather than silently returning a body shape with hardcoded values. The reasoning is that any future code path that calls `getUserData` before onboarding has finished is a real bug, not a graceful-degradation case. Throwing makes the bug visible. Returning a dummy hides it for as long as the dummy happens to round-trip through the rest of the app cleanly, which is exactly what happened here.

A silent fallback is comfortable until it isn't. Removing it forces every caller to handle the actual condition the data layer is in, which is what they should have been doing anyway.

## Bug two: keying off `gender == male`

After the onboarding race was fixed, the home screen was reading the right user record. The number was still wrong, but differently wrong. Smaller error margin, around 100 kcal.

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

This is the same shape of fix as removing the dummy fallback. Both replace an implicit-and-inferred default with an explicit decision the caller has to make. Implicit defaults are how silent bugs are kept silent.

## Bug three: fire-and-forget

After both fixes, fresh onboarding produced the right number. The bug that still wasn't fixed was changing the hormone profile after onboarding. If you opened the calculations dialog or the profile page, picked a different hormone profile, and tapped save, the home kcal didn't update. If you killed the app and reopened it, the hormone profile sometimes reset back to what it had been.

`ProfileBloc.updateUser` was declared as returning `void`. Both call sites, in `calculations_dialog._openCaloriesProfileDialog` and `profile_page._showCaloriesProfileDialog`, were calling it and then immediately doing other work. The other work included triggering a recalculation of the home kcal against what the bloc thought the user looked like, which was the previous version because the new version hadn't reached Hive yet. And on the cold-restart case, the app sometimes shut down before the unawaited future had a chance to complete, which is why the hormone profile occasionally reset.

The fix is again mechanical: change `updateUser` to return `Future<void>`, and `await` it at both call sites. Same shape as bug one. Nothing was being awaited that needed to be.

## The pattern across all three

What unsettles me about this triple is that every individual bug was reasonable. Returning a dummy when no user exists was a defensive choice. Keying PA constants off the user's gender was natural for the binary case. Declaring an update method as `void` matches a perfectly common Flutter pattern for fire-and-forget side effects. None of them were obviously wrong when written. None of them had been a problem until non-binary support arrived and exercised every layer in a way the binary case never had.

That's the part I want to remember. Adding a feature that exercises a new code path doesn't introduce new bugs. It exposes the bugs that have been there the whole time, in code that was never tested against the case the feature represents. The features users have been waiting for are often the ones that pull at every loose thread the codebase has been hiding.

The defensive thing the codebase wants now is fewer silent fallbacks. The dummy is gone. The implicit gender check is gone. The fire-and-forget update is gone. None of them were load-bearing. They were the kind of comfort code that lets bugs stay invisible, and removing them is the part of the fix that matters longer than the await statements.

The new tests that landed alongside this fix pin numerical TDEE values for the non-binary case at every PAL band. If any of those numbers move, something in the formulation has drifted, and we'll know about it on the next test run rather than when a user notices the home screen telling her she can eat five hundred calories a day she actually can't.
