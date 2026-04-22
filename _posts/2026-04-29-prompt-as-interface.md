---
layout: post
title: "The Prompt as Interface: How I Think About Writing Prompts for Engineering Tasks"
date: 2026-04-29
description: "Treating prompts like a CLI spec rather than a search query: the mental model shift that actually changed how much I get from AI tools."
categories: [AI]
tags:
  - ai
  - claude-code
  - productivity
  - tooling
---

The thing that took me a while to internalise about prompt quality is that it's not a communication problem, it's a specification problem. Vague input produces vague output not because the tool didn't understand you, but because you haven't fully specified what you want. Writing a better prompt and figuring out what you actually need turn out to be the same activity.

This isn't a list of prompt engineering tips. It's more about the mental model shift that changed how useful AI tools are for me in engineering work.

## From search query to spec

I came to AI tools with a search engine mental model. You type something in and get something back. With search engines, vague queries work because you're filtering from a large results set: the right answer is probably in there and you're hunting for it. With LLMs, the output is generated from your input. Vagueness doesn't broaden the results. It gives you the average of all possible things that could match your description.

The more useful model is the spec or the ticket. When I write a work item or a design document, I'm explicit about constraints, success criteria, what's in scope, and what's explicitly out of scope. A prompt that contains those same elements produces significantly more useful output than a prompt that contains only the top-level goal.

## What a good prompt actually contains

For engineering tasks, I think about a prompt as having four components:

The **objective**: what I want, stated specifically. Not "refactor this function" but "refactor this function to handle the case where the input list is empty without changing the return type or the calling interface."

The **constraints**: what can't change, what has to remain compatible, what assumptions the solution has to work within. This is the component most often missing. If the output needs to work within an existing interface, avoid a particular dependency, or stay within a complexity budget, that belongs in the prompt.

The **context**: what the tool needs to know about the surrounding system that it can't derive from the code. The migration that's in progress. The historical reason this particular thing works the way it does. The colleague who owns the component being called.

The **negative space**: what I'm not asking for. Sometimes the most useful thing to include is an explicit list of what I don't want, because the natural completion of a task without constraints tends to include things you'd have to undo.

## The moment you realise you already know

The most consistent side effect of writing precise prompts is that somewhere in the process of specifying the constraints and negative space carefully enough, the shape of the answer becomes obvious before the tool responds. Not always. Often enough to be reliable.

This is useful in itself. If I can write a prompt specific enough that I can predict what the answer should look like, I've already done the hard thinking. The tool's response is then confirmation and execution rather than synthesis. When I can't write a precise prompt, that's usually a sign I haven't thought the problem through yet.

## The parallel to writing good tickets

Prompt quality in AI tools is the same underlying problem as ticket quality in engineering teams. Vague tickets produce work that doesn't match intent. Detailed tickets with acceptance criteria, context, and explicit constraints produce work that can be reviewed against something concrete.

The skills transfer directly. Engineers who write good tickets tend to get more out of AI tools. The correlation isn't accidental. The underlying skill is precision in articulating what you need, and that applies equally whether the reader is a colleague or a model.

## What changes when you get this right

The benefit isn't magical output quality. It's fewer responses that miss the point, less back-and-forth, and a shorter path from intent to something useful. More of the value comes out of the first generation rather than through a sequence of corrections.

The deeper change, the one that compounded for me over time, is that the discipline of writing precise prompts has made me more precise about what I'm actually trying to do before I start. Prompting well turns out to require thinking well first, which is a less glamorous description of the skill but probably a more accurate one.
