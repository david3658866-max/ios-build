# vortek

Vortek IM - Flutter migration of im-uniapp

## Android 真机本地调试

本地调试真机不要直接裸跑 `flutter run`，请使用统一入口：

```powershell
powershell -File scripts/run-device.ps1 -DeviceId ZE223JPF9T
```

该脚本会先恢复 `adb reverse` 端口映射，再启动 Flutter。必须映射的本地端口包括：

- `27418`：IM API
- `27893`：IM WebSocket
- `8080`：本地 Web/H5 扫码入口
- `9001`：本地媒体/静态文件服务，图片、头像、文件预览依赖它

如果真机日志出现 `http://127.0.0.1:9001/... Connection refused`，优先检查端口映射，不要先改图片气泡代码。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
