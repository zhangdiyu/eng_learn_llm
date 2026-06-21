# Opening Experience Product Plan

## 1. Product Goal

Build the app's "open-time question" into a real product capability instead of a fixed code path.

The product should feel like:

- It remembers the user
- It does not repeat itself mechanically
- It asks useful questions at the right moment
- It can evolve from onboarding into long-term companionship
- It can be operated, measured, and improved over time

This means the app should no longer be designed as:

- "When app opens, show one hardcoded question"

It should be redesigned as:

- "When app opens, choose the best opening experience for this user and this moment"

## 2. Core Product Shift

The product should move from a single-question interaction to an `Opening Experience Engine`.

This engine chooses one opening card at app launch from several card types:

- `question_card`: ask a useful question
- `memory_card`: remind the user what they said before
- `progress_card`: reflect progress or streaks
- `suggestion_card`: offer a next action
- `resume_card`: continue an unfinished thread
- `celebration_card`: reinforce positive behavior

The key product principle is:

- Not every launch needs a question
- Every launch should feel relevant

## 3. User Problem

Current likely user experience:

- The app asks the same question again and again
- The question feels like code logic, not intelligence
- The app does not appear to learn from the user
- Opening the app becomes repetitive and low-value

Target user experience:

- The app feels aware of prior answers
- The app opens with variety and purpose
- Questions adapt to user stage, goals, and recency
- The user feels "this app is getting to know me"

## 4. Product Principles

1. Relevance beats randomness
2. Memory beats repetition
3. Lightweight interaction beats long forms
4. Product rhythm matters more than asking every time
5. Content must be configurable without code changes
6. Every launch should contribute to user understanding or user progress

## 5. Product Scope

### In Scope

- Opening card selection
- Question bank management
- User memory and history
- Rotation and cooldown rules
- Follow-up logic
- User segmentation and profile enrichment
- Event tracking and reporting

### Out of Scope for MVP

- Fully AI-generated questions for every launch
- Complex recommendation models
- Full CMS with role permissions
- Cross-device sync if the product is still single-device

## 6. Experience Design

### 6.1 Launch States

The opening experience should vary by user stage.

#### First Launch

Goal:

- Build trust
- Ask one very light question
- Establish tone

Examples:

- "What do you want this app to help you with most?"
- "Would you like this app to feel more like a coach, a journal, or a reminder partner?"

#### Early Usage

Goal:

- Build profile gradually
- Learn preferences
- Avoid repeated setup forms

Examples:

- "When are you most likely to use this app?"
- "Would quick wins or deeper reflection be more useful for you right now?"

#### Active Usage

Goal:

- Continue relevant conversations
- Help the user make progress

Examples:

- "Last time you said evenings are your hardest time. Has this week felt any better?"
- "You planned to study speaking for 10 minutes. Want to continue that now?"

#### Mature Usage

Goal:

- Reduce noise
- Increase precision
- Provide value without forcing interaction

Examples:

- "You have opened the app 4 days in a row. Want a lighter start today?"
- "You have not checked in on your English practice in 5 days. Resume or skip?"

### 6.2 Opening Card Rules

The app should not always show a question. Suggested mix:

- 45% `question_card`
- 20% `resume_card`
- 15% `memory_card`
- 10% `suggestion_card`
- 5% `progress_card`
- 5% `celebration_card`

These ratios can later be tuned through experiments.

## 7. System Architecture

The capability should be split into five product components.

### 7.1 Content Layer

Stores all question and card templates.

Responsibilities:

- Question metadata
- Copy variants
- Categories
- Trigger conditions
- Priorities
- Cooldown windows
- Follow-up chains

### 7.2 Memory Layer

Stores what the app knows about each user.

Responsibilities:

- Asked questions
- Answers
- Derived tags
- Last opened time
- User stage
- Current goals
- Incomplete tasks

### 7.3 Strategy Layer

Chooses what to show on each open.

Responsibilities:

- Build candidate set
- Apply exclusions
- Score candidates
- Balance relevance and diversity
- Select one card

### 7.4 Experience Layer

Renders the selected card and handles the interaction.

Responsibilities:

- Visual presentation
- Skip and dismiss behavior
- Answer capture
- Transition to next action

### 7.5 Analytics Layer

Measures whether the opening experience is effective.

Responsibilities:

- Exposure tracking
- Answer rate
- Skip rate
- Repeat rate
- Follow-through behavior

## 8. Content Model

Each question or opening card should be a content object with metadata.

### 8.1 Question Content Schema

