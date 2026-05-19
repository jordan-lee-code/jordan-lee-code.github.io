---
layout: post
title: "Pure-Logic Tests for the Hard Parts of a Domain App"
date: 2026-05-19
description: "The recurrence rules, rotation logic, and schedule math in bubbyway live in files that import nothing from Drizzle or SvelteKit, so vitest can exercise them in isolation. Here is what separating that logic out actually buys, what it costs in daily discipline, and where the seams have resisted being clean."
categories: [Software]
tags:
  - sveltekit
  - testing
  - vitest
  - typescript
  - architecture
  - sqlite
  - drizzle
---

The parts of bubbyway that are most likely to be wrong, and most expensive to be wrong about, are the parts that calculate when a thing is supposed to happen next. A chore that repeats every three days from a starting Tuesday, rotating between two people, with a snooze that pushes the next occurrence out by a day. A medicine that fires on weekdays in odd-numbered weeks. A birthday five days from now where the lead-time notification should already be visible on the Today screen, but only for the person whose birthday it is not. The recurrence rules and the rotation logic and the small date-math decisions are the parts of the app where the cost of a bug is "the wrong person gets the chore for the next three weeks" or "the medicine reminder fires at midnight on a Sunday", and those are the bugs that erode trust in the app faster than any other category.

The bit of the architecture I have come to rely on most heavily, when working on those parts of the app, is the choice to put the pure logic in files that import nothing from the database, nothing from Drizzle, and nothing from SvelteKit. Vitest can then exercise the logic without needing any of the framework's runtime to resolve, and the tests look like the tests of a small library rather than the tests of a feature inside a larger system. I want to walk through what that pattern actually buys, where it costs me ongoing discipline, and the cases where the separation has resisted being as clean as I would like.

## The shape of the split

The pattern lives in `src/lib/server/`. Anywhere there is date or schedule math, the file is split into two: a `<feature>.ts` that touches the database, and a `<feature>-<helper>.ts` that does not. The DB file imports the helper, re-exports any of its functions the rest of the app needs, and uses them itself when it has rows in hand. The helper file imports `Date` and primitives and nothing else from inside the project.

The current pairs are:

