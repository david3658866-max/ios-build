import 'package:json_annotation/json_annotation.dart';

part 'register_dto.g.dart';

/// 注册请求体。对应后端 RegisterDTO（POST /register）。
@JsonSerializable(includeIfNull: false)
class RegisterDTO {
  const RegisterDTO({
    this.mode = 'username',
    this.userName,
    this.phone,
    this.email,
    required this.password,
    this.nickName,
    this.code,
    this.deviceInfo,
    this.deviceId,
    this.clientVersion,
    this.loginType,
    this.inviteCode,
    this.registerTerminal = 1,
  });

  final String mode;
  final String? userName;
  final String? phone;
  final String? email;

  /// 5-20 位。
  final String password;
  final String? nickName;
  final String? code;
  final String? deviceInfo;
  final String? deviceId;
  final String? clientVersion;
  final String? loginType;

  /// H5/APP 必填邀请码。
  final String? inviteCode;

  /// 0:web 1:app 2:pc。
  final int registerTerminal;

  factory RegisterDTO.fromJson(Map<String, dynamic> json) =>
      _$RegisterDTOFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDTOToJson(this);
}