```json
{
  "id": "daily_focus_001",
  "type": "question_card",
  "title": "Today's focus",
  "content": "What is the one thing you most want to move forward today?",
  "category": "daily_focus",
  "intent": "understand_current_priority",
  "priority": 80,
  "cooldown_days": 7,
  "answer_type": "text",
  "audiences": ["new_user", "active_user"],
  "trigger_conditions": {
    "min_days_since_signup": 0,
    "max_recent_asks": 0
  },
  "follow_up_ids": ["daily_focus_blocker_001"],
  "enabled": true
}
```

### 8.2 Card Types

All opening cards should share a common interface:

```json
{
  "id": "resume_task_001",
  "type": "resume_card",
  "title": "Continue where you left off",
  "content": "Last time you planned to practice speaking for 10 minutes. Resume now?",
  "cta_primary": "Resume",
  "cta_secondary": "Not now",
  "priority": 70,
  "cooldown_days": 3,
  "enabled": true
}
```

## 9. Memory Model

The app should persist user memory. Do not keep this only in memory state.

### 9.1 Required Data Objects

#### `user_profiles`

- `user_id`
- `created_at`
- `last_opened_at`
- `user_stage`
- `preferred_tone`
- `preferred_interaction_length`
- `current_goal_summary`
- `profile_completeness_score`

#### `question_history`

- `id`
- `user_id`
- `question_id`
- `shown_at`
- `answered_at`
- `dismissed_at`
- `answer_text`
- `answer_json`
- `session_id`

#### `user_tags`

- `id`
- `user_id`
- `tag`
- `score`
- `source_question_id`
- `updated_at`

#### `opening_events`

- `id`
- `user_id`
- `session_id`
- `card_id`
- `card_type`
- `event_name`
- `event_time`
- `metadata_json`

## 10. Storage Recommendation

### MVP

Use `SQLite`.

Why:

- Easy to embed
- Sufficient for single-user or early multi-user scenarios
- Good fit for structured history and query logic
- More reliable than ad hoc JSON files for long-term growth

### Later Stage

Migrate to `Postgres` when:

- There are multiple users
- There is sync across devices
- There is admin tooling
- There are analytics jobs or experiments

### What Should Not Be Done

Avoid storing this only as:

- one in-memory array
- one "last question" variable
- one config file without history

That would fix only the symptom, not the product problem.

## 11. Selection Strategy

The app should use a scoring system rather than fixed order or pure randomness.

### 11.1 Candidate Generation

Candidate set should be filtered by:

- enabled status
- user stage
- cooldown rules
- prior answers
- current context
- time-based triggers

### 11.2 Scoring Factors

Each candidate should receive points from:

- `novelty_score`: never asked or not asked recently
- `relevance_score`: matches user tags or current goal
- `profile_gap_score`: helps fill missing profile fields
- `continuity_score`: follows a recent answer naturally
- `diversity_score`: avoids asking same category repeatedly
- `priority_score`: business-defined importance

### 11.3 Exclusion Rules

Exclude questions or cards when:

- the same question was asked within its cooldown window
- the same category appeared too many times in recent sessions
- the question depends on missing prerequisite context
- the card was dismissed too recently

### 11.4 Exploration Rule

Reserve a small amount of controlled randomness:

- 80% best scored card
- 20% top-5 exploration pick

This prevents the product from feeling too rigid.

### 11.5 Pseudocode

```ts
function selectOpeningCard(user, cards, history, tags, context) {
  const candidates = cards
    .filter(card => card.enabled)
    .filter(card => matchesUserStage(card, user))
    .filter(card => passesCooldown(card, history))
    .filter(card => matchesContext(card, context));

  const scored = candidates.map(card => ({
    card,
    score:
      noveltyScore(card, history) +
      relevanceScore(card, tags, user) +
      profileGapScore(card, user) +
      continuityScore(card, history) +
      diversityScore(card, history) +
      priorityScore(card)
  }));

  scored.sort((a, b) => b.score - a.score);
  return chooseWithExploration(scored);
}
```

## 12. UX Rules

### 12.1 Answer Friction

Keep the first interaction lightweight:

- one question at a time
- optional skip
- short answer or quick choices
- no forced multi-step setup

### 12.2 Skip Handling

Skipping is a signal, not a failure.

Track:

- skipped immediately
- skipped after viewing
- skipped by category

Use it to reduce similar cards temporarily.

### 12.3 Follow-Up Behavior

Not every question should open another question.

Better pattern:

