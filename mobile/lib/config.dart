import 'dart:io';

import 'package:flutter/foundation.dart';

/// Base URL for the ANDON REST API.
///
/// - Android emulator talks to the host via 10.0.2.2
/// - iOS simulator / desktop / web use localhost
/// - Physical devices: set [overrideBaseUrl] to your PC LAN IP
class ApiConfig {
  static const String? overrideBaseUrl = null;

  static String get baseUrl {
    if (overrideBaseUrl != null) {
      return overrideBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
