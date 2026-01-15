import 'package:flutter/material.dart';
import 'package:myprayerbank/models/prayer_project.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _daysCtrl = TextEditingController();

  double? _dailyHours;

  void _recalculateDaily() {
    final hours = double.tryParse(_hoursCtrl.text);
    final days = double.tryParse(_daysCtrl.text);

    if (hours != null && days != null && days > 0) {
      setState(() => _dailyHours = hours / days);
    } else {
      setState(() => _dailyHours = null);
    }
  }

  void _fillHours(int hours) {
    _hoursCtrl.text = hours.toString();
    _recalculateDaily();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final project = PrayerProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      targetHours: int.parse(_hoursCtrl.text),
      durationDays: int.parse(_daysCtrl.text),
      startDate: DateTime.now(),
    );

    Navigator.pop(context, project);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hoursCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Prayer Project')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Project title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(labelText: 'Target hours'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _recalculateDaily(),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter valid hours';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [20, 50, 100, 200, 300]
                    .map((h) => OutlinedButton(
                          onPressed: () => _fillHours(h),
                          child: Text('$h h'),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _daysCtrl,
                decoration: const InputDecoration(labelText: 'Number of days'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _recalculateDaily(),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter valid days';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_dailyHours != null)
                Text(
                  'You’ll pray about ${_dailyHours!.toStringAsFixed(2)} hours per day',
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
