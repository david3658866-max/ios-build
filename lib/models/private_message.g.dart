// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateMessage _$PrivateMessageFromJson(Map<String, dynamic> json) =>
    PrivateMessage(
      id: JsonParse.asNullableInt(json['id']),
      tmpId: JsonParse.asNullableString(json['tmpId']),
      sendId: JsonParse.asInt(json['sendId']),
      recvId: JsonParse.asInt(json['recvId']),
      content: JsonParse.asNullableString(json['content']),
      type: json['type'] == null ? 0 : JsonParse.asInt(json['type']),
      quoteMessage: json['quoteMessage'] == null
          ? null
          : QuoteMessage.fromJson(json['quoteMessage'] as Map<String, dynamic>),
      status: json['status'] == null ? 0 : JsonParse.asInt(json['status']),
      sendTime: JsonParse.asNullableDateTimeMs(json['sendTime']),
    );

Map<String, dynamic> _$PrivateMessageToJson(PrivateMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tmpId': instance.tmpId,
      'sendId': instance.sendId,
      'recvId': instance.recvId,
      'content': instance.content,
      'type': instance.type,
      'quoteMessage': instance.quoteMessage?.toJson(),
      'status': instance.status,
      'sendTime': instance.sendTime,
    };
