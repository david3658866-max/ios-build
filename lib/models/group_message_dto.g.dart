// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMessageDTO _$GroupMessageDTOFromJson(Map<String, dynamic> json) =>
    GroupMessageDTO(
      tmpId: json['tmpId'] as String,
      groupId: (json['groupId'] as num).toInt(),
      content: json['content'] as String,
      type: (json['type'] as num?)?.toInt() ?? 0,
      receipt: json['receipt'] as bool? ?? false,
      atUserIds:
          (json['atUserIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      quoteMessageId: (json['quoteMessageId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GroupMessageDTOToJson(GroupMessageDTO instance) =>
    <String, dynamic>{
      'tmpId': instance.tmpId,
      'groupId': instance.groupId,
      'content': instance.content,
      'type': instance.type,
      'receipt': instance.receipt,
      'atUserIds': instance.atUserIds,
      'quoteMessageId': ?instance.quoteMessageId,
    };
