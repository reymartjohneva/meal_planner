import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Empty meal journal list
  final List<Map<String, dynamic>> _mealJournal = [];

  final List<String> _moodOptions = [
    'Energized', 'Content', 'Satisfied', 'Neutral', 'Distracted',
    'Stressed', 'Anxious', 'Tired', 'Joyful', 'Rushed'
  ];

  void _addMeal() {
    final _titleController = TextEditingController();
    final _timeController = TextEditingController();
    final _mealController = TextEditingController();
    final _notesController = TextEditingController();
    final _imageController = TextEditingController();
    int? _satisfactionValue;
    String? _selectedMood;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Meal Experience'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      decoration: const InputDecoration(labelText: 'What did you eat?'),
                    ),
                    const SizedBox(height: 15),
                    const Text('How satisfied were you? (1-5)'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _satisfactionValue = index + 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _satisfactionValue == index + 1
                                  ? Colors.teal.shade300
                                  : Colors.grey.shade200,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: _satisfactionValue == index + 1
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 15),
                    const Text('How did you feel?'),
                    DropdownButtonFormField<String>(
                      value: _selectedMood,
                      hint: const Text('Select mood'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMood = newValue;
                        });
                      },
                      items: _moodOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes on your experience',
                        hintText: 'How did the meal make you feel?',
                      ),
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
                        _mealController.text.isNotEmpty) {
                      setState(() {
                        _mealJournal.add({
                          'title': _titleController.text,
                          'time': _timeController.text,
                          'meal': _mealController.text,
                          'satisfaction': _satisfactionValue,
                          'mood': _selectedMood,
                          'notes': _notesController.text,
                          'image': _imageController.text.isNotEmpty
                              ? _imageController.text
                              : 'default_meal.png',
                          'logged': false,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Experience'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _logMeal(int index) {
    if (_mealJournal[index]['satisfaction'] == null) {
      _showSatisfactionDialog(index);
    } else {
      setState(() {
        _mealJournal[index]['logged'] = !_mealJournal[index]['logged'];
      });
    }
  }

  void _showSatisfactionDialog(int index) {
    int? _satisfactionValue = _mealJournal[index]['satisfaction'];
    String? _selectedMood = _mealJournal[index]['mood'];
    final _notesController = TextEditingController(text: _mealJournal[index]['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('How was your meal?'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How satisfied were you? (1-5)'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _satisfactionValue = index + 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _satisfactionValue == index + 1
                                  ? Colors.teal.shade300
                                  : Colors.grey.shade200,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: _satisfactionValue == index + 1
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 15),
                    const Text('How did you feel?'),
                    DropdownButtonFormField<String>(
                      value: _selectedMood,
                      hint: const Text('Select mood'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMood = newValue;
                        });
                      },
                      items: _moodOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes on your experience',
                        hintText: 'How did the meal make you feel?',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_satisfactionValue != null) {
                      this.setState(() {
                        _mealJournal[index]['satisfaction'] = _satisfactionValue;
                        _mealJournal[index]['mood'] = _selectedMood;
                        _mealJournal[index]['notes'] = _notesController.text;
                        _mealJournal[index]['logged'] = true;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _getLoggedCount() {
    return _mealJournal.where((m) => m['logged'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    final loggedCount = _getLoggedCount();
    final today = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    final primaryColor = Colors.teal.shade600;
    final secondaryColor = Colors.amber.shade600;
    final backgroundColor = Colors.grey.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('PlannerHut',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
            _buildWellnessInsights(primaryColor, secondaryColor),
            const SizedBox(height: 25),
            _buildHeader(today, primaryColor),
            const SizedBox(height: 10),
            _mealJournal.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mealJournal.length,
              itemBuilder: (context, index) {
                final meal = _mealJournal[index];
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Journal'),
          BottomNavigationBarItem(icon: Icon(Icons.self_improvement_outlined), label: 'Wellness'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: Colors.grey.shade400
          ),
          const SizedBox(height: 16),
          Text(
            'No meals added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first meal experience',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessInsights(Color primaryColor, Color secondaryColor) {
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
          const Text(
            'Your Wellness Journey',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightCard(Icons.favorite_outline, 'Body Trust', 'Developing', Colors.pink.shade300),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
              _buildInsightCard(Icons.self_improvement_outlined, 'Mindfulness', 'Growing', Colors.amber.shade300),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
              _buildInsightCard(Icons.emoji_emotions_outlined, 'Satisfaction', 'Neutral', Colors.blue.shade300),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Wellness Tip',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try to eat mindfully today. Notice the tastes, textures, and feelings during your meals.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
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
              const Text('Meal Journal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
    final isLogged = meal['logged'] == true;

    // Icon and color for satisfaction rating
    IconData satisfactionIcon = Icons.sentiment_neutral;
    Color satisfactionColor = Colors.grey;

    if (meal['satisfaction'] != null) {
      if (meal['satisfaction'] >= 4) {
        satisfactionIcon = Icons.sentiment_very_satisfied;
        satisfactionColor = Colors.green;
      } else if (meal['satisfaction'] >= 3) {
        satisfactionIcon = Icons.sentiment_satisfied;
        satisfactionColor = Colors.amber;
      } else if (meal['satisfaction'] >= 2) {
        satisfactionIcon = Icons.sentiment_neutral;
        satisfactionColor = Colors.orange;
      } else {
        satisfactionIcon = Icons.sentiment_dissatisfied;
        satisfactionColor = Colors.red;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLogged ? Colors.teal.shade200 : Colors.grey.shade300,
          width: isLogged ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/${meal['image']}'),
            ),
            title: Text(meal['title'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${meal['time']} - ${meal['meal']}'),
                if (isLogged && meal['mood'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Mood: ${meal['mood']}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
            trailing: isLogged
                ? Icon(satisfactionIcon, color: satisfactionColor, size: 30)
                : ElevatedButton(
              onPressed: () => _logMeal(index),
              child: const Text('Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            onTap: () => _showMealDetails(meal),
          ),
          if (isLogged && meal['notes'] != null && meal['notes'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(
                    '${meal['notes']}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showMealDetails(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(meal['title']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (meal['image'] != null)
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: AssetImage('assets/images/${meal['image']}'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Time: ${meal['time']}'),
                Text('Food: ${meal['meal']}'),
                if (meal['satisfaction'] != null)
                  Text('Satisfaction: ${meal['satisfaction']}/5'),
                if (meal['mood'] != null)
                  Text('Mood: ${meal['mood']}'),
                if (meal['notes'] != null && meal['notes'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Notes:'),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(meal['notes']),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (!meal['logged'])
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _logMeal(_mealJournal.indexOf(meal));
                },
                child: const Text('Log Meal'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
      ],
    );
  }
}