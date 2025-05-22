import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Simplified settings values
  String _measurementUnit = 'Metric';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Would fetch settings from storage in a real app
    setState(() {
      // Load settings here in the future
    });
  }

  Future<void> _saveSettings() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );

    // Simulate saving with a delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Close loading dialog
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Settings saved successfully!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: Theme.of(context).primaryColor),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Settings Section
                _buildSectionHeader('App Settings'),
                const SizedBox(height: 16),

                _buildSettingsCard(
                  child: Column(
                    children: [
                      // Dark Mode
                      _buildSwitchTile(
                        'Dark Mode',
                        'Use dark theme throughout the app',
                        themeProvider.isDarkMode,
                        Icons.dark_mode_outlined,
                            (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                      const Divider(height: 1),
                      // Measurement Units
                      _buildDropdownTile(
                        'Measurement Units',
                        _measurementUnit,
                        ['Metric', 'Imperial'],
                        Icons.straighten_outlined,
                            (value) {
                          setState(() {
                            _measurementUnit = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Section
                _buildSectionHeader('Account'),
                const SizedBox(height: 16),

                _buildSettingsCard(
                  child: Column(
                    children: [
                      _buildActionTile(
                        'Export Data',
                        'Export your app data',
                        Icons.download_outlined,
                            () => _showExportDialog(context),
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        'Help & Support',
                        'Get help with using the app',
                        Icons.help_outline,
                            () => _showHelpSnackbar(context),
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        'About',
                        'App version 1.0.0',
                        Icons.info_outline,
                            () => _showAboutSnackbar(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                _buildSaveButton(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      IconData icon,
      Function(bool) onChanged,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile(
      String title,
      String value,
      List<String> options,
      IconData icon,
      Function(String?) onChanged,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: Container(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Save Settings',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Dialog and feedback methods
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Export Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExportOption(
                'Export All Data',
                Icons.download,
                    () {
                  Navigator.pop(context);
                  _showExportSnackbar(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ),
    );
  }

  void _showExportSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Exporting data...',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showHelpSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Help & Support coming soon'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAboutSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('App version 1.0.0'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}