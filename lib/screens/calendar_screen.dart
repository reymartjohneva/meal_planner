import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for FilteringTextInputFormatter
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/meal_reminder.dart';
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  final List<MealReminder> reminders;

  const CalendarScreen({Key? key, required this.reminders}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late List<MealReminder> _reminders;
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _mealTypeOptions = [
    'Breakfast',
    'Lunch',
    'Snack',
    'Dinner',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _reminders = List.from(widget.reminders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner Calendar'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'add_meal',
                child: Text('Add Meal'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEventsForDay,
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildMealListForSelectedDay(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _handleAddMealRequest(context),
      ),
    );
  }

  void _handleAddMealRequest(BuildContext context) {
    // Create DateTime objects with time set to midnight for proper comparison
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final selectedDateStart = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    if (selectedDateStart.isBefore(today)) {
      // Show error message if selected date is in the past
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add meals to past dates'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Proceed with showing the add meal dialog
      _showAddMealDialog(context);
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return []; // Will be populated via StreamBuilder in _buildMealListForSelectedDay
  }

  Widget _buildMealListForSelectedDay() {
    return StreamBuilder<QuerySnapshot>(
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
        }).where((meal) {
          final mealDateTime = (meal['dateTime'] as Timestamp).toDate();
          return mealDateTime.year == _selectedDay.year &&
              mealDateTime.month == _selectedDay.month &&
              mealDateTime.day == _selectedDay.day;
        }).toList();

        if (meals.isEmpty) {
          return const Center(child: Text('No meals planned for this day.'));
        }

        return ListView.builder(
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            final mealDateTime = (meal['dateTime'] as Timestamp).toDate();
            final timeFormatter = TimeOfDay.fromDateTime(mealDateTime).format(context);

            return Dismissible(
              key: Key(meal['id']),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                try {
                  await _firestoreService.deleteMeal(meal['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${meal['mealType']} removed')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting meal: $e')),
                  );
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(meal['mealType']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time: $timeFormatter'),
                      if (meal['description'] != null && meal['description'].isNotEmpty)
                        Text('Description: ${meal['description']}'),
                      Text('Calories: ${meal['calories']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _handleEditMealRequest(meal['id'], meal),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleEditMealRequest(String mealId, Map<String, dynamic> meal) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final mealDate = (meal['dateTime'] as Timestamp).toDate();
    final mealDateStart = DateTime(
      mealDate.year,
      mealDate.month,
      mealDate.day,
    );

    // Allow editing today's meals and future meals
    if (!mealDateStart.isBefore(today)) {
      _editMeal(mealId, meal);
    } else {
      // For past meals, show a different message
      // You may choose to still allow editing past meals or show this error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit meals from past dates'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuSelection(String value) async {
    if (value == 'add_meal') {
      _showAddMealDialog(context);
    }
  }

  void _showAddMealDialog(BuildContext context) {
    String? selectedMealType;
    final descriptionController = TextEditingController();
    final caloriesController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Meal for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    hint: const Text('Select Meal Type'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMealType = newValue;
                      });
                    },
                    items: _mealTypeOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Meal Type'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: caloriesController,
                    decoration: const InputDecoration(labelText: 'Calories'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Time'),
                    trailing: Text(selectedTime.format(context)),
                    onTap: () async {
                      final TimeOfDay? timeOfDay = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (timeOfDay != null) {
                        setState(() {
                          selectedTime = timeOfDay;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Add'),
                onPressed: () async {
                  if (selectedMealType != null &&
                      descriptionController.text.trim().isNotEmpty &&
                      caloriesController.text.trim().isNotEmpty) {
                    final scheduledDateTime = DateTime(
                      _selectedDay.year,
                      _selectedDay.month,
                      _selectedDay.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    try {
                      await _firestoreService.addMeal(
                        mealType: selectedMealType!,
                        description: descriptionController.text.trim(),
                        calories: int.parse(caloriesController.text.trim()),
                        dateTime: scheduledDateTime,
                      );

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meal added and reminder set!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding meal: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields')),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _editMeal(String mealId, Map<String, dynamic> meal) {
    String? selectedMealType = meal['mealType'];
    final descriptionController = TextEditingController(text: meal['description']);
    final caloriesController = TextEditingController(text: meal['calories'].toString());
    final dateTime = (meal['dateTime'] as Timestamp).toDate();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(dateTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Meal for ${dateTime.day}/${dateTime.month}/${dateTime.year}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    hint: const Text('Select Meal Type'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMealType = newValue;
                      });
                    },
                    items: _mealTypeOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Meal Type'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: caloriesController,
                    decoration: const InputDecoration(labelText: 'Calories'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Time'),
                    trailing: Text(selectedTime.format(context)),
                    onTap: () async {
                      final TimeOfDay? timeOfDay = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (timeOfDay != null) {
                        setState(() {
                          selectedTime = timeOfDay;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () async {
                  if (selectedMealType != null &&
                      descriptionController.text.trim().isNotEmpty &&
                      caloriesController.text.trim().isNotEmpty) {
                    final updatedDateTime = DateTime(
                      dateTime.year,
                      dateTime.month,
                      dateTime.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    try {
                      await _firestoreService.updateMeal(
                        mealId: mealId,
                        mealType: selectedMealType!,
                        description: descriptionController.text.trim(),
                        calories: int.parse(caloriesController.text.trim()),
                        dateTime: updatedDateTime,
                        logged: meal['logged'],
                        satisfaction: meal['satisfaction'],
                        mood: meal['mood'],
                        notes: meal['notes'],
                      );

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meal updated and reminder set!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating meal: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields')),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}