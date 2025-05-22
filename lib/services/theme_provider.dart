import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _isDarkMode = doc.data()?['isDarkMode'] ?? false;
          notifyListeners();
        }
      } catch (e) {
        print('Error loading theme preference: $e');
      }
    }
  }

  Future<void> _saveThemePreference() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set(
          {'isDarkMode': _isDarkMode},
          SetOptions(merge: true),
        );
      } catch (e) {
        print('Error saving theme preference: $e');
      }
    }
  }
}