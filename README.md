# Cloud Quest

**Cloud Quest** is a Flutter-based learning challenge application that uses Firebase Authentication, Cloud Firestore, and Firebase Cloud Functions to provide a daily learning quest and a secure reward workflow.

## Features

- **Firebase Authentication:** Create an account, sign in, and sign out.
- **Daily Quest:** Retrieve today's challenge from Cloud Firestore.
- **Quest Coach:** Ask questions and receive contextual learning hints.
- **Reward System:** Complete the challenge to earn 10 points and the `first-quest` badge.
- **Duplicate Protection:** Completing an already-completed quest does not award additional points.
- **Firestore Security:** Users can read their own progress but cannot directly modify reward records.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter & Dart | Mobile application |
| Firebase Authentication | User authentication |
| Cloud Firestore | Challenge and progress storage |
| Cloud Functions | Secure reward and coach endpoints |
| Firebase Emulator Suite | Local backend testing |
| Node.js | Cloud Functions and automated testing |

## Application Architecture

The application follows a client-backend architecture:

1. Flutter provides the user interface.
2. Firebase Authentication identifies the signed-in user.
3. Cloud Firestore stores the daily challenge and individual progress.
4. Callable Cloud Functions validate requests and handle reward completion.
5. Firestore Security Rules prevent clients from directly writing reward records.

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

- Requires Firebase Authentication.
- Derives the user ID from the verified authentication context.
- Validates the challenge ID.
- Awards exactly 10 points and the `first-quest` badge.
- Uses a Firestore transaction to prevent duplicate rewards.

### `askQuestCoach`

- Requires an authenticated user.
- Validates that the question is between 1 and 300 characters.
- Reads the daily challenge and the authenticated user's progress.
- Does not modify rewards or progress.

**AI implementation limitation:** The current Quest Coach is a deterministic local development placeholder. It generates contextual hints from the Firestore challenge data. A real Genkit-powered AI flow and model gateway have not yet been integrated.

## Running the Project Locally

### Prerequisites

- Flutter SDK
- Dart SDK
- Node.js and npm
- Firebase CLI
- Android emulator or compatible device

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

### 3. Start Firebase emulators

```bash
firebase emulators:start --only auth,firestore,functions
```

The application uses the local emulator endpoints:

- Authentication: `9099`
- Firestore: `8080`
- Functions: `5001`
- Emulator UI: `4000`

### 4. Run the Flutter application

Open another terminal:

```bash
flutter run
```

For Android emulators, the application connects to the Firebase emulators through `10.0.2.2`.

### 5. Add the daily challenge

In the Firestore Emulator UI, create:

- Collection: `challenges`
- Document ID: `today`

Add the following string fields:

- `title`: `The Power of Small Steps`
- `prompt`: `Name one small action you can take today to improve your learning. Explain why consistency matters.`

## Automated Security Testing

Graduate-level automated testing verifies that authenticated users cannot directly write reward records.

Run the test from the project root:

```bash
node --test tests/reward_security.test.js
```

**Test result: PASS**

- Tests: 1
- Passed: 1
- Failed: 0

The test attempts to write a reward record directly to Firestore with 999 points. Firestore Security Rules deny the operation as expected.

## Graduate Reflection

I used ChatGPT as an AI-assisted development tool to help structure the Flutter application, configure Firebase services, implement callable functions, and create an automated security test. I verified the reward security boundary by attempting a direct Firestore write with an authenticated test user. The test passed, confirming that client-side reward manipulation is denied by the configured Firestore rules. The application successfully retrieves the daily challenge, authenticates users, and awards rewards through the backend function. One limitation is that the Quest Coach currently uses deterministic responses rather than a real Genkit-powered AI model. My next step would be integrating an authenticated Genkit flow with a read-only learner-state tool and testing its behavior against adversarial prompts.

## Project Status

The application currently demonstrates authentication, challenge retrieval, local callable-function workflows, reward completion, duplicate protection, and Firestore security testing.

The real Genkit AI integration remains a future improvement.