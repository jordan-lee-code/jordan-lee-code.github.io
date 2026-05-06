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

The premise of Flutter is that you write your app once and it runs on iOS and Android with the same code. That premise is mostly true. The part that gets quietly elided is "mostly," because the gap between mostly true and entirely true is where a steady stream of iOS-only work lives. None of it shows up on Linux. None of it shows up in unit tests. All of it has to happen for the app to actually function on the platform Apple cares about.

I don't have a Mac. I run Linux Mint and develop the Flutter app on that, which works for the bulk of the codebase. The iOS work, when it shows up, has to happen on a Mac, and it shows up more often than the Flutter marketing suggests. This week was a particularly concentrated example: four PRs, all iOS-only, all of which Linux couldn't have caught.

## UIScene migration, before Apple makes me

Apple is in the middle of making `UIScene` lifecycle support mandatory. Flutter has been emitting a build warning on every iOS build for a while:

> To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle support will soon be required.

That's the kind of warning you can ignore for a while and then suddenly can't, when Apple flips the switch in a future iOS release and the app refuses to launch at all. The cost of doing the migration on your own schedule is small. The cost of doing it under emergency pressure when users are reporting that the app won't open is enormous. It's the kind of work that is best done before it's urgent.

The migration itself, for this app, was unusually clean. OpenNutriTracker is a single-window app with no state restoration, no `UIApplicationShortcutItem`, no `NSUserActivity`, and no background URL session. The corner cases that make scene migrations painful didn't apply. What landed was a minimum-viable `SceneDelegate.swift` stub holding the window reference, a scene manifest in `Info.plist` pointing at the existing storyboard, and `UIApplicationSupportsMultipleScenes = false` so the single-window behaviour stays bit-for-bit identical. `AppDelegate.swift` is unchanged because plugin registration, the notification-centre delegate, and the iCloud-backup exclusion all still belong there.

The `Runner.xcodeproj/project.pbxproj` change is the one that requires a Mac. There's a Ruby gem, `xcodeproj`, that you can drive from the command line to add the new file reference, group entry, and Compile Sources phase entry. You can't sensibly hand-edit the pbxproj file because the format is finicky and Xcode rewrites it on next open anyway. You could in principle do this on Linux if you installed the gem there, but the verification step (build and run on a simulator) requires real Mac hardware regardless, so the practical workflow is to do it all in one go on the Mac.

## Localisation that iOS silently ignores

The app ships with eight locales: English, German, Czech, Italian, Polish, Turkish, Ukrainian, and Chinese. Or rather, it ships with eight locale string sets. Whether iOS lets the user select a particular locale from system settings depends on whether iOS recognises the locale code and whether the app declares it.

`Info.plist` has a key called `CFBundleLocalizations` which is the list of locales the app is telling iOS it supports. Until last week, that key contained `en` and `de`. The other six locales shipped strings, but iOS would not surface them in the language picker because they weren't in the bundle declaration. A Polish user could install the app and never know it had Polish; the system language picker for the app showed only English and German.

This is the kind of bug that's invisible on Linux and Android. Linux doesn't have a system-level language picker for individual apps. Android doesn't use `CFBundleLocalizations`. The string sets all worked correctly when the locale was forced through the app's own settings screen. The drift was specifically between the strings the app actually had and what iOS would let users select.

The fix added the missing six locales to `CFBundleLocalizations`. The accompanying drift test added in the same PR parses the ARB filenames and the Info.plist, and fails if a future locale gets added without updating both. Fail loudly at build time, not silently in production.

## A locale code iOS doesn't accept

The Czech locale was an additional layer of the same problem. The project shipped Czech under the locale code `cz`. The BCP-47 / ISO 639-1 standard code for Czech is `cs`. iOS uses the standard code and silently ignores anything that doesn't match. Czech users on iOS could not select Czech from system settings, even after `CFBundleLocalizations` was fixed, because the entry in there was `cz` and iOS's language picker was looking for `cs`.

The rename was straightforward in the file system: `intl_cz.arb` became `intl_cs.arb`, the generated message file followed, and every reference to the locale code in the codebase got updated. The interesting part of the PR is the user-data migration. Anyone who had already selected Czech in the app's own settings screen had `'cz'` stored in their Hive `ConfigBox`. Without a migration, those users would have silently fallen back to English on the next app launch because the code in the box didn't match any registered locale anymore.

The migration is a single-line read-time mapping in `ConfigDataSource.getSelectedLocale`: if the stored value is `'cz'`, return `'cs'`. The Hive value gets rewritten as `cs` the next time the user touches the language setting. No background migration, no migration runner, no version bump. The minimum change that gets every existing user to the new code without anyone losing their language preference, with the rewrite happening lazily as users naturally interact with the setting.

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

The honest framing of cross-platform Flutter is that you write the bulk of the app once and pay a steady tax in platform-specific work for the parts that touch the OS underneath. The framework can't abstract over `UIScene`. It can't abstract over `CFBundleLocalizations`. It can't abstract over BCP-47 versus the standard the app happened to ship with originally. It can't abstract over the iOS notification centre's specific contract. All of those have to be done correctly on iOS, by someone with iOS access, regardless of how clean the Dart code is.

The bulk of the app is genuinely shared, which is the part of the cross-platform promise that holds. The OS-adjacent layer is platform-specific work that has to happen on platform-specific hardware, by someone willing to read platform-specific documentation, with platform-specific verification. The size of that layer isn't huge, but it's nonzero, and pretending it's zero is how you end up with iOS users who can't select Czech from system settings even though the strings shipped two years ago.

I think the trick is to schedule the platform-specific work deliberately rather than waiting for a user to file a bug. Once a quarter, take a Mac for a day, work through the warnings the build is emitting, do the deferred migrations before they become emergencies, audit the locale and notification configurations against what the app actually claims to do. None of that is complex work in isolation. It's just work that nobody does until they're forced to, and the cost of being forced to is always higher than the cost of doing it on your own schedule.
