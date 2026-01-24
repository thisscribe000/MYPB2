import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AppShell already provides the AppBar title.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: const [
          SizedBox(height: 12),
          Text(
            'We’ll add settings options here in the next stages (reminders, preferences, etc).',
          ),
        ],
      ),
    );
  }
}
