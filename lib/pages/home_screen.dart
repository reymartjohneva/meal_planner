import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/meal_reminder.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

import '../screens/calendar_screen.dart';
import '../screens/grocery_page.dart';
import '../screens/chatbot_page.dart';

// Helper class to hold DateTime
class _DateTimeHolder {
  DateTime dateTime;
  _DateTimeHolder(this.dateTime);
}

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

  final List<String> _mealTypeOptions = [
    'Breakfast',
    'Lunch',
    'Snack',
    'Dinner',
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

  void _addMeal() {
    final _descriptionController = TextEditingController();
    final _caloriesController = TextEditingController();

    // Use a wrapper for the TimeOfDay that can be updated
    final _dateTimeHolder = _DateTimeHolder(DateTime.now());

    _showMealForm(
      context: context,
      selectedMealType: null,
      descriptionController: _descriptionController,
      caloriesController: _caloriesController,
      dateTimeHolder: _dateTimeHolder,
      onSave: (String? updatedMealType) async {

        print('Updated Meal Type: $updatedMealType');
        print('Description: ${_descriptionController.text}');
        print('Calories: ${_caloriesController.text}');

        if (updatedMealType != null &&
            _descriptionController.text.isNotEmpty &&
            _caloriesController.text.isNotEmpty) {
          try {
            await _firestoreService.addMeal(
              mealType: updatedMealType,
              description: _descriptionController.text,
              dateTime: _dateTimeHolder.dateTime,
              calories: int.parse(_caloriesController.text),
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meal added successfully!'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding meal: $e'),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red, // Optional: Highlight error
              ),
            );
          }
        } else {
          // Show validation error if fields are missing
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill in all fields'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange, // Optional: Warning color
            ),
          );
        }
      },
      isEditing: false,
    );
  }

  void _editMeal(String mealId, Map<String, dynamic> meal) {
    final _descriptionController = TextEditingController(text: meal['description']);
    final _caloriesController = TextEditingController(text: meal['calories'].toString());
    final dateTime = meal['dateTime'] != null
        ? (meal['dateTime'] as Timestamp).toDate()
        : DateTime.now();
    final _dateTimeHolder = _DateTimeHolder(dateTime);

    _showMealForm(
      context: context,
        selectedMealType: meal['mealType'],
      descriptionController: _descriptionController,
      caloriesController: _caloriesController,
      dateTimeHolder: _dateTimeHolder,
      onSave: (String? updatedMealType) async {
        if (updatedMealType != null &&
            _descriptionController.text.isNotEmpty &&
            _caloriesController.text.isNotEmpty) {
          try {
            await _firestoreService.updateMeal(
              mealId: mealId,
              mealType: updatedMealType,
              description: _descriptionController.text,
              dateTime: _dateTimeHolder.dateTime,
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

  void _showMealForm({
    required BuildContext context,
    required String? selectedMealType,
    required TextEditingController descriptionController,
    required TextEditingController caloriesController,
    required _DateTimeHolder dateTimeHolder,
    required Future<void> Function(String?) onSave,
    required bool isEditing,
  }) {
    String? _localSelectedMealType = selectedMealType;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            String _formatDateTimeDisplay() {
              final dt = dateTimeHolder.dateTime;
              final date = "${dt.day}/${dt.month}/${dt.year}";
              final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
              final minute = dt.minute.toString().padLeft(2, '0');
              final period = dt.hour >= 12 ? 'PM' : 'AM';
              return "$date at $hour:$minute $period";
            }

            // Method to select date and time together
            Future<void> _selectDateTime(BuildContext context) async {

              final DateTime now = DateTime.now();
              final DateTime initialDate = dateTimeHolder.dateTime.isBefore(now) ? now : dateTimeHolder.dateTime;


              // First select date
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: now, // Set firstDate to today, preventing selection of past dates
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (pickedDate != null) {
                // Then select time
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(dateTimeHolder.dateTime),
                );

                if (pickedTime != null) {
                  // Combine date and time
                    final DateTime selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                    );

                    if (selectedDateTime.isBefore(now)) {
                      // Show error message if selected time is in the past
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot set meal time in the past. Using current time instead.'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      // Use current time instead
                      setState(() {
                        dateTimeHolder.dateTime = now;
                      });
                    } else {
                      setState(() {
                        dateTimeHolder.dateTime = selectedDateTime;
                      });
                    }
                }
              }
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEditing ? 'Edit Meal' : 'Add Meal',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMealType,
                      hint: Text(
                        'Select Meal Type',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _localSelectedMealType = newValue;
                          print('Dropdown changed to: $_localSelectedMealType');
                        });
                      },
                      items: _mealTypeOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'Meal Type',
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.white,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: caloriesController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Calories',
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 20),

                    InkWell(
                      onTap: () => _selectDateTime(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date & Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTimeDisplay(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    print('Before saving, selected meal type: $_localSelectedMealType'); // Debug
                    await onSave(_localSelectedMealType);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
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
      final dateTime = meal['dateTime'] != null
          ? (meal['dateTime'] as Timestamp).toDate()
          : DateTime.now();
      _firestoreService.updateMeal(
        mealId: mealId,
        mealType: meal['mealType'],
        description: meal['description'],
        dateTime: dateTime,
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
                      final dateTime = meal['dateTime'] != null
                          ? (meal['dateTime'] as Timestamp).toDate()
                          : DateTime.now();
                      _firestoreService.updateMeal(
                        mealId: mealId,
                        mealType: meal['mealType'],
                        description: meal['description'],
                        dateTime: dateTime,
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PlannerHut',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Add this line to remove the back button
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme() ,
            tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
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
                _buildWellnessInsights(),
                const SizedBox(height: 25),
                _buildHeader(today),
                const SizedBox(height: 10),
                _buildProgressBar(progress),
                const SizedBox(height: 10),
                meals.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return _buildMealCard(index, meal);
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
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
        backgroundColor: Theme.of(context).cardColor,
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chatbot'),

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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'No meals added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first meal',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildWellnessInsights() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
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
            color: Theme.of(context).cardColor,
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
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try to eat mindfully today. Notice the tastes, textures, and feelings during your meals.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String today) {
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
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  )),
              const SizedBox(height: 4),
              Text(today, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _addMeal,
            icon: Icon(Icons.add, size: 18),
            label: Text('Add Meal'),
            style: Theme.of(context).outlinedButtonTheme.style,
            ),
        ],
      ),
    );
  }

  Widget _buildMealCard(int index, Map<String, dynamic> meal) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLogged = meal['logged'] == true;
    final mealId = meal['id'];

    final mealDateTime = meal['dateTime'] != null
        ? (meal['dateTime'] as Timestamp).toDate()
        : DateTime.now();
    final formatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final dateTimeStr = '${formatter.format(mealDateTime)} at ${timeFormatter.format(mealDateTime)}';

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

    return GestureDetector(
      onTap: () => _showMealDetails(meal, mealId),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Theme.of(context).primaryColor.withOpacity(0.1),
            ]
                : [
              Theme.of(context).primaryColor.withOpacity(0.15),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLogged
                ? Colors.teal.shade200
                : Theme.of(context).primaryColor.withOpacity(isDarkMode ? 0.3 : 0.2),
            width: isLogged ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal['mealType'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      if (isLogged)
                        Icon(
                          satisfactionIcon,
                          color: satisfactionColor,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateTimeStr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Calories: ${meal['calories']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isLogged && meal['mood'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Mood: ${meal['mood']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (isLogged && meal['notes'] != null && meal['notes'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${meal['notes']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  // Add the new popup menu builder

  // Show reminder dialog
  void _showReminderConfirmationDialog(String mealId, Map<String, dynamic> meal) {
    final mealTitle = meal['mealType'];
    final mealDateTime = meal['dateTime'] != null
        ? (meal['dateTime'] as Timestamp).toDate()
        : DateTime.now();

    // Format date and time for display
    final formatter = DateFormat('EEEE, MMMM d');
    final timeFormatter = DateFormat('h:mm a');
    final dateTimeStr = '${formatter.format(mealDateTime)} at ${timeFormatter.format(mealDateTime)}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Reminder for $mealTitle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to set a reminder for:'),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(mealTitle),
                subtitle: Text(dateTimeStr),
              ),
              const SizedBox(height: 8),
              Text('Reminder will be set for the time you entered when adding this meal.'),
            ],
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
                  mealId: mealId,
                );
                Navigator.pop(context);
                _showReminderSetConfirmation();
              },
              child: const Text('Set Reminder'),
            ),
          ],
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

  void _showReminderSetConfirmation() {
    final snackBar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Reminder set successfully!'),

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

  // Save the reminder
  void _saveReminder({
    required Map<String, dynamic> meal,
    required String mealId,
  }) {
    final int reminderId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final mealDateTime = meal['dateTime'] != null
        ? (meal['dateTime'] as Timestamp).toDate()
        : DateTime.now();

    final reminderTime = TimeOfDay(
      hour: mealDateTime.hour,
      minute: mealDateTime.minute,
    );

    // Create the reminder object
    final reminder = MealReminder(
      id: reminderId,
      mealId: mealId,
      mealTitle: meal['mealType'],
      description: meal['description'],
      reminderTime: reminderTime,
      scheduledDate: mealDateTime,
      isRepeating: false, // Set to false by default
      weekdays: List.filled(7, false), // Not using weekdays for meal-specific reminders
    );

    setState(() {
      _mealReminders.add(reminder);
    });

    // Schedule the notification
    _scheduleReminder(reminder);
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
        final primaryColor = _isDarkMode ? Colors.green.shade300 : Colors.green.shade600;
        final backgroundColor = _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
        final textColor = _isDarkMode ? Colors.white : Colors.black;
        final subtitleColor = _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;

        final mealDateTime = meal['dateTime'] != null
            ? (meal['dateTime'] as Timestamp).toDate()
            : DateTime.now();
        final formatter = DateFormat('EEEE, MMMM d, yyyy');
        final timeFormatter = DateFormat('h:mm a');
        final dateTimeStr = '${formatter.format(mealDateTime)} at ${timeFormatter.format(mealDateTime)}';

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
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    meal['mealType'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dateTimeStr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    '${meal['calories']} calories',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Description',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meal['description'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                              style: Theme.of(context).textTheme.bodySmall,
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              meal['mood'],
                              style: TextStyle(color: Theme.of(context).primaryColor),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal['notes'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    style: Theme.of(context).elevatedButtonTheme.style,
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
                      _showReminderConfirmationDialog(mealId, meal);
                    },
                    icon: const Icon(Icons.alarm),
                    label: const Text('Set Reminder'),
                    style: Theme.of(context).outlinedButtonTheme.style,
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editMeal(mealId, meal);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: Theme.of(context).outlinedButtonTheme.style,
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