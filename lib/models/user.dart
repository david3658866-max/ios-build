import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'user.g.dart';

/// 用户信息。对应后端 UserVO（GET /user/self、/user/find/{id}，PUT /user/update）。
@JsonSerializable()
class User {
  const User({
    required this.id,
    this.userName,
    this.phone,
    this.email,
    this.nickName,
    this.sex = 0,
    this.type = 1,
    this.signature,
    this.headImage,
    this.headImageThumb,
    this.companyName,
    this.isBanned = false,
    this.reason,
    this.isManualApprove = false,
    this.isInBlacklist = false,
    this.isAudioTip = false,
    this.status = 0,
    this.online = false,
    this.lastLoginTime,
    this.userIdentity = 0,
    this.agentId,
    this.isRealName = false,
    this.totpEnabled = false,
  });

  @JsonKey(fromJson: JsonParse.asInt)
  final int id;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? userName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? phone;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? email;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? nickName;

  /// 性别。
  @JsonKey(fromJson: JsonParse.asInt)
  final int sex;

  /// 1 普通 / 2 审核账户。
  @JsonKey(fromJson: JsonParse.typeFromJson)
  final int type;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? signature;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? headImage;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? headImageThumb;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? companyName;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isBanned;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? reason;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isManualApprove;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isInBlacklist;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isAudioTip;

  /// 0 正常 / 1 注销。
  @JsonKey(fromJson: JsonParse.asInt)
  final int status;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool online;

  /// 最后登录时间（毫秒时间戳）。
  @JsonKey(fromJson: JsonParse.asNullableDateTimeMs)
  final int? lastLoginTime;

  /// 0 普通 / 1 高级。
  @JsonKey(fromJson: JsonParse.asInt)
  final int userIdentity;
  @JsonKey(fromJson: JsonParse.asNullableInt)
  final int? agentId;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isRealName;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool totpEnabled;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
