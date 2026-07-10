import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

import 'quote_message.dart';

part 'group_message.g.dart';

/// 群聊消息。对应后端 GroupMessageVO（cmd4 data / 群聊发送&离线返回）。
@JsonSerializable(explicitToJson: true)
class GroupMessage {
  const GroupMessage({
    this.id,
    this.tmpId,
    required this.groupId,
    required this.sendId,
    this.sendNickName,
    this.content,
    this.type = 0,
    this.receipt = false,
    this.receiptOk = false,
    this.readedCount = 0,
    this.atUserIds = const [],
    this.quoteMessage,
    this.status = 0,
    this.sendTime,
  });

  @JsonKey(fromJson: JsonParse.asNullableInt)
  final int? id;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? tmpId;
  @JsonKey(fromJson: JsonParse.asInt)
  final int groupId;
  @JsonKey(fromJson: JsonParse.asInt)
  final int sendId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? sendNickName;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? content;
  @JsonKey(fromJson: JsonParse.asInt)
  final int type;

  /// 是否回执消息。
  @JsonKey(fromJson: JsonParse.asBool)
  final bool receipt;

  /// 回执是否已完成。
  @JsonKey(fromJson: JsonParse.asBool)
  final bool receiptOk;
  @JsonKey(fromJson: JsonParse.asInt)
  final int readedCount;

  /// @ 的用户 id 列表。
  @JsonKey(fromJson: JsonParse.asIntList)
  final List<int> atUserIds;
  final QuoteMessage? quoteMessage;
  @JsonKey(fromJson: JsonParse.asInt)
  final int status;

  /// 发送时间（毫秒时间戳）。
  @JsonKey(fromJson: JsonParse.asNullableDateTimeMs)
  final int? sendTime;

  factory GroupMessage.fromJson(Map<String, dynamic> json) =>
      _$GroupMessageFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMessageToJson(this);
}
