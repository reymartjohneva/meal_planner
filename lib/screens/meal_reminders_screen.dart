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
    final Color backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Meal Reminders'),
        backgroundColor: Colors.teal.shade600,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      body: reminders.isEmpty
          ? Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 80,
                  color: Colors.teal.shade300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Reminders Set',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add reminders from your meal journal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          final timeString = reminder.reminderTime.format(context);

          // Determine meal icon based on time
          IconData mealIcon = Icons.lunch_dining;
          if (timeString.contains('AM')) {
            mealIcon = Icons.free_breakfast;
          } else if (timeString.contains('PM') && int.parse(timeString.split(':')[0]) >= 6) {
            mealIcon = Icons.dinner_dining;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.shade400,
                          Colors.teal.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      mealIcon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      reminder.mealTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      timeString,
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(84, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        reminder.isRepeating
                            ? Icons.repeat
                            : Icons.event,
                        size: 16,
                        color: subtitleColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          !reminder.isRepeating
                              ? '${reminder.scheduledDate.day}/${reminder.scheduledDate.month}/${reminder.scheduledDate.year}'
                              : _formatWeekdays(reminder.weekdays),
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                InkWell(
                  onTap: () => _confirmDeleteReminder(context, reminder.id),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remove Reminder',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

    // If all days are selected
    if (selectedDays.length == 7) {
      return 'Every day';
    }

    // If weekdays are selected
    if (selectedDays.length == 5 &&
        selectedDays.contains('Mon') &&
        selectedDays.contains('Tue') &&
        selectedDays.contains('Wed') &&
        selectedDays.contains('Thu') &&
        selectedDays.contains('Fri')) {
      return 'Weekdays';
    }

    // If weekends are selected
    if (selectedDays.length == 2 &&
        selectedDays.contains('Sat') &&
        selectedDays.contains('Sun')) {
      return 'Weekends';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}