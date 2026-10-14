import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ufuq_imperium/core/network/api_client.dart';
import 'package:ufuq_imperium/core/network/api_exception.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('ApiClient.envelope', () {
    test('unwraps {data: ...} and {data: {data: ...}}', () {
      expect(
        ApiClient.envelope({
          'data': [1],
        }),
        [1],
      );
      expect(
        ApiClient.envelope({
          'data': {
            'data': [2],
          },
        }),
        [2],
      );
      expect(ApiClient.envelope([3]), [3]);
    });
  });

  group('ApiClient.list', () {
    test('follows Laravel pagination', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          final page = request.url.queryParameters['page'] ?? '1';
          return _json({
            'data': [
              {'id': int.parse(page)},
            ],
            'meta': {'last_page': 3},
          });
        }),
      );
      final items = await client.list('/projects');
      expect(items.map((i) => i['id']), [1, 2, 3]);
    });

    test('maps HTTP errors to ApiException', () async {
      final client = ApiClient(
        client: MockClient((_) async => _json({'message': 'taken'}, 409)),
      );
      await expectLater(
        client.post('/x', {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isConflict, 'isConflict', true)
              .having((e) => e.message, 'message', 'taken'),
        ),
      );
    });

    test('reports offline as status 0', () async {
      final client = ApiClient(
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      await expectLater(
        client.list('/x'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)),
      );
    });
  });
}
