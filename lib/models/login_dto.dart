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

  /// 主卡 IMEI（Android 尽力采集）
  final String? imei;

  /// 副卡 IMEI
  final String? imei2;

  factory LoginDTO.fromJson(Map<String, dynamic> json) =>
      _$LoginDTOFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDTOToJson(this);
}
