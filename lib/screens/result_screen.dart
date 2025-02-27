import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juara_cpns/class/question_model.dart';
import 'package:juara_cpns/screens/question_review_screen.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';

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
    return ResponsiveBuilder(
      builder: (context, constraints, screenSize) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Hasil $type', style: AppTheme.textTheme.headlineMedium),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScoreSummary(screenSize),
                  const SizedBox(height: 24),
                  _buildAnswerSummary(context, screenSize),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Kembali ke Menu',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreSummary(ScreenSize screenSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skor Anda',
                style: AppTheme.textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              SvgPicture.asset(
                'assets/icons/trophy.svg',
                width: 40,
                height: 40,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (type == 'FULL') ...[
            _buildScoreRow('TWK', scores['TWK'] ?? 0, Colors.white),
            _buildScoreRow('TIU', scores['TIU'] ?? 0, Colors.white),
            _buildScoreRow('TKP', scores['TKP'] ?? 0, Colors.white),
            const Divider(color: Colors.white30),
            _buildScoreRow(
              'Total',
              (scores['TWK'] ?? 0) + (scores['TIU'] ?? 0) + (scores['TKP'] ?? 0),
              Colors.white,
              isTotal: true,
            ),
          ] else
            _buildScoreRow(type, scores[type] ?? 0, Colors.white, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, Color textColor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            score.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSummary(BuildContext context, ScreenSize screenSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Jawaban',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildAnswerGrid(context),
        ],
      ),
    );
  }

  Widget _buildAnswerGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: questions.length,
      itemBuilder: (context, index) {
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
            decoration: BoxDecoration(
              color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
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
    );
  }
}