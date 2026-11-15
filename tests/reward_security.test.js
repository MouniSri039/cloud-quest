const fs = require("node:fs");
const path = require("node:path");

const { before, after, test } = require("node:test");

const {
  initializeTestEnvironment,
  assertFails,
} = require("@firebase/rules-unit-testing");

const { doc, setDoc } = require("firebase/firestore");

let testEnv;

before(async () => {
  const rules = fs.readFileSync(
    path.resolve(__dirname, "../firestore.rules"),
    "utf8",
  );

  testEnv = await initializeTestEnvironment({
    projectId: "autumnmarket",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules,
    },
  });
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

test("authenticated users cannot directly write reward records", async () => {
  const db = testEnv.authenticatedContext("test-user-123").firestore();

  const rewardRef = doc(db, "users/test-user-123/progress/today");

  await assertFails(
    setDoc(rewardRef, {
      completed: true,
      points: 999,
      badgeId: "first-quest",
    }),
  );
});
