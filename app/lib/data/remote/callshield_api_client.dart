import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class CallShieldApiClient {
  final String baseUrl;
  final http.Client _client;

  CallShieldApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConstants.defaultDesktopApiUrl,
        _client = client ?? http.Client();

  Future<Map<String, dynamic>?> fetchManifest() async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl/api/data/manifest'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fetchShard(String shardKey) async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl/api/data/shards/$shardKey'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fetchHotNumbers() async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl/api/data/hot_numbers'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>> fetchSpamDomains() async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl/api/data/spam_domains'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> fetchModelWeights() async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl/api/data/model_weights'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> submitSpamReport({
    required String number,
    required String type,
    List<String>? smsDomains,
    List<String>? smsUrlIndicators,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'number': number,
          'type': type,
          if (smsDomains != null && smsDomains.isNotEmpty) 'sms_domains': smsDomains,
          if (smsUrlIndicators != null && smsUrlIndicators.isNotEmpty)
            'sms_url_indicators': smsUrlIndicators,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> lookupCaller(String number) async {
    try {
      final encoded = Uri.encodeComponent(number);
      final res = await _client.get(Uri.parse('$baseUrl/api/lookup/$encoded'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> batchAnalyze(List<Map<String, dynamic>> items) async {
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/lookup/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': items}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
