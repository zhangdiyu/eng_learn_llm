# Daily English Quest - Android App Plan

## 1. Product Goal

Build a polished mobile learning game for practicing everyday English conversations:

1. AI generates a practical Chinese sentence or dialogue prompt.
2. The learner translates or responds in English.
3. AI evaluates meaning, grammar, naturalness, and tone.
4. The app gives a clear explanation, corrections, and better alternatives.
5. The learner continues to the next question with gradually increasing difficulty.

The first release targets Android. The architecture should leave room for iOS later.

## 2. Recommended Technology

### Mobile app

- Flutter
- Dart
- Material 3
- Riverpod for state management
- GoRouter for navigation
- Dio for HTTP requests
- Drift or Isar for local learning history
- Flutter Secure Storage for user tokens and non-model secrets
- SharedPreferences for lightweight settings

### AI integration

- Client-side DeepSeek-compatible chat completion API
- Dio interceptors for timeout, retry, and redacted logging
- Freezed/json_serializable models for structured JSON validation
- Repository interface so a server gateway can be added later without changing UI

### Repository layout

```text
eng_learn_llm/
  app/                  # Flutter Android application
  docs/                 # Product and technical documentation
  .gitignore
  README.md
```

## 3. API Key Security

Use a bring-your-own-key model. The learner enters a personal model API key
during setup. Do not package a shared DeepSeek API key inside the Android app.
A key stored in an APK, `BuildConfig`, assets, or committed config can be
extracted even when the source file itself is excluded from Git.

Use this initial flow:

```text
Android App -> DeepSeek-compatible API
```

Store the user-entered key with `flutter_secure_storage`, backed by Android
Keystore. Keep the key in memory only while making a request. Never place it in
logs, analytics, crash reports, local databases, exported backups, or error
messages.

The API setup screen should contain:

- API key with hidden input
- Test connection button
- Save and delete credentials actions
- Short privacy and billing warning

The provider configuration is built into the app:

```text
API format: OpenAI-compatible Chat Completions
Base URL:   https://api.deepseek.com
Endpoint:   /chat/completions
Model:      deepseek-v4-flash
```

Keep these values in a typed application configuration class rather than an
editable user form. Only the API key is supplied by the learner. Release builds
must never contain a real shared key.

Limitations of client-side BYOK:

- A rooted or compromised device may expose the user's key.
- The app cannot centrally enforce model spending or rate limits.
- Provider errors and API changes affect clients directly.
- App-store privacy disclosures must explain that prompts are sent to the
  configured model provider.

These are acceptable for a personal or BYOK product. Keep an `AiProvider`
interface so a hosted gateway can be introduced later for shared accounts,
subscriptions, centralized abuse control, or managed usage.

## 4. Core Game Loop

1. Select a topic, level, or daily challenge.
2. Receive a Chinese situation and sentence.
3. Read optional hints based on difficulty.
4. Type an English answer.
5. Submit and receive a score and explanation.
6. Review the recommended answer and alternatives.
7. Gain XP, maintain a streak, and continue.
8. Incorrect concepts enter the review queue.

The user should not need to wait for AI to generate the next question after
every answer. Keep one or two prefetched questions ready.

## 5. Main Screens

### Onboarding

- Choose current level: beginner, elementary, intermediate, advanced
- Select learning goals: travel, work, social life, shopping, dining
- Explain the answer and feedback flow with one sample question
- Optional short placement test

### Home

- Daily goal progress ring
- Continue learning button
- Current streak, XP, and level
- Daily challenge
- Review mistakes shortcut
- Topic cards with completion progress

### Learning session

- Scenario title and compact illustration
- Chinese prompt card
- Speaker identity and conversational context
- English input box
- Hint button
- Submit button
- Skip button with a small XP cost
- Session progress and remaining hearts

### Feedback

- Overall result: correct, mostly correct, or needs revision
- Score from 0 to 100
- Meaning, grammar, naturalness, and tone breakdown
- User answer with highlighted issues
- Recommended answer
- One or two natural alternatives
- Short Chinese explanation
- Key phrase and grammar note
- Retry and next question actions

### Review

- Mistake notebook
- Filter by topic, grammar point, and error type
- Spaced repetition queue
- Retry difficult sentences
- Mastered state

### Profile and settings

- Learning statistics
- Topic mastery map
- Sound, vibration, and theme settings
- Daily goal and reminder
- AI service status
- Data export and reset

## 6. Visual Direction

Use a warm, modern game-like visual style without making it childish:

- Primary color: deep indigo or ocean blue
- Accent color: mint green for success
- Warm amber for hints and streaks
- Soft red only for corrections
- Rounded cards with restrained shadows
- Large readable Chinese and English typography
- Subtle gradients on progress and reward elements
- Small animations for XP, correct answers, streaks, and level-ups
- Dark mode
- Minimum touch target of 48 dp
- Support common Android screen sizes and system font scaling

Suggested theme:

