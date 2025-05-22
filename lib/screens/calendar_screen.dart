import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Map for meal type colors (adjusted for dark mode)
  final Map<String, MaterialColor> _mealTypeColors = {
    'Breakfast': Colors.amber,
    'Lunch': Colors.green,
    'Snack': Colors.purple,
    'Dinner': Colors.blue,
  };

  // Map for meal type icons
  final Map<String, IconData> _mealTypeIcons = {
    'Breakfast': Icons.free_breakfast,
    'Lunch': Icons.lunch_dining,
    'Snack': Icons.cookie,
    'Dinner': Icons.dinner_dining,
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _reminders = List.from(widget.reminders);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'PlannerHut',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _handleAddMealRequest(context),
            tooltip: 'Add Meal',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter functionality coming soon')),
              );
            },
            tooltip: 'Filter Meals',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildCalendar(),
          _buildDayHeader(),
          Expanded(
            child: _buildMealListForSelectedDay(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _handleAddMealRequest(context),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_monthName(_focusedDay.month)} ${_focusedDay.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan your meals ahead',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    });
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        headerVisible: false,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: CalendarFormat.month,
        eventLoader: _getEventsForDay,
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.red),
          holidayTextStyle: const TextStyle(color: Colors.red),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
          weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedDay.day} ${_monthName(_selectedDay.month)} ${_selectedDay.year}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          _buildDayIndicator(),
        ],
      ),
    );
  }

  Widget _buildDayIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Function to check if selected day is today
    bool isToday() {
      final now = DateTime.now();
      return _selectedDay.year == now.year &&
          _selectedDay.month == now.month &&
          _selectedDay.day == now.day;
    }

    // Function to check if selected day is in the past
    bool isPast() {
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
      return selectedDateStart.isBefore(today);
    }

    if (isToday()) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.green.shade700 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today, size: 16, color: isDarkMode ? Colors.white : Colors.green.shade800),
            const SizedBox(width: 4),
            Text(
              'Today',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (isPast()) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 16, color: isDarkMode ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Past',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 16, color: isDarkMode ? Colors.white : Colors.blue.shade800),
            const SizedBox(width: 4),
            Text(
              'Upcoming',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Cannot add meals to past dates'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      _showAddMealDialog(context);
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return []; // Populated via StreamBuilder in _buildMealListForSelectedDay
  }

  Widget _buildMealListForSelectedDay() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getMeals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ],
              ),
            );
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

          meals.sort((a, b) {
            final aTime = (a['dateTime'] as Timestamp).toDate();
            final bTime = (b['dateTime'] as Timestamp).toDate();
            return aTime.compareTo(bTime);
          });

          if (meals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_meals, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(height: 16),
                  Text(
                    'No meals planned for this day',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a meal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _handleAddMealRequest(context),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              final mealDateTime = (meal['dateTime'] as Timestamp).toDate();
              final timeFormatter = TimeOfDay.fromDateTime(mealDateTime).format(context);
              final mealType = meal['mealType'] as String;
              final mealColor = isDarkMode
                  ? (_mealTypeColors[mealType]?.shade700 ?? Colors.grey.shade700)
                  : (_mealTypeColors[mealType]?.shade400 ?? Colors.grey.shade400);
              final mealIcon = _mealTypeIcons[mealType] ?? Icons.restaurant;

              return Dismissible(
                key: Key(meal['id']),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delete, color: Colors.white),
                    ],
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  try {
                    await _firestoreService.deleteMeal(meal['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${meal['mealType']} removed'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting meal: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                child: GestureDetector(
                  onTap: () => _handleEditMealRequest(meal['id'], meal),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        color: Theme.of(context).primaryColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                        width: 1,
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
                          mealIcon,
                          size: 20,
                          color: mealColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    meal['mealType'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: mealColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      timeFormatter,
                                      style: TextStyle(
                                        color: mealColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (meal['description'] != null && meal['description'].isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  meal['description'],
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${meal['calories']} cal',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
                ),
              );
            },
          );
        },
      ),
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

    if (!mealDateStart.isBefore(today)) {
      _editMeal(mealId, meal);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Cannot edit meals from past dates'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Meal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedDay.day} ${_monthName(_selectedDay.month)} ${_selectedDay.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: selectedMealType,
                        hint: Text(
                          'Select Meal Type',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMealType = newValue;
                          });
                        },
                        items: _mealTypeOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          final color = isDarkMode
                              ? (_mealTypeColors[value]?.shade700 ?? Colors.grey.shade700)
                              : (_mealTypeColors[value]?.shade400 ?? Colors.grey.shade400);
                          final icon = _mealTypeIcons[value] ?? Icons.restaurant;

                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(icon, color: color),
                                const SizedBox(width: 8),
                                Text(value, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'What will you be eating?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      filled: true,
                    ),
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: caloriesController,
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      hintText: 'Estimated calories',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.local_fire_department),
                      suffixText: 'cal',
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? timeOfDay = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.fromSwatch(
                                primarySwatch: Colors.green,
                                brightness: Theme.of(context).brightness,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (timeOfDay != null) {
                        setState(() {
                          selectedTime = timeOfDay;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 12),
                          Text(
                            'Time',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            selectedTime.format(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'Add Meal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Meal added and reminder set!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding meal: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Please fill in all fields'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Meal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${dateTime.day} ${_monthName(dateTime.month)} ${dateTime.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: selectedMealType,
                        hint: Text(
                          'Select Meal Type',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMealType = newValue;
                          });
                        },
                        items: _mealTypeOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          final color = isDarkMode
                              ? (_mealTypeColors[value]?.shade700 ?? Colors.grey.shade700)
                              : (_mealTypeColors[value]?.shade400 ?? Colors.grey.shade400);
                          final icon = _mealTypeIcons[value] ?? Icons.restaurant;

                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(icon, color: color),
                                const SizedBox(width: 8),
                                Text(value, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'What will you be eating?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      filled: true,
                    ),
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: caloriesController,
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      hintText: 'Estimated calories',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.local_fire_department),
                      suffixText: 'cal',
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? timeOfDay = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.fromSwatch(
                                primarySwatch: Colors.green,
                                brightness: Theme.of(context).brightness,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (timeOfDay != null) {
                        setState(() {
                          selectedTime = timeOfDay;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 12),
                          Text(
                            'Time',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            selectedTime.format(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                        logged: meal['logged'] ?? false,
                        satisfaction: meal['satisfaction'] ?? 0,
                        mood: meal['mood'] ?? '',
                        notes: meal['notes'] ?? '',
                      );

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Meal updated successfully!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating meal: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Please fill in all fields'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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