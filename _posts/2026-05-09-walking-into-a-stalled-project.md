---
layout: post
title: "Walking Into Someone Else's Stalled Project"
date: 2026-05-09
description: "Coming into a stalled open source project means doing the unglamorous foundation work before the visible work makes sense. Texture from a week of getting flow back."
categories: [Open Source]
tags:
  - open-source
  - maintainer
  - flutter
  - process
---

The repo had been quiet for months. Not abandoned, not officially. The maintainer was around. Some issues were getting triaged. New community PRs were arriving. None of them were getting reviewed or merged. The most recent merged PR I could find on the day I started was a small fix from earlier in the year. The contributor PRs that had landed in the queue since then were sitting open with a few sympathetic comments and no apparent path to landing.

This is a recognisable shape. Not failure, not abandonment, just the slow drift that happens when the original maintainer is dealing with the rest of their life and the project that started as a side hobby has accumulated more user demand than the side-hobby budget can absorb. There is nothing wrong with this. It is the natural lifecycle of an open source project that is doing well enough to attract contributions but isn't anyone's full-time work.

What I want to write about is what it actually felt like to walk into that, with the goal of getting things flowing again, and what the work turned out to be in practice. Almost none of it was the satisfying feature work that makes screenshots. Most of it was the kind of foundation work that nobody talks about, because it's the work that makes everyone else's work possible.

## The first week was almost entirely scaffolding

Before any of the user-facing features in the queue could land safely, I had to do work the queue itself didn't represent. The first commit I made on the project was a `CLAUDE.md` documenting the codebase architecture for AI-assisted contributors, plus an updated `GettingStarted.md` covering FVM (the Flutter version manager the project actually used, which wasn't documented anywhere). I wrote it for me first. Reading my way into someone else's codebase is faster when I'm forced to write down what I've learned, and the artefact left behind is usable by every contributor that follows.

Then came the regression-test pack. The test suite when I arrived had 135 tests, mostly covering older parts of the codebase. The features that had landed in the previous few months were almost entirely untested. Before I started landing more features, I added 119 new tests covering the existing-but-untested code paths. That sounds defensive and it is. The reason is that I was about to start merging community PRs at speed, and I wanted a regression net underneath the existing behaviour before I started adding things that might collide with it. New behaviour can be tested by its own author. Pre-existing behaviour without coverage is the silent risk in any feature merge, because the merge might break it and nobody would notice.

The third piece was establishing a release flow. The project nominally had a `develop` branch and a `main` branch but the boundary between them had blurred. Some PRs targeted `develop`, some targeted `main`, some looked like they'd been merged into both. The flow we settled on was that everything goes to `develop`, then a periodic `develop → main` PR cuts a release once the develop branch is in good shape. Simple, common, and uncontroversial. The point of writing it down was not the novelty. The point was making it explicit so that contributors who showed up after me could find the answer to "where does my PR go" without having to guess from the recent commit graph.

That set of three pieces (architecture docs, regression tests, release flow) took most of the first day or two. It produced no new features. It changed nothing a user could see. It was the work that made everything after it possible.

## Reading other people's PRs in good faith

The largest single thing I shipped early in the week was a port of seven features that had been sitting in a contributor's fork. Erik (different Erik) had built a bundle of small useful improvements: a quick-weight widget on the home screen, a weekly weight rate goal, a 2024 update to the activity compendium, an extended diary calendar range, direct text input alongside sliders in calculations, a fix for some broken nutrient label concatenation, and daily meal reminder notifications. The bundle sat in his fork at parity with our codebase from a few months earlier. To land it, the work was rebasing all seven features onto our current `develop`, resolving conflicts that had accumulated during the months our codebase had moved on, fixing things the conflicts produced, and verifying behaviour on each feature individually before merging the lot.

This is the kind of work that's hard to describe as productive without context. There's no new code being designed. The features were already designed and implemented by someone else. The work is the patience of going through someone else's commits one at a time, understanding what each was for, deciding whether anything in it conflicted with the current codebase or other features in the bundle, and producing a single coherent landing. That work is genuinely valuable and it's also genuinely thankless, in the sense that the visible artefact is just the merged PR, not the seven hours of careful reading underneath it.

What I want to say about it is that reading other people's PRs in good faith is its own skill. The instinct, when you're a maintainer with limited time, is to read someone else's contribution looking for reasons not to land it. That's how queues stall. The reasons not to land things accumulate, the threshold for merging keeps rising, and after enough months the contributor stops opening PRs because they've stopped getting merged. The way out of that pattern is to read PRs looking for what's right about them, then dealing with the things that need fixing as fixable problems rather than blockers. Most contributor PRs are workable if you put the work in. The work is not nothing. But it's almost always less than the cost of the queue stalling further.

## The CONTRIBUTING file that came late

After about five days of merging, an issue came through where a first-time contributor had opened their PR against `main` instead of `develop`, because nothing on the repo told them which one to use. We rebased and merged it, but it surfaced something I should have done earlier: write down the contribution rules for newcomers, in a place GitHub would surface to them.

