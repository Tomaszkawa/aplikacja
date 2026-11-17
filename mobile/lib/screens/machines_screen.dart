import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';
import 'incidents_screen.dart';
import 'report_incident_screen.dart';

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  List<Machine> _machines = [];
  List<Incident> _incidents = [];
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
      if (_machines.isEmpty) {
        _loading = true;
      }
    });

    try {
      final machines = await widget.api.fetchMachines();
      final incidents = await widget.api.fetchIncidents();
      if (!mounted) return;
      setState(() {
        _machines = machines;
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

  Future<void> _openIncidents() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncidentsScreen(api: widget.api),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _openReport({int? machineId}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportIncidentScreen(
          api: widget.api,
          initialMachineId: machineId,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zgłoszenie zostało utworzone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANDON'),
        actions: [
          IconButton(
            tooltip: 'Zgłoszenia',
            onPressed: _openIncidents,
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            tooltip: 'Odśwież',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReport(),
        icon: const Icon(Icons.add_alert),
        label: const Text('Zgłoś awarię'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _machines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _machines.isEmpty) {
      return _ErrorPane(message: _error!, onRetry: _refresh);
    }

    if (_machines.isEmpty) {
      return const Center(child: Text('Brak maszyn w systemie'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _machines.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                const Expanded(
                  child: Text(
                    'Maszyny',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            );
          }

          final machine = _machines[index - 1];
          final health = healthForMachine(machine.id, _incidents);
          final color = colorForMachineHealth(health);

          return Material(
            color: andonCard,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openReport(machineId: machine.id),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 6, color: color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.precision_manufacturing,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    machine.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    machine.location,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color),
                              ),
                              child: Text(
                                health.label,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}
