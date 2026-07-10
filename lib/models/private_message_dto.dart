import 'package:json_annotation/json_annotation.dart';

part 'private_message_dto.g.dart';

/// 私聊发送请求体。对应后端 PrivateMessageDTO。
@JsonSerializable(includeIfNull: false)
class PrivateMessageDTO {
  const PrivateMessageDTO({
    required this.tmpId,
    required this.recvId,
    required this.content,
    this.type = 0,
    this.quoteMessageId,
  });

  final String tmpId;
  final int recvId;

  /// 文本内容，≤1024。
  final String content;
  final int type;
  final int? quoteMessageId;

  factory PrivateMessageDTO.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessageDTOFromJson(json);

  Map<String, dynamic> toJson() => _$PrivateMessageDTOToJson(this);
}
