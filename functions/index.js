const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

setGlobalOptions({maxInstances: 5});

// Award 10 points and the First Quest badge exactly once.
exports.completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }

  if (request.data?.challengeId !== "today") {
    throw new HttpsError("invalid-argument", "Invalid challenge ID.");
  }

  const uid = request.auth.uid;
  const challengeRef = db.doc("challenges/today");
  const progressRef = db.doc(`users/${uid}/progress/today`);

  const challenge = await challengeRef.get();

  if (!challenge.exists) {
    throw new HttpsError("not-found", "Today's challenge was not found.");
  }

  return db.runTransaction(async (transaction) => {
    const progress = await transaction.get(progressRef);

    if (progress.exists && progress.data().completed === true) {
      return {
        completed: true,
        points: progress.data().points,
        badgeId: progress.data().badgeId,
        alreadyCompleted: true,
      };
    }

    const reward = {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      completedAt: FieldValue.serverTimestamp(),
    };

    transaction.set(progressRef, reward);

    return {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      alreadyCompleted: false,
    };
  });
});

// Local development coach placeholder.
// Reads only the signed-in learner's challenge and progress.
// Replace with the authenticated Genkit flow for final AI integration.
exports.askQuestCoach = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }

  const question = request.data?.question;

  if (
    typeof question !== "string" ||
    question.trim().length === 0 ||
    question.length > 300
  ) {
    throw new HttpsError(
        "invalid-argument",
        "Enter a question of 1 to 300 characters.",
    );
  }

  // Derive identity from verified Firebase Authentication.
  const uid = request.auth.uid;

  // Read-only access to this learner's quest state.
  const challengeRef = db.doc("challenges/today");
  const progressRef = db.doc(`users/${uid}/progress/today`);

  const [challenge, progress] = await Promise.all([
    challengeRef.get(),
    progressRef.get(),
  ]);

  if (!challenge.exists) {
    throw new HttpsError("not-found", "Today's challenge is unavailable.");
  }

  const challengeData = challenge.data();
  const progressData = progress.exists ? progress.data() : null;

  const reply = progressData?.completed ?
    `You've already completed "${challengeData.title}". Great work!` :
    [
      `For "${challengeData.title}", think about the key idea `,
      `in this prompt: ${challengeData.prompt}. `,
      "Break it into smaller steps and try the first one yourself.",
    ].join("");

  return {
    reply,
    source: "local-development-coach",
    completed: progressData?.completed ?? false,
  };
});
