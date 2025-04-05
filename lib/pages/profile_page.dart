import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('assets/images/profile_picture.jpg'), // Replace with your image
            ),
            const SizedBox(height: 20),
            // Name
            Text(
              'Ainor Jamal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Bio
            Text(
              'IT Student at Caraga State University\nPassionate about technology and solving problems.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            // Logout button (UI only, no functionality)
            ElevatedButton(
              onPressed: () {
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, // Set background color here
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle logout operation
  Future<void> _performLogout(BuildContext context) async {
    try {
      await authService.value.signOut();


      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      // Handle any errors during logout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }
}
