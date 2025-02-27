import 'package:flutter/material.dart';
import 'package:juara_cpns/class/question_model.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';

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
    return ResponsiveBuilder(
      builder: (context, constraints, screenSize) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Detail Soal', style: AppTheme.textTheme.headlineMedium),
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
                  _buildQuestionHeader(context),
                  const SizedBox(height: 24),
                  _buildQuestionContent(),
                  const SizedBox(height: 24),
                  _buildAnswerSection(),
                  const SizedBox(height: 24),
                  if (question.explanation != null && question.explanation!.isNotEmpty)
                    _buildExplanationSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionHeader(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      hasShadow: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getQuestionTypeColor(question.type).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getQuestionTypeColor(question.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${questionNumber + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getQuestionTypeColor(question.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.type,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _getQuestionTypeColor(question.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kategori: ${_getQuestionTypeFullName(question.type)}',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    return CustomCard(
      hasShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan',
            style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection() {
    return CustomCard(
      hasShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilihan Jawaban',
            style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...question.options.map((option) {
            final isUserAnswer = option == userAnswer;
            final isCorrectAnswer = option == question.correctAnswer;

            Color backgroundColor = Colors.grey.shade50;
            Color borderColor = Colors.grey.shade300;
            Color textColor = AppTheme.textPrimaryColor;

            if (isUserAnswer) {
              backgroundColor = isCorrectAnswer
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.errorColor.withOpacity(0.1);
              borderColor = isCorrectAnswer ? AppTheme.successColor : AppTheme.errorColor;
              textColor = isCorrectAnswer ? AppTheme.successColor : AppTheme.errorColor;
            } else if (isCorrectAnswer && !isUserAnswer) {
              backgroundColor = AppTheme.successColor.withOpacity(0.05);
              borderColor = AppTheme.successColor.withOpacity(0.5);
              textColor = AppTheme.successColor;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isUserAnswer ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isUserAnswer
                            ? (isCorrectAnswer ? AppTheme.successColor : AppTheme.errorColor)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUserAnswer
                              ? (isCorrectAnswer ? AppTheme.successColor : AppTheme.errorColor)
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isUserAnswer
                          ? Icon(
                        isCorrectAnswer ? Icons.check : Icons.close,
                        size: 16,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          fontWeight: isUserAnswer ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (question.type == 'TKP' && isUserAnswer)
                      Text(
                        'Skor: ${question.tkpScoring[option] ?? 0}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExplanationSection() {
    return CustomCard(
      hasShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pembahasan',
            style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            question.explanation!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'TWK':
        return Colors.blue;
      case 'TIU':
        return Colors.purple;
      case 'TKP':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getQuestionTypeFullName(String type) {
    switch (type) {
      case 'TWK':
        return 'Wawasan Kebangsaan';
      case 'TIU':
        return 'Inteligensia Umum';
      case 'TKP':
        return 'Karakteristik Pribadi';
      default:
        return type;
    }
  }
}