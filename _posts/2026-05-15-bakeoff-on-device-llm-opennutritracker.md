---
layout: post
title: "Picking an On-Device LLM by Holding a Bakeoff"
date: 2026-05-15
description: "A small Flutter harness, eleven prompts, ten model families, and one question: which small LLM can estimate food macros on a Pixel 8 in under ten seconds? Here is what won on accuracy, what is still being measured for speed, and what the methodology taught me along the way."
categories: [Open Source]
tags:
  - flutter
  - llm
  - on-device
  - open-source
  - nutrition
  - mobile
---

The AI-fill-custom-dish feature in [OpenNutriTracker](https://github.com/simonoppowa/OpenNutriTracker) is the small bit of the app where someone types "two fried eggs with bacon" and the app comes back with a kcal-and-macros estimate that is not actively misleading. [Issue #250](https://github.com/simonoppowa/OpenNutriTracker/issues/250) is the place that work lives, and the version of it I have spent the last few weeks on is the on-device one, where the model has to run on the same Pixel 8 in the user's pocket and there is no network round-trip to a hosted API to fall back on. The question I needed an answer to was the practical one: of the small open-source LLMs that fit on a phone, which one is good enough at estimating food macros from a freeform description, fast enough that the UI does not feel broken while you wait?

The honest answer is that no published benchmark I could find measured the thing I actually cared about. Vendor leaderboards measure capability scores that are dominated by reasoning and chat quality, not by structured-JSON reliability on nutrition prompts. Phone-CPU latency is not measured at all, because the people who ship these models do not ship them onto phones. So I built llm-bakeoff, a small Flutter harness that runs the same evaluator over the same eleven prompts on whatever model the user has downloaded, and prints out the numbers I actually wanted.

## The shape of the harness

The harness is a Flutter app. Each model is a row with a Download button next to it. The download streams the GGUF file with resume support, so the half-gigabyte Qwen and the two-and-a-bit gigabyte Phi can both come down over a flaky train connection without losing progress. Once at least one model is on disk you tap Run bake-off and watch a log of the prompts and their per-prompt latencies and JSON-validity results stream past. The whole thing writes a `bakeoff-results.json` you can `adb pull` off the phone for the desktop write-up.

Inference is via [llamadart](https://pub.dev/packages/llamadart), a Dart FFI wrapper around `llama.cpp`. Models are Q4_K_M quantisations: Q3 is too lossy on the kind of factual-recall task this is, Q5 and Q6 are too big to ship to a phone with three apps fighting for storage. `gpuLayers: 0` because on-device GPU offload is its own can of worms and not the thing this spike is measuring. Everything runs on the CPU, which is what a Pixel 8 user is going to be running on if they enable this feature, so it is what the harness measures.

The prompts started as eight single-food cases (`a plain butter croissant`, `pierogi ruskie (potato + cheese)`, `zwei Spiegeleier mit Speck`, `trzy pączki z marmoladą`, `svíčková na smetaně s knedlíky` and a few more), deliberately spanning English, German, Polish, and Czech. Multilingual handling matters because OpenNutriTracker has a meaningful user base in those languages, and a model that returns reasonable kcal for "rice" but falls apart on "pierogi" is not a model that ships. Earlier today I added three multi-food prompts (a sandwich and crisps, pasta with parmesan, scrambled eggs with toast and butter) because the real UI lets people enter a full meal in one box, and the structural question of "did the model emit the right number of items, with all four nutrition fields filled in" turned out to be a separate axis of competence from the per-item accuracy on single foods.

## What the evaluator actually checks

The bit of the methodology I am quietly fondest of is the evaluator pipeline, because most of the work it does is the work that would otherwise be done by hand, badly, after the fact. The evaluator takes each model's raw output and runs it through six checks in order:

1. **JSON parse.** No JSON, no further questions; the cell is flagged `unparseable` and the rest of the pipeline skips. Qwen 3 4B failed this check on 6 of 8 prompts even with `/no_think` and a 2048-token budget, and that single fact was enough to take it out of the running.
2. **Field presence.** All four of `kcal_per_100g`, `protein_g`, `carbs_g`, and `fat_g` must be filled. If any is null the cell is flagged `low` and the harness re-prompts with the world-knowledge fallback prompt before giving up.
3. **Plausibility.** Kcal in `[10, 900]`, each macro in `[0, 100] g`, sum of macros under `110 g`. Catches the worst hallucinations (the 1635 kcal/100 g pierogi DeepSeek-R1 produced, for example) before they reach the rest of the pipeline.
4. **Atwater coherence.** This is the check that does the most work, and it is the one I would build into a structured-nutrition evaluator next time without hesitating. The Atwater factors say that protein and carbs contribute about 4 kcal per gram and fat about 9 kcal per gram, so `4·protein + 4·carbs + 9·fat` should be within 15% of the kcal value the model gave. A model that gives you 200 kcal of croissant with 4 g protein, 20 g carbs, and 2 g fat is wrong in a way you can detect without an expert nutritionist, because the macros and the kcal do not add up. About 25% of the otherwise plausible-looking outputs in early runs failed Atwater coherence, which is roughly the rate at which language models confabulate internally inconsistent numbers when nobody is checking.
5. **Snippet agreement.** The harness grounds each prompt with keyless search: the offline Open Food Facts catalog first, then the live OFF API, then Wikipedia in the prompt's locale (so `pl.wikipedia.org` for the pączki prompt), then English Wikipedia, then Wikidata's `wbsearchentities` for the canonical name, then DuckDuckGo lite HTML as a last resort. The evaluator extracts any "per 100 g, X kcal" values that appear in the snippets and compares the median against the model's kcal; within 15% upgrades the confidence by a notch, more than 30% downgrades it.
6. **Cross-runner consensus.** When two or more runners independently land within ±15% on the same prompt, the confidence bumps up by a notch. This is the closest thing the pipeline has to a self-checking trust signal: if Qwen and Phi both think a nectarine is around 44 kcal/100 g, the UI can show that number with more confidence than if either of them said it on their own.

The output of the pipeline is a single `ai_confidence` flag (`unparseable`, `abstained`, `low`, `medium`, `high`) that the OpenNutriTracker UI can use to decide whether to show the result plainly, behind a "rough estimate" disclaimer, or to refuse the estimate altogether.

## What the desktop accuracy run said

The accuracy axis is run on the desktop through Ollama, because GPU offload gives you numbers fast enough to iterate on the evaluator and the prompts without burning a fortnight per pass. The phone-CPU latency is a separate axis, measured on the actual Pixel 8.

The headline finding from run v7, after the multi-food prompt refactor, is one I did not expect: **Qwen 2.5 0.5B** came out on top. At 398 MB it is a quarter the size of Phi-4 mini and three times smaller than Granite 3.2 2B, yet it landed 7 of 8 single-food prompts within ±25% of the reference value, with median error of 12% and a perfect 3/3 on the multi-food structural score. In the v5 run, before the multi-food prompts were added and before the prompt schema got tightened, the same 0.5B model had been a weak performer (2/8 within ±25%, 65% median error) and I had flagged it as "too small, don't ship". The honest read of that turnaround is that the prompt and schema were doing more of the work than I had been giving them credit for, and the model was waiting to be asked the question in a way it could answer.

**Phi-4 mini** still has the best tail behaviour (8 of 8 prompts within ±50%, median error 8%), which makes it the candidate for users for whom occasional edge-case accuracy matters more than speed. **Qwen 2.5 1.5B** is the mid-pack honest-abstain candidate: 6 of 8 within ±25%, similar to Granite 3.2 2B and Qwen 2.5 3B, and small enough to be the obvious default for users who do not have two and a half gigabytes to give up to a single feature.

One of the quietly interesting findings is that **Qwen 2.5 3B is worse than its 1.5B sibling**. The notes in `RESULTS.md` capture it more carefully than I can in a single sentence, but the gist is that the larger context budget gives the bigger model room to invent plausible-but-wrong numbers, where the smaller model abstains more honestly when it does not know. "Bigger model, better answer" is a good rough heuristic for general capability scores. It is not a good heuristic for structured-JSON nutrition estimation, where confidence calibration matters as much as raw recall.

Two models had to be excluded entirely. DeepSeek-R1's chain-of-thought reasoning consumed the entire token budget on every prompt, with one cell producing a 1635 kcal/100 g pierogi hallucination and an average error of 81%; on the phone it took 90 seconds per prompt before timing out. Qwen 3 4B emitted unparseable JSON on most of its outputs even with the reasoning-suppression directive. Reporting what failed is part of the work; a bakeoff that only writes up the winners is not a bakeoff, it is a brochure.

## The speed numbers are the ones still in flight

The accuracy ranking is settled. The phone-CPU speed table is the part I am still measuring, because phone-run-06 was in flight as I started writing this and the numbers will land into `RESULTS.md` in the next few days. The shape of the answer is predictable from the warmup runs: Qwen 2.5 1.5B is somewhere in the 10 to 30 seconds per prompt band, and Phi-4 mini is in the 30 to 90 seconds band on the same device. The speed weighting in the recommendation is deliberately heavy, because a feature that returns an answer in 10 seconds feels alive and a feature that returns one in 40 seconds feels broken, regardless of how good the answer eventually is.

The bar I have set for the recommendation is concrete: Phi-4 mini wins only if its phone latency comes in at no more than twice the latency of the smaller candidate. If it is three times slower, the speed-weighted decision goes the other way and the smaller model ships. I am still genuinely unsure which side of that line Phi will land on, and I would rather sit with the not-knowing for a few more days than guess at the answer.

## What I have taken from holding the bakeoff

The thing I keep coming back to, when I look at what the harness has actually surfaced, is how much of small-model evaluation is methodology rather than models. The Atwater coherence check did more work than swapping in a stronger base would have, because most of the noise was internally inconsistent outputs rather than uniformly wrong ones. The multi-food prompt schema rescue rescued Qwen 2.5 0.5B from being written off. The keyless search grounding makes the evaluator's confidence calibration meaningfully better than a model talking to itself. None of those are model-side improvements. They are all things the harness does around the model.

What this means for the shipping config is probably that OpenNutriTracker gets two on-device tiers. Qwen 2.5 1.5B at around a gigabyte for the small-and-fast default, Phi-4 mini at 2.4 GB as the stronger-English-reasoning option for users who can afford the storage and the extra latency. The final decision is the one I am waiting on the phone-CPU numbers for, and I want to be honest that the part of the work that feels like the result is not the result yet.

I love this kind of spike, in the slightly soft way one loves a thing one has spent a fortnight squinting at. There is something quietly pleasing about a small, contained question that has a small, contained answer, and a harness that produces the answer reproducibly enough that the next person to ask the same question does not have to start from scratch. The harness will land in the OpenNutriTracker org once the phone-speed numbers are in and the recommendation is settled, so anyone else who wants to run their own bakeoff on a phone they actually own can pick it up and start from somewhere other than zero.
