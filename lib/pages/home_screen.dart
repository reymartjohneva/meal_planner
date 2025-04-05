import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'profile_page.dart'; // Import the ProfilePage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _todayMeals = [
    {
      'title': 'Breakfast',
      'time': '8:00 AM',
      'meal': 'Greek Yogurt with Berries',
      'calories': 320,
      'image': 'breakfast.png',
      'completed': true,
    },
    {
      'title': 'Lunch',
      'time': '12:30 PM',
      'meal': 'Grilled Chicken Salad',
      'calories': 450,
      'image': 'lunch.png',
      'completed': false,
    },
    {
      'title': 'Snack',
      'time': '4:00 PM',
      'meal': 'Apple with Almond Butter',
      'calories': 220,
      'image': 'snack.png',
      'completed': false,
    },
    {
      'title': 'Dinner',
      'time': '7:00 PM',
      'meal': 'Salmon with Roasted Vegetables',
      'calories': 580,
      'image': 'dinner.png',
      'completed': false,
    },
  ];

  void _addMeal() {
    final _titleController = TextEditingController();
    final _timeController = TextEditingController();
    final _mealController = TextEditingController();
    final _caloriesController = TextEditingController();
    final _imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Meal'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Meal Title'),
                ),
                TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                TextField(
                  controller: _mealController,
                  decoration: const InputDecoration(labelText: 'Meal Description'),
                ),
                TextField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
                TextField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: 'Image Filename'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty &&
                    _mealController.text.isNotEmpty &&
                    _caloriesController.text.isNotEmpty &&
                    _imageController.text.isNotEmpty) {
                  setState(() {
                    _todayMeals.add({
                      'title': _titleController.text,
                      'time': _timeController.text,
                      'meal': _mealController.text,
                      'calories': int.tryParse(_caloriesController.text) ?? 0,
                      'image': _imageController.text,
                      'completed': false,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Meal'),
            ),
          ],
        );
      },
    );
  }

  void _toggleComplete(int index) {
    setState(() {
      _todayMeals[index]['completed'] = !_todayMeals[index]['completed'];
    });
  }

  double _calculateProgress() {
    if (_todayMeals.isEmpty) return 0;
    final completed = _todayMeals.where((m) => m['completed'] == true).length;
    return completed / _todayMeals.length;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final today = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    final primaryColor = Colors.green.shade600;
    final secondaryColor = Colors.amber.shade700;
    final backgroundColor = Colors.grey.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Meal Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // Navigate to profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopStats(progress, primaryColor, secondaryColor),
            const SizedBox(height: 25),
            _buildHeader(today, primaryColor),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayMeals.length,
              itemBuilder: (context, index) {
                final meal = _todayMeals[index];
                return _buildMealCard(index, meal, primaryColor);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMeal,
        backgroundColor: secondaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Grocery'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildTopStats(double progress, Color primaryColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(Icons.local_fire_department, '1570', 'Calories', Colors.deepOrange.shade400),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
              _buildStatCard(Icons.fitness_center, '65g', 'Protein', Colors.red.shade300),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
              _buildStatCard(Icons.water_drop, '1.6L', 'Water', Colors.blue.shade300),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                height: 16,
                width: MediaQuery.of(context).size.width * progress * 0.85,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryColor, Colors.amber.shade300],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String today, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Today\'s Meals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 4),
              Text(today, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _addMeal,
            icon: Icon(Icons.add, size: 18, color: primaryColor),
            label: Text('Add Meal', style: TextStyle(color: primaryColor)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(int index, Map<String, dynamic> meal, Color primaryColor) {
    final isCompleted = meal['completed'] == true;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: isCompleted ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isCompleted ? Colors.grey.shade300 : primaryColor.withOpacity(0.7)),
      ),
      color: isCompleted ? Colors.grey.shade50 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage('assets/images/${meal['image']}'),
        ),
        title: Text(meal['title'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${meal['time']} - ${meal['meal']}'),
        trailing: IconButton(
          icon: Icon(isCompleted ? Icons.check_circle : Icons.check_circle_outline, color: primaryColor),
          onPressed: () => _toggleComplete(index),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8))),
      ],
    );
  }
}
