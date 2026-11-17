enum Priority { low, medium, high }

enum IncidentStatus { open, inProgress, resolved }

extension PriorityX on Priority {
  String get apiValue => name;

  String get label => switch (this) {
        Priority.low => 'Low',
        Priority.medium => 'Medium',
        Priority.high => 'High',
      };

  static Priority fromApi(String value) => Priority.values.firstWhere(
        (p) => p.name == value,
        orElse: () => Priority.medium,
      );
}

extension IncidentStatusX on IncidentStatus {
  String get apiValue => switch (this) {
        IncidentStatus.open => 'open',
        IncidentStatus.inProgress => 'in_progress',
        IncidentStatus.resolved => 'resolved',
      };

  String get label => switch (this) {
        IncidentStatus.open => 'Awaria',
        IncidentStatus.inProgress => 'Naprawa',
        IncidentStatus.resolved => 'Rozwiązane',
      };

  static IncidentStatus fromApi(String value) => switch (value) {
        'in_progress' => IncidentStatus.inProgress,
        'resolved' => IncidentStatus.resolved,
        _ => IncidentStatus.open,
      };

  IncidentStatus? get next => switch (this) {
        IncidentStatus.open => IncidentStatus.inProgress,
        IncidentStatus.inProgress => IncidentStatus.resolved,
        IncidentStatus.resolved => null,
      };
}

class Machine {
  Machine({
    required this.id,
    required this.name,
    required this.location,
  });

  final int id;
  final String name;
  final String location;

  factory Machine.fromJson(Map<String, dynamic> json) => Machine(
        id: json['id'] as int,
        name: json['name'] as String,
        location: json['location'] as String,
      );
}

class Incident {
  Incident({
    required this.id,
    required this.machineId,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int machineId;
  final String description;
  final Priority priority;
  final IncidentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status != IncidentStatus.resolved;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: json['id'] as int,
        machineId: json['machine_id'] as int,
        description: json['description'] as String,
        priority: PriorityX.fromApi(json['priority'] as String),
        status: IncidentStatusX.fromApi(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

/// Machine health derived from active incidents (per lab spec).
enum MachineHealth { sprawna, awaria, naprawa }

MachineHealth healthForMachine(int machineId, List<Incident> incidents) {
  final active = incidents.where((i) => i.machineId == machineId && i.isActive);
  if (active.any((i) => i.status == IncidentStatus.open)) {
    return MachineHealth.awaria;
  }
  if (active.any((i) => i.status == IncidentStatus.inProgress)) {
    return MachineHealth.naprawa;
  }
  return MachineHealth.sprawna;
}

extension MachineHealthX on MachineHealth {
  String get label => switch (this) {
        MachineHealth.sprawna => 'Sprawna',
        MachineHealth.awaria => 'Awaria',
        MachineHealth.naprawa => 'Naprawa',
      };
}
