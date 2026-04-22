---
layout: post
title: "Six Weeks with Claude Code: What It Actually Changed in My Workflow"
date: 2026-04-28
description: "Not a review of Claude Code's features but an account of what concretely changed in my day-to-day work after six weeks of using it seriously."
categories: [DevOps, AI]
tags:
  - ai
  - devops
  - claude-code
  - claude
  - tooling
  - productivity
---

I wrote about AI in the engineering workflow [earlier this month](/devops/ai/2026/04/19/integrating-ai-into-engineering-workflow): the augmentation vs replacement framing, where different tools land in practice, the calibration problem of trusting output too much or too little. That post was more about the category than the specifics.

This one is about what actually changed after six weeks of using Claude Code as a serious work tool. Not what it's capable of in principle. What it did to how I spend my time.

## The thing that changed first

The first concrete shift was how I begin complex work. Before, I'd open the relevant files, read enough to orient myself, and then start making changes or writing notes. Now I spend the first few minutes front-loading context into a Claude Code session: the files, the problem, the constraints, the things I've already ruled out.

The act of writing that context down forces a clarity I was skipping before. To explain a problem properly, I have to understand it properly. The output I get back is almost secondary to the clarifying work the prompt itself requires. This is not what I expected from an AI coding tool.

## Infrastructure change planning

The use case I described in the earlier post, mapping the blast radius of Terraform changes before touching anything, has become routine. A change that touches a shared module in a library consumed by dozens of dependent repos has a dependency graph I want to understand before I start. Feeding the relevant module code and asking Claude to trace which surfaces it exposes, which variables are load-bearing, and where breaking changes would land gives me a structured plan I can actually review and argue with.

This is faster than building the same picture by reading through each dependent repo manually, and less error-prone, because I'm looking at an explicit representation of the dependencies rather than trying to hold them in my head.

## PR descriptions

I used to find PR descriptions difficult to write, and not because they're complicated. By the time I've made a change, the context in my head no longer maps cleanly to something useful for a reviewer. The description I'd write was usually a thin paraphrase of the diff title.

Now the description comes out of the session context. When I've been working through a change with Claude Code, the context required to generate a useful PR description is already there. The description it produces isn't always exactly what I'd write, but it's a good first draft that captures the motivation and scope better than I typically would cold.

## Bash scripting

The display-profiles tool I published last week was partly written with Claude Code. The parts where it helped most: the coordinate normalisation logic for the display positioning wizard, the ASCII block diagram renderer, and the shell argument parsing boilerplate I have to look up every time. The DE detection logic and the overall structure I wrote myself, because those required understanding specific to the problem I was solving.

The pattern that works is using it for parts that are algorithmically interesting but not domain-specific. Multi-monitor coordinate geometry is a solved problem I don't want to reinvent. The shell integration architecture is what needed my actual thinking.

## What didn't change

Code review. I still do this manually and think that's correct. Reviewing a colleague's PR requires understanding their intent, the codebase context, the team's current direction, and often institutional knowledge about why something is the way it is. A tool that doesn't have that context will miss the things that matter, which are usually not "this line is syntactically wrong" but "this will break when we run the migration in three sprints."

Architectural decisions. For anything structural about how systems are composed or how responsibility is distributed, I want to think it through myself. The tool is useful for checking my reasoning, not replacing it.

Anything genuinely time-sensitive. When something is on fire and I need to move fast, adding a context-loading step is overhead I don't want.

## Rate limits

Still frustrating, still the biggest friction point. Intensive work sessions that would benefit most from the tool are also most likely to hit a cap mid-flow. I've adapted by batching context-heavy work rather than making piecemeal queries, and structuring sessions to front-load the hardest questions before the window fills up. That's a workaround, not a solution.

## Where it sits now

The thing that changed my workflow most isn't the code generation, which is useful and occasionally excellent. It's the planning overhead. I write better notes before starting. I structure problems more carefully. I catch more "I haven't actually thought this through" moments before they turn into half-done branches or wrong turns.

That's a quieter benefit than "it writes code for me." It's also the one that's compounded the most.
