import 'package:flutter/material.dart';

import 'models.dart';

const Color andonRed = Color(0xFFC62828);
const Color andonAmber = Color(0xFFF9A825);
const Color andonGreen = Color(0xFF2E7D32);
const Color andonBg = Color(0xFF101418);
const Color andonSurface = Color(0xFF1A222B);
const Color andonCard = Color(0xFF24303C);

ThemeData buildAndonTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE53935),
      brightness: Brightness.dark,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: andonBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: andonSurface,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: andonCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: andonRed,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: andonSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

Color colorForMachineHealth(MachineHealth health) => switch (health) {
      MachineHealth.sprawna => andonGreen,
      MachineHealth.awaria => andonRed,
      MachineHealth.naprawa => andonAmber,
    };

Color colorForIncidentStatus(IncidentStatus status) => switch (status) {
      IncidentStatus.open => andonRed,
      IncidentStatus.inProgress => andonAmber,
      IncidentStatus.resolved => andonGreen,
    };

Color colorForPriority(Priority priority) => switch (priority) {
      Priority.low => const Color(0xFF90A4AE),
      Priority.medium => andonAmber,
      Priority.high => andonRed,
    };
