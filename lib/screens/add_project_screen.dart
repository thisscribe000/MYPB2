import 'package:flutter/material.dart';
import 'dart:math';
import '../models/prayer_project.dart';

class AddProjectScreen extends StatefulWidget {
  final void Function(PrayerProject project) onAdd;

  /// If true, after saving we pop back to Pray Now flow.
  /// (We’ll wire this when we add the Pray Now FAB.)
  final bool fromPrayNow;

  const AddProjectScreen({
    super.key,
    required this.onAdd,
    this.fromPrayNow = false,
  });

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _targetHoursCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();

  DateTime _startDate = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetHoursCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final today = _dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today, // ✅ blocks past dates
      lastDate: DateTime(today.year + 5),
    );

    if (picked != null) {
      setState(() {
        _startDate = _dateOnly(picked);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final targetHours = int.parse(_targetHoursCtrl.text.trim());
    final days = int.parse(_daysCtrl.text.trim());

    final id = Random().nextInt(999999).toString();

    final project = PrayerProject(
      id: id,
      title: title,
      targetHours: targetHours,
      durationDays: days,
      plannedStartDate: _startDate,
    );

    widget.onAdd(project);

    // ✅ If user came from Pray Now, we just pop back.
    // (Pray Now will already be in the stack.)
    Navigator.pop(context);
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Project')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Project title',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Title is required';
                  if (t.length < 2) return 'Title is too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _targetHoursCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target hours (e.g. 50)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Target hours is required';
                  final n = int.tryParse(t);
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _daysCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration (days) (e.g. 10)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Duration days is required';
                  final n = int.tryParse(t);
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Must be greater than 0';
                  if (n > 3650) return 'Too long (max 3650 days)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  title: const Text('Start date'),
                  subtitle: Text('${_fmtDate(_startDate)} (Day 1)'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Project'),
              ),
              const SizedBox(height: 10),

              const Text(
                'Note: Start date can only be today or later.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