`CONTRIBUTING.md` landed two days before this post is dated. It covers the develop-branch policy, the localisation workflow (the project has eight locales and adding a new user-facing string is a sixteen-file change before the build will pass), and pointers to the existing material on environment setup and codegen commands. It's short on purpose. The things a typical contributor will care about (where does my PR go, what do I need to update for a new string, how do I run the tests) are the first things you see. The things a contributor only cares about if they're touching deeper internals (DI registration order, Hive type IDs, BLoC layout) stay in `CLAUDE.md`.

The honest reflection here is that I should have written `CONTRIBUTING.md` on day one. Not because there was a queue of contributors waiting for it, but because the act of writing it would have surfaced the conventions I was implicitly assuming and forced me to check whether they were actually correct. Writing things down for newcomers is one of the cleanest ways to find out which of your own assumptions don't survive contact with someone who doesn't already know.

## The CI changes that mattered most

The most visible CI change was wiring up PR validation properly. When I arrived, the workflow was running on `push` to `develop` and `main` but not on `pull_request`, which meant a PR's validation was, in effect, "did the author run the tests locally before opening." Real PR validation across linux checks, Android build, iOS build, and an iOS integration test landed across a few PRs over the week.

The CI change that mattered most was smaller and stranger. Once PR validation was firing on `pull_request`, every push to `develop` while a `develop → main` release PR was open started firing both the `pull_request` synchronize event and the `push` event for the same SHA, doubling every job in the checks list. The fix was three lines in the trigger matrix: drop `develop` from the `push` triggers, since pre-merge validation was now covered by `pull_request` for every flow. Direct pushes to `develop` are forbidden by project policy anyway, so the lost trigger was moot.

What that change actually did, beyond stopping duplicate runs, was change the feel of the repo. CI runs that finish in half the time make every other piece of work feel less heavy. The reviewer doesn't wait as long. The contributor sees feedback faster. The maintainer doesn't have to mentally filter out the duplicate red ticks when scanning checks pages. Three lines of YAML, real change in how the project felt to work in.

## What I learned about taking on someone else's project

The thing I keep returning to is how much of the work was building scaffolding for the work, rather than the work itself. The architecture documentation, the regression tests, the release flow, the CONTRIBUTING file, the CI fixes. None of that is feature work. All of it is what makes feature work go fast without breaking things. A project that's been quiet for months has accumulated a lot of accumulated mismatches in its scaffolding, and the temptation when you arrive is to jump straight to merging the visible queue. That instinct produces short-term throughput at the cost of medium-term breakage. The slower start, where you fix the scaffolding first, pays for itself within the first week.

The other thing I want to be honest about is the emotional texture. There is a particular feeling to opening a project you didn't write, reading someone else's code carefully, and trying to leave it better than you found it. It's not unlike being a guest in someone's house. You want to be useful but you also don't want to rearrange their kitchen without asking. The original maintainer is still the original maintainer. They built the project. The shape of it is theirs. The work I was doing was at the maintainer's invitation, and the question of how much to change versus how much to leave alone is a question I came back to more than once.

What I tried to do, and I think mostly succeeded at, is to leave the existing patterns in place wherever I could and add new patterns only where they were genuinely needed. The DI structure stayed the same. The bloc layout stayed the same. The codebase shape stayed the same. New features composed the existing primitives rather than introducing new abstractions. The tests follow the patterns the existing tests followed. The aesthetic of the project, such as it is, isn't disturbed.

That's the part I think matters when you walk into someone else's house. You can fix the loose floorboards and patch the roof and replant the garden. What you don't get to do is rearrange the furniture. The original character of the place is what people came for in the first place.

## Where it is now

The queue is empty. The contributor PRs that had been waiting are merged. The release flow works. CI is fast. The regression test pack is in place. The next time someone opens a PR, the path for it to land is short. The next time the original maintainer comes back to the project, the project they come back to should look like it's been looked after, not like it's been remodelled.

That feels like the right outcome. The work to get there was not glamorous. Most of it was reading and writing and waiting for builds to finish. The thing that strikes me about it, looking back, is how much of it was the same work over and over: read the code, write down what you found, run the tests, merge the PR, repeat. There was no single decision worth a war story. There was a week of small careful decisions that compounded into a project that's working again.

I think that's what most maintainer work actually is. Not heroics, not big reorganisations, not the kind of thing that makes a conference talk. Just the patient accumulation of small decisions made carefully, over and over, until the project starts moving on its own again. The work I did this week on someone else's stalled project wasn't different in kind from the work I do on infrastructure at my day job. It's the same instinct: notice what's broken, fix the smallest thing first, keep the existing tenants happy, leave a path for whoever comes next.

That's enough to be doing. It's also more than I think most people give themselves credit for, when the work doesn't make screenshots and nobody is paying particular attention.
