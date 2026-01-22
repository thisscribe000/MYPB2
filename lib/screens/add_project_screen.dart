import 'package:flutter/material.dart';
import '../models/prayer_project.dart';

class AddProjectScreen extends StatefulWidget {
  final Future<void> Function(PrayerProject project) onAdd;

  const AddProjectScreen({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _targetHoursCtrl = TextEditingController();
  final _durationDaysCtrl = TextEditingController();

  DateTime _plannedStartDate = DateTime.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetHoursCtrl.dispose();
    _durationDaysCtrl.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  bool get _isValidNow {
    final titleOk = _titleCtrl.text.trim().isNotEmpty;

    final target = int.tryParse(_targetHoursCtrl.text.trim());
    final duration = int.tryParse(_durationDaysCtrl.text.trim());

    final targetOk = target != null && target > 0;
    final durationOk = duration != null && duration > 0;

    final today = _dateOnly(DateTime.now());
    final startOk = !_dateOnly(_plannedStartDate).isBefore(today);

    return titleOk && targetOk && durationOk && startOk;
  }

  Future<void> _pickStartDate() async {
    final today = _dateOnly(DateTime.now());
    final initial = _dateOnly(_plannedStartDate).isBefore(today)
        ? today
        : _dateOnly(_plannedStartDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today, // ✅ no past dates allowed
      lastDate: DateTime(today.year + 10),
    );

    if (picked == null) return;

    setState(() {
      _plannedStartDate = _dateOnly(picked);
    });
  }

  Future<void> _save() async {
    // Run validators
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final title = _titleCtrl.text.trim();
    final targetHours = int.parse(_targetHoursCtrl.text.trim());
    final durationDays = int.parse(_durationDaysCtrl.text.trim());

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final project = PrayerProject(
      id: id,
      title: title,
      targetHours: targetHours,
      durationDays: durationDays,
      plannedStartDate: _dateOnly(_plannedStartDate),
    );

    await widget.onAdd(project);

    if (!mounted) return;
    // Don’t pop here, because AppShell’s onAdd already pops the route.
    // If you later reuse this screen elsewhere, this still stays safe.
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final startIsPast = _dateOnly(_plannedStartDate).isBefore(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
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
                  if (v == null || v.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _targetHoursCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target hours',
                  hintText: 'e.g. 50',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter a valid number > 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _durationDaysCtrl,
                decoration: const InputDecoration(
                  labelText: 'Number of days',
                  hintText: 'e.g. 10',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter a valid number > 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Planned start date'),
                  subtitle: Text(_fmtDDMMYYYY(_plannedStartDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickStartDate,
                ),
              ),

              if (startIsPast)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Start date cannot be in the past.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 18),

              ElevatedButton.icon(
                onPressed: _isValidNow ? _save : null,
                icon: const Icon(Icons.save),
                label: const Text('Save project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
