import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isDarkMode = false; // Track dark mode state

  // Empty meal journal list
  final List<Map<String, dynamic>> _mealJournal = [];

  final List<String> _moodOptions = [
    'Energized', 'Content', 'Satisfied', 'Neutral', 'Distracted',
    'Stressed', 'Anxious', 'Tired', 'Joyful', 'Rushed'
  ];

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _addMeal() {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _caloriesController = TextEditingController();
    TimeOfDay _selectedTime = TimeOfDay.now();

    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (picked != null && picked != _selectedTime) {
        setState(() {
          _selectedTime = picked;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Meal'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Meal Title'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(labelText: 'Calories'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('Time: '),
                        TextButton(
                          onPressed: () => _selectTime(context),
                          child: Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                        _descriptionController.text.isNotEmpty &&
                        _caloriesController.text.isNotEmpty) {
                      this.setState(() {
                        _mealJournal.add({
                          'title': _titleController.text,
                          'time': _selectedTime.format(context),
                          'meal': _descriptionController.text,
                          'calories': int.parse(_caloriesController.text),
                          'logged': false,
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

    // Theme colors based on dark mode state
    final primaryColor = _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600;
    final secondaryColor = _isDarkMode ? Colors.amber.shade400 : Colors.amber.shade600;
    final backgroundColor = _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final cardColor = _isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('PlannerHut',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
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
            _buildWellnessInsights(primaryColor, secondaryColor, textColor),
            const SizedBox(height: 25),
            _buildHeader(today, primaryColor, textColor, subtitleColor),
            const SizedBox(height: 10),
            _mealJournal.isEmpty
                ? _buildEmptyState(subtitleColor)
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mealJournal.length,
              itemBuilder: (context, index) {
                final meal = _mealJournal[index];
                return _buildMealCard(index, meal, primaryColor, cardColor, textColor, subtitleColor);
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
        unselectedItemColor: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
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

  Widget _buildEmptyState(Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: _isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400
          ),
          const SizedBox(height: 16),
          Text(
            'No meals added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first meal',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessInsights(Color primaryColor, Color secondaryColor, Color textColor) {
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
            color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
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
                  Text(
                    'Try to eat mindfully today. Notice the tastes, textures, and feelings during your meals.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String today, Color primaryColor, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Meal Journal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: textColor,
                  )
              ),
              const SizedBox(height: 4),
              Text(
                  today,
                  style: TextStyle(color: subtitleColor)
              ),
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

  Widget _buildMealCard(int index, Map<String, dynamic> meal, Color primaryColor, Color cardColor, Color textColor, Color subtitleColor) {
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
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLogged ? Colors.teal.shade200 : _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: isLogged ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.restaurant,
                color: primaryColor,
              ),
            ),
            title: Text(
                meal['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                )
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${meal['time']} - ${meal['meal']}',
                  style: TextStyle(color: subtitleColor),
                ),
                Text(
                  'Calories: ${meal['calories']}',
                  style: TextStyle(color: subtitleColor),
                ),
                if (isLogged && meal['mood'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Mood: ${meal['mood']}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: subtitleColor,
                      ),
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
                  Divider(color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                  Text(
                    '${meal['notes']}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: subtitleColor,
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
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final cardColor = _isDarkMode ? Colors.grey.shade800 : Colors.white;
    final backgroundColor = _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(meal['title'], style: TextStyle(color: textColor)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text('Time: ${meal['time']}', style: TextStyle(color: textColor)),
                Text('Description: ${meal['meal']}', style: TextStyle(color: textColor)),
                Text('Calories: ${meal['calories']}', style: TextStyle(color: textColor)),
                if (meal['satisfaction'] != null)
                  Text('Satisfaction: ${meal['satisfaction']}/5', style: TextStyle(color: textColor)),
                if (meal['mood'] != null)
                  Text('Mood: ${meal['mood']}', style: TextStyle(color: textColor)),
                if (meal['notes'] != null && meal['notes'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes:', style: TextStyle(color: textColor)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(meal['notes'], style: TextStyle(color: textColor)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600)),
            ),
            if (!meal['logged'])
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _logMeal(_mealJournal.indexOf(meal));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600,
                ),
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