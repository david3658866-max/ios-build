import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

import 'group_message.dart';

part 'group.g.dart';

/// 群。对应后端 GroupVO（GET /group/list、/group/find/{groupId}）。
@JsonSerializable()
class Group {
  const Group({
    required this.id,
    this.name,
    this.ownerId,
    this.headImage,
    this.headImageThumb,
    this.notice,
    this.remarkNickName,
    this.showNickName,
    this.showGroupName,
    this.remarkGroupName,
    this.isAllMuted = false,
    this.isAllowInvite = false,
    this.isAllowShareCard = false,
    this.dissolve = false,
    this.quit = false,
    this.isMuted = false,
    this.isBanned = false,
    this.reason,
    this.isDnd = false,
    this.isTop = false,
    this.topMessage,
  });

  @JsonKey(fromJson: JsonParse.asInt)
  final int id;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? name;
  @JsonKey(fromJson: JsonParse.asNullableInt)
  final int? ownerId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? headImage;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? headImageThumb;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? notice;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? remarkNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? showNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? showGroupName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? remarkGroupName;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isAllMuted;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isAllowInvite;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isAllowShareCard;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool dissolve;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool quit;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isMuted;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isBanned;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? reason;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isDnd;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isTop;

  /// 群置顶消息。
  final GroupMessage? topMessage;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);

  Map<String, dynamic> toJson() => _$GroupToJson(this);
}
