import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({
    super.key,
    required this.api,
    this.initialMachineId,
  });

  final ApiClient api;
  final int? initialMachineId;

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  late Future<List<Machine>> _machinesFuture;
  int? _machineId;
  Priority _priority = Priority.medium;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _machineId = widget.initialMachineId;
    _machinesFuture = widget.api.fetchMachines();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_machineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz maszynę')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.api.createIncident(
        machineId: _machineId!,
        description: _descriptionController.text.trim(),
        priority: _priority,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowe zgłoszenie')),
      body: FutureBuilder<List<Machine>>(
        future: _machinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
              ),
            );
          }

          final machines = snapshot.data!;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _machineId,
                  decoration: const InputDecoration(labelText: 'Maszyna'),
                  items: machines
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.name} (${m.location})'),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _machineId = value),
                  validator: (value) =>
                      value == null ? 'Wybierz maszynę' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_submitting,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Opis problemu',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3) {
                      return 'Opis musi mieć co najmniej 3 znaki';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Priorytet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<Priority>(
                  segments: Priority.values
                      .map(
                        (p) => ButtonSegment(
                          value: p,
                          label: Text(p.label),
                        ),
                      )
                      .toList(),
                  selected: {_priority},
                  onSelectionChanged: _submitting
                      ? null
                      : (values) => setState(() => _priority = values.first),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _submitting ? 'Wysyłanie…' : 'Wyślij zgłoszenie',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
