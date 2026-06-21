export type OpeningCardType =
  | "question_card"
  | "resume_card"
  | "memory_card"
  | "suggestion_card"
  | "progress_card"
  | "celebration_card";

export type AnswerType = "text" | "single_select" | "multi_select" | "boolean";

export type OpeningCard = {
  id: string;
  type: OpeningCardType;
  title: string;
  content: string;
  category: string;
  intent: string;
  priority: number;
  cooldownDays: number;
  answerType?: AnswerType;
  answerOptions?: string[];
  audiences: string[];
  followUpIds?: string[];
  enabled: boolean;
  triggerConditions?: Record<string, unknown>;
};

export type UserProfile = {
  userId: string;
  userStage: string;
  preferredTone?: string;
  preferredInteractionLength?: string;
  currentGoalSummary?: string;
  profileCompletenessScore: number;
  lastOpenedAt?: string;
};

export type UserTag = {
  tag: string;
  score: number;
};

export type OpeningHistoryRecord = {
  cardId: string;
  cardType: OpeningCardType;
  category: string;
  shownAt: string;
  answeredAt?: string;
  dismissedAt?: string;
  actionType?: string;
};

export type LaunchContext = {
  openedAt: string;
  timezone?: string;
  localHour?: number;
  daysSinceLastOpen?: number;
  consecutiveOpenDays?: number;
  hasUnfinishedTask?: boolean;
  currentSurface?: string;
};

export type OpeningSelectionResult = {
  sessionId: string;
  card: OpeningCard | null;
  reason: string;
  debugScores: Array<{
    cardId: string;
    score: number;
    reasons: string[];
  }>;
};

type SelectionInput = {
  user: UserProfile;
  cards: OpeningCard[];
  history: OpeningHistoryRecord[];
  tags: UserTag[];
  context: LaunchContext;
  sessionId: string;
};

type ScoredCard = {
  card: OpeningCard;
  score: number;
  reasons: string[];
};

function daysBetween(nowIso: string, thenIso: string): number {
  const now = new Date(nowIso).getTime();
  const then = new Date(thenIso).getTime();
  const msPerDay = 1000 * 60 * 60 * 24;
  return Math.floor((now - then) / msPerDay);
}

function matchesAudience(card: OpeningCard, user: UserProfile): boolean {
  return card.audiences.includes(user.userStage) || card.audiences.includes("active_user");
}

function shownWithinCooldown(card: OpeningCard, history: OpeningHistoryRecord[], nowIso: string): boolean {
  const match = history.find((item) => item.cardId === card.id);
  if (!match) return false;
  return daysBetween(nowIso, match.shownAt) < card.cooldownDays;
}

function noveltyScore(card: OpeningCard, history: OpeningHistoryRecord[], nowIso: string): number {
  const match = history.find((item) => item.cardId === card.id);
  if (!match) return 35;
  const days = daysBetween(nowIso, match.shownAt);
  if (days > card.cooldownDays * 2) return 15;
  if (days > card.cooldownDays) return 5;
  return -100;
}

function relevanceScore(card: OpeningCard, tags: UserTag[], user: UserProfile): number {
  let score = 0;
  const tagNames = tags.map((tag) => tag.tag);

  if (card.category === "memory_resume" && tagNames.includes("speaking_focus")) score += 20;
  if (card.category === "daily_focus" && user.currentGoalSummary) score += 10;
  if (card.type === "resume_card" && user.userStage === "inactive_returning_user") score += 18;
  if (card.type === "progress_card" && user.userStage === "habit_building_user") score += 16;

  return score;
}

function continuityScore(card: OpeningCard, history: OpeningHistoryRecord[]): number {
  const mostRecent = history[0];
  if (!mostRecent) return 0;

  if (card.type === "resume_card" && mostRecent.actionType === "answered") return 14;
  if (card.type === "memory_card" && mostRecent.category === "daily_focus") return 8;
  return 0;
}

