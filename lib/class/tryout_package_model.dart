class TryoutPackage {
  final String id;
  final String name;
  final int price;
  final bool isLocked;
  final Map<String, int> questions;
  final int duration;
  final String description;

  TryoutPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.isLocked,
    required this.questions,
    required this.duration,
    required this.description,
  });

  factory TryoutPackage.fromMap(Map<String, dynamic> map) {
    return TryoutPackage(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      isLocked: map['isLocked'],
      questions: Map<String, int>.from(map['questions']),
      duration: map['duration'],
      description: map['description'],
    );
  }
}