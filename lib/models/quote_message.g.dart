// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteMessage _$QuoteMessageFromJson(Map<String, dynamic> json) => QuoteMessage(
  id: JsonParse.asInt(json['id']),
  sendId: JsonParse.asNullableInt(json['sendId']),
  content: JsonParse.asNullableString(json['content']),
  type: json['type'] == null ? 0 : JsonParse.asInt(json['type']),
  status: json['status'] == null ? 0 : JsonParse.asInt(json['status']),
);

Map<String, dynamic> _$QuoteMessageToJson(QuoteMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sendId': instance.sendId,
      'content': instance.content,
      'type': instance.type,
      'status': instance.status,
    };
