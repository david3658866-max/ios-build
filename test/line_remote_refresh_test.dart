import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_repository.dart';

class _MemAdapter implements HttpClientAdapter {
  _MemAdapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);
}

void main() {
  test('mergeWithBuiltins keeps seeds and lets remote overwrite same id', () {
    final remote = [
      const LineConfig(
        id: 'line1',
        name: '主线路-远程',
        label: 'remote',
        host: 'new-main.test',
        baseUrl: 'https://new-main.test/api',
        wsUrl: 'wss://new-main.test/im',
        scanUrl: 'https://h5.test',
      ),
      const LineConfig(
        id: 'lineX',
        name: 'REMOTE_ONLY',
        label: 'added',
        host: 'x.test',
        baseUrl: 'https://x.test/api',
        wsUrl: 'wss://x.test/im',
        scanUrl: 'https://h5.test',
      ),
    ];
    final merged = LineRepository.mergeWithBuiltins(remote);
    expect(merged.first.id, 'line1');
    expect(merged.first.host, 'new-main.test');
    expect(merged.any((e) => e.id == 'lineX'), isTrue);
    // Builtin line2~line4 still present even though remote omitted them.
    for (final seed in kBuiltinProductionLines) {
      expect(merged.any((e) => e.id == seed.id), isTrue, reason: seed.id);
    }
    final line2 = merged.firstWhere((e) => e.id == 'line2');
    expect(line2.host, kBuiltinProductionLines.firstWhere((e) => e.id == 'line2').host);
  });

  test('refreshFromRemote merges remote with builtins', () async {
    final repo = LineRepository.instance;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _MemAdapter((options) {
      final payload = {
        'configVersion': 'merge-verify-v1',
        'notModified': false,
        'lines': [
          {
            'id': 'line1',
            'name': '主线路',
            'label': 'remote-verify',
            'host': 'kivola.de010.com',
            'baseUrl': 'https://kivola.de010.com/api',
            'wsUrl': 'wss://kivola.de010.com/im',
            'scanUrl': 'https://novali.de010.com',
          },
          {
            'id': 'lineX',
            'name': 'REMOTE_VERIFY_LINE',
            'label': 'added-by-remote',
            'host': 'new.de010.com',
            'baseUrl': 'https://new.de010.com/api',
            'wsUrl': 'wss://new.de010.com/im',
            'scanUrl': 'https://novali.de010.com',
          },
        ],
      };
      return ResponseBody.fromString(
        jsonEncode(payload),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final changed = await repo.refreshFromRemote(dio);
    expect(changed, isTrue);
    expect(repo.configVersion, 'merge-verify-v1');
    final ids = repo.productionLines.map((e) => e.id).toList();
    expect(ids.contains('line1'), isTrue);
    expect(ids.contains('lineX'), isTrue);
    expect(ids.contains('line2'), isTrue);
    expect(ids.contains('line3'), isTrue);
    expect(ids.contains('line4'), isTrue);
    expect(
      repo.productionLines.firstWhere((e) => e.id == 'lineX').name,
      'REMOTE_VERIFY_LINE',
    );
  });
}