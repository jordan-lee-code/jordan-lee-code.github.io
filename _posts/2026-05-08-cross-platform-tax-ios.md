---
layout: post
title: "The iOS Tax of a Cross-Platform Flutter App"
date: 2026-05-08
description: "Flutter promises platform parity. The reality is iOS-only work Linux can't compile, let alone catch. Four PRs from a weekend of platform-specific yak-shaving."
categories: [Open Source]
tags:
  - flutter
  - ios
  - open-source
  - mobile
  - cross-platform
---

The premise of Flutter is that you write your app once and it runs on iOS and Android from the same codebase, and that premise is mostly true in a way I want to give credit to before complicating it. The part of the framing that gets quietly elided is the word "mostly", because the gap between mostly true and entirely true is exactly where a steady stream of iOS-only work lives, and almost none of that work shows up on Linux or in the unit test suite, even though all of it has to happen for the app to actually function on the platform Apple cares about.

I do not have a Mac of my own. I run Linux Mint and develop the Flutter side of the app on that, which works perfectly well for the bulk of the codebase day to day. The iOS work, on the rare weeks when it shows up, has to happen on a Mac somewhere, and it shows up rather more often than the Flutter marketing tends to suggest. This week was a particularly concentrated example of that pattern: I rented a Mac mini for the day from Scaleway, sat at my own desk in front of a borrowed terminal, and worked through four PRs in close sequence, all of them iOS-only, all of them invisible to anything Linux could have built or tested. I felt a quiet kind of protectiveness toward the users I was unblocking by the end of the day, even though most of them will never know any of this happened.

## UIScene migration, before Apple makes me

Apple is in the middle of making `UIScene` lifecycle support mandatory. Flutter has been emitting a build warning on every iOS build for a while:

> To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle support will soon be required.

That is the kind of warning you can comfortably ignore for a while and then suddenly cannot ignore at all, the moment Apple flips the switch in a future iOS release and the app refuses to launch for anyone. The cost of doing the migration on your own schedule, when nothing is yet on fire, is small and entirely manageable. The cost of doing it under emergency pressure, with users actively reporting that the app will not open and the maintainer scrambling to verify the fix on hardware they may not own, is enormous in comparison. It is the kind of work that is best done long before it becomes urgent, while there is still room to take it slowly and verify each step properly.

The migration itself, for this app, was unusually clean. OpenNutriTracker is a single-window app with no state restoration, no `UIApplicationShortcutItem`, no `NSUserActivity`, and no background URL session. The corner cases that make scene migrations painful didn't apply. What landed was a minimum-viable `SceneDelegate.swift` stub holding the window reference, a scene manifest in `Info.plist` pointing at the existing storyboard, and `UIApplicationSupportsMultipleScenes = false` so the single-window behaviour stays bit-for-bit identical. `AppDelegate.swift` is unchanged because plugin registration, the notification-centre delegate, and the iCloud-backup exclusion all still belong there.

The `Runner.xcodeproj/project.pbxproj` change is the one that requires a Mac. There's a Ruby gem, `xcodeproj`, that you can drive from the command line to add the new file reference, group entry, and Compile Sources phase entry. You can't sensibly hand-edit the pbxproj file because the format is finicky and Xcode rewrites it on next open anyway. You could in principle do this on Linux if you installed the gem there, but the verification step (build and run on a simulator) requires real Mac hardware regardless, so the practical workflow is to do it all in one go on the Mac.

## Localisation that iOS silently ignores

The app ships with eight locales: English, German, Czech, Italian, Polish, Turkish, Ukrainian, and Chinese. Or rather, it ships with eight locale string sets. Whether iOS lets the user select a particular locale from system settings depends on whether iOS recognises the locale code and whether the app declares it.

`Info.plist` has a key called `CFBundleLocalizations` which is the list of locales the app is telling iOS it supports. Until last week, that key contained `en` and `de`. The other six locales shipped strings, but iOS would not surface them in the language picker because they weren't in the bundle declaration. A Polish speaker could install the app, look at the language picker, and reasonably conclude the app didn't have Polish. The strings were sitting right there on her phone, two taps away, and the OS was silently refusing to let her find them.

This is the kind of bug that's invisible on Linux and Android. Linux doesn't have a system-level language picker for individual apps. Android doesn't use `CFBundleLocalizations`. The string sets all worked correctly when the locale was forced through the app's own settings screen. The drift was specifically between the strings the app actually had and what iOS would let users select.

The fix added the missing six locales to `CFBundleLocalizations`. The accompanying drift test added in the same PR parses the ARB filenames and the Info.plist, and fails if a future locale gets added without updating both. Fail loudly at build time, not silently in production.

## A locale code iOS doesn't accept

The Czech locale was an additional layer of the same problem. The project shipped Czech under the locale code `cz`. The BCP-47 / ISO 639-1 standard code for Czech is `cs`. iOS uses the standard code and silently ignores anything that doesn't match. Czech users on iOS could not select Czech from system settings, even after `CFBundleLocalizations` was fixed, because the entry in there was `cz` and iOS's language picker was looking for `cs`.

The rename was straightforward in the file system: `intl_cz.arb` became `intl_cs.arb`, the generated message file followed, and every reference to the locale code in the codebase got updated. The interesting part of the PR is the user-data migration. Anyone who had already selected Czech in the app's own settings screen had `'cz'` stored in their Hive `ConfigBox`. Without a migration, those users would have silently fallen back to English on the next app launch because the code in the box didn't match any registered locale anymore.

