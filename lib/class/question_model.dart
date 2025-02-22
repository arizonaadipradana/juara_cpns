class Question {
  final String id;
  final String type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final Map<String, int> tkpScoring;
  final String? packageId;
  final String? explanation; // Add this field

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    this.correctAnswer = '',
    this.tkpScoring = const {},
    this.packageId,
    this.explanation, // Add this parameter
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      type: map['type'],
      question: map['question'],
      options: List<String>.from(map['options']),
      correctAnswer: map['correctAnswer'] ?? '',
      tkpScoring: Map<String, int>.from(map['tkpScoring'] ?? {}),
      packageId: map['packageId'],
      explanation: map['explanation'], // Add this field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'tkpScoring': tkpScoring,
      'packageId': packageId,
      'explanation': explanation, // Add this field
    };
  }
}