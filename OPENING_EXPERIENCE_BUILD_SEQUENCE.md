# Opening Experience Build Sequence

## Goal

Turn the current repeated startup question behavior into a productized opening experience with memory, variation, and measurable impact.

This document describes the recommended execution order so a team can build without ambiguity.

## Phase 0: Align the Product Shape

Deliverables:

- confirm that startup experience becomes an `Opening Experience Engine`
- agree that the app can show multiple opening card types, not only a question
- agree on MVP scope

Decisions to lock:

- storage engine: `SQLite`
- content source: `question_bank_seed.json`
- first supported card types:
  - `question_card`
  - `resume_card`
  - `memory_card`
  - `suggestion_card`
- first user stages:
  - `new_user`
  - `active_user`
  - `inactive_returning_user`

## Phase 1: Stop Repetition

Objective:

- make sure the same question is not shown repeatedly on every open

Implementation:

1. create `opening_cards`
2. create `opening_history`
3. load seed content
4. replace hardcoded first-question logic with eligible-card selection
5. record every card shown
6. enforce card-level cooldown

Ship condition:

- the same card no longer repeats within its cooldown window

## Phase 2: Add Memory

Objective:

- make the app feel aware of previous user behavior

Implementation:

1. create `user_profiles`
2. create `user_tags`
3. record answers in structured form
4. infer simple tags from answers
5. use prior answers to affect future card selection

Ship condition:

- user A and user B can receive different startup cards based on prior use

## Phase 3: Add Product Rhythm

Objective:

- stop treating every open as the same situation

Implementation:

1. detect dormant returning users
2. detect active users with streaks or unfinished tasks
3. introduce `resume_card`, `memory_card`, and `progress_card`
4. reduce question frequency when a better opening type exists

Ship condition:

- the app sometimes opens with memory or resume instead of another question

## Phase 4: Make It Measurable

Objective:

- make optimization possible

Implementation:

1. create `opening_events`
2. emit analytics events for show, answer, skip, dismiss, and CTA click
3. define dashboards or reports for repeat rate and answer rate

Ship condition:

- the team can verify whether the new opening flow is better than the old one

## Phase 5: Tune the Product

Objective:

- move from functional to excellent

Implementation:

1. adjust scoring weights
2. add copy variants
3. expand the question bank
4. test different tones and answer formats
5. tune audience and cooldown settings

Ship condition:

- metrics improve without increasing friction

## First Sprint Recommendation

If the team has only one sprint, build this slice:

1. SQLite tables for `opening_cards`, `opening_history`, and `user_profiles`
2. seed content loader
3. opening selector with cooldown logic
4. startup integration
5. exposure and answer tracking

This is the smallest version that already feels more like a product than a code branch.

## Ownership Suggestion

Suggested split if multiple people are involved:

- Product: card taxonomy, stage rules, success metrics
- Frontend: rendering opening cards and capturing actions
- Backend or app logic: selector, storage, history, stage updates
- Data: events, dashboards, experimentation setup

## Product Readiness Checklist

Before calling it productized, confirm:

- startup behavior is no longer hardcoded
- content is editable without changing core logic
- memory survives app restart
- selection responds to history
- opening experience can vary by user state
- analytics exist to measure quality
