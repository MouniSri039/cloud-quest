# Cloud Quest

Cloud Quest is a Flutter-based learning challenge application powered by Firebase and Google's Gemini AI. It provides daily learning challenges, personalized AI coaching, and a secure reward workflow.

## Features

- **Firebase Authentication:** Create an account, sign in, and sign out.
- **Daily Quest:** Retrieve today's learning challenge from Cloud Firestore.
- **AI Quest Coach:** Receive contextual, Gemini-generated learning hints using Genkit.
- **Reward System:** Complete the challenge to earn 10 points and the `first-quest` badge.
- **Duplicate Protection:** Repeated completion requests do not award additional points or badges.
- **Firestore Security:** Users can read their own progress but cannot directly modify reward records.
- **Persistent Progress:** Completion status and rewards are stored in Firestore.
- **Local Emulator Support:** Develop and test Firebase functionality locally.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter and Dart | Mobile application |
| Firebase Authentication | User authentication |
| Cloud Firestore | Challenge and progress storage |
| Firebase Cloud Functions | Secure backend operations |
| Genkit | AI application framework |
| Google Gemini 3.1 Flash-Lite | AI-generated coaching responses |
| Firebase Emulator Suite | Local backend development and testing |
| Node.js | Cloud Functions and automated testing |
| Firestore Security Rules | Database access control |

## Application Architecture

The application follows a client-backend architecture:

1. Flutter provides the mobile user interface.
2. Firebase Authentication identifies the signed-in user.
3. Cloud Firestore stores daily challenges and individual progress.
4. Callable Cloud Functions validate requests and process backend operations.
5. Genkit connects the Quest Coach to Google's Gemini model.
6. Firestore Security Rules prevent clients from directly modifying reward records.

### Firestore Data Model

**Challenge document**

`challenges/today`

- `title`: The Power of Small Steps
- `prompt`: Daily learning challenge description

**User progress document**

`users/{uid}/progress/today`

- `completed`: Completion status
- `points`: Points earned
- `badgeId`: Awarded badge identifier
- `completedAt`: Completion timestamp

## Security and Backend Logic

### `completeToday`

The reward function:

- Requires Firebase Authentication.
- Derives the user ID from the verified authentication context.
- Validates the challenge ID.
- Awards exactly 10 points and the `first-quest` badge.
- Uses a Firestore transaction to prevent duplicate rewards.
- Returns the existing reward when the quest has already been completed.

### `readMyQuestState`

The server-side read-only learner-state helper:

- Receives the UID derived from verified Firebase Authentication.
- Reads only `challenges/today`.
- Reads only the authenticated learner's `users/{uid}/progress/today` document.
- Does not modify challenge data, progress, or rewards.
- Supplies learner-state context to the Quest Coach.

### `askQuestCoach`

The AI coaching function:

- Requires an authenticated user.
- Validates questions between 1 and 300 characters.
- Derives the user's identity from the verified authentication context.
- Retrieves challenge and learner progress through the read-only helper.
- Uses Genkit and Gemini 3.1 Flash-Lite to generate contextual learning hints.
- Provides guidance before and after quest completion.
- Instructs the model not to modify rewards or follow requests to override its coaching instructions.
- Does not have reward-writing functionality.

The AI coach and reward function are separate backend operations. Only `completeToday` can award points and badges.

### Firestore Security Rules

The security rules enforce the following boundaries:

- Authenticated users can read challenge documents.
- Challenge documents cannot be modified by clients.
- Users can read only their own progress documents.
- Clients cannot directly write progress or reward records.

## Running the Project Locally

### Prerequisites

- Flutter SDK
- Dart SDK
- Node.js and npm
- Firebase CLI
- Android emulator or compatible device
- Google AI Studio Gemini API key

### 1. Install Flutter dependencies

```bash
flutter pub get
```

### 2. Install Functions dependencies

```bash
cd functions
npm install
cd ..
```

### 3. Configure the Gemini API key

The Gemini API key must remain on the server and must never be placed in the Flutter application.

For local Firebase Emulator development, create a file named `.secret.local` inside the `functions` directory:

