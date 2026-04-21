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

There's been a lot of noise about AI in software engineering over the last couple of years, and most of it sits at one of two extremes. Either AI is a glorified autocomplete that occasionally saves you a Google search, or it's about to replace your entire engineering team. Neither is accurate, and the reality of trying to actually integrate these tools into a real workflow is more interesting and more frustrating than either camp tends to admit.

I've been using AI tooling seriously for a while now: Claude Code daily, Devin for specific experiments, GitHub Copilot in the background. Here's what I've actually found.

## The replacement framing is the wrong one

Tools like Devin are marketed, more or less explicitly, as autonomous engineering agents. You hand them a task, they go off and do it. The pitch is that you can replace junior engineers, or at least dramatically reduce the need for them.

I understand why that framing exists. It's a compelling sales narrative. But it fundamentally misunderstands what junior engineers actually do on a team, and it underestimates how much invisible context is required to make good engineering decisions.

A junior engineer isn't just someone who writes code. They ask questions when something feels off. They push back when a task doesn't make sense. They learn the codebase and accumulate institutional knowledge. An autonomous agent handed a ticket doesn't know that the naming convention in that repo is intentionally inconsistent for a historical reason, or that the team is mid-migration and the "right" approach today would break everything in two weeks. It just does what it's told, with confidence.

I've watched Devin produce technically correct work that was completely wrong for the context. And it turns out I'm not alone in that assessment. The video below covers developer sentiment around Claude Code in some depth, and it's worth noting that the presenter calls Devin out directly: it "never quite took off in part because they kind of lied about a lot of the things it could do." That matches what I found in practice. It's impressive and genuinely useful for isolated, well-defined tasks. For anything that requires judgment, it struggles.

## Where Claude Code is different

{% include embed/youtube.html id='LACyqdAfnaw' %}

One of the more interesting things covered here is the source code leak from a few months ago. Anthropic accidentally published a source map in the NPM package, exposing the client-side code. The conclusion the video draws: there's no secret in the software. It's just calling the Claude API in a loop and invoking tools based on model output. The comment section response to that apparently amounted to "yeah, duh."

That's fair. But I think the "there's no secret" framing slightly misses the point. The value was never going to be in the wrapper. It's in what happens when a model that's genuinely strong at reasoning and code is given the right scaffolding to operate in a real development environment.

There's also some interesting stuff in the leaked code that didn't make headlines as much: a regex for detecting angry users to flag when things are going wrong, a mechanism to detect and misdirect attempts to distill the model, and a couple of unreleased features including "dream mode" for compressing memories and an undercover mode for contributing to open source without revealing the Claude Code origin. Whether those features ship or not, it suggests the team is thinking seriously about Claude Code as a long-running, context-aware collaborator rather than a stateless query tool.

The video also points out that Claude Code sits 40th on the Terminal Bench leaderboard. That sounds damning until you consider what Terminal Bench is measuring: benchmark task completion in isolation. The model itself (Opus 4.5) sits near the top of the same leaderboard when run through other agent harnesses. So the question isn't whether the model can do the thing. It's whether the wrapper is optimised for benchmark tasks, and clearly it isn't. That doesn't tell you much about how it performs on the kind of complex, multi-step infrastructure work I'm actually doing.

The form factor argument in the video is the most interesting bit, and I think it's largely right. Claude Code sits between two existing categories: IDE tools like Cursor and Copilot, where you're watching every change in real time, and no-code tools like Replit and Bolt, where you're not really supposed to look at the code at all. The terminal occupies a middle ground. It feels technical to developers. You're in a real environment where changes are reviewable, where you can send things for review, where you're not locked in a sandbox. But you're also not micromanaging every edit.

Claude Code doesn't try to replace you. It works alongside you in the IDE and positions itself as a planning and orchestration layer rather than an autonomous executor. That distinction matters a lot in practice.

The most useful thing it does for me is help structure complex, multi-step work before I write a single line. When I'm looking at a change that needs to touch fifteen modules across a shared Terraform library and cascade through dependent product repos, the failure mode isn't "I don't know how to write the Terraform". It's "I haven't fully mapped the blast radius of this change before I start." Claude Code is very good at that mapping. Feed it the relevant context, ask it to reason through the dependencies, and you get a structured plan you can actually pick apart and sanity-check before committing to it.

The subagent model is particularly useful here. I can delegate parallel research across multiple repos while keeping a coherent thread of intent. It's the difference between trying to hold fifteen browser tabs in your head and having a collaborator who can say "here's what I found in each of those, here's where they conflict."

It also stays honest about uncertainty. When it doesn't know something, it says so rather than confidently hallucinating an answer. That might sound like a low bar, but it's actually critical for trusting any tool in a production engineering context. The [Bullshit Benchmark](https://petergpt.github.io/bullshit-benchmark/viewer/index.v2.html) tests exactly this: how well models detect and push back on false or misleading information rather than just going along with it. The top 13 spots are almost entirely Claude models. Claude Sonnet 4.6 scores 91% on clear pushback, Opus 4.5 scores 90%, and the only non-Claude model in the top 13 is Qwen3.5 397b in 9th. That tracks with my day-to-day experience. The willingness to say "that's not right" is as important as the ability to produce good output.

## The real difficulty of integration

The harder problem isn't choosing between tools. It's changing how you work in the first place.

AI tooling is only useful if you invest in feeding it the right context. That means writing better task definitions, being more explicit about constraints and intent, and building the habit of thinking out loud in a way the tool can engage with. None of that comes naturally, and there's a period (weeks, maybe longer) where using AI tooling actively slows you down because you're learning how to work with it rather than just doing the work.

There's also a calibration problem. The temptation is to trust the output more than you should early on, then overcorrect and barely use it after the first bad result. The useful relationship is somewhere in the middle: treat it like a capable but context-limited collaborator whose work you always review, not an oracle and not a toy.

The rate limit complaints the video mentions are real. The rolling 5-hour window, the weekly cap, the peak and off-peak tiers — it's genuinely complicated. But the telling thing is that almost nobody frustrated with the limits is suggesting switching tools. The conversation is about upgrading plans, not leaving. That's a reasonable signal about how much people actually value it once they've gotten past the learning curve.

## What I've settled on

Claude Code for planning, orchestration, and anything that benefits from structured reasoning before implementation. Copilot for in-editor completions and boilerplate. Devin for genuinely isolated tasks with clear acceptance criteria where the risk of context failure is low.

The video's conclusion — that there's no hidden secret in the software, just strong models and the right positioning — is probably the most honest framing I've come across. It doesn't try to oversell what's happening under the hood, and it acknowledges that the obsession is partly about form factor and developer psychology, not just raw capability.

The engineers who'll do well with AI are the ones who treat it as a force multiplier on what they already know how to do, rather than a shortcut around having to know things in the first place. Claude Code's positioning leans into that, whether intentionally or not, and I think that's a big part of why it landed the way it did.
