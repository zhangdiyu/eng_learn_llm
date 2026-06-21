# Opening Experience Launch Checklist

## Product Readiness

- The opening experience is defined as a reusable system, not a one-off startup prompt.
- Multiple card types exist, not only a single question flow.
- The team agrees on target user stages for MVP.
- The team agrees on repeat-rate and answer-rate success thresholds.

## Data Readiness

- `opening_cards` table exists.
- `opening_history` table exists.
- `user_profiles` table exists.
- `user_tags` table exists.
- `opening_events` table exists.
- Seed content has been loaded successfully.

## Logic Readiness

- Startup no longer uses a hardcoded first question.
- Card selection checks audience and cooldown rules.
- Same-card repetition is blocked during cooldown.
- Same-category overuse is reduced.
- Returning users can receive a different opening than new users.
- There is a fallback when no eligible card is available.

## Experience Readiness

- The card can be shown without blocking app startup indefinitely.
- The user can answer, skip, or dismiss.
- Skip and dismiss are handled separately.
- At least one memory or resume path exists.
- The user is not forced into a long setup flow on first use.

## Analytics Readiness

- Exposure events are recorded.
- Answer events are recorded.
- Skip events are recorded.
- Dismiss events are recorded.
- Downstream action events can be correlated to the opening session.

## QA Readiness

- Reopening the app does not show the same card immediately.
- A brand-new user receives onboarding-style content.
- A returning inactive user receives reactivation-style content.
- An answered card affects future selection.
- An empty history state does not crash the app.
- An empty content state fails gracefully.

## Operational Readiness

- Someone owns content updates.
- Someone owns metrics review.
- The team has a weekly review ritual for repeat rate and answer rate.
- There is a process for disabling low-performing cards.

## Launch Decision

Ship only when:

- repeat behavior is meaningfully improved
- the opening experience is measurable
- the system can evolve by changing content and rules rather than rewriting core logic
