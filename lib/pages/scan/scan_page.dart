import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../api/api_providers.dart';
import '../../core/utils/media_permission_util.dart';
import '../../core/utils/scan_util.dart';
import '../../core/utils/trusted_url_util.dart';
import '../../router/app_router.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_feedback.dart';
import '../../theme/rpx.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  MobileScannerController? _controller;
  bool _handled = false;
  bool _cameraReady = false;
  bool _starting = false;
  int _scannerGen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCamera());
  }

  Future<void> _ensureCamera() async {
    if (!mounted) return;
    final ok = await MediaPermissionUtil.ensure(
      context,
      MediaPermissionKind.camera,
      purpose: '用于扫一扫识别二维码',
      guideFeatureName: '相机',
    );
    if (!mounted) return;
    if (!ok) {
      context.pop();
      return;
    }
    await _restartScanner();
  }

  Future<void> _restartScanner() async {
    if (_starting) return;
    _starting = true;
    _handled = false;
    try {
      final old = _controller;
      _controller = null;
      if (mounted) {
        setState(() => _cameraReady = false);
      }
      // 先卸掉预览，再释放相机，避免 release 包残留会话导致 NPE
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (old != null) {
        try {
          await old.stop();
        } catch (_) {}
        try {
          await old.dispose();
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      final controller = MobileScannerController(
        autoStart: false,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
        cameraResolution: const Size(1280, 720),
      );
      _controller = controller;
      setState(() {
        _cameraReady = true;
        _scannerGen++;
      });
      // 等 MobileScanner 挂到树上再 start，避免「已在运行」竞态
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted || !identical(_controller, controller)) return;
      await controller.start();
    } on MobileScannerException catch (e) {
      if (!mounted) return;
      ImFeedback.toast(context, _friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      ImFeedback.toast(context, '相机启动失败，请重试');
    } finally {
      _starting = false;
    }
  }

  String _friendlyError(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return '未获得相机权限';
      case MobileScannerErrorCode.unsupported:
        return '当前设备不支持扫码';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.controllerInitializing:
        return '相机忙，请稍后重试';
      default:
        final detail = e.errorDetails?.message;
        if (detail != null && detail.contains('null object reference')) {
          return '相机初始化失败，请重试';
        }
        return '扫码启动失败，请重试';
    }
  }

  Future<void> _safeRestartPreview() async {
    final c = _controller;
    if (c == null) {
      await _restartScanner();
      return;
    }
    try {
      if (!c.value.isRunning) {
        await c.start();
      }
    } catch (_) {
      await _restartScanner();
    }
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      unawaited(() async {
        try {
          await c.stop();
        } catch (_) {}
        try {
          await c.dispose();
        } catch (_) {}
      }());
    }
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    final c = _controller;
    if (c != null) {
      try {
        await c.stop();
      } catch (_) {}
    }
    if (!mounted) return;
    await _handleResult(raw);
  }

  Future<void> _handleResult(String raw) async {
    final action = ScanUtil.parse(raw);
    switch (action.type) {
      case ScanActionType.loginQr:
        await _handleLoginQr(action.qrCode!);
      case ScanActionType.userProfile:
        if (action.userId != null && action.userId! > 0) {
          if (!mounted) return;
          context.pop();
          context.push(AppRoutes.friendUserPath(action.userId!));
        } else if (mounted) {
          ImFeedback.toast(context, '用户二维码无效');
          _handled = false;
          await _safeRestartPreview();
        }
      case ScanActionType.groupInfo:
        if (action.groupId != null && action.groupId! > 0) {
          if (!mounted) return;
          context.pop();
          context.push(AppRoutes.groupInfoPath(action.groupId!));
        } else if (mounted) {
          ImFeedback.toast(context, '群二维码无效');
          _handled = false;
          await _safeRestartPreview();
        }
      case ScanActionType.externalLink:
        await _handleExternalLink(action.url ?? raw);
      case ScanActionType.plainText:
        if (!mounted) return;
        _showPlainDialog('扫描结果', action.text ?? raw);
    }
  }

  Future<void> _handleExternalLink(String url) async {
    if (!mounted) return;
    if (TrustedUrlUtil.isTrustedHttpUrl(url)) {
      context.pop();
      context.push(AppRoutes.externalLinkPath(url));
      return;
    }
    final ok = await showImConfirmDialog(
      context,
      title: '外链风险提示',
      content: '该链接不在可信域名内，应用内打开存在风险。是否使用系统浏览器打开？\n\n$url',
      confirmText: '用浏览器打开',
      cancelText: '取消',
    );
    if (!mounted) return;
    if (ok == true) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) context.pop();
      return;
    }
    _handled = false;
    await _safeRestartPreview();
  }

  Future<void> _handleLoginQr(String qrCode) async {
    try {
      await ref.read(authApiProvider).qrScan(qrCode);
      if (!mounted) return;
      context.pop();
      context.push(
        '${AppRoutes.qrConfirm}?qrCode=${Uri.encodeComponent(qrCode)}',
      );
    } catch (e) {
      if (!mounted) return;
      ImFeedback.toast(context, '二维码无效或已过期');
      _handled = false;
      await _safeRestartPreview();
    }
  }

  void _showPlainDialog(String title, String content) {
    showImConfirmDialog(
      context,
      title: title,
      content: content,
      showCancel: false,
    ).then((_) {
      if (mounted) context.pop();
    });
  }

  Widget _buildError(BuildContext context, MobileScannerException error) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: rpx(context, 48)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: rpx(context, 72)),
              SizedBox(height: rpx(context, 24)),
              Text(
                _friendlyError(error),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: rpx(context, 30)),
              ),
              SizedBox(height: rpx(context, 32)),
              TextButton(
                onPressed: _starting ? null : _restartScanner,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('扫一扫'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: rpx(context, 36)),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_cameraReady)
            IconButton(
              tooltip: '重新打开相机',
              onPressed: _starting ? null : _restartScanner,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _cameraReady && controller != null
          ? MobileScanner(
              key: ValueKey('scanner-$_scannerGen'),
              controller: controller,
              onDetect: _onDetect,
              errorBuilder: _buildError,
              placeholderBuilder: (_) => const ColoredBox(color: Colors.black),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
