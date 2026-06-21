# Opening Experience Implementation Spec

## 1. Purpose

This document translates the product plan into implementation-ready engineering specifications.

It is intended to answer:

- what data to store
- what services to build
- what events to emit
- what launch-time flow to implement
- what logic decides which opening card is shown

This spec assumes the product is moving from a hardcoded startup question toward an `Opening Experience Engine`.

## 2. Recommended MVP Architecture

Use a layered design with clear boundaries.

### Core Modules

- `opening_content_store`
- `opening_history_store`
- `user_profile_store`
- `opening_selector`
- `opening_engine`
- `opening_event_tracker`
- `tag_inference_service`

### Responsibilities

#### `opening_content_store`

- load card definitions
- list enabled cards
- filter cards by type or audience

#### `opening_history_store`

- store exposures
- store answers
- store dismisses
- query recent history

#### `user_profile_store`

- read profile
- update stage
- update summary preferences
- persist inferred signals

#### `opening_selector`

- accept user context
- filter eligible cards
- compute scores
- return the best card

#### `opening_engine`

- orchestrate end-to-end startup behavior
- request context
- call selector
- record exposure
- return UI-ready payload

#### `opening_event_tracker`

- record analytics events
- normalize event payloads
- support downstream dashboards

#### `tag_inference_service`

- derive reusable user tags from answers
- update user memory

## 3. SQLite Schema

The following schema is designed for MVP and can later migrate to Postgres with minor changes.

### 3.1 `opening_cards`

```sql
CREATE TABLE IF NOT EXISTS opening_cards (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  intent TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 50,
  cooldown_days INTEGER NOT NULL DEFAULT 7,
  answer_type TEXT,
  answer_options_json TEXT,
  audiences_json TEXT NOT NULL,
  trigger_conditions_json TEXT,
  follow_up_ids_json TEXT,
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### 3.2 `user_profiles`

```sql
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_opened_at TEXT,
  user_stage TEXT NOT NULL DEFAULT 'new_user',
  preferred_tone TEXT,
  preferred_interaction_length TEXT,
  current_goal_summary TEXT,
  profile_completeness_score REAL NOT NULL DEFAULT 0,
  metadata_json TEXT
);
```

### 3.3 `opening_history`

```sql
CREATE TABLE IF NOT EXISTS opening_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  card_id TEXT NOT NULL,
  card_type TEXT NOT NULL,
  category TEXT NOT NULL,
  shown_at TEXT NOT NULL,
  answered_at TEXT,
  dismissed_at TEXT,
  action_type TEXT,
  answer_text TEXT,
  answer_json TEXT,
  metadata_json TEXT,
  FOREIGN KEY (user_id) REFERENCES user_profiles(user_id),
  FOREIGN KEY (card_id) REFERENCES opening_cards(id)
);
```

### 3.4 `user_tags`

```sql
CREATE TABLE IF NOT EXISTS user_tags (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  tag TEXT NOT NULL,
  score REAL NOT NULL DEFAULT 1,
  source_card_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user_profiles(user_id)
);
```

### 3.5 `opening_events`

```sql
CREATE TABLE IF NOT EXISTS opening_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  card_id TEXT,
  card_type TEXT,
  event_name TEXT NOT NULL,
  event_time TEXT NOT NULL,
  metadata_json TEXT,
  FOREIGN KEY (user_id) REFERENCES user_profiles(user_id)
);
```

## 4. Suggested Indexes

These indexes support the most common launch-time queries.

```sql
CREATE INDEX IF NOT EXISTS idx_opening_history_user_shown_at
ON opening_history(user_id, shown_at DESC);

CREATE INDEX IF NOT EXISTS idx_opening_history_user_card
ON opening_history(user_id, card_id);

CREATE INDEX IF NOT EXISTS idx_opening_history_user_category
ON opening_history(user_id, category);

CREATE INDEX IF NOT EXISTS idx_opening_events_user_event_time
ON opening_events(user_id, event_time DESC);

CREATE INDEX IF NOT EXISTS idx_user_tags_user_tag
ON user_tags(user_id, tag);
```

## 5. Startup Flow

The app launch should follow this flow.

### 5.1 High-Level Sequence

1. App opens
2. Resolve `user_id`
3. Create `session_id`
4. Load or create `user_profile`
5. Gather launch context
6. Request opening card from `opening_engine`
7. Render selected card
8. Record exposure event
9. On user action, record answer, dismiss, or resume
10. Update memory and user profile
11. Optionally offer next action

### 5.2 Launch Context Object

```ts
type LaunchContext = {
  openedAt: string;
  appVersion?: string;
  timezone?: string;
  localHour?: number;
  daysSinceLastOpen?: number;
  consecutiveOpenDays?: number;
  hasUnfinishedTask?: boolean;
  currentSurface?: string;
};
```

## 6. Selector Logic

### 6.1 Filtering

Eligible cards should pass:

- `enabled === true`
- audience match
- cooldown not violated
- trigger conditions satisfied
- prerequisite context satisfied

### 6.2 Scoring Formula

Recommended first-pass scoring:

```ts
score =
  noveltyScore +
  relevanceScore +
  continuityScore +
  profileGapScore +
  diversityScore +
  priorityScore +
  returnStateScore;
