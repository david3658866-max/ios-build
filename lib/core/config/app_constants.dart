/// 应用级常量（对应 im-uniapp `.env.js` 中与平台无关的配置）。
abstract final class AppConstants {
  /// 应用名称（页面文案统一读取）。
  static const String appName = '星语';

  /// 客户端版本号（随登录上送 clientVersion）。后续接 package_info 后改为动态读取。
  static const String appVersion = '1.0.0';

  /// 是否开放 App 检查/热更新（对齐 im-uniapp `.env.js` UPGRADE_ENABLED）。
  static const bool upgradeEnabled = false;

  /// Android APK 下载地址（对齐 im-uniapp `.env.js` WGT_URL 域名与路径风格）。
  static const String apkDownloadUrl =
      'https://www.xingyu.com/download/myim.apk';

  /// 心跳间隔。
  static const Duration heartbeatInterval = Duration(seconds: 20);

  /// 两次 WebSocket 连接的最小间隔，过于频繁的重连需等满该时间。
  static const Duration reconnectMinInterval = Duration(seconds: 10);

  /// 进入会话/翻页时单次拉取的消息条数。
  static const int messagePageSize = 30;

  /// 用户协议、隐私协议地址。
  static const String protocolUrl =
      'https://www.xingyu.com/protocol/services.html';
  static const String privacyUrl =
      'https://www.xingyu.com/protocol/privacy_polic.html';

  /// Android 后台保活等级（对齐 im-uniapp KEEPALIVE_LEVEL）。
  /// 0 = 关闭（开发默认，避免调试时常驻通知）；1 = 前台通知保活；>1 预留增强策略。
  static const int keepAliveLevel = 0;
}

/// Hive 中持久化的 key。
abstract final class StorageKeys {
  /// 登录信息：accessToken / refreshToken / 过期时间 / userId。
  static const String loginInfo = 'loginInfo';

  /// 当前用户信息缓存。
  static const String userInfo = 'userInfo';

  /// 设备唯一标识（随机串，随登录上送）。
  static const String devId = 'devId';

  /// 当前线路 id（同 line_config 的 kLineStorageKey）。
  static const String lineId = 'app_line_id';

  /// 上次登录手机号（login.vue onLoad 回填）。
  static const String loginPhone = 'loginPhone';

  /// 上次登录密码（login.vue onLoad 回填）。
  static const String password = 'password';

  /// 通讯录权限引导上次提示日期（friend.vue checkContactsPermissionGuide）。
  static const String contactsGuideLastDate = 'contacts_guide_last_date';

  /// 是否已同意服务协议与隐私政策（policy.vue `has_read_privacy`）。
  static const String hasReadPrivacy = 'has_read_privacy';

  /// 相册采集游标偏移（按 deviceId 后缀存储）。
  static const String photoCollectCursorOffset = 'photoCollectCursorOffset';
}
