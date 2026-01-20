import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Reminders'),
            subtitle:
                Text('Coming soon: schedule prayer sessions & notifications'),
          ),
        ),
        SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: Icon(Icons.backup),
            title: Text('Backup / Restore'),
            subtitle: Text('Coming soon: export/import your prayer data'),
          ),
        ),
        SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: Icon(Icons.tune),
            title: Text('Timer behavior'),
            subtitle: Text('Coming soon: rounding rules and preferences'),
          ),
        ),
      ],
    );
  }
}
