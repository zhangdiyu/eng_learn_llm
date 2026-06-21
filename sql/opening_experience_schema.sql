BEGIN TRANSACTION;

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

COMMIT;
