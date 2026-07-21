import 'package:json_annotation/json_annotation.dart';

part 'login_dto.g.dart';

/// 登录请求体。对应后端 LoginDTO（POST /login）。
@JsonSerializable(includeIfNull: false)
class LoginDTO {
  const LoginDTO({
    this.mode = 'username',
    this.terminal = 1,
    this.userName,
    this.phone,
    this.email,
    required this.password,
    this.totpCode,
    this.code,
    this.deviceInfo,
    this.deviceId,
    this.clientVersion,
    this.loginType,
    this.platform,
    this.rawHardwareId,
    this.imei,
    this.imei2,
    this.isPhysicalDevice,
    this.emulatorSuspect,
    this.deviceCheckToken,
  });

  /// username / phone / email。
  final String mode;

  /// 0:web 1:app 2:pc —— App 固定传 1。
  final int terminal;
  final String? userName;
  final String? phone;
  final String? email;
  final String password;

  /// Google 验证器（可空）。
  final String? totpCode;

  /// 验证码（可空）。
  final String? code;
  final String? deviceInfo;
  final String? deviceId;
  final String? clientVersion;

  /// android / ios，精确区分在线端。
  final String? loginType;

  /// android | ios
  final String? platform;

  /// Android ANDROID_ID / iOS IDFV
  final String? rawHardwareId;

  /// 已废弃：客户端不再采集 IMEI，保留字段仅为兼容旧包/历史数据。
  final String? imei;

  /// 已废弃：客户端不再采集 IMEI2。
  final String? imei2;

  /// 是否物理真机
  final bool? isPhysicalDevice;

  /// 疑似模拟器/云机
  final bool? emulatorSuspect;

  /// iOS DeviceCheck token（Base64），可空
  final String? deviceCheckToken;

  factory LoginDTO.fromJson(Map<String, dynamic> json) =>
      _$LoginDTOFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDTOToJson(this);
}
