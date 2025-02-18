import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:juara_cpns/class/question_model.dart';

class TryoutScreen extends StatefulWidget {
  final String type; // 'TWK', 'TIU', or 'TKP'

  const TryoutScreen({Key? key, required this.type}) : super(key: key);

  @override
  _TryoutScreenState createState() => _TryoutScreenState();
}

class _TryoutScreenState extends State<TryoutScreen> {
  List<Question> questions = [];
  Map<String, String> userAnswers = {};
  int currentQuestionIndex = 0;
  Timer? timer;
  int remainingSeconds = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQuestions();
    startTimer();
  }

  void startTimer() {
    // Set duration based on question type
    int duration;
    switch (widget.type) {
      case 'TWK':
        duration = 30 * 60; // 30 minutes
        break;
      case 'TIU':
        duration = 35 * 60; // 35 minutes
        break;
      case 'TKP':
        duration = 35 * 60; // 35 minutes
        break;
      default:
        duration = 100 * 60; // 100 minutes for full tryout
    }

    remainingSeconds = duration;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          submitAnswers();
        }
      });
    });
  }

  Future<void> loadQuestions() async {
    final questionsSnapshot = await FirebaseFirestore.instance
        .collection('questions')
        .where('type', isEqualTo: widget.type)
        .get();

    setState(() {
      questions = questionsSnapshot.docs
          .map((doc) => Question.fromMap(doc.data()))
          .toList();
      isLoading = false;
    });
  }

  Future<void> submitAnswers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    int score = 0;
    for (var question in questions) {
      final userAnswer = userAnswers[question.id];
      if (userAnswer == null) continue;

      if (question.type == 'TKP') {
        score += question.tkpScoring[userAnswer] ?? 0;
      } else {
        score += userAnswer == question.correctAnswer ? 5 : 0;
      }
    }

    await FirebaseFirestore.instance
        .collection('user_answers')
        .doc(user.uid)
        .collection('attempts')
        .add({
      'type': widget.type,
      'score': score,
      'answers': userAnswers,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // if (mounted) {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(
    //       builder: (context) => ResultScreen(
    //         score: score,
    //         type: widget.type,
    //       ),
    //     ),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Tryout ${widget.type}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: currentQuestionIndex / questions.length,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soal ${currentQuestionIndex + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.question,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ...question.options.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: userAnswers[question.id],
                      onChanged: (value) {
                        setState(() {
                          userAnswers[question.id] = value!;
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex--;
                      });
                    },
                    child: const Text('Sebelumnya'),
                  ),
                if (currentQuestionIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex++;
                      });
                    },
                    child: const Text('Selanjutnya'),
                  ),
                if (currentQuestionIndex == questions.length - 1)
                  ElevatedButton(
                    onPressed: submitAnswers,
                    child: const Text('Selesai'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}