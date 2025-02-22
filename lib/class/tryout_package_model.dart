// lib/models/tryout_package_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juara_cpns/class/practice_package_model.dart';

class TryoutPackage {
  final String id;
  final String name;
  final String description;
  final int price;
  final int duration;
  final bool isLocked;
  final Map<String, int> questions;
  final bool isActive;
  final DateTime lastUpdated;

  TryoutPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.isLocked,
    required this.questions,
    required this.isActive,
    required this.lastUpdated,
  });

  factory TryoutPackage.fromMap(Map<String, dynamic> map, String id) {
    return TryoutPackage(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? 0,
      duration: map['duration'] ?? 0,
      isLocked: map['isLocked'] ?? true,
      questions: Map<String, int>.from(map['questions'] ?? {}),
      isActive: map['isActive'] ?? true,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'isLocked': isLocked,
      'questions': questions,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Convert to PracticePackage format for payment processing
  PracticePackage toPracticePackage() {
    return PracticePackage(
      id: id,
      title: name,
      type: 'FULL',
      questionCount: questions.values.fold(0, (sum, count) => sum + count),
      duration: duration,
      isLocked: isLocked,
      price: price,
      order: 0,
      isActive: isActive,
      lastUpdated: lastUpdated,
    );
  }
}