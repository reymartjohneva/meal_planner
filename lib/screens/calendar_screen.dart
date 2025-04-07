import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/meal_reminder.dart';

class CalendarScreen extends StatefulWidget {
  final List<MealReminder> reminders;

  const CalendarScreen({Key? key, required this.reminders}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner Calendar'),
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
                _focusedDay = focusedDay; // update `_focusedDay` here as well
              });
            },
            calendarFormat: CalendarFormat.month,
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
    );
  }

  Widget _buildMealListForSelectedDay() {
    final mealsForSelectedDay = widget.reminders.where((reminder) {
      final reminderDate = reminder.scheduledDate;
      return reminderDate.year == _selectedDay.year &&
          reminderDate.month == _selectedDay.month &&
          reminderDate.day == _selectedDay.day;
    }).toList();

    if (mealsForSelectedDay.isEmpty) {
      return Center(child: Text('No meals planned for this day.'));
    }

    return ListView.builder(
      itemCount: mealsForSelectedDay.length,
      itemBuilder: (context, index) {
        final reminder = mealsForSelectedDay[index];
        return ListTile(
          title: Text(reminder.mealTitle),
          subtitle: Text('Time: ${reminder.reminderTime.format(context)}'),
        );
      },
    );
  }
}