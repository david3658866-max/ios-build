import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'friend.g.dart';

/// 好友。对应后端 FriendVO（GET /friend/list、/friend/find/{friendId}）。
@JsonSerializable()
class Friend {
  const Friend({
    required this.id,
    this.nickName,
    this.showNickName,
    this.remarkNickName,
    this.headImage,
    this.companyName,
    this.isDnd = false,
    this.isTop = false,
    this.deleted = false,
    this.online = false,
    this.onlineWeb = false,
    this.onlineApp = false,
  });

  @JsonKey(fromJson: JsonParse.asInt)
  final int id;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? nickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? showNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? remarkNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? headImage;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? companyName;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isDnd;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isTop;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool deleted;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool online;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool onlineWeb;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool onlineApp;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);

  Map<String, dynamic> toJson() => _$FriendToJson(this);
}
