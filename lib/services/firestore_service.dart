import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirestoreService {
  final CollectionReference meals =
      FirebaseFirestore.instance.collection('meals');
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  // READ
  Stream<QuerySnapshot> getMeals() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await meals.doc(mealId).delete();
  }


  Future<void> setOnboardingCompleted() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    print('Setting onboardingCompleted for user: $userId');
    await users.doc(userId).set(
      {'onboardingCompleted': true},
      SetOptions(merge: true),
    );
  }

  Future<bool> isOnboardingCompleted() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    final doc = await users.doc(userId).get();
    print('Firestore doc exists: ${doc.exists}, data: ${doc.data()}');
    return doc.exists && (doc.data() as Map<String, dynamic>)['onboardingCompleted'] == true;
  }

}



