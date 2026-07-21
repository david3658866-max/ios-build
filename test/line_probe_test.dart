import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';

/// 线路探活集成测试：不依赖真机，直接请求线上 API。
void main() {
  test('主线路 /line/ping 探活应成功', () async {
    final ok = await LineManager().isAvailable(kDefaultLine);
    expect(
      ok,
      isTrue,
      reason: '${kDefaultLine.baseUrl}/line/ping 应返回 HTTP 200 且 code=200',
    );
  });

  test('ApiResponse 能解析主线路 ping 响应', () async {
    final ms = await LineManager().probe(kDefaultLine);
    expect(ms, isNotNull);
    expect(ms!, greaterThan(0));
  });
}
