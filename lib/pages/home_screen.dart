import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/meal_reminder.dart';
import 'profile_page.dart';
import '../screens/meal_reminders_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/grocery_page.dart';
import '../screens/chatbot_page.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false; // Track dark mode state

  final FirestoreService _firestoreService = FirestoreService(); // Add Firestore service

  // New fields for reminders
  final NotificationService _notificationService = NotificationService();
  final List<MealReminder> _mealReminders = [];

  final List<String> _moodOptions = [
    'Energized', 'Content', 'Satisfied', 'Neutral', 'Distracted',
    'Stressed', 'Anxious', 'Tired', 'Joyful', 'Rushed'
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    // Other initialization...

  }

  Future<void> _initializeNotifications() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
    // TODO: Load saved reminders from storage
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _addMeal() {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _caloriesController = TextEditingController();

    // Use a wrapper for the TimeOfDay that can be updated
    final _timeHolder = _TimeHolder(TimeOfDay.now());

    _showMealForm(
      context: context,
      titleController: _titleController,
      descriptionController: _descriptionController,
      caloriesController: _caloriesController,
      timeHolder: _timeHolder,
      onSave: () async {
        if (_titleController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty &&
            _caloriesController.text.isNotEmpty) {
          try {
            await _firestoreService.addMeal(
              title: _titleController.text,
              description: _descriptionController.text,
              time: _timeHolder.time.format(context),
              calories: int.parse(_caloriesController.text),
            );
            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding meal: $e')),
            );
          }
        }
      },
      isEditing: false,
    );
  }

  void _editMeal(String mealId, Map<String, dynamic> meal) {
    final _titleController = TextEditingController(text: meal['title']);
    final _descriptionController = TextEditingController(text: meal['description']);
    final _caloriesController = TextEditingController(text: meal['calories'].toString());
    final _timeHolder = _TimeHolder(_parseTime(meal['time']));

    _showMealForm(
      context: context,
      titleController: _titleController,
      descriptionController: _descriptionController,
      caloriesController: _caloriesController,
      timeHolder: _timeHolder,
      onSave: () async {
        if (_titleController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty &&
            _caloriesController.text.isNotEmpty) {
          try {
            await _firestoreService.updateMeal(
              mealId: mealId,
              title: _titleController.text,
              description: _descriptionController.text,
              time: _timeHolder.time.format(context),
              calories: int.parse(_caloriesController.text),
              logged: meal['logged'],
              satisfaction: meal['satisfaction'],
              mood: meal['mood'],
              notes: meal['notes'],
            );
            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating meal: $e')),
            );
          }
        }
      },
      isEditing: true,
    );
  }

  // Parse the time string back to TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
    try {
      final format = RegExp(r'(\d+):(\d+) ([AP]M)');
      final match = format.firstMatch(timeStr);
      if (match != null) {
        int hour = int.parse(match.group(1) ?? '12');
        final int minute = int.parse(match.group(2) ?? '0');
        final String period = match.group(3) ?? 'AM';

        if (period == 'PM' && hour < 12) hour += 12;
        else if (period == 'AM' && hour == 12) hour = 0;

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return TimeOfDay.now();
    }
    return TimeOfDay.now();
  }



  void _showMealForm({
    required BuildContext context,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required TextEditingController caloriesController,
    required _TimeHolder timeHolder,
    required VoidCallback onSave,
    required bool isEditing,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _selectTime(BuildContext context) async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: timeHolder.time,
              );

              if (picked != null) {
                setState(() {
                  timeHolder.time = picked;
                });
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Meal' : 'Add Meal'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Meal Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: caloriesController,
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
                            timeHolder.time.format(context),
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
                  onPressed: onSave,
                  child: Text(isEditing ? 'Update' : 'Add Meal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _logMeal(String mealId, Map<String, dynamic> meal) {
    if (meal['satisfaction'] == null) {
      _showSatisfactionDialog(mealId, meal);
    } else {
      _firestoreService.updateMeal(
        mealId: mealId,
        title: meal['title'],
        description: meal['description'],
        time: meal['time'],
        calories: meal['calories'],
        logged: !meal['logged'],
        satisfaction: meal['satisfaction'],
        mood: meal['mood'],
        notes: meal['notes'],
      );
    }
  }

  void _showSatisfactionDialog(String mealId, Map<String, dynamic> meal) {
    int? _satisfactionValue = meal['satisfaction'];
    String? _selectedMood = meal['mood'];
    final _notesController = TextEditingController(text: meal['notes'] ?? '');

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
                      _firestoreService.updateMeal(
                        mealId: mealId,
                        title: meal['title'],
                        description: meal['description'],
                        time: meal['time'],
                        calories: meal['calories'],
                        logged: true,
                        satisfaction: _satisfactionValue,
                        mood: _selectedMood,
                        notes: _notesController.text,
                      );
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

  void _deleteMeal(String mealId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteMeal(mealId);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting meal: $e')),
                );
              }
            },
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  int _getLoggedCount(List<Map<String, dynamic>> meals) {
    return meals.where((m) => m['logged'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              _navigateToRemindersManagementScreen();
            },
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getMeals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meals = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

          final loggedCount = _getLoggedCount(meals);
          final totalMeals = meals.length;
          final progress = totalMeals > 0 ? loggedCount / totalMeals : 0.0;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildWellnessInsights(primaryColor, secondaryColor, textColor),
                const SizedBox(height: 25),
                _buildHeader(today, primaryColor, textColor, subtitleColor),
                const SizedBox(height: 10),
                _buildProgressBar(progress),
                const SizedBox(height: 10),
                meals.isEmpty
                    ? _buildEmptyState(subtitleColor)
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return _buildMealCard(index, meal, primaryColor, cardColor, textColor, subtitleColor);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
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
        type: BottomNavigationBarType.fixed, // Added to support 5 items
        onTap: (index) {
          if (index == 1) { // Calendar tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CalendarScreen(reminders: _mealReminders),
              ),
            );
          } else if (index == 2) { // Grocery tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroceryPage(), // Navigate to Grocery Page
              ),
            );
          } else if (index == 3) { // Chatbot tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatbotPage(), // Navigate to Chatbot Page
              ),
            );
          } else {
            setState(() {
              _currentIndex = index; // Update the current index for other tabs
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store_outlined), label: 'Grocery'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    final progressColor = progress < 0.3
        ? Colors.red
        : progress < 0.7
        ? Colors.amber
        : Colors.teal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const Text(
            'Meal Logging Progress',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: progressColor,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of meals logged',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
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
              color: _isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
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
                  )),
              const SizedBox(height: 4),
              Text(today, style: TextStyle(color: subtitleColor)),
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
    final mealId = meal['id'];

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
                  '${meal['time']} - ${meal['description']}',
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLogged)
                  Icon(satisfactionIcon, color: satisfactionColor, size: 24)
                else
                  ElevatedButton(
                    onPressed: () => _logMeal(mealId, meal),
                    child: const Text('Log'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                _buildPopupMenu(mealId, meal),
              ],
            ),
            onTap: () => _showMealDetails(meal, mealId),
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

  // Add the new popup menu builder
  PopupMenuButton<String> _buildPopupMenu(String mealId, Map<String, dynamic> meal) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'reminder',
          child: Row(
            children: [
              Icon(Icons.alarm, size: 20, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Set Reminder'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.teal),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'reminder') {
          _showReminderDialog(mealId, meal);
        } else if (value == 'edit') {
          _editMeal(mealId, meal);
        } else if (value == 'delete') {
          _deleteMeal(mealId);
        }
      },
    );
  }

  // Show reminder dialog
  void _showReminderDialog(String mealId, Map<String, dynamic> meal) {
    final mealTitle = meal['title'];

    TimeOfDay initialTime = _parseTime(meal['time']);
    TimeOfDay selectedTime = initialTime;
    DateTime selectedDate = DateTime.now();
    bool isRepeating = false;
    List<bool> selectedWeekdays = List.filled(7, false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set Reminder for $mealTitle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Repeat?'),
                      value: isRepeating,
                      onChanged: (value) {
                        setState(() {
                          isRepeating = value;
                        });
                      },
                    ),
                    if (isRepeating) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text('Repeat on:'),
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          _buildWeekdayChip(setState, selectedWeekdays, 0, 'M'),
                          _buildWeekdayChip(setState, selectedWeekdays, 1, 'T'),
                          _buildWeekdayChip(setState, selectedWeekdays, 2, 'W'),
                          _buildWeekdayChip(setState, selectedWeekdays, 3, 'T'),
                          _buildWeekdayChip(setState, selectedWeekdays, 4, 'F'),
                          _buildWeekdayChip(setState, selectedWeekdays, 5, 'S'),
                          _buildWeekdayChip(setState, selectedWeekdays, 6, 'S'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveReminder(
                      meal: meal,
                      time: selectedTime,
                      date: selectedDate,
                      isRepeating: isRepeating,
                      weekdays: selectedWeekdays,
                    );
                    Navigator.pop(context);
                    _showReminderConfirmation();
                  },
                  child: const Text('Set Reminder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build weekday selection chip
  Widget _buildWeekdayChip(
      StateSetter setState,
      List<bool> selectedWeekdays,
      int index,
      String label,
      ) {
    return FilterChip(
      label: Text(label),
      selected: selectedWeekdays[index],
      onSelected: (bool selected) {
        setState(() {
          selectedWeekdays[index] = selected;
        });
      },
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal,
    );
  }

  // Save the reminder
  void _saveReminder({
    required Map<String, dynamic> meal,
    required TimeOfDay time,
    required DateTime date,
    required bool isRepeating,
    required List<bool> weekdays,
  }) {
    final int reminderId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // Create the reminder
    final reminderDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Save to the list
    final reminder = MealReminder(
      id: reminderId,
      mealTitle: meal['title'],
      reminderTime: time,
      scheduledDate: reminderDateTime,
      isRepeating: isRepeating,
      weekdays: weekdays,
    );

    setState(() {
      _mealReminders.add(reminder);
    });

    // Schedule the notification
    _scheduleReminder(reminder);

    // TODO: Save to persistent storage in a real app
    // _saveRemindersToStorage();
  }

  // Schedule a reminder notification
  void _scheduleReminder(MealReminder reminder) async {
    final now = DateTime.now();

    if (reminder.isRepeating) {
      // For repeating reminders, schedule for each selected weekday
      for (int i = 0; i < 7; i++) {
        if (reminder.weekdays[i]) {
          // Calculate next occurrence of this weekday
          final nextDate = _getNextDateForWeekday(i);
          final scheduledTime = DateTime(
            nextDate.year,
            nextDate.month,
            nextDate.day,
            reminder.reminderTime.hour,
            reminder.reminderTime.minute,
          );

          // Create a unique ID for each weekday reminder
          final uniqueId = reminder.id + (i * 1000);

          await _notificationService.scheduleMealReminder(
            id: uniqueId,
            title: 'Meal Reminder',
            mealName: reminder.mealTitle,
            scheduledTime: scheduledTime,
            description: 'Time for your ${reminder.mealTitle}!',
          );
        }
      }
    } else {
      // For one-time reminders
      if (reminder.scheduledDate.isAfter(now)) {
        await _notificationService.scheduleMealReminder(
          id: reminder.id,
          title: 'Meal Reminder',
          mealName: reminder.mealTitle,
          scheduledTime: reminder.scheduledDate,
          description: 'Time for your ${reminder.mealTitle}!',
        );
      }
    }
  }

  // Get the next date for a given weekday (0 = Monday, 6 = Sunday)
  DateTime _getNextDateForWeekday(int weekday) {
    DateTime date = DateTime.now();

    // Convert to 1-7 format where 1 is Monday and 7 is Sunday
    int currentWeekday = date.weekday;

    // Convert input weekday from 0-6 to 1-7
    int targetWeekday = weekday + 1;

    // Calculate days to add
    int daysToAdd = targetWeekday - currentWeekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }

    return date.add(Duration(days: daysToAdd));
  }

  // Show confirmation after setting a reminder
  void _showReminderConfirmation() {
    final snackBar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Reminder set successfully!'),
          TextButton(
            onPressed: () {
              _navigateToRemindersManagementScreen();
            },
            child: const Text(
              'VIEW ALL',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'DISMISS',
        onPressed: () {},
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Navigate to reminders management screen
  void _navigateToRemindersManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealRemindersScreen(
          reminders: _mealReminders,
          onDelete: _deleteReminder,
        ),
      ),
    );
  }

  // Delete a reminder
  void _deleteReminder(int id) {
    setState(() {
      _mealReminders.removeWhere((reminder) => reminder.id == id);
    });

    // Cancel the notification
    _notificationService.cancelReminder(id);

    // For repeating reminders, cancel all related weekday reminders
    for (int i = 0; i < 7; i++) {
      _notificationService.cancelReminder(id + (i * 1000));
    }

    // TODO: Save to persistent storage in a real app
    // _saveRemindersToStorage();
  }

  // Show meal details
  void _showMealDetails(Map<String, dynamic> meal, String mealId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isLogged = meal['logged'] == true;
        final primaryColor = _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600;
        final backgroundColor = _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
        final textColor = _isDarkMode ? Colors.white : Colors.black;
        final subtitleColor = _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;

        // Satisfaction emoji and text
        String satisfactionEmoji = '😐';
        String satisfactionText = 'Neutral';

        if (meal['satisfaction'] != null) {
          if (meal['satisfaction'] >= 5) {
            satisfactionEmoji = '😁';
            satisfactionText = 'Excellent';
          } else if (meal['satisfaction'] >= 4) {
            satisfactionEmoji = '🙂';
            satisfactionText = 'Good';
          } else if (meal['satisfaction'] >= 3) {
            satisfactionEmoji = '😐';
            satisfactionText = 'Neutral';
          } else if (meal['satisfaction'] >= 2) {
            satisfactionEmoji = '😕';
            satisfactionText = 'Not Great';
          } else {
            satisfactionEmoji = '😞';
            satisfactionText = 'Poor';
          }
        }

        return Container(
          padding: const EdgeInsets.all(24),
          color: backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    meal['title'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    meal['time'],
                    style: TextStyle(color: subtitleColor),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    '${meal['calories']} calories',
                    style: TextStyle(color: subtitleColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meal['description'],
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              if (isLogged) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Satisfaction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              satisfactionEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$satisfactionText (${meal['satisfaction']}/5)',
                              style: TextStyle(color: subtitleColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (meal['mood'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mood',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              meal['mood'],
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (meal['notes'] != null && meal['notes'].isNotEmpty) ...[
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal['notes'],
                    style: TextStyle(
                      color: textColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logMeal(mealId, meal);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Log This Meal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showReminderDialog(mealId, meal);
                    },
                    icon: const Icon(Icons.alarm),
                    label: const Text('Set Reminder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editMeal(mealId, meal);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(IconData icon, String title, String status, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Helper class for TimeOfDay selection
class _TimeHolder {
  TimeOfDay time;
  _TimeHolder(this.time);
}