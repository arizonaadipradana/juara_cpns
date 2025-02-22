import 'package:flutter/material.dart';
import 'package:juara_cpns/class/question_model.dart';
import 'package:juara_cpns/screens/question_review_screen.dart';

class ResultScreen extends StatelessWidget {
  final List<Question> questions;
  final Map<String, String> userAnswers;
  final Map<String, int> scores;
  final String type;

  const ResultScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.scores,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil $type'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreSection(),
                  const SizedBox(height: 24),
                  const Text(
                    'Detail Jawaban',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnswerGrid(context),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali ke Menu'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skor Anda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (type == 'FULL') ...[
              _buildScoreRow('TWK', scores['TWK'] ?? 0),
              _buildScoreRow('TIU', scores['TIU'] ?? 0),
              _buildScoreRow('TKP', scores['TKP'] ?? 0),
              const Divider(),
              _buildScoreRow(
                'Total',
                (scores['TWK'] ?? 0) + (scores['TIU'] ?? 0) + (scores['TKP'] ?? 0),
                isTotal: true,
              ),
            ] else
              _buildScoreRow(type, scores[type] ?? 0, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerGrid(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        questions.length,
            (index) {
          final question = questions[index];
          final userAnswer = userAnswers[question.id] ?? '';
          bool isCorrect = false;

          if (question.type == 'TKP') {
            final score = question.tkpScoring[userAnswer] ?? 0;
            isCorrect = score > 0;
          } else {
            isCorrect = userAnswer == question.correctAnswer;
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionReviewScreen(
                    question: question,
                    userAnswer: userAnswer,
                    questionNumber: index,
                  ),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}