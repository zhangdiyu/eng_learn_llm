# Opening Experience Operating Model

## Purpose

This document explains how to run the opening experience as an ongoing product capability rather than a one-time engineering feature.

If the system is only built and never operated, it will gradually become repetitive again. Productization requires a continuing operating loop.

## 1. Product Team Loop

The opening experience should be owned like a small product surface.

Every cycle should review:

- what cards are being shown
- what users answer versus skip
- what categories are overused
- whether repeat rate is rising
- whether openings lead to downstream activity

## 2. Weekly Operating Ritual

Suggested weekly review:

1. inspect same-card repeat rate
2. inspect same-category repeat rate
3. inspect answer rate by card type
4. inspect skip rate by audience segment
5. inspect downstream action rate
6. review worst-performing cards
7. tune priorities, cooldowns, or copy
8. add at least one new card or variant if content feels stale

## 3. Ownership

Suggested ownership split:

- Product owner: defines user stages, quality thresholds, content priorities
- Engineer: maintains selector logic, storage, and integrations
- Designer or content owner: writes card copy and variants
- Data owner: validates metrics and trend reporting

In a small team, one person can cover multiple roles, but the responsibilities should still exist.

## 4. Content Operations

The question bank should be treated as a living content library.

### Required Content Practices

- review top repeated cards every week
- prune cards with high skip and low downstream action
- create variants for cards with good intent but stale phrasing
- balance functional prompts with emotional or reflective prompts

### Card Lifecycle

- draft
- enabled
- monitored
- tuned
- deprecated

## 5. Metric Interpretation

### Good Signs

- answer rate stable or rising
- repeat rate falling
- more users receiving non-question opening cards
- better downstream action after opening

### Warning Signs

- one category dominates most openings
- dismisses cluster around one audience
- returning users still get onboarding-style prompts
- answer rate drops after content expansion

## 6. Experimentation Strategy

Once baseline quality is acceptable, test one variable at a time.

Good experiment candidates:

- supportive tone versus direct tone
- short answer choices versus free text
- memory card before question versus question before memory card
- light CTA versus strong CTA

Keep experiments narrow enough that results are interpretable.

## 7. Release Management

Do not ship large content or logic changes blindly.

Recommended release approach:

- ship to internal users first
- watch repeat rate and crash rate
- verify stage assignment and cooldown behavior
- then expand rollout

## 8. Long-Term Product Roadmap

After MVP proves stable, extend the system in this order:

1. card variants and copy testing
2. richer user stage models
3. adaptive timing and non-blocking openings
4. admin content management
5. recommendation tuning
6. cross-device memory sync

## 9. Product Standard

The feature behaves like a real product when:

- it can be measured
- it can be tuned
- it can be expanded without core rewrites
- it adapts to users over time
- it is owned as an ongoing experience, not a one-off startup prompt
