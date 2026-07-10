// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateMessageDTO _$PrivateMessageDTOFromJson(Map<String, dynamic> json) =>
    PrivateMessageDTO(
      tmpId: json['tmpId'] as String,
      recvId: (json['recvId'] as num).toInt(),
      content: json['content'] as String,
      type: (json['type'] as num?)?.toInt() ?? 0,
      quoteMessageId: (json['quoteMessageId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PrivateMessageDTOToJson(PrivateMessageDTO instance) =>
    <String, dynamic>{
      'tmpId': instance.tmpId,
      'recvId': instance.recvId,
      'content': instance.content,
      'type': instance.type,
      'quoteMessageId': ?instance.quoteMessageId,
    };
