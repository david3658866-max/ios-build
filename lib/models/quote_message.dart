import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'quote_message.g.dart';

/// 引用消息（内嵌于私聊/群聊消息）。对应后端 QuoteMessageVO。
@JsonSerializable()
class QuoteMessage {
  const QuoteMessage({
    required this.id,
    this.sendId,
    this.content,
    this.type = 0,
    this.status = 0,
  });

  @JsonKey(fromJson: JsonParse.asInt)
  final int id;
  @JsonKey(fromJson: JsonParse.asNullableInt)
  final int? sendId;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? content;
  @JsonKey(fromJson: JsonParse.asInt)
  final int type;
  @JsonKey(fromJson: JsonParse.asInt)
  final int status;

  factory QuoteMessage.fromJson(Map<String, dynamic> json) =>
      _$QuoteMessageFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteMessageToJson(this);
}
