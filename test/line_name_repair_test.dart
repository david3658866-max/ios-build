import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_repository.dart';

void main() {
  test('merge repairs ??? display text from builtins', () {
    final remote = [
      const LineConfig(
        id: 'line1',
        name: '???',
        label: 'de010 ???',
        host: 'new-main.test',
        baseUrl: 'https://new-main.test/api',
        wsUrl: 'wss://new-main.test/im',
        scanUrl: 'https://h5.test',
      ),
    ];
    final merged = LineRepository.mergeWithBuiltins(remote);
    final line1 = merged.firstWhere((e) => e.id == 'line1');
    expect(line1.host, 'new-main.test');
    expect(line1.name, isNot('???'));
    expect(line1.name, kBuiltinProductionLines.first.name);
  });

  test('merge does not re-inject admin-disabled builtin lines', () {
    final remote = [
      const LineConfig(
        id: 'line1',
        name: '主线路',
        label: 'main',
        host: 'zenty.bgznp.com',
        baseUrl: 'https://zenty.bgznp.com/api',
        wsUrl: 'wss://zenty.bgznp.com/im',
        scanUrl: 'https://kavun.bgznp.com',
      ),
      const LineConfig(
        id: 'line3',
        name: '备用线路2',
        label: 'bak2',
        host: 'muvin.bgznp.com',
        baseUrl: 'https://muvin.bgznp.com/api',
        wsUrl: 'wss://muvin.bgznp.com/im',
        scanUrl: 'https://kavun.bgznp.com',
      ),
    ];
    final merged = LineRepository.mergeWithBuiltins(remote);
    expect(merged.map((e) => e.id).toList(), ['line1', 'line3']);
    expect(merged.any((e) => e.id == 'line2'), isFalse);
  });
}