- Ask
- Capture answer
- Offer one small next step when relevant

Example:

- Question: "What do you most want to improve in English right now?"
- Answer: "Speaking"
- Follow-up card: "Want a 5-minute speaking prompt now?"

## 13. Content Operations

To make this a real product, content should be editable without code changes.

Minimum content operations support:

- enable or disable cards
- change priority
- edit cooldown days
- update copy variants
- add new categories

Recommended near-term structure:

- seed content in JSON
- content loader into SQLite
- admin config later

## 14. Metrics

Track metrics at the opening-card layer.

### Core Product Metrics

- `launch_open_rate`
- `opening_card_exposure_rate`
- `answer_rate`
- `skip_rate`
- `resume_click_rate`
- `same_question_repeat_rate_7d`
- `same_category_repeat_rate_7d`
- `profile_completeness_growth`
- `downstream_action_rate`

### Quality Thresholds

Suggested early targets:

- same-question repeat within 7 days: less than 2%
- answer rate: greater than 35%
- skip rate: less than 45%
- downstream action after opening card: greater than 20%

These are starting targets, not final guarantees.

## 15. Experimentation Plan

Once baseline behavior is stable, run A/B tests on:

- question-first versus memory-first open
- quick choices versus free text
- low-friction versus deeper reflective prompts
- always show card versus conditional card
- supportive tone versus direct productivity tone

## 16. MVP Delivery Plan

### Phase 1: Fix the Repetition Problem

Goal:

- Stop asking the same question every time

Build:

- question bank
- question history
- cooldown filtering
- basic random selection among valid candidates

Success condition:

- same question does not repeat within cooldown window

### Phase 2: Make It Feel Personal

Goal:

- Make the app appear to learn from prior interactions

Build:

- user profile
- user tags
- category balancing
- follow-up logic
- stage-based selection

Success condition:

- opening cards clearly differ based on prior answers

### Phase 3: Turn It Into a Product System

Goal:

- Create a durable, measurable opening experience platform

Build:

- multiple card types
- analytics dashboard
- content management workflow
- experiments
- recommendation tuning

Success condition:

- the opening system improves retention and engagement metrics

## 17. Implementation Blueprint

### Backend or Local Logic Modules

Suggested modules:

- `content_repository`
- `user_profile_repository`
- `question_history_repository`
- `opening_selector`
- `tag_extractor`
- `opening_event_tracker`

### Suggested Service Interfaces

```ts
type OpeningCard = {
  id: string;
  type: string;
  title: string;
  content: string;
  priority: number;
  cooldownDays: number;
};

interface OpeningEngine {
  getOpeningCard(userId: string, context: OpeningContext): Promise<OpeningCard>;
  recordExposure(userId: string, cardId: string, sessionId: string): Promise<void>;
  recordAnswer(userId: string, cardId: string, answer: OpeningAnswer): Promise<void>;
  recordDismiss(userId: string, cardId: string, sessionId: string): Promise<void>;
}
```

### Frontend Launch Flow

1. App opens
2. Load session context
3. Request best opening card
4. Render card
5. Record exposure
6. User answers, resumes, skips, or dismisses
7. Persist outcome
8. Optionally show next best action

## 18. Seed Segments

Start with simple user segments:

- `new_user`
- `exploring_user`
- `habit_building_user`
- `goal_oriented_user`
- `inactive_returning_user`

Later, these can become dynamic or score-based.

## 19. Risks and Anti-Patterns

Avoid these traps:

- Pure randomness with no memory
- Asking a question on every launch regardless of context
- Treating all users the same
- Deep onboarding up front
- Using only free text when quick choices would reduce friction
- No analytics, which makes optimization impossible

## 20. Immediate Build Recommendation

If implementation starts now, build in this order:

1. Add structured `questions` content
2. Add persistent `question_history`
3. Add cooldown-based selection
4. Add category balancing
5. Add user profile and tags
6. Add opening card types beyond questions
7. Add analytics events

## 21. Product Definition of Done

This capability feels like a product when:

- the same user does not repeatedly see the same opening
- the app remembers prior answers
- the opening experience changes with user stage
- not every launch forces the same interaction pattern
- content can be expanded without code rewrites
- metrics exist to evaluate quality

## 22. Next Step for the Existing App

The next engineering task should be:

- find the current open-time question trigger
- replace hardcoded selection with an opening engine
- persist show and answer history
- seed the initial question bank

If the current app already has startup hooks, state management, or local storage, the first integration should happen there rather than introducing a parallel flow.