function profileGapScore(card: OpeningCard, user: UserProfile): number {
  if (user.profileCompletenessScore > 0.8) return 0;
  if (card.category === "onboarding") return 18;
  return 0;
}

function diversityScore(card: OpeningCard, history: OpeningHistoryRecord[]): number {
  const recent = history.slice(0, 3);
  const repeated = recent.filter((item) => item.category === card.category).length;
  if (repeated >= 2) return -20;
  if (repeated === 1) return -6;
  return 8;
}

function priorityScore(card: OpeningCard): number {
  return Math.round(card.priority / 10);
}

function returnStateScore(card: OpeningCard, user: UserProfile, context: LaunchContext): number {
  if ((context.daysSinceLastOpen ?? 0) >= 5 && card.type === "resume_card") return 18;
  if ((context.consecutiveOpenDays ?? 0) >= 3 && card.type === "progress_card") return 14;
  if (context.hasUnfinishedTask && card.type === "resume_card") return 15;
  if (user.userStage === "new_user" && card.category === "onboarding") return 20;
  return 0;
}

function scoreCard(card: OpeningCard, input: SelectionInput): ScoredCard | null {
  if (!card.enabled) return null;
  if (!matchesAudience(card, input.user)) return null;
  if (shownWithinCooldown(card, input.history, input.context.openedAt)) return null;

  const reasons: string[] = [];
  let score = 0;

  const novelty = noveltyScore(card, input.history, input.context.openedAt);
  score += novelty;
  reasons.push(`novelty:${novelty}`);

  const relevance = relevanceScore(card, input.tags, input.user);
  score += relevance;
  reasons.push(`relevance:${relevance}`);

  const continuity = continuityScore(card, input.history);
  score += continuity;
  reasons.push(`continuity:${continuity}`);

  const profileGap = profileGapScore(card, input.user);
  score += profileGap;
  reasons.push(`profile_gap:${profileGap}`);

  const diversity = diversityScore(card, input.history);
  score += diversity;
  reasons.push(`diversity:${diversity}`);

  const priority = priorityScore(card);
  score += priority;
  reasons.push(`priority:${priority}`);

  const returnState = returnStateScore(card, input.user, input.context);
  score += returnState;
  reasons.push(`return_state:${returnState}`);

  return { card, score, reasons };
}

function chooseWithExploration(sorted: ScoredCard[]): ScoredCard | null {
  if (sorted.length === 0) return null;
  if (sorted.length === 1) return sorted[0];

  const topFive = sorted.slice(0, 5);
  const shouldExplore = Math.random() < 0.2;
  if (!shouldExplore) return sorted[0];

  const pool = topFive.slice(1);
  return pool.length > 0 ? pool[Math.floor(Math.random() * pool.length)] : sorted[0];
}

export function selectOpeningCard(input: SelectionInput): OpeningSelectionResult {
  const scored = input.cards
    .map((card) => scoreCard(card, input))
    .filter((card): card is ScoredCard => card !== null)
    .sort((a, b) => b.score - a.score);

  const selected = chooseWithExploration(scored);

  return {
    sessionId: input.sessionId,
    card: selected?.card ?? null,
    reason: selected ? "selected_by_scoring_engine" : "no_eligible_card",
    debugScores: scored.map((item) => ({
      cardId: item.card.id,
      score: item.score,
      reasons: item.reasons
    }))
  };
}

export function inferTagsFromAnswer(cardId: string, answer: unknown): UserTag[] {
  if (typeof answer !== "string") return [];

  const normalized = answer.toLowerCase();
  const tags: UserTag[] = [];

  if (normalized.includes("speak")) tags.push({ tag: "speaking_focus", score: 1 });
  if (normalized.includes("english")) tags.push({ tag: "english_learning", score: 1 });
  if (normalized.includes("quick")) tags.push({ tag: "short_interaction_preference", score: 1 });

  if (cardId === "welcome_style_001" && normalized.includes("coach")) {
    tags.push({ tag: "coach_tone_preference", score: 1 });
  }

  return tags;
}
