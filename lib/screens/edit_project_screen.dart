import 'package:flutter/material.dart';
import 'package:myprayerbank/models/prayer_project.dart';

class EditProjectScreen extends StatefulWidget {
  final PrayerProject project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _daysCtrl;

  double? _dailyHours;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.project.title);
    _hoursCtrl = TextEditingController(text: widget.project.targetHours.toString());
    _daysCtrl = TextEditingController(text: widget.project.durationDays.toString());
    _recalculateDaily();
  }

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

    final updated = PrayerProject(
      id: widget.project.id,
      title: _titleCtrl.text.trim(),
      targetHours: int.parse(_hoursCtrl.text),
      durationDays: int.parse(_daysCtrl.text),
      startDate: widget.project.startDate,
      totalMinutesPrayed: widget.project.totalMinutesPrayed,
      notes: List<PrayerNote>.from(widget.project.notes),
    );

    Navigator.pop(context, updated);
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
      appBar: AppBar(title: const Text('Edit Project')),
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
                Text('You’ll pray about ${_dailyHours!.toStringAsFixed(2)} hours per day'),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
