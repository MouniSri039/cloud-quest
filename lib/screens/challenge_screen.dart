
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final questionController = TextEditingController();
  String? hint;
  bool loadingHint = false;
  bool completing = false;

  Future<void> getHint() async {
    final question = questionController.text.trim();

    if (question.isEmpty) {
      setState(() => hint = 'Enter a question first.');
      return;
    }

    setState(() {
      loadingHint = true;
      hint = null;
    });

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('askQuestCoach')
          .call({'question': question});

      setState(() => hint = result.data['reply'] as String);
    } on FirebaseFunctionsException catch (e) {
      setState(() => hint = e.message ?? 'Could not get a hint.');
    } catch (e) {
      setState(() => hint = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => loadingHint = false);
    }
  }

  Future<void> completeChallenge() async {
    setState(() => completing = true);

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('completeToday')
          .call({'challengeId': 'today'});

      final alreadyCompleted = result.data['alreadyCompleted'] == true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alreadyCompleted
              ? 'Quest already completed! No extra points awarded.'
              : 'Quest completed! You earned 10 points and First Quest badge!'),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Could not complete quest.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong.')),
        );
      }
    } finally {
      if (mounted) setState(() => completing = false);
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('challenges')
            .doc('today')
            .snapshots(),
        builder: (context, challengeSnapshot) {
          if (challengeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!challengeSnapshot.hasData ||
              !challengeSnapshot.data!.exists) {
            return const Center(child: Text('No challenge available.'));
          }

          final challenge = challengeSnapshot.data!.data()!;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('progress')
                .doc('today')
                .snapshots(),
            builder: (context, progressSnapshot) {
              final progress = progressSnapshot.data?.data();
              final completed = progress?['completed'] == true;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'TODAY’S QUEST',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    challenge['title'] ?? 'Daily Challenge',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    challenge['prompt'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.stars,
                          color: Colors.amber, size: 32),
                      title: Text('Points: ${progress?['points'] ?? 0}'),
                      subtitle: Text(
                        completed
                            ? 'Badge: ${progress?['badgeId'] ?? 'First Quest'}'
                            : 'Complete your quest to earn 10 points!',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AI QUEST COACH',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: questionController,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ask for a hint...',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: loadingHint ? null : getHint,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: Text(loadingHint ? 'Getting hint...' : 'Get Hint'),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(hint!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed:
                        (completed || completing) ? null : completeChallenge,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      completed
                          ? 'Quest Completed'
                          : completing
                              ? 'Completing...'
                              : 'Complete Quest (+10 points)',
                    ),
                  ),
                  if (completed)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '🎉 You earned your First Quest badge!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
