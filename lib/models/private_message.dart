import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

import 'quote_message.dart';

part 'private_message.g.dart';

/// 私聊消息。对应后端 PrivateMessageVO（cmd3 data / 私聊发送&离线返回）。
///
/// 不含 sendNickName/selfSend：客户端本地计算 selfSend=(sendId==我)，名称从好友表取。
@JsonSerializable(explicitToJson: true)
class PrivateMessage {
  const PrivateMessage({
    this.id,
    this.tmpId,
    required this.sendId,
    required this.recvId,
    this.content,
    this.type = 0,
    this.quoteMessage,
    this.status = 0,
    this.sendTime,
  });

  /// 服务端消息 id（发送中为空）。
  @JsonKey(fromJson: JsonParse.asNullableInt)
  final int? id;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? tmpId;
  @JsonKey(fromJson: JsonParse.asInt)
  final int sendId;
  @JsonKey(fromJson: JsonParse.asInt)
  final int recvId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? content;
  @JsonKey(fromJson: JsonParse.asInt)
  final int type;
  final QuoteMessage? quoteMessage;
  @JsonKey(fromJson: JsonParse.asInt)
  final int status;

  /// 发送时间（毫秒时间戳）。
  @JsonKey(fromJson: JsonParse.asNullableDateTimeMs)
  final int? sendTime;

  factory PrivateMessage.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PrivateMessageToJson(this);
}