```

### 6.3 Score Dimensions

#### `noveltyScore`

- high if never shown
- medium if shown long ago
- low or negative if shown recently

#### `relevanceScore`

- based on matching tags
- based on current goal summary
- based on known preferred interaction mode

#### `continuityScore`

- high when the card naturally continues the prior interaction
- especially important for `resume_card` and `memory_card`

#### `profileGapScore`

- high if the card helps fill missing profile information

#### `diversityScore`

- penalize repeated categories in recent sessions

#### `priorityScore`

- direct mapping from content importance

#### `returnStateScore`

- reward reactivation cards for dormant users
- reward momentum cards for habit users

## 7. Cooldown Rules

Cooldown should apply at more than one level.

### Card-Level Cooldown

- same card cannot reappear within `cooldown_days`

### Category-Level Soft Cooldown

- if the same category appears 2 times in last 3 sessions, reduce score

### Dismissal Cooldown

- if dismissed recently, suppress similar cards for a short period

### Follow-Up Cooldown

- follow-up should not appear unless the parent interaction occurred recently

## 8. Event Model

The system should emit events for every major action.

### 8.1 Required Events

- `opening_session_started`
- `opening_card_selected`
- `opening_card_shown`
- `opening_card_answered`
- `opening_card_dismissed`
- `opening_card_skipped`
- `opening_card_cta_clicked`
- `opening_followup_rendered`
- `opening_session_completed`

### 8.2 Example Event Payload

```json
{
  "event_name": "opening_card_answered",
  "user_id": "u_123",
  "session_id": "s_456",
  "card_id": "daily_focus_001",
  "card_type": "question_card",
  "event_time": "2026-06-19T09:00:00Z",
  "metadata": {
    "category": "daily_focus",
    "answer_type": "text",
    "answer_length": 18
  }
}
```

## 9. Answer Handling

### 9.1 Supported MVP Answer Types

- `text`
- `single_select`
- `multi_select`
- `boolean`

### 9.2 Persistence Rules

- always record exposure before waiting for answer
- record dismiss separately from skip
- persist raw answer and normalized answer when possible

### 9.3 Normalization

Normalize answers into reusable product signals.

Examples:

- "I want to practice speaking" -> tags: `speaking_focus`, `english_learning`
- "Just give me quick tasks" -> preference: `short_interaction`

## 10. User Stage Logic

The engine should assign a stage to each user.

### Suggested Stages

- `new_user`
- `exploring_user`
- `habit_building_user`
- `goal_oriented_user`
- `inactive_returning_user`

### Example Stage Rules

- new signup -> `new_user`
- 3 opens in 7 days -> `habit_building_user`
- answer includes strong goal language -> `goal_oriented_user`
- no opens in 5+ days -> `inactive_returning_user`

## 11. Service Interfaces

### 11.1 Opening Engine Interface

```ts
type OpeningSelectionResult = {
  sessionId: string;
  card: OpeningCard | null;
  reason: string;
  debugScores?: Array<{ cardId: string; score: number }>;
};

interface OpeningEngine {
  prepareOpening(userId: string, context: LaunchContext): Promise<OpeningSelectionResult>;
  recordExposure(userId: string, sessionId: string, cardId: string): Promise<void>;
  recordAnswer(userId: string, sessionId: string, cardId: string, answer: unknown): Promise<void>;
  recordDismiss(userId: string, sessionId: string, cardId: string): Promise<void>;
}
```

### 11.2 Selector Interface

```ts
interface OpeningSelector {
  selectCard(input: {
    user: UserProfile;
    cards: OpeningCard[];
    history: OpeningHistoryRecord[];
    tags: UserTag[];
    context: LaunchContext;
  }): Promise<OpeningCard | null>;
}
```

## 12. Fallback Rules

The app should always have a graceful fallback.

### If No Eligible Card Exists

- show no opening card
- or show a generic low-friction suggestion card

### If History Store Fails

- fallback to question bank only
- still avoid fixed first-card behavior

### If Profile Does Not Exist

- create profile and serve a `new_user` onboarding card

## 13. Observability

### Required Debug Information

For internal builds, log:

- selected card id
- top 5 scored candidates
- exclusion reasons
- stage assignment
- cooldown decisions

This is important because opening logic can otherwise feel unpredictable during development.

## 14. QA Checklist

The following should be manually verified:

- same card does not repeat inside cooldown window
- recent dismiss reduces immediate resurfacing
- returning users see a different mix than new users
- answering updates profile or tags
- no launch crash if content store is empty
- no launch crash if history is empty
- exposure always records before answer
- skip and dismiss are analytically distinct

## 15. MVP Definition of Done

Engineering MVP is complete when:

- content is loaded from seed data
- opening card selection is not hardcoded
- opening history persists across app restarts
- same card respects cooldown
- user stage changes selection behavior
- at least one follow-up or resume path works
- events are recorded for exposure and answer

## 16. Recommended Build Order

1. create SQLite schema
2. load seed cards
3. build history store
4. build selector with cooldown and scoring
5. integrate startup flow
6. record exposure and answer events
7. add stage assignment and tag inference
8. add resume and memory card behavior
