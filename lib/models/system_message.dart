import 'package:json_annotation/json_annotation.dart';

import '../core/utils/json_parse.dart';

part 'system_message.g.dart';

/// 系统消息。对应后端 SystemMessageVO（cmd5 data / 系统离线返回）。
///
/// 坑点：序号字段后端可能序列化为 `SeqNo`（大写）或 `seqNo`，两者都要兼容
/// （原 uniapp 已做兼容），故用 readValue 双取。
@JsonSerializable()
class SystemMessage {
  const SystemMessage({
    required this.id,
    this.seqNo = 0,
    this.title,
    this.coverUrl,
    this.intro,
    this.content,
    this.type = 0,
    this.status = 0,
    this.sendTime,
  });

  @JsonKey(fromJson: JsonParse.asInt)
  final int id;

  @JsonKey(readValue: _readSeqNo, fromJson: JsonParse.asInt)
  final int seqNo;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? title;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? coverUrl;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? intro;
  @JsonKey(fromJson: JsonParse.asNullableString)
  final String? content;
  @JsonKey(fromJson: JsonParse.asInt)
  final int type;
  @JsonKey(fromJson: JsonParse.asInt)
  final int status;

  /// 发送时间（毫秒时间戳）。
  @JsonKey(fromJson: JsonParse.asNullableDateTimeMs)
  final int? sendTime;

  factory SystemMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SystemMessageToJson(this);
}

Object? _readSeqNo(Map json, String key) => json['SeqNo'] ?? json['seqNo'];
