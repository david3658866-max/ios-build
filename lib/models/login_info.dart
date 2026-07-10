import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'login_info.g.dart';

/// 登录令牌信息。对应后端 LoginVO（POST /login、PUT /refreshToken 返回）。
///
/// 注意：`*ExpiresIn` 后端返回的是**秒**。
@JsonSerializable()
class LoginInfo {
  const LoginInfo({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.accessTokenExpiresIn = 0,
    this.refreshTokenExpiresIn = 0,
    this.deviceId,
  });

  @JsonKey(fromJson: JsonParse.asString)
  final String accessToken;
  @JsonKey(fromJson: JsonParse.asString)
  final String refreshToken;
  /// 用户 ID。后端 LoginVO 可能返回 null，此时降级为 0（token 仍有效，userId 由 /user/self 补齐）。
  @JsonKey(fromJson: JsonParse.asInt)
  final int userId;

  /// access token 有效期（秒）。
  @JsonKey(fromJson: JsonParse.asInt)
  final int accessTokenExpiresIn;

  /// refresh token 有效期（秒）。
  @JsonKey(fromJson: JsonParse.asInt)
  final int refreshTokenExpiresIn;

  /// 服务端确认的设备 ID（App 登录绑定后返回）。
  @JsonKey(fromJson: JsonParse.asString)
  final String? deviceId;

  factory LoginInfo.fromJson(Map<String, dynamic> json) =>
      _$LoginInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginInfoToJson(this);
}
