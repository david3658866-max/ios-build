import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

import 'private_message.dart';

part 'friend.g.dart';

/// 好友。对应后端 FriendVO（GET /friend/list、/friend/find/{friendId}）。
@JsonSerializable(explicitToJson: true)
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
    this.topMessage,
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

  /// 私聊置顶消息（双方可见）。
  final PrivateMessage? topMessage;

  Friend copyWith({
    int? id,
    String? nickName,
    String? showNickName,
    String? remarkNickName,
    String? headImage,
    String? companyName,
    bool? isDnd,
    bool? isTop,
    bool? deleted,
    bool? online,
    bool? onlineWeb,
    bool? onlineApp,
    PrivateMessage? topMessage,
    bool clearTopMessage = false,
  }) {
    return Friend(
      id: id ?? this.id,
      nickName: nickName ?? this.nickName,
      showNickName: showNickName ?? this.showNickName,
      remarkNickName: remarkNickName ?? this.remarkNickName,
      headImage: headImage ?? this.headImage,
      companyName: companyName ?? this.companyName,
      isDnd: isDnd ?? this.isDnd,
      isTop: isTop ?? this.isTop,
      deleted: deleted ?? this.deleted,
      online: online ?? this.online,
      onlineWeb: onlineWeb ?? this.onlineWeb,
      onlineApp: onlineApp ?? this.onlineApp,
      topMessage: clearTopMessage ? null : (topMessage ?? this.topMessage),
    );
  }

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);

  Map<String, dynamic> toJson() => _$FriendToJson(this);
}
