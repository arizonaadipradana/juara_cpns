import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/class/question_model.dart';
import 'package:juara_cpns/screens/result_screen.dart';

class TryoutScreen extends StatefulWidget {
  final String type;
  final String? packageId;
  final Set<String> markedQuestions = {};

  TryoutScreen({
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
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool canSubmit = false;

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

  Future<void> submitAnswers() async {
    if (userId.isEmpty) return;

    try {
      // Calculate scores
      Map<String, int> scores = {};
      int twkScore = 0, tiuScore = 0, tkpScore = 0;

      for (var question in questions) {
        final userAnswer = userAnswers[question.id];
        if (userAnswer == null) continue;

        if (question.type == 'TKP') {
          tkpScore += question.tkpScoring[userAnswer] ?? 0;
        } else {
          if (userAnswer == question.correctAnswer) {
            if (question.type == 'TWK') {
              twkScore += 5;
            } else if (question.type == 'TIU') {
              tiuScore += 5;
            }
          }
        }
      }

      scores = {
        'TWK': twkScore,
        'TIU': tiuScore,
        'TKP': tkpScore,
      };

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('user_answers')
          .doc('${userId}_${widget.packageId ?? widget.type}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'userId': userId,
        'packageId': widget.packageId,
        'type': widget.type,
        'answers': userAnswers,
        'scores': scores,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Navigate to result screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              questions: questions,
              userAnswers: userAnswers,
              scores: scores,
              type: widget.type,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting answers: $e')),
        );
      }
    }
  }

  Future<void> saveProgress() async {
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_progress')
          .doc('${userId}_${widget.packageId ?? widget.type}')
          .set({
        'userId': userId,
        'packageId': widget.packageId,
        'type': widget.type,
        'answers': userAnswers,
        'markedQuestions': widget.markedQuestions.toList(), // Add this line
        'lastQuestionIndex': currentQuestionIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving progress: $e');
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

  double _calculateProgress() {
    if (questions.isEmpty) return 0.0;
    return userAnswers.length / questions.length;
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
          Column(
            children: [
              LinearProgressIndicator(
                value: _calculateProgress(),
                backgroundColor: Colors.grey[200],
                color: Colors.green, // Use green to match answered questions
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${userAnswers.length}/$totalQuestions soal dijawab',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildQuestionIndicators(), // Add this line
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
                          canSubmit = userAnswers.length == questions.length;
                        });
                        saveProgress();
                      },
                    );
                  }),
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
                      saveProgress();
                    },
                    child: const Text('Selanjutnya'),
                  ),
                if (currentQuestionIndex == questions.length - 1 && canSubmit)
                  ElevatedButton(
                    onPressed: submitAnswers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('Selesai'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _markQuestions(List<Question> question){
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          if (widget.markedQuestions.contains(question[currentQuestionIndex].id)) {
            widget.markedQuestions.remove(question[currentQuestionIndex].id);
          } else {
            widget.markedQuestions.add(question[currentQuestionIndex].id);
          }
        });
        saveProgress(); // Update to include marked questions
      },
      icon: Icon(
        widget.markedQuestions.contains(question[currentQuestionIndex].id)
            ? Icons.bookmark
            : Icons.bookmark_border,
      ),
      label: Text(
          widget.markedQuestions.contains(question[currentQuestionIndex].id)
              ? 'Hapus Tanda'
              : 'Tandai Soal'
      )
    );
  }

  Widget _buildQuestionIndicators() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text(
            'Status Soal:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              questions.length,
                  (index) {
                final question = questions[index];
                Color backgroundColor;
                Color textColor = Colors.white;

                if (widget.markedQuestions.contains(question.id)) {
                  backgroundColor = Colors.orange; // Marked question
                } else if (userAnswers.containsKey(question.id)) {
                  backgroundColor = Colors.green; // Answered
                } else {
                  backgroundColor = Colors.grey.shade300; // Unanswered
                  textColor = Colors.black;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentQuestionIndex = index;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        if (index == currentQuestionIndex)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _markQuestions(questions),
              const SizedBox(width: 16),
              _buildIndicatorLegend(Colors.green, 'Sudah dijawab'),
              const SizedBox(width: 16),
              _buildIndicatorLegend(Colors.orange, 'Ditandai'),
              const SizedBox(width: 16),
              _buildIndicatorLegend(Colors.grey.shade300, 'Belum dijawab'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
