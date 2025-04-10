import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for FilteringTextInputFormatter
import 'package:table_calendar/table_calendar.dart';
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
                value: 'import',
                child: Text('Import Meal Plan'),
              ),
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
            onFormatChanged: (format) {
              // Handle format change if needed
            },
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
        onPressed: () => _showAddMealDialog(context),
      ),
    );
  }

  List<MealReminder> _getEventsForDay(DateTime day) {
    return _reminders.where((reminder) {
      final reminderDate = reminder.scheduledDate;
      return reminderDate.year == day.year &&
          reminderDate.month == day.month &&
          reminderDate.day == day.day;
    }).toList();
  }

  Widget _buildMealListForSelectedDay() {
    final mealsForSelectedDay = _getEventsForDay(_selectedDay);

    if (mealsForSelectedDay.isEmpty) {
      return const Center(child: Text('No meals planned for this day.'));
    }

    return ListView.builder(
      itemCount: mealsForSelectedDay.length,
      itemBuilder: (context, index) {
        final reminder = mealsForSelectedDay[index];
        return Dismissible(
          key: Key(reminder.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            setState(() {
              _reminders.remove(reminder);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${reminder.mealTitle} removed')),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(reminder.mealTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time: ${reminder.reminderTime.format(context)}'),
                  if (reminder.description != null && reminder.description!.isNotEmpty)
                    Text('Description: ${reminder.description}'),
                  if (reminder.calories != null && reminder.calories! > 0)
                    Text('Calories: ${reminder.calories}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditMealDialog(context, reminder),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'import':
        _showImportDialog();
        break;
      case 'add_meal':
        _showAddMealDialog(context);
        break;
    }
  }

  void _showImportDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Meal Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your meal plan JSON data below:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '[{"mealTitle": "Breakfast", "scheduledDate": "2025-04-08", "reminderTime": "08:00"}]',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _importMealPlanFromJson(textController.text);
              Navigator.pop(context);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _importMealPlanFromJson(String jsonString) {
    try {
      if (jsonString.isEmpty) return;

      final List<dynamic> jsonData = jsonDecode(jsonString);
      List<MealReminder> importedMeals = [];

      for (var mealData in jsonData) {
        // Parse the date
        DateTime scheduledDate;
        if (mealData['scheduledDate'] is String) {
          scheduledDate = DateTime.parse(mealData['scheduledDate']);
        } else {
          // Skip invalid entries
          continue;
        }

        // Parse the time
        TimeOfDay reminderTime;
        if (mealData['reminderTime'] is String) {
          final timeParts = mealData['reminderTime'].split(':');
          if (timeParts.length == 2) {
            reminderTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          } else {
            // Skip invalid entries
            continue;
          }
        } else {
          // Skip invalid entries
          continue;
        }

        importedMeals.add(MealReminder(
          id: mealData['id'] ?? DateTime.now().millisecondsSinceEpoch,
          mealTitle: mealData['mealTitle'] ?? 'Unnamed Meal',
          scheduledDate: scheduledDate,
          reminderTime: reminderTime,
          description: mealData['description'],
          calories: mealData['calories'],
        ));
      }

      setState(() {
        _reminders.addAll(importedMeals);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${importedMeals.length} meals')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing meal plan: $e')),
      );
    }
  }

  void _showAddMealDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final caloriesController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Meal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Meal Title'),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final newMeal = MealReminder(
                        id: DateTime.now().millisecondsSinceEpoch,
                        mealTitle: titleController.text,
                        description: descriptionController.text,
                        calories: caloriesController.text.isNotEmpty ?
                        int.parse(caloriesController.text) : 0,
                        scheduledDate: _selectedDay,
                        reminderTime: selectedTime,
                      );

                      setState(() {
                        _reminders.add(newMeal);
                      });

                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          }
      ),
    );
  }

  void _showEditMealDialog(BuildContext context, MealReminder reminder) {
    final titleController = TextEditingController(text: reminder.mealTitle);
    final descriptionController = TextEditingController(text: reminder.description ?? '');
    final caloriesController = TextEditingController(
        text: reminder.calories != null ? reminder.calories.toString() : '');
    TimeOfDay selectedTime = reminder.reminderTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Meal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Meal Title'),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final index = _reminders.indexWhere((item) => item.id == reminder.id);

                      if (index != -1) {
                        setState(() {
                          _reminders[index] = MealReminder(
                            id: reminder.id,
                            mealTitle: titleController.text,
                            description: descriptionController.text,
                            calories: caloriesController.text.isNotEmpty ?
                            int.parse(caloriesController.text) : 0,
                            scheduledDate: reminder.scheduledDate,
                            reminderTime: selectedTime,
                          );
                        });
                      }

                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          }
      ),
    );
  }
}