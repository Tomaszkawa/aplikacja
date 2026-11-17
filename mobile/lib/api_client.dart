import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<Machine>> fetchMachines() async {
    final response = await _get('/machines');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Machine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Incident>> fetchIncidents() async {
    final response = await _get('/incidents');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Incident> createIncident({
    required int machineId,
    required String description,
    required Priority priority,
  }) async {
    final response = await _send(
      'POST',
      '/incidents',
      body: {
        'machine_id': machineId,
        'description': description,
        'priority': priority.apiValue,
      },
      okStatuses: {201},
    );
    return Incident.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Incident> updateIncidentStatus({
    required int incidentId,
    required IncidentStatus status,
  }) async {
    final response = await _send(
      'PATCH',
      '/incidents/$incidentId',
      body: {'status': status.apiValue},
      okStatuses: {200},
    );
    return Incident.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<http.Response> _get(String path) =>
      _send('GET', path, okStatuses: {200});

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required Set<int> okStatuses,
  }) async {
    try {
      final uri = _uri(path);
      late final http.Response response;
      final headers = {'Content-Type': 'application/json'};

      switch (method) {
        case 'GET':
          response = await _client.get(uri).timeout(const Duration(seconds: 8));
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 8));
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 8));
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      if (!okStatuses.contains(response.statusCode)) {
        throw ApiException(
          _messageFromBody(response.body, response.statusCode),
          statusCode: response.statusCode,
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Brak połączenia z serwerem ($_baseUrl). '
        'Uruchom backend i sprawdź adres API.',
      );
    }
  }

  String _messageFromBody(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        return detail.toString();
      }
    } catch (_) {}
    return 'Błąd serwera (HTTP $statusCode)';
  }
}
