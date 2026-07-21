import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_repository.dart';

void main() {
  test('LineConfig json roundtrip', () {
    final line = kBuiltinProdLines.first;
    final again = LineConfig.fromJson(line.toJson());
    expect(again.id, line.id);
    expect(again.baseUrl, line.baseUrl);
    expect(again.wsUrl, line.wsUrl);
  });

  test('LineRepository starts from builtin seeds', () {
    final repo = LineRepository.instance;
    expect(repo.productionLines, isNotEmpty);
    expect(repo.productionLines.first.id, 'line1');
    expect(repo.configVersion, isNotEmpty);
    final encoded = jsonEncode(
      repo.productionLines.map((e) => e.toJson()).toList(),
    );
    expect(encoded.contains('zenty') || encoded.contains('kivola'), isTrue);
  });

  test('bindLineRuntime overrides kLines getters', () {
    bindLineRuntime(
      productionLines: () => [
            const LineConfig(
              id: 'lineX',
              name: 'X',
              label: 'X',
              host: 'x.test',
              baseUrl: 'https://x.test/api',
              wsUrl: 'wss://x.test/im',
              scanUrl: 'https://h5.test',
            ),
          ],
      visibleLines: () => [
            const LineConfig(
              id: 'lineX',
              name: 'X',
              label: 'X',
              host: 'x.test',
              baseUrl: 'https://x.test/api',
              wsUrl: 'wss://x.test/im',
              scanUrl: 'https://h5.test',
            ),
          ],
      byId: (id) => const LineConfig(
            id: 'lineX',
            name: 'X',
            label: 'X',
            host: 'x.test',
            baseUrl: 'https://x.test/api',
            wsUrl: 'wss://x.test/im',
            scanUrl: 'https://h5.test',
          ),
      defaultLine: () => const LineConfig(
            id: 'lineX',
            name: 'X',
            label: 'X',
            host: 'x.test',
            baseUrl: 'https://x.test/api',
            wsUrl: 'wss://x.test/im',
            scanUrl: 'https://h5.test',
          ),
      configVersion: () => 'test-ver',
    );
    expect(kLines.single.id, 'lineX');
    expect(effectiveLineConfigVersion, 'test-ver');
    expect(lineById('anything').id, 'lineX');
  });
}