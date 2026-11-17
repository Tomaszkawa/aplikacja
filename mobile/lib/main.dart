import 'package:flutter/material.dart';

import 'api_client.dart';
import 'screens/machines_screen.dart';
import 'theme.dart';

void main() {
  runApp(const AndonApp());
}

class AndonApp extends StatelessWidget {
  const AndonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();
    return MaterialApp(
      title: 'ANDON',
      debugShowCheckedModeBanner: false,
      theme: buildAndonTheme(),
      home: MachinesScreen(api: api),
    );
  }
}
