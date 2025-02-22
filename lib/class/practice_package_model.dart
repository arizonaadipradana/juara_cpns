import 'package:cloud_firestore/cloud_firestore.dart';

class PracticePackage {
  final String id;
  final String title;
  final String type;
  final int questionCount;
  final int duration;
  final bool isLocked;
  final int price;
  final int order;
  final bool isActive;
  final DateTime lastUpdated;

  PracticePackage({
    required this.id,
    required this.title,
    required this.type,
    required this.questionCount,
    required this.duration,
    required this.isLocked,
    required this.price,
    required this.order,
    required this.isActive,
    required this.lastUpdated,
  });

  factory PracticePackage.fromMap(Map<String, dynamic> map, String id) {
    return PracticePackage(
      id: id,
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      questionCount: map['questionCount'] ?? 0,
      duration: map['duration'] ?? 0,
      isLocked: map['isLocked'] ?? false,
      price: map['price'] ?? 0,
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'questionCount': questionCount,
      'duration': duration,
      'isLocked': isLocked,
      'price': price,
      'order': order,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}