import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: const [
          Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text('Coming soon:'),
          SizedBox(height: 10),
          Text('• Daily goals'),
          Text('• Reminders / notifications'),
          Text('• Theme & UI options'),
          Text('• Export (PDF / text)'),
          Text('• Backup & restore'),
        ],
      ),
    );
  }
}
