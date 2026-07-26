# WS failover + chip HTTP/WS

## Plan
- P0: 2 consecutive WS disconnected without connected -> probeAll + adoptHealthyLine + forceReconnect; cooldown 60s on success, 15s on fail
- P1: logged-in + HTTP ok + WS down -> chip shows 消息异常 (orange), not 连接失败

## Files
- lib/core/utils/line_switch_util.dart
- lib/core/di/app_providers.dart
- lib/services/auth_controller.dart
- lib/widgets/line_switcher.dart
- test/line_switch_test.dart

## Verify
1. flutter test test/line_switch_test.dart
2. Device: after login, HTTP ok + WS down shows 消息异常; 2 disconnects toast auto switch