```text
Primary:   #4F46E5
Secondary: #14B8A6
Success:   #22C55E
Warning:   #F59E0B
Error:     #EF4444
Surface:   #F8FAFC
Dark:      #0F172A
```

## 7. Difficulty System

### Level 1 - Starter

- One short sentence
- Familiar vocabulary
- Present tense
- Full word-bank hint
- First-letter hint
- Chinese explanation after submission
- Accept multiple simple natural answers

Example:

```text
Situation: You meet a colleague in the morning.
Chinese: 早上好，你今天怎么样？
Hint words: morning / how / today
```

### Level 2 - Elementary

- One or two connected sentences
- Basic past and future tense
- Partial phrase hints
- Common travel, dining, and shopping situations

### Level 3 - Intermediate

- Multi-turn context
- Politeness and tone requirements
- Phrasal verbs and common collocations
- Hints cost XP

### Level 4 - Advanced

- Nuanced social and workplace situations
- Indirect requests, disagreement, apology, and negotiation
- No default hints
- Evaluation focuses strongly on tone and naturalness

### Adaptive progression

- Track accuracy by topic, grammar point, and vocabulary group.
- Increase difficulty after stable performance, not after one correct answer.
- Reduce complexity after repeated failures.
- Reintroduce weak concepts using spaced repetition.
- Never punish a valid English answer only because it differs from the reference.

## 8. AI Responsibilities

Use two separate AI tasks:

1. Generate a question.
2. Evaluate the learner's answer.

Keeping them separate makes validation, retries, caching, and analytics easier.

### Question generation rules

- Generate practical, culturally neutral daily situations.
- Match the requested CEFR-like level.
- Avoid obscure vocabulary unless the level requires it.
- Include expected intent, useful phrases, and acceptable answer examples.
- Do not expose the reference answer before submission.
- Return strict JSON only.

Example response contract:

```json
{
  "questionId": "generated-id",
  "level": "A1",
  "topic": "restaurant",
  "situationZh": "你在餐厅点餐。",
  "promptZh": "我想要一杯水，谢谢。",
  "speakerRole": "customer",
  "targetIntent": "politely request a glass of water",
  "hints": {
    "keywords": ["would", "water", "please"],
    "firstLetters": "I w... l... a g... of w..., p..."
  },
  "referenceAnswers": [
    "I'd like a glass of water, please.",
    "Could I have a glass of water, please?"
  ],
  "focusPoints": ["polite requests", "I'd like"]
}
```

### Evaluation rules

- Judge semantic correctness before exact wording.
- Accept contractions, regional variants, and natural alternatives.
- Distinguish serious errors from style improvements.
- Do not claim an answer is wrong only because punctuation or capitalization is imperfect.
- Give concise Chinese explanations.
- Return strict JSON only.

Example response contract:

```json
{
  "verdict": "mostly_correct",
  "score": 86,
  "dimensions": {
    "meaning": 95,
    "grammar": 80,
    "naturalness": 82,
    "tone": 90
  },
  "correctedAnswer": "I'd like a glass of water, please.",
  "alternatives": [
    "Could I have a glass of water, please?"
  ],
  "explanationZh": "意思表达正确。点餐时使用 I'd like 比 I want 更自然、更礼貌。",
  "issues": [
    {
      "type": "naturalness",
      "original": "I want",
      "suggestion": "I'd like",
      "reasonZh": "在服务场景中更礼貌自然"
    }
  ],
  "keyTakeawayZh": "礼貌提出需求时可使用 I'd like..."
}
```

## 9. Prompt Strategy

### System prompt for question generation

```text
You are an English conversation curriculum designer for Chinese learners.
Create exactly one practical daily-conversation exercise at the requested
level and topic. The learner sees Chinese and must answer in English.

Requirements:
- Match vocabulary, grammar, sentence length, and social nuance to the level.
- Use realistic spoken English, not textbook-only phrasing.
- Include multiple acceptable reference answers.
- Avoid ambiguous Chinese prompts unless context resolves the ambiguity.
- Keep beginner hints useful without revealing the full answer.
- Return valid JSON matching the provided schema. Return no markdown.
```

### System prompt for evaluation

```text
You are a fair English speaking and writing coach for Chinese learners.
Evaluate whether the learner's English communicates the target intent in the
given situation.

Priority:
1. Meaning and task completion
2. Grammar
3. Naturalness
4. Tone and politeness

Accept valid alternatives and regional English. Do not require exact matching
with a reference answer. Explain errors briefly in Chinese, provide a corrected
answer, and include at most two natural alternatives. Return valid JSON matching
the provided schema. Return no markdown.
```

The gateway should inject level, topic, recent questions, target intent,
reference answers, and the learner answer into dedicated structured fields.
Never concatenate untrusted user text into the system instruction.

## 10. Scoring and Progression

Suggested score:

```text
Meaning      45%
Grammar      25%
Naturalness  20%
Tone         10%
```

Result thresholds:

