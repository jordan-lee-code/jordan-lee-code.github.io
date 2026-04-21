---
layout: post
title: "AI in the Engineering Workflow: Augmentation vs Replacement"
date: 2026-04-20
categories: [DevOps, AI]
tags:
  - ai
  - devops
  - claude-code
  - claude
  - devin
  - tooling
  - productivity
---

There's been a lot of noise about AI in software engineering over the last couple of years, and most of it sits at one of two extremes. Either AI is a glorified autocomplete that occasionally saves you a Google search, or it's about to replace your entire engineering team. Neither is accurate, and the reality of integrating these tools into a real workflow is more interesting and more frustrating than either camp tends to admit.

I've been using AI tooling seriously for a while now: Claude Code daily, Devin for specific experiments, GitHub Copilot running quietly in the background. What follows is what I've genuinely found, working through it rather than watching from a distance.

## The replacement framing is the wrong one

Tools like Devin are marketed, more or less explicitly, as autonomous engineering agents. You hand them a task, they go off and do it. The pitch is that you can replace junior engineers, or at least dramatically reduce the need for them.

I understand why that framing exists. It's a compelling sales narrative. But it fundamentally misunderstands what junior engineers actually do on a team, and it underestimates how much invisible context is required to make good engineering decisions.

A junior engineer isn't just someone who writes code. They ask questions when something feels off. They push back when a task doesn't make sense. They learn the codebase and accumulate institutional knowledge.

An autonomous agent handed a ticket doesn't know that the naming convention in that repo is intentionally inconsistent for a historical reason, or that the team is mid-migration and the "right" approach today would break everything in two weeks. It just does what it's told, with confidence.

I've watched Devin produce technically correct work that was completely wrong for the context. It's impressive and genuinely useful for isolated, well-defined tasks. For anything that requires judgment, it struggles.

## Where Claude Code is different

{% include embed/youtube.html id='LACyqdAfnaw' %}

The video above covers the developer sentiment around Claude Code in some depth and is worth watching in full. The short version of its conclusions: there's no secret in the implementation, just a capable model given sensible scaffolding to operate in a real environment. The terminal form factor sits usefully between IDE tools where you watch every edit and no-code tools where you're not meant to look at the code at all. And the benchmark scores that look damning largely reflect the fact that Claude Code isn't optimised for benchmark tasks, which isn't the same thing as it not working well.

Those conclusions track with my experience. What actually matters is what it does in practice, and that's harder to capture in a leaderboard position.

The most useful thing it does for me is help structure complex, multi-step work before I write a single line. When I'm looking at a change that needs to touch fifteen modules across a shared Terraform library and cascade through dependent product repos, the failure mode isn't "I don't know how to write the Terraform". It's "I haven't fully mapped the blast radius of this change before I start." Claude Code is very good at that mapping. Feed it the relevant context, ask it to reason through the dependencies, and you get a structured plan you can actually pick apart and sanity-check before committing to it.

The subagent model is particularly useful here. I can delegate parallel research across multiple repos while keeping a coherent thread of intent. It's the difference between trying to hold fifteen browser tabs in your head and having a collaborator who can say "here's what I found in each of those, here's where they conflict."

It also stays honest about uncertainty. When it doesn't know something, it says so rather than confidently hallucinating an answer. That might sound like a low bar, but it's actually critical for trusting any tool in a production engineering context. The [Bullshit Benchmark](https://petergpt.github.io/bullshit-benchmark/viewer/index.v2.html) tests exactly this: how well models detect and push back on false or misleading information rather than just going along with it. The top 13 spots are almost entirely Claude models. Claude Sonnet 4.6 scores 91% on clear pushback, Opus 4.5 scores 90%, and the only non-Claude model in the top 13 is Qwen3.5 397b in 9th. That tracks with my day-to-day experience. The willingness to say "that's not right" is as important as the ability to produce good output.

## The real difficulty of integration

The harder problem isn't choosing between tools. It's changing how you work in the first place.

AI tooling is only useful if you invest in feeding it the right context. That means writing better task definitions, being more explicit about constraints and intent, and building the habit of thinking out loud in a way the tool can engage with. None of that comes naturally, and there's a period (weeks, maybe longer) where using AI tooling actively slows you down because you're learning how to work with it rather than just doing the work.

There's also a calibration problem that catches most people. The temptation is to trust the output too much early on, then swing hard the other way after the first genuinely bad result and barely use the thing at all. I've done both. The relationship that actually works sits somewhere in the middle: a capable but context-limited collaborator whose work you always review, not an oracle and not a toy.

The rate limit complaints the video mentions are real. The rolling 5-hour window, the weekly cap, the peak and off-peak tiers — genuinely complicated to navigate. But the telling thing is that almost nobody frustrated with the limits is suggesting switching tools. The conversation is about upgrading plans, not leaving, and that's a more honest signal of how much people value it once they've cleared the learning curve than any benchmark score.

## Not all AI generation is the same

Everything I've said above is about code generation, and the enthusiasm is genuine. But I think it's worth being explicit about where I draw the line, because I don't think the same logic extends to image and video generation.

The reason is specific: generated imagery is consumed passively. Someone sees a realistic photo or video and has no signal that it isn't real. The asymmetry between production cost (near zero) and believability (high) makes it a misinformation accelerant in a way code gen isn't. A hallucinated code snippet fails visibly when you run it. A generated image of something that never happened just looks like a photograph.

The communities most harmed aren't random. They're the ones already targeted by misinformation and harassment: minorities, women in public life, trans people, people of colour, marginalised groups, political dissidents. Deepfakes disproportionately target these groups. The technology doesn't create a new category of harm. It lowers the barrier to existing harms that were already causing serious damage.

There's also a consent problem that doesn't have a clean answer. These models were trained on work scraped from illustrators, photographers, and designers, many of them freelancers, without consent. The output competes with those people directly. That's not democratising creativity; it's displacing the people whose work built the training corpus.

Code gen lands differently for a structural reason: code isn't passively consumed. It has to be read, reviewed, tested, and deployed by someone who takes responsibility for it. The human stays in the loop in a way that doesn't apply to a generated image dropped into a news article. And the most compelling use cases for code gen, building tools you'd otherwise pay subscriptions for, reducing dependency on commercial SaaS, making self-hosting genuinely accessible, are fundamentally about increasing individual ownership rather than displacing skilled work.

Code gen accelerates people who already have a foundation. Image gen displaces the people who built theirs. That asymmetry is why one sits fine with me and the other doesn't.

## What I've settled on

Claude Code for planning, orchestration, and anything that benefits from structured reasoning before implementation. Copilot for in-editor completions and boilerplate. Devin for genuinely isolated tasks with clear acceptance criteria where the risk of context failure is low.

The video's conclusion, that there's no hidden secret in the software and never was, just strong models and considered positioning, is probably the most honest framing I've come across. It doesn't reach for mystique, and it acknowledges that the genuine enthusiasm around Claude Code is partly about form factor and developer psychology, not purely raw capability.

The engineers who'll do well with AI are the ones who treat it as a force multiplier on what they already know, rather than a shortcut around having to know things in the first place. That instinct is baked into how Claude Code positions itself, and I think it's the heart of why it landed the way it did.
