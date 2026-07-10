import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'group_member.g.dart';

/// 群成员。对应后端 GroupMemberVO（GET /group/members/{groupId}?version=）。
/// version 用于增量同步。
@JsonSerializable()
class GroupMember {
  const GroupMember({
    required this.userId,
    this.showNickName,
    this.remarkNickName,
    this.headImage,
    this.companyName,
    this.isManager = false,
    this.isMuted = false,
    this.quit = false,
    this.online = false,
    this.showGroupName,
    this.remarkGroupName,
    this.version = 0,
  });

  @JsonKey(fromJson: JsonParse.asInt)
  final int userId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? showNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? remarkNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? headImage;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? companyName;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isManager;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isMuted;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool quit;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool online;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? showGroupName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? remarkGroupName;
  @JsonKey(fromJson: JsonParse.asInt)
  final int version;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMemberToJson(this);
}
