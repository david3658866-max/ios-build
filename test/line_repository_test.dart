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
    expect(repo.productionLines.first.id, kBuiltinProductionLines.first.id);
    expect(repo.configVersion, isNotEmpty);
    final encoded = jsonEncode(
      repo.productionLines.map((e) => e.toJson()).toList(),
    );
    expect(
      encoded.contains('helix') ||
          encoded.contains('orion') ||
          encoded.contains('kivola'),
      isTrue,
    );
    // 冷启动时探活池应覆盖全部内置种子。
    expect(
      repo.probeCandidateLines.length,
      greaterThanOrEqualTo(kBuiltinProductionLines.length),
    );
  });

  test('mergeWithBuiltins keeps remote enabled; probe pool still has seeds', () {
    final remote = kPreferredBuiltinLineIds.take(3).map((id) {
      final seed = kBuiltinProdLines.firstWhere((e) => e.id == id);
      return seed;
    }).toList();
    final merged = LineRepository.mergeWithBuiltins(remote);
    expect(merged.length, 3);
    // byId 仍能解析未下发种子（failover 用）；merge 不含远程未启用的种子。
    final seedId = kBuiltinProdLines
        .firstWhere((e) => remote.every((r) => r.id != e.id))
        .id;
    expect(merged.any((e) => e.id == seedId), isFalse);
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