- 90-100: excellent
- 75-89: correct or mostly correct
- 60-74: understandable but needs revision
- Below 60: retry recommended

Game progression:

- Correct answer: base XP
- No-hint bonus
- First-attempt bonus
- Daily goal bonus
- Topic completion badge
- Streak protection item earned through learning, not payment
- Hearts regenerate with time or review practice

XP should motivate practice but never block all learning.

## 11. Local Data Model

Core entities:

- UserProfile
- LearningPreferences
- Question
- Attempt
- Evaluation
- TopicProgress
- SkillMastery
- ReviewItem
- DailySession
- Achievement

Store generated questions and evaluations locally so sessions survive app
restarts. Do not store the model API key on the device.

## 12. AI Client Architecture

Core interface:

```dart
abstract interface class AiProvider {
  Future<GeneratedQuestion> generateQuestion(QuestionRequest request);
  Future<AnswerEvaluation> evaluateAnswer(EvaluationRequest request);
  Future<ConnectionResult> testConnection();
}
```

Required safeguards:

- Built-in `https://api.deepseek.com` base URL
- Built-in `deepseek-v4-flash` model name
- Authorization header added only by a redacting interceptor
- Response JSON schema validation
- Connection test before starting a session
- Request timeout and one controlled retry
- Maximum token and input length
- Prompt-injection-resistant field separation
- Duplicate question detection
- Basic content moderation
- Logs and crash reports that redact authorization headers and user answers
- Friendly offline and service-error messages
- Delete-key and reset-provider controls

## 13. Offline and Failure Experience

- Cache at least 10 starter questions locally.
- Prefetch upcoming AI questions when online.
- Allow review sessions entirely offline.
- Save an answer before sending it.
- Retry failed requests without losing user input.
- Show a clear service status instead of an endless loading spinner.
- Fall back to curated questions when AI is unavailable.

## 14. Accessibility and Input

- Chinese UI with English learning content
- Keyboard-friendly answer input
- Optional text-to-speech for reference answers
- Optional speech-to-text in a later milestone
- Screen-reader labels
- Color is not the only correctness signal
- Adjustable sound, vibration, and animation
- Respect reduced-motion settings

## 15. Testing

### Mobile

- Unit tests for scoring, progression, hints, and review scheduling
- Widget tests for learning and feedback screens
- Golden tests for light and dark themes
- Integration tests for a complete learning session
- Offline, timeout, malformed JSON, and app restart tests

### AI integration

- Prompt builder tests
- JSON schema validation tests
- Retry and timeout tests
- Redaction tests for secrets
- Secure-storage tests
- Connection configuration tests
- A fixed evaluation benchmark containing correct alternatives, common Chinese
  learner mistakes, incomplete answers, and prompt-injection attempts

### Acceptance criteria

- A valid alternative answer is accepted.
- A wrong-tense or meaning-changing answer is explained accurately.
- Beginner hints are available before submission.
- No shared API key appears in the APK or repository.
- The user's API key never appears in logs, analytics, crash reports, or UI
  after it is saved.
- A session can recover after an app restart.
- The core review flow works without network access.

## 16. Delivery Milestones

### Milestone 0 - Foundation

- Create Flutter project and AI provider abstraction
- Configure linting, formatting, environments, and Git ignore rules
- Add Material 3 design tokens and navigation shell
- Add CI for tests and static analysis

### Milestone 1 - Playable MVP

- Onboarding and level selection
- BYOK API setup and connection test
- Home screen
- AI question generation
- English text answer input
- AI evaluation and feedback
- Next-question flow
- Local attempt history
- Loading, retry, and error states

### Milestone 2 - Learning system

- Four difficulty bands
- Hint system
- Topic selection
- Adaptive progression
- Mistake notebook
- Spaced repetition
- Daily goals, XP, streaks, and achievements

### Milestone 3 - Product polish

- Animations and haptics
- Dark mode
- Text-to-speech
- Offline curated question pack
- Performance and accessibility pass
- Analytics with privacy controls

### Milestone 4 - Android release

- App icon, splash screen, screenshots, and store copy
- Android signing with ignored local keystore properties
- Privacy policy and data disclosure
- Internal testing build
- Crash reporting and release monitoring
- Google Play closed test, then production release

## 17. Suggested MVP Boundary

Include:

- Text-based answers
- Five daily-life topics
- Four broad levels
- AI generation and evaluation
- Hints for beginner levels
- XP, streak, daily goal
- Mistake review
- Offline cached questions

Defer:

- Voice scoring
- Multiplayer or leaderboards
- Social login
- Subscriptions
- Teacher dashboard
- Fully generated illustrations

This boundary is large enough to feel like a complete product while remaining
realistic for the first Android release.

## 18. Definition of Done

The first production release is done when a new learner can install the Android
app, choose a level, complete a stable 10-question session, receive fair and
useful feedback, continue after network interruptions, review mistakes later,
and securely manage their own model API key without exposing it through the
repository, logs, analytics, or crash reports.