- `chores.ts` and `chores-rotation.ts`, covering chore CRUD and the rotation parser.
- `meds.ts` and `meds-schedule.ts`, covering medicine CRUD, adherence aggregation, and the pure schedule math (which days a medicine fires on, when the next dose is, what the streak count is).
- `occasions.ts` and `occasions-dates.ts`, covering yearly occasion CRUD and the pure date math (when an occasion's lead window opens, how to compute "turning 34" from a starting year, how to handle February 29 birthdays in non-leap years).
- `recurrence.ts`, already pure with no DB imports at all. The chore recurrence engine, with its five recurrence kinds (`none`, `every_n_days`, `every_n_weeks`, `every_n_months`, `weekly_on_weekdays`) and the `nextDueAfter` function that takes a recurrence input and a reference moment and returns the next due date.

The rule is small. If a new piece of logic does not need to read the database, it goes in the helper file. The DB-touching file picks it up by import and re-exports it, so callers elsewhere in the app keep working without caring which file the function physically lives in.

## What a test looks like

The test for `nextDueAfter` opens like this, with a tiny helper for parsing dates that the test file owns rather than importing:

```typescript
import { describe, expect, it } from 'vitest';
import { nextDueAfter } from './recurrence';

function ymd(s: string): Date {
  const [y, m, d] = s.split('-').map(Number);
  const r = new Date(y, m-1, d);
  r.setHours(0, 0, 0, 0);
  return r;
}

describe('nextDueAfter', () => {
  it('every_n_days advances by N from start', () => {
    const r = nextDueAfter(
      {
        kind: 'every_n_days',
        n: 3,
        weekdaysMask: 0,
        startsOn: ymd('2026-01-01')
      },
      ymd('2026-01-01')
    );
    expect(r.toDateString()).toBe(ymd('2026-01-04').toDateString());
  });
});
```

There is no fixture setup. There is no in-memory database. There is no mocking of the ORM, no stubbing of `$app/environment`, no decision about whether the test should run against a fresh sqlite file or a shared one. The test imports the function, calls it with inputs, and asserts on the output. It runs in tens of milliseconds.

The same shape covers the awkward corners. The `every_n_months` test pins the behaviour where January 31 plus one month should snap to February 28 (or 29 in a leap year), because JavaScript's native `Date.setMonth` overflows to March 3 instead. The `weekly_on_weekdays` tests pin the behaviour for bitmasks where multiple weekdays are set, and for the case where the next due weekday is in the following week. The `chores-rotation` tests pin the behaviour for the case where two people are in rotation and one of them has been archived, where the rotation should skip the archived person rather than pause until they come back. None of those cases need any of the database; they need only the inputs and the expected outputs.

## What it costs

The cost of the discipline is real and ongoing. Designing a new feature is a little harder, because the tricky bits have to be expressible as pure functions before the database layer touches them, and that sometimes pushes the data model into shapes it would not naturally take. A function that needs to know "the list of people currently in rotation for this chore" has to receive that list as an argument rather than fetching it inline. The DB code wraps the pure function with a small amount of bookkeeping that fetches the list, calls the function, and writes the result back. That extra wrapping is a small surface area for bugs of its own.

The other small ongoing cost is that some logic looks pure at first and turns out not to be. The first version of the chore rotation logic was a single function that, given a chore, returned the next assignee. The second version had to be split into a pure function that, given a list of assignees and the most recent completion, returned the next assignee, plus a tiny DB-touching wrapper that looked up the assignees and the completion. The split was the right move, but I had to make it after the fact, which meant changing every caller. The lesson I keep relearning is to design the pure function first and the DB wrapper second, because the reverse direction is more work than it sounds and tends to leave the DB wrapper holding state the pure function should own.

## What it buys

The benefit is the part I want the rest of this post to be honest about, because it is the part that pays back the daily discipline a hundred times over.

The recurrence test suite is sixty tests at this point, covering every recurrence kind across every awkward edge: month-end overflow, year boundaries, daylight-saving transitions, the case where `startsOn` is in the future, the case where the reference date falls exactly on a stride. When all sixty pass, I can change a line in `recurrence.ts` and know within milliseconds whether I have quietly broken the behaviour for the case where someone has snoozed a chore over a Saturday-night clock change. The DB layer that calls `nextDueAfter` does not have its own tests for any of this, because it does not need them; the math is being tested at the level where the math lives, and the DB layer is just composing the math with row-shaped state.

The same property holds for the medicine schedule and the occasion dates. The "turning 34" display logic, for example, is a few lines in `occasions-dates.ts` that takes a starting year and a target date and returns the integer age, with sensible behaviour for occasions whose starting year is null and for occasions whose date falls in the past part of the current year versus the future part. The test file pins half a dozen cases that exercise the corners, and the page that displays "turning 34" in the Today view is a thin shell over the pure function, free of its own date logic. When I add a new occasion kind (anniversaries, for example, which are years-since rather than age-at-next-birthday), the change is a single new branch in the pure function and three new test cases pinning the new branch's behaviour, and the rendering layer needs no changes at all.

The thing I keep coming back to is that the Drizzle layer is then quite boring. Most of the DB-touching code is just selecting rows, calling the pure function, and writing the result back. The interesting decisions are pinned by tests in the helper files, and the part of the code that talks to the database is the part where bugs are honestly mostly visible at first glance because there is so little going on. "Boring database layer" is the property I have come to want from this style of app, because the boring parts are the parts that do not surprise you in production.

## The seams that have resisted being clean

I want to be honest about the cases where the separation is not as crisp as the rest of the post might suggest, because pretending the architecture is perfect would be the bit of the writing that I would later regret.

The two cases that I keep thinking about are schedule math near daylight-saving boundaries, and the interaction between recurrence and snooze. The DST one is the older of the two. The pure functions all work in the local time zone of the machine they run on, and most of the time that is fine, but there are a small handful of cases where a recurrence that should fire at "Saturday 09:00 local" lands an hour earlier or later than it should around the spring or autumn clock change. I have a couple of tests pinning the cases I have understood, and a couple of cases I have not yet understood well enough to write tests for. I am sitting with not knowing the answer, and I am not going to pretend the gap is not there.

The snooze interaction is the newer one. A chore that is snoozed has a `snoozed_until` value that overrides its recurrence-calculated `next_due_at` until the snooze expires. The question of "what is the true next occurrence of this chore" stops being a pure function of the chore's recurrence alone, because the snooze state is part of the answer. I have refactored the helper a couple of times to thread the snooze state in as an argument, and each version has been a small improvement, and none of them have felt as clean as the unsnoozed version of the same function. I think there is a better shape here that I have not yet seen, and I am hoping the next refactor lands somewhere that feels obviously right rather than slightly tense.

## What I am taking from the pattern

The thing I keep returning to is that the parts of a small app that are most worth testing are also the parts that are easiest to write badly, and the architecture choice that makes them testable is almost always the same choice that makes them clearer in the first place. The pure helper file is not just a place to put functions that vitest can reach; it is a place that forces me to write the function with its inputs spelled out and its dependencies threaded in, which is also the form in which the function is easiest for me to reason about when I come back to it in three months and have forgotten what I was thinking when I wrote it.

The tests are a side effect of the clarity. The clarity is what I am actually after. The tests are the property that lets me change the clarity later without losing it, which is a different property and an even more valuable one, and I do not think I would have arrived at it if I had been trying to keep the pure logic in the same files as the database access from the start. The split is the discipline that makes the clarity stable, and the stability is the part that pays back the cost.

There is something quietly satisfying about a test suite that runs in under a second and tells me the truth about the part of the code I actually need the truth about. I love that property of the bubbyway codebase more than almost any other, and I would build any future app of this kind the same way.
