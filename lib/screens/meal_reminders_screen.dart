import 'package:flutter/material.dart';
import '../models/meal_reminder.dart';

class MealRemindersScreen extends StatelessWidget {
  final List<MealReminder> reminders;
  final Function(int) onDelete;

  const MealRemindersScreen({
    super.key,
    required this.reminders,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final Color cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtitleColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Meal Reminders'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: reminders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: subtitleColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders set',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add reminders from your meal journal',
              style: TextStyle(
                color: subtitleColor,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.teal.shade700,
                ),
              ),
              title: Text(
                reminder.mealTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time: ${reminder.reminderTime.format(context)}',
                    style: TextStyle(color: subtitleColor),
                  ),
                  if (!reminder.isRepeating)
                    Text(
                      'Date: ${reminder.scheduledDate.day}/${reminder.scheduledDate.month}/${reminder.scheduledDate.year}',
                      style: TextStyle(color: subtitleColor),
                    )
                  else
                    Text(
                      'Repeats: ${_formatWeekdays(reminder.weekdays)}',
                      style: TextStyle(color: subtitleColor),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () {
                  _confirmDeleteReminder(context, reminder.id);
                },
              ),
              onTap: () {
                // Show reminder details
              },
            ),
          );
        },
      ),
    );
  }

  // Format weekdays for display
  String _formatWeekdays(List<bool> weekdays) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = <String>[];

    for (int i = 0; i < weekdays.length; i++) {
      if (weekdays[i]) {
        selectedDays.add(days[i]);
      }
    }

    if (selectedDays.isEmpty) {
      return 'No days selected';
    }

    return selectedDays.join(', ');
  }

  // Confirm before deleting a reminder
  void _confirmDeleteReminder(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}