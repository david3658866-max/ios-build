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
  test('mergeWithBuiltins lets remote overwrite same id and keeps remote-only',
      () {
    final remote = [
      const LineConfig(
        id: 'line1',
        name: '线路1-远程',
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
    expect(merged.map((e) => e.id).toList(), ['line1', 'lineX']);
    expect(merged.first.host, 'new-main.test');
    // Admin omitted builtins are not re-injected.
    expect(merged.any((e) => e.id == 'line2'), isFalse);
  });

  test('refreshFromRemote applies remote list (no builtin re-inject)', () async {
    final repo = LineRepository.instance;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _MemAdapter((options) {
      final payload = {
        'configVersion': 'merge-verify-v1',
        'notModified': false,
        'lines': [
          {
            'id': 'line1',
            'name': '线路1',
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

    final reached = await repo.refreshFromRemote(dio);
    expect(reached, isTrue);
    expect(repo.configVersion, 'merge-verify-v1');
    final ids = repo.productionLines.map((e) => e.id).toList();
    expect(ids, ['line1', 'lineX']);
    expect(
      repo.productionLines.firstWhere((e) => e.id == 'lineX').name,
      'REMOTE_VERIFY_LINE',
    );
  });

  test('refreshFromRemote uses absolute baseUrl when provided', () async {
    final repo = LineRepository.instance;
    final dio = Dio(BaseOptions(baseUrl: 'https://dead.invalid/api'));
    String? hitPath;
    dio.httpClientAdapter = _MemAdapter((options) {
      hitPath = options.path;
      final payload = {
        'configVersion': 'via-healthy-v1',
        'notModified': false,
        'lines': [
          {
            'id': 'line5',
            'name': '线路5',
            'label': 'ok',
            'host': 'breeze.bgznp.com',
            'baseUrl': 'https://breeze.bgznp.com/api',
            'wsUrl': 'wss://breeze.bgznp.com/im',
            'scanUrl': 'https://kavun.bgznp.com',
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

    final reached = await repo.refreshFromRemote(
      dio,
      baseUrl: 'https://breeze.bgznp.com/api',
    );
    expect(reached, isTrue);
    expect(hitPath, 'https://breeze.bgznp.com/api/line/config');
    expect(repo.configVersion, 'via-healthy-v1');
    expect(repo.productionLines.single.id, 'line5');
  });

    test('prod builtins seed 403 new lines (line45+) from app_line', () {
    expect(kBuiltinProdLines.length, 403);
    expect(kBuiltinProdLines.first.id, 'line46');
    expect(kBuiltinProdLines.first.host, 'helix.scnjrm.com');
    expect(kBuiltinProdLines.last.id, 'line447');
    expect(kBuiltinProdLines.last.host, 'glyph.dvdda.com');
    expect(kLineConfigVersion, '2026-07-31-prod-403');
  });
}
