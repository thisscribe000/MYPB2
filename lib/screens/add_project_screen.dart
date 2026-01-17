import 'package:flutter/material.dart';
import 'package:myprayerbank/models/prayer_project.dart';
import 'dart:math';

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

  DateTime _plannedStartDate = DateTime.now();
  double? _dailyHours;

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  void _recalc() {
    final hours = double.tryParse(_hoursCtrl.text);
    final days = double.tryParse(_daysCtrl.text);
    if (hours != null && days != null && days > 0) {
      setState(() => _dailyHours = hours / days);
    } else {
      setState(() => _dailyHours = null);
    }
  }

  DateTime? get _endDate {
    final days = int.tryParse(_daysCtrl.text);
    if (days == null || days <= 0) return null;
    return DateTime(_plannedStartDate.year, _plannedStartDate.month, _plannedStartDate.day)
        .add(Duration(days: days - 1));
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedStartDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _plannedStartDate = picked);
    }
  }

  void _fillHours(int hours) {
    _hoursCtrl.text = hours.toString();
    _recalc();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final project = PrayerProject(
      id: Random().nextInt(1000000).toString(),
      title: _titleCtrl.text.trim(),
      targetHours: int.parse(_hoursCtrl.text),
      durationDays: int.parse(_daysCtrl.text),
      plannedStartDate: _plannedStartDate,
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
    final end = _endDate;

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
                decoration: const InputDecoration(labelText: 'Project title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(labelText: 'Target hours'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _recalc(),
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
                onChanged: (_) => _recalc(),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter valid days';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Planned start date'),
                subtitle: Text('${_plannedStartDate.year}-${_plannedStartDate.month.toString().padLeft(2, '0')}-${_plannedStartDate.day.toString().padLeft(2, '0')}'),
                trailing: TextButton(
                  onPressed: _pickStartDate,
                  child: const Text('Pick'),
                ),
              ),

              if (end != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'End date: ${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 16),
              if (_dailyHours != null)
                Text('You’ll pray about ${_dailyHours!.toStringAsFixed(2)} hours per day'),

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
