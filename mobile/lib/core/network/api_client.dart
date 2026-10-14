import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:ufuq_imperium/core/config/app_config.dart';
import 'package:ufuq_imperium/core/network/api_exception.dart';

/// Thin JSON client over the public Laravel API. No auth, no WebView.
/// Features build their repositories on top of it.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 25);
  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${AppConfig.apiUrl}$path').replace(queryParameters: query);

  void close() => _client.close();

  /// One resource, already unwrapped from Laravel's `{data: ...}` envelope.
  Future<Object?> getData(String path) async => envelope(await get(path));

  /// The raw decoded JSON of a GET.
  Future<Object?> get(String path, [Map<String, String>? query]) async {
    final http.Response response;
    try {
      response = await _client
          .get(_uri(path, query), headers: _headers)
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'timeout');
    } catch (_) {
      throw ApiException(0, 'offline');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _message(response));
    }
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException(response.statusCode, 'bad json');
    }
  }

  Future<void> post(String path, Map<String, Object?> body) async {
    final http.Response response;
    try {
      response = await _client
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'timeout');
    } catch (_) {
      throw ApiException(0, 'offline');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _message(response));
    }
  }

  /// A list endpoint. Follows Laravel pagination when the response carries it.
  Future<List<Map<String, dynamic>>> list(String path) async {
    final first = await get(path);
    final items = _asMaps(envelope(first));
    final last = _lastPage(first);
    if (last > 1) {
      final rest = await Future.wait([
        for (var page = 2; page <= last && page <= 20; page++)
          get(path, {'page': '$page'}).then((body) => _asMaps(envelope(body))),
      ]);
      for (final more in rest) {
        items.addAll(more);
      }
    }
    return items;
  }

  /// Laravel resources arrive as `{data: ...}` and sometimes `{data: {data: ...}}`.
  static Object? envelope(Object? body) {
    if (body is! Map || !body.containsKey('data')) return body;
    final data = body['data'];
    if (data is Map && data.containsKey('data')) return data['data'];
    return data;
  }

  int _lastPage(Object? body) {
    if (body is! Map) return 1;
    final meta = body['meta'];
    if (meta is Map) {
      final value = meta['last_page'];
      if (value is num) return value.toInt();
    }
    return 1;
  }

  List<Map<String, dynamic>> _asMaps(Object? value) => value is List
      ? [
          for (final item in value)
            if (item is Map) Map<String, dynamic>.from(item),
        ]
      : <Map<String, dynamic>>[];

  String? _message(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
    } catch (_) {}
    return null;
  }
}
