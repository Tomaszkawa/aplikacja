import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  List<Incident> _incidents = [];
  Map<int, String> _machineNames = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      if (_incidents.isEmpty) _loading = true;
    });

    try {
      final machines = await widget.api.fetchMachines();
      final incidents = await widget.api.fetchIncidents();
      if (!mounted) return;
      setState(() {
        _machineNames = {for (final m in machines) m.id: m.name};
        _incidents = incidents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _advanceStatus(Incident incident) async {
    final next = incident.status.next;
    if (next == null) return;

    try {
      await widget.api.updateIncidentStatus(
        incidentId: incident.id,
        status: next,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status zmieniony na ${next.label}')),
        );
      }
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zgłoszenia'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _incidents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _incidents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _refresh,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (_incidents.isEmpty) {
      return const Center(child: Text('Brak zgłoszeń'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _incidents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final incident = _incidents[index];
          final statusColor = colorForIncidentStatus(incident.status);
          final machineName = _machineNames[incident.machineId] ??
              'Maszyna #${incident.machineId}';
          final next = incident.status.next;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          machineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _Chip(
                        label: incident.status.label,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(incident.description),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Chip(
                        label: incident.priority.label,
                        color: colorForPriority(incident.priority),
                      ),
                      Text(
                        _dateFormat.format(incident.createdAt.toLocal()),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (next != null)
                        TextButton.icon(
                          onPressed: () => _advanceStatus(incident),
                          icon: const Icon(Icons.playlist_add_check),
                          label: Text('→ ${next.label}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
