import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/class/question_model.dart';

class TryoutScreen extends StatefulWidget {
  final String type;
  final String? packageId;

  const TryoutScreen({
    super.key,
    required this.type,
    this.packageId,
  });

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
  String? errorMessage;
  int totalQuestions = 0; // Add this variable to store total questions

  @override
  void initState() {
    super.initState();
    loadPackageAndQuestions();
  }

  Future<void> loadPackageAndQuestions() async {
    try {
      // First, get the package details to know the total question count
      if (widget.packageId != null) {
        final packageDoc = await FirebaseFirestore.instance
            .collection('practice_packages')
            .doc(widget.packageId)
            .get();

        if (packageDoc.exists) {
          setState(() {
            totalQuestions = packageDoc.data()?['questionCount'] ?? 0;
          });
        }
      }

      // Then load the questions
      await loadQuestions();
    } catch (e) {
      print('Error loading package details: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan saat memuat paket: ${e.toString()}';
      });
    }
  }

  Future<void> loadQuestions() async {
    try {
      Query query = FirebaseFirestore.instance.collection('questions');

      if (widget.packageId != null) {
        query = query.where('packageId', isEqualTo: widget.packageId);
      } else {
        query = query
            .where('type', isEqualTo: widget.type)
            .limit(totalQuestions > 0 ? totalQuestions : 30);
      }

      final questionsSnapshot = await query.get();
      print('Found ${questionsSnapshot.docs.length} questions');

      if (questionsSnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Tidak ada soal tersedia untuk saat ini';
        });
        return;
      }

      // Create list of questions
      List<Question> loadedQuestions = questionsSnapshot.docs
          .map((doc) => Question.fromMap(
          {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      // Shuffle the questions
      loadedQuestions.shuffle();

      // Ensure we don't exceed totalQuestions
      if (totalQuestions > 0 && loadedQuestions.length > totalQuestions) {
        loadedQuestions = loadedQuestions.sublist(0, totalQuestions);
      }

      setState(() {
        questions = loadedQuestions;
        isLoading = false;

        // Update totalQuestions if it wasn't set from package
        if (totalQuestions == 0) {
          totalQuestions = questions.length;
        }

        startTimer();
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan saat memuat soal: ${e.toString()}';
      });
    }
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
          // submitAnswers();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tryout ${widget.type}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tryout ${widget.type}'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tryout ${widget.type}'),
        ),
        body: const Center(
          child: Text('Tidak ada soal tersedia'),
        ),
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
            value: (currentQuestionIndex + 1) / totalQuestions,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soal ${currentQuestionIndex + 1} dari $totalQuestions',
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
                // if (currentQuestionIndex == questions.length - 1)
                //   ElevatedButton(
                //     onPressed: submitAnswers,
                //     child: const Text('Selesai'),
                //   ),
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
