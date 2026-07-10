import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'chat_session_summary.g.dart';

/// 会话摘要。对应后端 ChatSessionSummaryVO（GET /message/offline/sessionSummary）。
/// 启动时拉取，用于初始化/对齐本地会话列表。
@JsonSerializable()
class ChatSessionSummary {
  const ChatSessionSummary({
    required this.type,
    required this.targetId,
    this.lastContent,
    this.lastSendTime,
    this.sendNickName,
    this.unreadCount = 0,
    this.maxMsgId = 0,
    this.showName,
    this.headImage,
    this.companyName,
    this.isDnd = false,
    this.isTop = false,
  });

  /// PRIVATE / GROUP / SYSTEM。
  @JsonKey(fromJson: JsonParse.asString)
  final String type;
  @JsonKey(fromJson: JsonParse.asInt)
  final int targetId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? lastContent;

  /// 最后消息时间（毫秒时间戳）。
  @JsonKey(fromJson: JsonParse.asNullableDateTimeMs)
  final int? lastSendTime;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? sendNickName;
  @JsonKey(fromJson: JsonParse.asInt)
  final int unreadCount;
  @JsonKey(fromJson: JsonParse.asInt)
  final int maxMsgId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? showName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? headImage;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? companyName;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isDnd;
  @JsonKey(fromJson: JsonParse.asBool)
  final bool isTop;

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSessionSummaryToJson(this);
}
