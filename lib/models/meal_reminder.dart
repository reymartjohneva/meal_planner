import 'package:flutter/material.dart';

class MealReminder {
  final int id;
  final String mealTitle;
  final TimeOfDay reminderTime;
  final DateTime scheduledDate;
  final bool isRepeating;
  final List<bool> weekdays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

  MealReminder({
    required this.id,
    required this.mealTitle,
    required this.reminderTime,
    required this.scheduledDate,
    this.isRepeating = false,
    this.weekdays = const [false, false, false, false, false, false, false],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealTitle': mealTitle,
      'reminderHour': reminderTime.hour,
      'reminderMinute': reminderTime.minute,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isRepeating': isRepeating,
      'weekdays': weekdays,
    };
  }

  factory MealReminder.fromMap(Map<String, dynamic> map) {
    return MealReminder(
      id: map['id'],
      mealTitle: map['mealTitle'],
      reminderTime: TimeOfDay(
        hour: map['reminderHour'],
        minute: map['reminderMinute'],
      ),
      scheduledDate: DateTime.parse(map['scheduledDate']),
      isRepeating: map['isRepeating'],
      weekdays: List<bool>.from(map['weekdays']),
    );
  }
}