import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom app bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF43A047),
                      Color(0xFF1E88E5),
                    ],
                  ),
                ),
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined),
                onPressed: () {
                  // Settings action
                },
              ),
            ],
          ),

          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Profile picture with decorative ring
                  Transform.translate(
                    offset: Offset(0, -60),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: AssetImage('assets/images/profile_picture.jpg'),
                      ),
                    ),
                  ),

                  // Name with custom styling
                  Text(
                    'Ainor Jamal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF2E3D50),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bio with improved typography
                  Text(
                    'IT Student at Caraga State University',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2E3D50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  Text(
                    'Passionate about technology and solving problems.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Stats cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(context, '12', 'Projects'),
                      _buildStatCard(context, '43', 'Followers'),
                      _buildStatCard(context, '128', 'Following'),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Edit profile action
                          },
                          icon: Icon(Icons.edit_outlined),
                          label: Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Color(0xFF43A047)),
                            foregroundColor: Color(0xFF43A047),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Share profile action
                          },
                          icon: Icon(Icons.share_outlined),
                          label: Text('Share Profile'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Logout button with improved design
                  ElevatedButton.icon(
                    onPressed: () {
                      performLogout(context);
                    },
                    icon: Icon(Icons.logout_rounded),
                    label: Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: Size(double.infinity, 56),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create stat cards
  Widget _buildStatCard(BuildContext context, String value, String label) {
    return Container(
      width: 90,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF43A047),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Function to handle logout operation
  Future<void> performLogout(BuildContext context) async {
    try {
      await authService.value.signOut();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      // Handle any errors during logout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }
}