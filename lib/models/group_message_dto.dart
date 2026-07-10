import 'package:json_annotation/json_annotation.dart';

part 'group_message_dto.g.dart';

/// 群聊发送请求体。对应后端 GroupMessageDTO。
@JsonSerializable(includeIfNull: false)
class GroupMessageDTO {
  const GroupMessageDTO({
    required this.tmpId,
    required this.groupId,
    required this.content,
    this.type = 0,
    this.receipt = false,
    this.atUserIds = const [],
    this.quoteMessageId,
  });

  final String tmpId;
  final int groupId;

  /// 文本内容，≤1024。
  final String content;
  final int type;

  /// 是否回执消息，默认 false。
  final bool receipt;

  /// @ 的用户 id 列表，≤20。
  final List<int> atUserIds;
  final int? quoteMessageId;

  factory GroupMessageDTO.fromJson(Map<String, dynamic> json) =>
      _$GroupMessageDTOFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMessageDTOToJson(this);
}
