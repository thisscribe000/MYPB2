import 'package:flutter/material.dart';
import '../models/prayer_project.dart';

class AddProjectScreen extends StatefulWidget {
  final void Function(PrayerProject project) onAdd;

  const AddProjectScreen({super.key, required this.onAdd});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _titleController = TextEditingController();
  final _daysController = TextEditingController();

  int? _selectedHours;

  final List<int> suggestedHours = [20, 50, 100, 200, 300];

  void _saveProject() {
    if (_titleController.text.isEmpty ||
        _daysController.text.isEmpty ||
        _selectedHours == null) {
      return;
    }

    final project = PrayerProject.fromHours(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      targetHours: _selectedHours!,
      durationDays: int.parse(_daysController.text),
      startDate: DateTime.now(),
    );

    widget.onAdd(project);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Prayer Project')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Title'),
            TextField(controller: _titleController),
            const SizedBox(height: 16),
            const Text('Target Hours'),
            Wrap(
              spacing: 8,
              children: suggestedHours.map((h) {
                return ChoiceChip(
                  label: Text('$h hrs'),
                  selected: _selectedHours == h,
                  onSelected: (_) {
                    setState(() => _selectedHours = h);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Number of Days'),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveProject,
              child: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}
