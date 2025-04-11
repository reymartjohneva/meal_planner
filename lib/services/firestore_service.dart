import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirestoreService {
  final CollectionReference meals =
      FirebaseFirestore.instance.collection('meals');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // READ
  Stream<QuerySnapshot> getMeals() {
    if (userId == null) throw Exception('User not authenticated');

    return meals
        .where('userId', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // CREATE
  Future<void> addMeal({
    required String mealType,
    required String description,
    required int calories,
    required DateTime dateTime,
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    await meals.add({
      'mealType': mealType,
      'description': description,
      'calories': calories,
      'dateTime': Timestamp.fromDate(dateTime),
      'userId': userId,
      'logged': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE
  Future<void> updateMeal({
    required String mealId,
    required String mealType,
    required String description,
    required int calories,
    required DateTime dateTime,
    required bool logged,
    int? satisfaction,
    String? mood,
    String? notes,
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    Map<String, dynamic> data = {
      'mealType': mealType,
      'description': description,
      'calories': calories,
      'dateTime': Timestamp.fromDate(dateTime),
      'logged': logged,
      'userId': userId,
    };
    if (satisfaction != null) data['satisfaction'] = satisfaction;
    if (mood != null) data['mood'] = mood;
    if (notes != null) data['notes'] = notes;

    await meals.doc(mealId).update(data);
  }

  // DELETE
  Future<void> deleteMeal(String mealId) async {
    if (userId == null) throw Exception('User not authenticated');

    await meals.doc(mealId).delete();
  }

}