```text
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Replace the placeholder with your own API key.

Do not commit `.secret.local` or expose the API key in screenshots, source code, or GitHub.

### 4. Start Firebase emulators

From the project root:

```bash
firebase emulators:start --only auth,firestore,functions
```

The application uses the following local emulator endpoints:

| Service | Port |
|---|---:|
| Authentication | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Emulator UI | 4000 |

### 5. Add the daily challenge

Open the Firestore Emulator UI and create:

- Collection: `challenges`
- Document ID: `today`

Add these string fields:

**title**

```text
The Power of Small Steps
```

**prompt**

```text
Name one small action you can take today to improve your learning. Explain why consistency matters.
```

### 6. Run the Flutter application

Open a separate terminal:

```bash
flutter run -d emulator-5554
```

For Android emulators, the application connects to Firebase emulators through `10.0.2.2`.

## Automated Testing and Verification

### Firestore security test

Run from the project root:

```bash
node --test tests/reward_security.test.js
```

**Verified result: PASS**

- Tests: 1
- Passed: 1
- Failed: 0

The test attempts to write a reward record directly to Firestore with an authenticated test user. Firestore Security Rules deny the operation as expected.

### Flutter analysis

```bash
flutter analyze
```

**Verified result:** No issues found.

### Flutter tests

```bash
flutter test
```

**Verified result:** All tests passed.

### Functions lint

Run inside the `functions` directory:

```bash
npm run lint
```

**Verified result:** Passed.

### Manual application verification

The following behaviors were also tested:

- User sign-up and sign-in.
- Daily challenge retrieval.
- Gemini-generated contextual coaching responses.
- Coaching after quest completion.
- Prompt-injection attempt requesting additional rewards.
- Reward total remained at 10 points and the badge remained unchanged after the adversarial request.
- Successful quest completion and badge award.

The prompt-injection test demonstrates that the tested request did not change rewards. It does not establish immunity to every possible prompt injection.

## Evidence and Screenshots

The `evidence/` directory contains screenshots documenting the application and its verification.

| Screenshot | Description |
|---|---|
| `01-challenge-completed.png` | Completed quest, 10 points, and earned badge |
| `02-signed-out-login.png` | Authentication screen |
| `03-quest-coach-hint.png` | Coach response before completion |
| `04-adversarial-prompt-test.png` | Earlier adversarial prompt test |
| `05-firestore-reward-record.png` | Firestore user progress document |
| `06-security-test-passed.png` | Automated security test result |
| `07-firestore-security-rules.png` | Firestore access-control rules |
| `08-coach-after-completion.png` | Coach response after quest completion |
| `09-gemini-quest-coach-success.png` | Successful Gemini-generated hint |
| `10-prompt-injection-no-extra-rewards.png` | Adversarial request with unchanged rewards |

## Graduate Reflection

I used ChatGPT as an AI-assisted development tool to build the Flutter application, configure Firebase, integrate Genkit with Gemini, and implement backend security. Gemini powers the Quest Coach, which generates contextual learning hints using challenge and learner-progress information retrieved on the server. I verified the security boundary by attempting a direct Firestore reward write with an authenticated test user; Firestore correctly denied it. I also tested an adversarial prompt requesting additional points and confirmed that the reward total remained unchanged. Flutter analysis, Flutter tests, Functions lint, and the Firestore security test passed. A remaining improvement is implementing the learner-state helper as an explicit model-invoked Genkit tool and expanding automated tests for authentication scope and duplicate completion.

## Project Status

Cloud Quest currently demonstrates:

- Firebase authentication and session management.
- Daily challenge retrieval from Firestore.
- Genkit integration with Gemini for AI-generated coaching.
- Server-side authenticated learner-state retrieval.
- Secure callable reward completion.
- Transaction-based duplicate reward protection.
- Firestore security rules.
- Automated security testing.
- Local Firebase Emulator Suite integration.

**Future improvements:** Implement an explicit model-invoked read-only Genkit tool and expand automated emulator tests for AI authentication scope, read-only behavior, and duplicate reward completion.
