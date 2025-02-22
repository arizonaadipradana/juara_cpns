// question_review_screen.dart
import 'package:flutter/material.dart';
import 'package:juara_cpns/class/question_model.dart';

class QuestionReviewScreen extends StatelessWidget {
  final Question question;
  final String userAnswer;
  final int questionNumber;

  const QuestionReviewScreen({
    super.key,
    required this.question,
    required this.userAnswer,
    required this.questionNumber,
  });

  @override
  Widget build(BuildContext context) {
    bool isCorrect = false;
    int scoreValue = 0;

    // Determine if answer is correct and get score
    if (question.type == 'TKP') {
      scoreValue = question.tkpScoring[userAnswer] ?? 0;
      isCorrect = scoreValue > 0;
    } else {
      isCorrect = userAnswer == question.correctAnswer;
      scoreValue = isCorrect ? 5 : 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Soal ${questionNumber + 1}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Tipe: ${question.type}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Question Text
            const Text(
              'Pertanyaan:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Options with highlighting
            const Text(
              'Pilihan Jawaban:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...question.options.map((option) {
              Color? backgroundColor;
              Color? textColor;

              if (option == userAnswer) {
                backgroundColor = isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
                textColor = isCorrect ? Colors.green : Colors.red;
              } else if (option == question.correctAnswer && !isCorrect && question.type != 'TKP') {
                backgroundColor = Colors.green.withOpacity(0.1);
                textColor = Colors.green;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(
                    color: backgroundColor ?? Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (option == userAnswer)
                      Icon(
                        Icons.check_circle,
                        color: textColor,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: option == userAnswer || option == question.correctAnswer
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (question.type == 'TKP' && option == userAnswer)
                      Text(
                        'Skor: ${question.tkpScoring[option]}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // Score Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (question.type != 'TKP')
                    Text(
                      isCorrect ? 'Jawaban Benar (+5 poin)' : 'Jawaban Salah (0 poin)',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    )
                  else
                    Text(
                      'Skor: $scoreValue poin',
                      style: TextStyle(
                        color: scoreValue > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Explanation (if available)
            if (question.explanation != null && question.explanation!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pembahasan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(question.explanation!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}