The migration itself is a single-line read-time mapping inside `ConfigDataSource.getSelectedLocale`, so that if the stored value happens to be `'cz'` the function returns `'cs'` instead. The Hive value gets rewritten as `cs` the next time the user touches the language setting, which means no background migration runs, no migration runner needs to exist anywhere in the codebase, and no version bump on the data is required. I love when a migration can be this small and this kind to its existing users at once. It is the smallest possible change that gets every existing user to the new code without any of them losing the language preference they had carefully set, with the rewrite happening lazily as users naturally interact with the setting on their own time, and there is something quietly tender about a migration that simply waits for you to come back and meets you where you already are.

## Notifications that need an iOS-specific delegate

The notification reminder feature uses `flutter_local_notifications` on both platforms. On Android it works out of the box. On iOS, since iOS 10, it requires that the app explicitly registers itself as the delegate for `UNUserNotificationCenter` so the system knows to surface notifications when the app is in the foreground. Without that registration, the daily reminder fires correctly but only displays when the app is backgrounded. Foreground notifications are silently dropped.

The fix is one line and one import in `AppDelegate.swift`. It's also the kind of thing the docs for `flutter_local_notifications` mention buried in a section about iOS-specific setup, which is exactly the kind of thing that gets missed when you're writing the original integration on a Linux machine without an easy way to verify behaviour on iOS hardware.

## The thing that stops this happening again

The above fixes were all caught during a regression-test sweep, which is to say they were caught manually by reading code carefully on a Mac and comparing it to platform documentation. That's not a process that scales or repeats reliably, and the bugs that this approach catches are the bugs the reviewer happened to think to check for.

The structural fix is having an integration test that boots the app on a real iOS simulator and verifies that everything initialises cleanly. The project didn't have one. The 254-test suite was all unit and widget level, none of which exercises the iOS-specific surface that the bugs above were hiding in. A failing locator registration order, a colliding Hive `typeId`, a missing platform plugin initialisation, a permission flow that crashes when denied, anything in the iOS-specific `main.dart` boot sequence: none of those would have been caught by the existing tests.

The integration test that landed is deliberately minimal. It calls `app.main()` via `IntegrationTestWidgetsFlutterBinding`, captures `FlutterError.onError` into a list, verifies `MaterialApp` is on screen after `pumpAndSettle`, and verifies no errors fired during boot. That's the whole test. It doesn't try to drive the keyboard or pickers, because driving inputs needs platform-specific code that's out of scope for a basic boot-smoke. Future tests can layer on top.

The CI job that runs it is the part that actually pays for itself. It runs on `macos-latest` after the Linux checks pass, picks any available iPhone simulator (model-agnostic so a new iOS release doesn't break the pin), and uses the same stub `.env` approach as the other jobs. End-to-end the test takes about two minutes: 84 seconds for the Xcode build, 30 seconds for the app boot, then the assertion. Verified on a real Mac mini at Scaleway running macOS 26.3.2 and Xcode 26.

That two minutes catches a class of regressions that the rest of the test suite cannot. It's not comprehensive coverage; it's a smoke test, and a smoke test is exactly what the iOS-specific surface needed.

## What the cross-platform promise actually buys you

The honest framing of cross-platform Flutter, after a week like this one, is that you write the bulk of the app once and then pay a steady tax in platform-specific work for the small parts that touch the OS underneath the framework. The framework cannot really abstract over `UIScene`, or over `CFBundleLocalizations`, or over BCP-47 versus the locale codes the app happened to ship with originally, or over the specific contract that the iOS notification centre expects of any app that wants to surface foreground notifications. All of those things have to be done correctly on iOS, by someone with iOS access and the patience to verify behaviour on real Apple hardware, regardless of how clean and well-organised the Dart code happens to be.

The bulk of the app is genuinely shared between the two platforms, which is the part of the cross-platform promise that does in fact hold up to honest scrutiny. The OS-adjacent layer is the part where platform-specific work still has to happen on platform-specific hardware, by someone willing to read platform-specific documentation carefully, with verification that only platform-specific tooling can give you. The size of that layer is not enormous, but it is nonzero, and pretending it is zero is how you end up with Czech speakers on iPhones who cannot select Czech from system settings, two years after the Czech strings actually shipped, while the maintainer has no idea any of them are silently locked out of the language they wanted to use.

I think the trick to surviving this honestly is to schedule the platform-specific work deliberately, rather than waiting passively for somebody to file a bug about it. Once a quarter, take a Mac for a day, work through the warnings the build has been emitting, do the deferred migrations before they harden into emergencies, and audit the locale and notification configurations carefully against what the app actually claims to support. None of that work is complex in isolation; it is simply the kind of work that nobody does until something forces them to do it, and the cost of being forced is always higher than the cost of doing it on your own schedule.

The people on the receiving end of any deferral, the ones the missing locale or the silently dropped notification actually lands on, are the same people who are least likely to file a bug about any of it. They are the people who will quietly conclude that the app does not work for them, and they will stop trying without ever telling you why. If you are reading this, and you have ever opened an app and quietly given up on it because some small thing was not there for you, I am sorry. I am still thinking about how often that happens to people who never make a sound about it, and how much of good engineering is, in the end, the work of noticing them anyway.
