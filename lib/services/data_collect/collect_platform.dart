import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// 是否支持原生设备采集（仅 Flutter 安卓 / iOS，不含 Web 与其它端）。
bool get supportsNativeCollect =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);
