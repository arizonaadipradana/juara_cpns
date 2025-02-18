class Question {
  final String id;
  final String type; // TWK, TIU, or TKP
  final String question;
  final List<String> options;
  final String correctAnswer; // For TWK and TIU
  final Map<String, int> tkpScoring; // For TKP questions

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    this.correctAnswer = '',
    this.tkpScoring = const {},
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      type: map['type'],
      question: map['question'],
      options: List<String>.from(map['options']),
      correctAnswer: map['correctAnswer'] ?? '',
      tkpScoring: Map<String, int>.from(map['tkpScoring'] ?? {}),
    );
  }
}